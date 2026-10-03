import QtQuick
import Quickshell
import Quickshell.Io
import qs
pragma Singleton

/**
 * Wallpaper Service
 *
 * Maintains a scanned list of wallpapers (`wallpapers`) with pre-generated
 * 384x216 JPEG thumbnails. Each entry: { path, name, mtime, thumb }. The shell start
 * triggers scanWallpapers(), which runs `lib/thumbnailer.sh` synchronously to
 * regenerate any missing or stale thumbs into `~/.cache/yaks/thumbnails/`,
 * then reads the directory listing newest-first and emits the entries.
 * Thumbs persist across reloads; only files whose source mtime is newer than
 * the thumb get regenerated. The carousel reads `tile.modelData.thumb` with a
 * `?v=<mtime>` cache-buster so a replaced wallpaper file forces a reload.
 */
Item {
    id: root

    property var wallpapers: []
    property string currentWallpaper: ""

    property bool isLoading: false
    property bool hasScanned: false
    // A scan was requested while another was in flight; replayed on completion.
    property bool pendingScan: false

    // Wallpaper transitions. Transition.qml listens for transitionRequested and
    // answers with applyNow() once the freeze is holding the screen; a request that
    // lands mid-flight is parked in _queuedPath instead of starting a second one.
    signal transitionRequested(string path)
    property bool _transitionPending: false
    property string _queuedPath: ""

    // applyNow writes currentWallpaper so Theme re-applies, but the actual
    // wallpaper Image swap is held here until WallpaperTransition.commitPending()
    // fires at wipe start. Otherwise WallpaperBackground picks up the new source
    // mid-freeze and flashes the new wallpaper ~500 ms before the wipe reveals.
    property string _pendingSource: ""
    signal pendingCommitted(string path)

    readonly property string wallpaperListFile: Globals.cacheDir + "/wallpaper.json"
    readonly property string thumbDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/yaks/thumbnails"
    readonly property string thumbScript: Globals.rootDir + "/lib/thumbnailer.sh"

    FileView {
        id: listCacheView
        path: root.wallpaperListFile
        onLoadedChanged: {
            if (loaded && !root.hasScanned) {
                try {
                    var json = JSON.parse(text());
                    if (Array.isArray(json)) root.wallpapers = json;
                } catch (e) {}
            }
        }
    }

    // Atomic writer for the scanned-list cache (atomicWrites defaults to true),
    // replacing the previous `printf > file` shell-out so a crash mid-write can
    // not leave a truncated cache. Read side stays on listCacheView.
    FileView {
        id: listCacheWriter
        path: root.wallpaperListFile
        watchChanges: false
    }

    Connections {
        target: Preferences
        function onLoadedChanged() {
            if (Preferences.loaded) {
                if (root.currentWallpaper === "") {
                    root.currentWallpaper = Preferences.currentWallpaper;
                }
                if (!root.hasScanned) {
                    scanWallpapers();
                }
            }
        }
    }

    Connections {
        target: Preferences.wallpaper
        function onDirectoryChanged() {
            if (Preferences.loaded) {
                refreshWallpapers();
            }
        }
    }

    // A wallpaper change is a *request*; WallpaperTransition owns how it is shown.
    // `animate: false` is the escape hatch for changes that must not cost the user
    // two seconds of frozen desktop — the startup auto-apply is the only caller,
    // because there is no prior image to wipe away.
    function setWallpaper(path, animate = true) {
        if (!path || path === "" || root.currentWallpaper === path) return;

        // A transition already owns the screen. Queue behind it: the wallpaper it
        // is wiping to will be replaced mid-flight otherwise, and the second wipe
        // would never be seen.
        if (root._transitionPending) {
            root._queuedPath = path;
            return;
        }

        if (animate) {
            root._transitionPending = true;
            root.transitionRequested(path);
            return;
        }

        applyNow(path);
    }

    // The real write. Called by setWallpaper on an unanimated change, and by
    // Transition.qml mid-freeze, once the "before" screenshot is already on screen
    // and the new one is safe to put underneath it.
    function applyNow(path) {
        root.currentWallpaper = path;

        Preferences.currentWallpaper = path;

        root._pendingSource = path;
    }

    // Called by WallpaperTransition at wipe start, fully hidden under the
    // overlay's progress=0 fully-opaque frame, so the Image.source swap is
    // invisible. WallpaperBackground listens to pendingCommitted instead of
    // currentWallpaperChanged while a transition is in flight.
    function commitPending() {
        if (root._pendingSource !== "") root.pendingCommitted(root._pendingSource);
    }

    // Recoverable delete: gio trash moves the file to the desktop trash, so a
    // mis-aimed hold costs nothing. A non-zero exit means the file is still
    // there, so the scan is replayed rather than the list left disagreeing with
    // the directory.
    function trash(path) {
        if (!path) return;

        Runner.run(["gio", "trash", path], function (out, exitCode) {
            if (exitCode !== 0) {
                refreshWallpapers();
            }
        });

        var kept = [];
        for (var i = 0; i < root.wallpapers.length; i++) {
            if (root.wallpapers[i].path !== path) kept.push(root.wallpapers[i]);
        }
        root.wallpapers = kept;
        listCacheWriter.setText(JSON.stringify(kept));

        // The background must not keep pointing at a file that no longer exists.
        if (root.currentWallpaper === path) {
            root.currentWallpaper = "";
            Preferences.currentWallpaper = "";
            if (kept.length > 0) setWallpaper(kept[0].path);
        }

        Runner.runDetached(["notify-send", "-a", "Wallpaper", "-i", "symbol:image-trash", "Wallpaper", "The <b>" + path.split("/").pop() + "</b> wallpaper was moved to the trash."]);
    }

    function ensureScanned() {
        if (!hasScanned) {
            if (Preferences.loaded) {
                scanWallpapers();
            } else {
                console.log("[WallpaperService] ensureScanned called before Preferences loaded, skipping until load");
            }
        }
    }
    function refreshWallpapers() { hasScanned = false; scanWallpapers(); }

    function expandPath(path) {
        var home = Globals.homeDir;
        if (path.indexOf("$HOME") === 0) return home + path.substring(5);
        if (path.indexOf("~") === 0) return home + path.substring(1);
        return path;
    }

    /**
     * One shell pipeline: ensure cache dir exists, run thumbnailer to fill
     * missing/stale thumbs, list files newest-first with thumb paths appended.
     * The thumbnailer is sync within the pipeline so the list step is guaranteed
     * to see up-to-date thumb files for every source it returns.
     */
    function scanWallpapers() {
        if (isLoading) {
            // A scan is already running; don't drop this request. Replay the
            // newest one when the in-flight scan finishes, so a directory
            // change arriving mid-scan is never lost.
            root.pendingScan = true;
            return;
        }

        var dir = expandPath(Preferences.wallpaper.directory);
        if (!dir || dir === "") {
            console.warn("[WallpaperService] No valid directory to scan");
            root.wallpapers = [];
            root.hasScanned = true;
            return;
        }

        var wpdirJson = JSON.stringify(dir);
        var thumbdirJson = JSON.stringify(root.thumbDir);
        var scriptJson = JSON.stringify(root.thumbScript);

        var cmd = ["sh", "-c",
            "export PATH=\"" + Globals.toolPath + "\"; " +
            "thumbdir=" + thumbdirJson + "; " +
            "mkdir -p \"$thumbdir\"; " +
            "sh " + scriptJson + " " + wpdirJson + " \"$thumbdir\"; " +
            "find " + wpdirJson + " -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) -printf '%T@\\t%p\\n' | sort -rn | " +
            "while IFS=$'\\t' read -r mtime path; do " +
            "  printf '%s\\t%s\\t%s\\n' \"$mtime\" \"$path\" \"$thumbdir/$(basename \"$path\").jpg\"; " +
            "done"];

        isLoading = true;
        var proc = Runner.run(cmd, function(output, exitCode) {
            isLoading = false;
            hasScanned = true;

            if (exitCode !== 0) {
                root.wallpapers = [];
                console.warn("[WallpaperService] scan failed for", dir, "exit code", exitCode);
                Runner.runDetached(["notify-send", "-a", "Wallpaper", "-i", "symbol:image-error", "Wallpaper", "Could not scan directory: " + dir]);
                root._replayPendingScan();
                return;
            }

            var lines = output.trim().split("\n").filter(l => l.length > 0);
            var entries = [];
            for (var i = 0; i < lines.length; i++) {
                var t1 = lines[i].indexOf("\t");
                if (t1 < 1) continue;
                var t2 = lines[i].indexOf("\t", t1 + 1);
                if (t2 < 0) continue;
                var path = lines[i].substring(t1 + 1, t2);
                entries.push({
                    path: path,
                    name: path.substring(path.lastIndexOf("/") + 1),
                    mtime: parseFloat(lines[i].substring(0, t1)),
                    thumb: lines[i].substring(t2 + 1)
                });
            }
            root.wallpapers = entries;

            listCacheWriter.setText(JSON.stringify(entries));
            if (root.currentWallpaper === "" && entries.length > 0) {
                setWallpaper(entries[0].path, false);
            }

            root._replayPendingScan();
        });

        if (!proc) {
            isLoading = false;
            hasScanned = true;
            scanRetryTimer.start();
        }
    }

    // Run a scan that was requested while one was in flight, if any. Clears the
    // flag first so the replayed scan can itself be superseded cleanly.
    function _replayPendingScan() {
        if (!root.pendingScan)
            return;
        root.pendingScan = false;
        root.scanWallpapers();
    }

    property Timer scanRetryTimer: Timer {
        interval: 1000
        repeat: false
        onTriggered: root.scanWallpapers()
    }

    Component.onCompleted: {
        if (Preferences.loaded) {
            scanWallpapers();
        }
    }
}
