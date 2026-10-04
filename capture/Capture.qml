import Quickshell
import qs

// Native screenshot and screen recording. Not a capsule module: a fullscreen
// exclusive-keys overlay is nothing like the morphing island, so this
// follows the WallpaperTransition precedent — an always-alive Scope declared
// from shell.qml that broadcasts to one overlay PanelWindow per screen.
//
// Phases: idle → capture (freezing) → select. Releasing a selection ends the
// run: the PNG is written and copied to the clipboard, or gpu-screen-recorder
// is handed the region, and the overlay goes away. There is no editor, so
// nothing outlives the grab.
//
// Select is one gesture set, not two modes: drag past the threshold for a
// free region, click for the window under the pointer, Enter for the screen.
Scope {
    id: root

    property string phase: "idle"

    // What a finished selection is spent on. Set by begin(), so every overlay
    // reads the right one from the first frame of the freeze.
    property string mode: "shot"

    property var _overlays: []
    property int _readyCount: 0

    signal broadcastBegin()
    signal broadcastEnter()
    signal broadcastAbort()

    readonly property string saveDir: Quickshell.env("YAKS_SCREENSHOT_DIR")
        || (Globals.homeDir + "/Pictures/Screenshots")

    readonly property string recordDir: Quickshell.env("YAKS_RECORD_DIR")
        || (Globals.homeDir + "/Videos")

    // GSR creates this when it starts and removes it when it exits, so the
    // socket is the recorder's state: asking it beats remembering a pid here,
    // which a shell reload would lose.
    readonly property string recordSock: Quickshell.env("XDG_RUNTIME_DIR")
        + "/yaks-record.sock"

    function toggleShot() {
        if (phase !== "idle") {
            close();
            return;
        }
        begin(false);
    }

    // The selection is worth opening only if nothing is already recording; the
    // same binding stops an existing run, so the decision is one status hop.
    function toggleRecord() {
        if (phase !== "idle") {
            close();
            return;
        }
        Runner.run(["gsr-cli", "-ipc", recordSock, "status"], function (out) {
            if (out.trim() === "running") stopRecording();
            else begin(true);
        });
    }

    function begin(asRecord) {
        if (phase !== "idle") return;
        mode = asRecord ? "record" : "shot";
        Modules.closeAll();
        _readyCount = 0;
        beginPhase("capture");
        broadcastBegin();
        Runner.run(["mkdir", "-p", mode === "record" ? recordDir : saveDir]);
    }

    function close() {
        if (phase === "idle") return;
        beginPhase("idle");
        broadcastAbort();
    }

    // The overlay stays alive because phase stays "select" until close(), so
    // there is no editor reference to keep — the caller hands itself in.
    function finish(overlay) {
        if (phase !== "select" || !overlay) {
            close();
            return;
        }
        if (mode === "record") {
            startRecording(overlay);
            close();
            return;
        }
        const path = saveDir + "/" + stamp() + ".png";
        overlay.grabAndSave(path, function (ok) {
            if (!ok) {
                Runner.run(["notify-send", "Screenshot", "Could not save " + path]);
            } else {
                Runner.run(["sh", "-c", 'wl-copy --type image/png < "$1"', "sh", path]);
                Runner.run(["notify-send", "Screenshot", "Saved " + path]);
            }
            close();
        });
    }

    // GSR wants a global region in the coordinates slurp prints, and sel is
    // screen-local, so the screen origin goes back in. A whole-screen
    // selection needs no special case: it is already the monitor's rect.
    //
    // It runs in its own transient unit like an app launch — yaks is a systemd
    // user service with KillMode=control-group, so a plain detached child would
    // be SIGKILLed mid-file by a shell restart. The IPC socket is what stops it.
    function startRecording(overlay) {
        const sel = overlay.sel;
        const scr = overlay.modelData;
        const region = sel.width + "x" + sel.height
            + "+" + (sel.x + scr.x) + "+" + (sel.y + scr.y);
        const path = recordDir + "/" + stamp() + ".mp4";
        Runner.run(Launcher._appUnit.concat([
            "gpu-screen-recorder",
            "-w", "region",
            "-region", region,
            "-c", "mp4",
            "-q", "ultra",
            "-f", "144",
            "-a", "default_output",
            "-ipc", recordSock,
            "-o", path
        ]), function (out, code) {
            if (code === 0) {
                Runner.run(["notify-send", "Recording", "Recording " + path]);
            } else {
                Runner.run(["notify-send", "Recording", "Could not start the recorder"]);
            }
        });
    }

    // gsr-cli stop finalises the container and only then prints the path, so
    // this is also the save confirmation — no polling and no exit code guess.
    function stopRecording() {
        Runner.run(["gsr-cli", "-ipc", recordSock, "stop"], function (out, code) {
            const path = out.trim();
            Runner.run(["notify-send", "Recording", code === 0 && path
                ? "Saved " + path
                : "Nothing was recording"]);
        });
    }

    function registerOverlay(o) {
        if (_overlays.indexOf(o) < 0) _overlays.push(o);
    }

    function unregisterOverlay(o) {
        const i = _overlays.indexOf(o);
        if (i >= 0) _overlays.splice(i, 1);
    }

    function reportReady(overlay) {
        if (overlay._counted) return;
        overlay._counted = true;
        _readyCount++;
        if (_readyCount >= _overlays.length) {
            beginPhase("select");
            broadcastEnter();
        }
    }

    function beginPhase(next) {
        if (phase === next) return;
        phase = next;
        console.log("[Capture] ->", next);
    }

    // Compositor rects for one screen, in that screen's local coordinates.
    // Not cached: a window can appear between the freeze and the click.
    // Empty for a recording: GSR's -w window id is X11-only, so a window pick
    // would record a static rect that the window could walk out of.
    function windowRectsFor(screenName) {
        const out = [];
        if (mode !== "shot") return out;
        let scr = null;
        for (let i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === screenName) {
                scr = Quickshell.screens[i];
                break;
            }
        }
        if (!scr) return out;
        const ws = Compositor.activeWorkspaceId;
        const clients = Compositor.windowByAddress;
        for (const addr in clients) {
            const c = clients[addr];
            if (!c || !c.at || !c.size) continue;
            // hyprctl lists scratchpad and off-workspace windows too, and on a
            // tiling layout their rects land on top of the visible ones — so
            // the pick would outline a window the user cannot even see.
            if (c.hidden) continue;
            if (ws >= 0 && c.workspace && c.workspace.id !== ws) continue;
            const r = _clamp({
                x: c.at[0] - scr.x,
                y: c.at[1] - scr.y,
                w: c.size[0],
                h: c.size[1]
            }, scr.width, scr.height);
            if (r.w > 8 && r.h > 8) out.push(r);
        }
        return out;
    }

    // Trim a rect to a 0,0,w,h box — a window can hang off the screen edge.
    function _clamp(r, w, h) {
        const x = Math.max(0, Math.min(r.x, w));
        const y = Math.max(0, Math.min(r.y, h));
        return {
            x: x,
            y: y,
            w: Math.max(0, Math.min(r.w, w - x)),
            h: Math.max(0, Math.min(r.h, h - y))
        };
    }

    function stamp() {
        const d = new Date();
        const p = function (v) { return (v < 10 ? "0" : "") + v; };
        return d.getFullYear()
            + p(d.getMonth() + 1) + p(d.getDate())
            + "_" + p(d.getHours()) + p(d.getMinutes()) + p(d.getSeconds());
    }

    Variants {
        model: Quickshell.screens
        Overlay { }
    }
}