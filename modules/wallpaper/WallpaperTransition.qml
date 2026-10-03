import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs

/**
 * Wallpaper freeze
 *
 * Screenshots the whole desktop, applies the new wallpaper behind that frozen
 * image, then erases the screenshot with a shader so the new wallpaper is
 * revealed underneath. Every user wallpaper change goes through here; the point
 * is that the bar, an open popout and the wallpaper itself all land at once,
 * which an in-process crossfade cannot do — it only ever has the one item to
 * animate.
 *
 * The mechanism is shibui-dots' shader-transition, retargeted in-process:
 * upstream launches a second quickshell to run arbitrary theme scripts, so its
 * window is always-on and it ends in Qt.quit(). Here the shell *is* the process,
 * so the windows hide between transitions and `done` unwinds instead of quitting.
 *
 * The phase machine is a plain string, not an enum or a set of booleans: the
 * transitions are strictly sequential, each one entered exactly once, and a
 * string makes an illegal jump a visible no-op rather than a state to reason
 * about.
 *
 * Phase: waitForOSDHide → takingScreenshots → loadingScreenshots → overlaySettle
 *      → runningTheme → runningTransition → done
 */
Scope {
    id: root

    property string phase: "done"
    readonly property int totalScreens: Quickshell.screens.length
    property int screensReadyCount: 0
    property int transitionsFinishedCount: 0

    // The screenshot a wipe is replacing. Held by the root so every screen's
    // window reads the same one.
    property string pendingPath: ""

    // Cache-buster for the screenshot loads. grim rewrites the same paths every
    // time and Qt will not re-decode an unchanged source URL, so without this
    // the second transition shows the first transition's screenshot.
    property double cacheBuster: Date.now()

    readonly property string shotDir: Globals.cacheDir + "/transition"
    readonly property string grimCmd: "mkdir -p \"" + shotDir + "\" && for m in $(hyprctl monitors -j | jq -r '.[].name'); do grim -o \"$m\" \"" + shotDir + "/BG_$m.png\" & done; wait"

    readonly property int transitionMs: Math.max(100, Math.round(Preferences.wallpaper.transitionDuration))

    // One settle timer per pause, all named for what they are waiting on rather
    // than reused, because each phase needs a different duration.
    readonly property int _osdHideMs: 150
    // One composited frame is all the opaque overlay needs before the theme
    // swaps underneath it; the phase name is kept for the log.
    readonly property int _overlaySettleMs: 80
    readonly property int _loadTimeoutMs: 1500
    // Backstop only: if Theme never fires `applied` the freeze must still end.
    readonly property int _themeTimeoutMs: 2000

    // ── COORDINATION ───────────────────────────────────────────────────
    // One window per screen, all in one process, so the phases are shared state
    // rather than cross-process messages — but the two broadcasts are still the
    // only way in: a window cannot join a phase halfway.
    signal broadcastLoadScreenshots()
    signal broadcastStartTransition()
    signal broadcastFinish()

    Connections {
        target: Wallpaper
        function onTransitionRequested(path) {
            root.start(path);
        }
    }

    Connections {
        target: Theme
        function onApplied() {
            if (root.phase === "runningTheme") root.beginPhase("runningTransition");
        }
    }

    function start(path) {
        if (root.phase !== "done" || !path) return;
        root.pendingPath = path;
        root.beginPhase("waitForOSDHide");
    }

    function beginPhase(next) {
        root.phase = next;
        console.log("[Transition] ->", next);

        switch (next) {
            case "waitForOSDHide":
                // The bar has to be gone *before* grim looks, and the compositor
                // needs a frame or two to actually stop drawing it. A bar baked
                // into the screenshot would reappear after the wipe as a pop
                // rather than fading with the rest of the desktop.
                Modules.osdSuppressed = true;
                osdHideTimer.restart();
                break;

            case "takingScreenshots":
                screenshotProcess.running = true;
                // A failed spawn never reaches onExited, so without this a
                // missing grim wedges the desktop in the frozen screenshot for
                // good. Degrading to an instant swap is the right failure.
                if (!screenshotProcess.running) beginPhase("loadingScreenshots");
                break;

            case "loadingScreenshots":
                root.screensReadyCount = 0;
                root.broadcastLoadScreenshots();
                loadTimeoutTimer.restart();
                break;

            case "overlaySettle":
                loadTimeoutTimer.stop();
                loadSettleTimer.restart();
                break;

            case "runningTheme":
                // The desktop is already frozen on screen, so this is the one
                // moment a wallpaper can change without the user seeing it
                // happen. Apply the palette immediately (skipping Theme's
                // debounce) and wait for Theme.applied — not a fixed timer — so
                // the wipe starts the instant the theme is actually done.
                Wallpaper.applyNow(root.pendingPath);
                Theme.requestApply("wallpaper", true);
                themeTimeoutTimer.restart();
                break;

            case "runningTransition":
                themeTimeoutTimer.stop();
                root.transitionsFinishedCount = 0;
                // Commit the deferred wallpaper source swap. The overlay is fully
                // opaque at progress=0, so the swap is invisible; otherwise the
                // wallpaper would flash ~500 ms before the wipe reveals it.
                Wallpaper.commitPending();
                root.broadcastStartTransition();
                break;

            case "done":
                themeTimeoutTimer.stop();
                root.broadcastFinish();
                Modules.osdSuppressed = false;
                root.pendingPath = "";
                root.cacheBuster = Date.now();
                // The freeze is over; release the deferred-swap guard so the next
                // unanimated apply reaches WallpaperBackground directly. Cleared
                // before drainQueued so its applyNow is not itself deferred.
                Wallpaper._transitionPending = false;
                root.drainQueued();
                break;
        }
    }

    // A request that landed mid-flight cannot start a second freeze — the screen
    // is already showing a wipe. Apply it plain instead; two freezes back to back
    // read worse than a wallpaper that simply cuts.
    function drainQueued() {
        if (Wallpaper._queuedPath === "") return;
        var queued = Wallpaper._queuedPath;
        Wallpaper._queuedPath = "";
        Wallpaper.applyNow(queued);
    }

    function reportScreenReady() {
        if (root.phase !== "loadingScreenshots") return;
        root.screensReadyCount++;
        if (root.screensReadyCount >= root.totalScreens) beginPhase("overlaySettle");
    }

    function reportTransitionFinished() {
        if (root.phase !== "runningTransition") return;
        root.transitionsFinishedCount++;
        if (root.transitionsFinishedCount >= root.totalScreens) beginPhase("done");
    }

    // ── TIMERS ─────────────────────────────────────────────────────────
    Timer {
        id: osdHideTimer
        interval: root._osdHideMs
        onTriggered: root.beginPhase("takingScreenshots")
    }

    Timer {
        id: loadSettleTimer
        interval: root._overlaySettleMs
        onTriggered: root.beginPhase("runningTheme")
    }

    Timer {
        id: themeTimeoutTimer
        interval: root._themeTimeoutMs
        onTriggered: {
            if (root.phase === "runningTheme") root.beginPhase("runningTransition");
        }
    }

    // The screenshot is a plain file and a screen whose monitor name never
    // matches what hyprctl reports would leave the ready count short forever —
    // pinned, on stale screenshots, with no way out but restarting the shell.
    // Proceeding is always recoverable; hanging is not.
    Timer {
        id: loadTimeoutTimer
        interval: root._loadTimeoutMs
        onTriggered: {
            if (root.phase === "loadingScreenshots") root.beginPhase("overlaySettle");
        }
    }

    // ── SCREENSHOT ──────────────────────────────────────────────────────
    Process {
        id: screenshotProcess
        running: false
        command: ["bash", "-c", root.grimCmd]
        onExited: root.beginPhase("loadingScreenshots")
    }

    // ── WINDOWS ─────────────────────────────────────────────────────────
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: transitionWindow

            property var modelData
            screen: modelData

            WlrLayershell.namespace: "yaks:transition"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"
            // Hidden between transitions. Upstream keeps this window up for the
            // life of its throwaway process; yaks has to survive the wipe, and a
            // permanently-live full-screen Overlay window would sit over the
            // desktop swallowing input.
            visible: false

            Connections {
                target: root

                function onBroadcastLoadScreenshots() {
                    // progress left at 1.0 (transparent) by the previous wipe, and
                    // only reset by restart() at runningTransition — too late. Reset
                    // here so the overlay is fully opaque the instant it appears,
                    // hiding the runningTheme source swap underneath it.
                    transitionAnim.stop();
                    shader.progress = 0.0;
                    transitionWindow.visible = true;
                    screenshotImage.source = "file://" + root.shotDir + "/BG_" + modelData.name + ".png?t=" + root.cacheBuster;
                }

                function onBroadcastStartTransition() {
                    transitionAnim.restart();
                }

                function onBroadcastFinish() {
                    transitionWindow.visible = false;
                    screenshotImage.source = "";
                }
            }

            // Never shown: the shader samples it as a texture, and an Image with
            // no visible pixels still decodes and uploads. Making it visible
            // would just draw the frozen desktop twice.
            Image {
                id: screenshotImage
                visible: false
                onStatusChanged: {
                    if (status === Image.Ready) root.reportScreenReady();
                }
            }

            ShaderEffect {
                id: shader
                anchors.fill: parent

                // Declaration order matches the ubuf block in wipe.frag
                // (qt_Matrix, qt_Opacity, progress, seed, …) — Qt rejects the
                // shader outright if these two get out of step. `seed` is unused
                // by this fragment — it is declared only because the ubuf block
                // requires it, and removing it would be a load failure.
                property real progress: 0.0
                property real seed: 0.5
                property Image sourceImage: screenshotImage

                fragmentShader: Qt.resolvedUrl("../../assets/shaders/wipe.frag.qsb")
            }

            NumberAnimation {
                id: transitionAnim
                target: shader
                property: "progress"
                from: 0.0
                to: 1.0
                duration: root.transitionMs
                easing.type: Easing.InOutQuad

                onStopped: root.reportTransitionFinished()
            }
        }
    }
}