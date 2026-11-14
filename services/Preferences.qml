import QtQuick
import Quickshell
import Quickshell.Io
import qs
import "../lib/apps.js" as Apps
pragma Singleton

QtObject {
    id: root

    property bool loaded: false

    // ── USER GROUPS ──────────────────────────────

    property QtObject notifications: QtObject {
        property int mode: 0 // 0: Normal, 1: DND (Silent)

        onModeChanged: root.requestSave()
    }

    property QtObject bar: QtObject {
        property string position: "top"
        property int height: 55
        property int marginTop: 10
        property int workspaceCount: 5
        property bool clock12Hour: false

        // Space the bar reserves from its screen edge.
        readonly property int reservedZone: height + marginTop

        onPositionChanged: root.requestSave()
        onHeightChanged: root.requestSave()
        onMarginTopChanged: root.requestSave()
        onWorkspaceCountChanged: root.requestSave()
        onClock12HourChanged: root.requestSave()
    }

    property QtObject wallpaper: QtObject {
        property string directory: ""
        property int transitionDuration: 1750

        onDirectoryChanged: root.requestSave()
        onTransitionDurationChanged: root.requestSave()
    }

    property QtObject applications: QtObject {
        // Defaults come from the single hook registry (lib/apps.js), so
        // registering an app there is enough to make its toggle appear here.
        property var themedApps: Apps.defaultThemedApps()

        onThemedAppsChanged: root.requestSave()
    }

    property QtObject globals: QtObject {
        property string shellFont: "Outfit"
        property string rounding: "round"
        property double backgroundOpacity: 1.0
        property bool capsuleOutline: true
        property bool shadow: true
        property int scale: 1 // 0: 0.9x, 1: 1.0x, 2: 1.1x

        onShellFontChanged: root.requestSave()
        onRoundingChanged: root.requestSave()
        onBackgroundOpacityChanged: root.requestSave()
        onCapsuleOutlineChanged: root.requestSave()
        onShadowChanged: root.requestSave()
        onScaleChanged: {
            if (scale === 0) root.bar.height = 50;
            else if (scale === 1) root.bar.height = 55;
            else if (scale === 2) root.bar.height = 60;
            root.requestSave();
        }
    }

    // ── TOP-LEVEL VALUES ─────────────────────────────────────────────────

    property string currentWallpaper: ""

    onCurrentWallpaperChanged: root.requestSave()

    // ── SCHEMA ───────────────────────────────────────────────────────────

    property var _schema: [
        ["notifications", "mode"],
        ["bar", "position"],
        ["globals", "scale"],
        ["bar", "height"],
        ["bar", "marginTop"],
        ["bar", "workspaceCount"],
        ["bar", "clock12Hour"],
        ["wallpaper", "directory"],
        ["wallpaper", "transitionDuration"],
        ["applications", "themedApps"],
        ["globals", "shellFont"],
        ["globals", "rounding"],
        ["globals", "backgroundOpacity"],
        ["globals", "capsuleOutline"],
        ["globals", "shadow"],
        ["currentWallpaper"]
    ]

    function _get(path) {
        var o = root;
        for (var i = 0; i < path.length - 1; i++) o = o[path[i]];
        return o[path[path.length - 1]];
    }

    function _set(path, val) {
        var o = root;
        for (var i = 0; i < path.length - 1; i++) o = o[path[i]];
        o[path[path.length - 1]] = val;
    }

    function _getData(data, path) {
        for (var i = 0; i < path.length; i++) {
            if (data == null || typeof data !== "object") return undefined;
            data = data[path[i]];
        }
        return data;
    }

    function _setData(data, path, val) {
        for (var i = 0; i < path.length - 1; i++) {
            if (!data[path[i]] || typeof data[path[i]] !== "object") data[path[i]] = {};
            data = data[path[i]];
        }
        data[path[path.length - 1]] = val;
    }

    // ── PERSISTENCE ──────────────────────────────────────────────────────

    readonly property string prefsFile: Globals.dataDir + "/preferences.json"

    // ── WRITE SERIALISATION ─────────────────────────────────────────────
    // FileView.setText() is asynchronous, so a save requested while one is
    // already in flight must not start a second overlapping write — the older
    // one could land last and clobber the newer state. `_writing` guards that:
    // while a write is in flight, `save()` only marks `_dirty` and the write
    // is started when the current one completes, so at most one is ever live.
    property bool _dirty: false
    property bool _writing: false
    property string _pendingContent: ""

    function save() {
        if (!loaded) return;
        var data = {};
        for (var i = 0; i < _schema.length; i++)
            _setData(data, _schema[i], _get(_schema[i]));

        root._pendingContent = JSON.stringify(data, null, 2);
        root._dirty = true;
        root._flush();
    }

    function _flush() {
        if (root._writing || !root._dirty)
            return;
        root._dirty = false;
        root._writing = true;
        prefsWriter.setText(root._pendingContent);
    }

    property Timer saveTimer: Timer {
        interval: 500
        repeat: false
        onTriggered: root.save()
    }

    function requestSave() {
        if (loaded) saveTimer.restart();
    }

    // ── INITIALISATION ──────────────────────────────────────────────────

    Component.onCompleted: {
        // Create the data dir first; FileView.setText() does not create parent
        // directories and the first save can follow immediately after a
        // missing-file boot, so sequencing here avoids a lost initial write.
        Runner.run(["mkdir", "-p", Globals.dataDir], function () {
            Runner.run(["test", "-f", root.prefsFile], function (out, exitCode) {
                if (exitCode !== 0) {
                    console.log("[Preferences] No preferences file found. Booting with defaults immediately.");
                    safetyTimer.stop();
                    root.loaded = true;
                    root.requestSave(); // Create the file
                } else {
                    prefsFileView.reload();
                }
            });
        });
    }

    property Timer safetyTimer: Timer {
        interval: 10000
        running: true
        repeat: false
        onTriggered: {
            if (!root.loaded) {
                console.warn("[Preferences] Load timed out, assuming defaults. Manual changes will now be allowed.");
                root.loaded = true;
            }
        }
    }

    property FileView prefsFileView: FileView {
        path: root.prefsFile
        watchChanges: false
        onLoadedChanged: {
            if (loaded) {
                const rawText = text();
                if (rawText.trim().length === 0) {
                    console.log("[Preferences] File is empty, skipping parse.");
                    safetyTimer.stop();
                    root.loaded = true;
                    return;
                }

                try {
                    var data = JSON.parse(rawText);
                    if (!data || typeof data !== "object") throw new Error("Invalid JSON");

                    // Snapshot default container values BEFORE the schema-driven load
                    // overwrites them — later used to reconcile stale entries.
                    var containerDefaults = Object.create(null);
                    for (var si = 0; si < _schema.length; si++) {
                        var snapPath = _schema[si];
                        var walker = root;
                        for (var pi = 0; pi < snapPath.length; pi++) walker = walker[snapPath[pi]];
                        if (Array.isArray(walker)) containerDefaults[snapPath.join(".")] = walker.slice();
                        else if (walker && typeof walker === "object") containerDefaults[snapPath.join(".")] = Object.assign({}, walker);
                    }

                    // ── SCHEMA-DRIVEN LOAD ─────────────────────────────────
                    for (var i = 0; i < _schema.length; i++) {
                        var path = _schema[i];
                        // applications.themedApps is handled by merge below
                        if (path.length === 2 && path[0] === "applications" && path[1] === "themedApps") continue;
                        var val = _getData(data, path);
                        if (val !== undefined) _set(path, val);
                    }

                    // ── RECONCILE CONTAINERS ────────────────────────────
                    // Arrays keep only entries a default still lists (a
                    // component removed by a shell update must not linger) and
                    // then adopt any default entry they are missing, so a
                    // component added by an update shows up without wiping the
                    // user's saved order. Dictionaries only ever gain keys —
                    // removing one would silently re-enable a default the user
                    // deliberately turned off.
                    var reconciled = false;
                    for (var containerKey in containerDefaults) {
                        if (containerKey === "applications.themedApps") continue;
                        var parts = containerKey.split(".");
                        var current = _get(parts);
                        var fallback = containerDefaults[containerKey];
                        if (Array.isArray(fallback) && Array.isArray(current)) {
                            var valid = Object.create(null);
                            for (var vi = 0; vi < fallback.length; vi++) valid[fallback[vi]] = true;
                            var next = current.filter(function (v) { return !!valid[v]; });
                            for (var mi = 0; mi < fallback.length; mi++)
                                if (next.indexOf(fallback[mi]) === -1) next.push(fallback[mi]);
                            if (next.join(" ") !== current.join(" ")) {
                                _set(parts, next);
                                reconciled = true;
                            }
                        } else if (fallback && current && typeof fallback === "object" && typeof current === "object") {
                            var merged = Object.assign({}, current);
                            var added = false;
                            for (var key in fallback) {
                                if (!(key in merged)) { merged[key] = fallback[key]; added = true; }
                            }
                            if (added) {
                                _set(parts, merged);
                                reconciled = true;
                            }
                        }
                    }
                    var components = root.bar.componentsEnabled;
                    if (components && typeof components === "object" && "dock" in components) {
                        var prunedComponents = Object.assign({}, components);
                        delete prunedComponents.dock;
                        root.bar.componentsEnabled = prunedComponents;
                        reconciled = true;
                    }
                    if (reconciled)
                        console.log("[Preferences] Reconciled preferences with the current defaults.");

                    // ── MERGE DICTIONARIES ─────────────────────────────────
                    var savedApps = _getData(data, ["applications", "themedApps"]);
                    if (savedApps !== undefined && typeof savedApps === "object") {
                        var currentApps = root.applications.themedApps;
                        var appsChanged = false;
                        for (var appId in savedApps) {
                            if (!(appId in currentApps)) continue;
                            if (currentApps[appId] !== savedApps[appId]) {
                                currentApps[appId] = savedApps[appId];
                                appsChanged = true;
                            }
                        }
                        if (appsChanged) {
                            // Reassign to trigger property change
                            root.applications.themedApps = Object.assign({}, currentApps);
                        }
                    }

                    safetyTimer.stop();
                    root.loaded = true;

                    if (reconciled) root.requestSave();
                } catch (e) {
                    console.error("[Preferences] Failed to parse preferences file:", e.message);
                }
            }
        }
    }

    // Atomic writer (atomicWrites defaults to true): content is written to a
    // temp file and renamed over the target only on success, so a crash mid
    // write can never truncate preferences.json. Reads stay on prefsFileView;
    // this view is write-only and does not watch for external changes.
    property FileView prefsWriter: FileView {
        path: root.prefsFile
        watchChanges: false

        onSaved: {
            root._writing = false;
            root._flush(); // Start a write queued while this one was in flight.
        }
        onSaveFailed: function (error) {
            console.error("[Preferences] Failed to save preferences:", error);
            root._writing = false;
            // Keep any newer queued content rather than dropping it; the next
            // save or debounce will retry it.
        }
    }
}
