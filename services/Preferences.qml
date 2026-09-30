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
        property bool overhang: false
        property int overhangReserve: 70
        property int workspaceCount: 5
        property var components: ["workspaces", "dock", "indicators", "clock"]
        property var componentsEnabled: ({"workspaces": true, "dock": true, "indicators": true, "clock": true})

        // Space the bar reserves from its screen edge. With overhang on, only
        // `overhangReserve`% of the bar height stays reserved (plus the top
        // margin); the remainder of the floating capsule sits over windows.
        readonly property int reservedZone: overhang
            ? marginTop + Math.round(height * Math.max(0, Math.min(100, overhangReserve)) / 100)
            : height + marginTop

        onPositionChanged: root.requestSave()
        onHeightChanged: root.requestSave()
        onMarginTopChanged: root.requestSave()
        onOverhangChanged: root.requestSave()
        onOverhangReserveChanged: root.requestSave()
        onWorkspaceCountChanged: root.requestSave()
        onComponentsChanged: root.requestSave()
        onComponentsEnabledChanged: root.requestSave()
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
        property bool islandOutline: true
        property bool shadow: true
        property int scale: 1 // 0: 0.9x, 1: 1.0x, 2: 1.1x

        onShellFontChanged: root.requestSave()
        onRoundingChanged: root.requestSave()
        onBackgroundOpacityChanged: root.requestSave()
        onIslandOutlineChanged: root.requestSave()
        onShadowChanged: root.requestSave()
        onScaleChanged: {
            if (scale === 0) root.bar.height = 50;
            else if (scale === 1) root.bar.height = 55;
            else if (scale === 2) root.bar.height = 60;
            root.requestSave();
        }
    }

    property QtObject indicators: QtObject {
        property var order: ["notifications", "wifi", "settings", "power"]

        onOrderChanged: root.requestSave()
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
        ["bar", "overhang"],
        ["bar", "overhangReserve"],
        ["bar", "workspaceCount"],
        ["bar", "components"],
        ["bar", "componentsEnabled"],
        ["wallpaper", "directory"],
        ["wallpaper", "transitionDuration"],
        ["applications", "themedApps"],
        ["globals", "shellFont"],
        ["globals", "rounding"],
        ["globals", "backgroundOpacity"],
        ["globals", "islandOutline"],
        ["globals", "shadow"],
        ["indicators", "order"],
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

    // One-time bootstrap so the data directory exists before the first write.
    // FileView.setText() does not create parent directories.
    property Process _dataDirProc: Process {
        command: ["mkdir", "-p", Globals.dataDir]
    }

    // ── INITIALISATION ──────────────────────────────────────────────────

    Component.onCompleted: {
        // Create the data dir first; the first save can follow immediately after
        // a missing-file boot, so sequencing here avoids a lost initial write.
        _dataDirProc.onExited.connect(function () {
            ProcessService.run(["sh", "-c", "test -f " + root.prefsFile], function(out, exitCode) {
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
        _dataDirProc.running = true;
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

                    // Snapshot the default valid components BEFORE overwriting them with user data
                    var defaultValidComponents = root.bar.components.slice();

                    // Snapshot default array values BEFORE the schema-driven load
                    // overwrites them — later used to prune stale array entries.
                    var arrayDefaults = Object.create(null);
                    for (var si = 0; si < _schema.length; si++) {
                        var snapPath = _schema[si];
                        var walker = root;
                        for (var pi = 0; pi < snapPath.length; pi++) walker = walker[snapPath[pi]];
                        if (Array.isArray(walker)) arrayDefaults[snapPath.join(".")] = walker.slice();
                    }

                    // ── SCHEMA-DRIVEN LOAD ─────────────────────────────────
                    for (var i = 0; i < _schema.length; i++) {
                        var path = _schema[i];
                        // applications.themedApps is handled by merge below
                        if (path.length === 2 && path[0] === "applications" && path[1] === "themedApps") continue;
                    var val = _getData(data, path);
                    if (val !== undefined) _set(path, val);
                }

                // Capture the legacy free-form radius before the stale-key
                // prune removes it, so it can be migrated to a preset below.
                var legacyRadius = _getData(data, ["globals", "cornerRadius"]);

                // ── PRUNE STALE KEYS ─────────────────────────────────
                var allowed = Object.create(null);
                for (var p = 0; p < _schema.length; p++) {
                    var sp = _schema[p];
                    if (!allowed[sp[0]]) allowed[sp[0]] = Object.create(null);
                    if (sp.length > 1) allowed[sp[0]][sp[1]] = true;
                }

                var prunedAny = false;
                for (var key in data) {
                    if (!allowed[key]) {
                        delete data[key];
                        prunedAny = true;
                        continue;
                    }
                    if (data[key] && typeof data[key] === "object") {
                        for (var sub in data[key]) {
                            if (!allowed[key][sub]) {
                                delete data[key][sub];
                                prunedAny = true;
                            }
                        }
                    }
                }
                for (var arrayKey in arrayDefaults) {
                    var parts = arrayKey.split(".");
                    var arr = _get(parts);
                    if (!Array.isArray(arr)) continue;
                    var validEntries = Object.create(null);
                    for (var vi = 0; vi < arrayDefaults[arrayKey].length; vi++)
                        validEntries[arrayDefaults[arrayKey][vi]] = true;
                    var filtered = arr.filter(function(v) { return !!validEntries[v]; });
                    if (filtered.length !== arr.length) {
                        _set(parts, filtered);
                        prunedAny = true;
                    }
                }
                if (prunedAny)
                    console.log("[Preferences] Pruned stale entries from preferences file.");

                // ── MERGE DICTIONARIES ─────────────────────────────────
                    var savedApps = _getData(data, ["applications", "themedApps"]);
                    if (savedApps !== undefined && typeof savedApps === "object") {
                        var currentApps = root.applications.themedApps;
                    var appsChanged = false;
                    for (var key in savedApps) {
                        if (!(key in currentApps)) continue;
                        if (currentApps[key] !== savedApps[key]) {
                            currentApps[key] = savedApps[key];
                            appsChanged = true;
                        }
                    }
                    if (appsChanged) {
                        // Reassign to trigger property change
                        root.applications.themedApps = Object.assign({}, currentApps);
                    }
                }

                    // ── MIGRATIONS ─────────────────────────────────────────

                    var loadedEnabled = root.bar.componentsEnabled || {};
                    var cleanedEnabled = {};
                    for (var i = 0; i < defaultValidComponents.length; i++) {
                        var c = defaultValidComponents[i];
                        cleanedEnabled[c] = loadedEnabled[c] !== undefined ? loadedEnabled[c] : true;
                    }

                    var migrated = false;

                    // Legacy free-form cornerRadius -> nearest designed preset.
                    if (legacyRadius !== undefined && _getData(data, ["globals", "rounding"]) === undefined) {
                        root.globals.rounding = legacyRadius <= 10 ? "sharp"
                                            : legacyRadius <= 20 ? "soft" : "round";
                        console.log("[Preferences] Migrated legacy cornerRadius " + legacyRadius + " -> rounding=" + root.globals.rounding);
                        migrated = true;
                    }

                    if (Object.keys(loadedEnabled).length !== defaultValidComponents.length) {
                        root.bar.componentsEnabled = cleanedEnabled;
                        console.log("[Preferences] Cleaned up legacy/invalid components from bar configuration.");
                        root.bar = Object.assign({}, root.bar);
                        migrated = true;
                    }
                    safetyTimer.stop();
                    root.loaded = true;

                    if (migrated || prunedAny) root.requestSave();
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
