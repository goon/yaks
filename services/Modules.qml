import QtQuick
import Quickshell
import qs
pragma Singleton

QtObject {
    id: root

    // ── STATE ─────────────────────────────────────────────────────────
    // The single source of truth for "what is the island showing". A module name
    // means open; "" means closed. Capsule.qml owns what is actually *loaded*,
    // which lags this by the collapse animation — everything else asks here.
    property string activeModuleName: ""
    property Item activeModuleItem: null

    property var _pendingCallbacks: []

// Run cb once the active module's item exists. The only caller is
    // toggleSettings, which needs the page stack to exist before it can push.
    // Queued callbacks are dropped when the island closes, so one can never fire
    // against the next module.
    function runWhenModuleReady(callback) {
        if (activeModuleItem) Qt.callLater(callback);
        else _pendingCallbacks.push(callback);
    }

    // The queue belongs to the *intent*, not the item: activeModuleItem is a
    // mirror of the capsule loader and legitimately outlives closeAll() through
    // the collapse animation and the eviction delay. What invalidates a queued
    // callback is the intent going away, not the item — the mirror clearing is
    // Capsule's business alone, and clearing it here is what left a re-entered
    // cached module with no item to key against.
    onActiveModuleNameChanged: {
        if (activeModuleName === "") _pendingCallbacks = [];
    }

    onActiveModuleItemChanged: {
        if (!activeModuleItem) return;
        while (_pendingCallbacks.length > 0) {
            var cb = _pendingCallbacks.shift();
            if (typeof cb === "function") Qt.callLater(cb);
        }
    }

    // ── MODULE REGISTRY ──────────────────────────────────────────────────
    // A module's QML source, the width the capsule morphs toward before the
    // module can report its own, and how the capsule should treat it: a
    // `popout` takes focus and captures clicks outside, a `toast` does
    // neither. Keep widths in step with each module's implicitWidth.
    readonly property var moduleRegistry: ({
        "launcher":      { source: "../modules/launcher/Launcher.qml",      width: 400, height: 500, kind: "popout", evictionTime: 10000 },
        "settings":      { source: "../modules/settings/Settings.qml",      width: 400, height: 500, kind: "popout", evictionTime: 10000 },
        "wallpaper":     { source: "../modules/wallpaper/Wallpaper.qml",                height: 500, kind: "popout", evictionTime: 3000 },
        "calendar":      { source: "../modules/calendar/Calendar.qml",     width: 320, height: 260, kind: "popout", evictionTime: 5000 },
"forecast": { source: "../modules/forecast/Forecast.qml", width: 300, height: 276, kind: "popout", evictionTime: 5000 },
        // The volume toast is the bar face wearing a slider: its height tracks
        // `bar.height`, so the pre-load estimate must too or the capsule morphs
        // to 100 and then snaps back.
        "volume_toast":   { source: "../modules/toasts/VolumeToast.qml",     width: 300, height: Preferences.bar.height, kind: "toast",  evictionTime: 3000 },
        "notification_toast": { source: "../modules/toasts/NotificationToast.qml", width: 420, height: 140, kind: "toast", evictionTime: 3000 }
    })

    // Pre-load estimate for the morph target; a generic default when the
    // registry has nothing better.
    function expectedWidth(name) {
        var module = root.moduleRegistry[name];
        return (module && module.width) ? module.width : 420;
    }

    function expectedHeight(name) {
        var module = root.moduleRegistry[name];
        return (module && module.height) ? module.height : 500;
    }

    function evictionTime(name) {
        var module = root.moduleRegistry[name];
        return (module && module.evictionTime) ? module.evictionTime : 5000;
    }

    // Resolve a module's QML file from the registry; empty string if unknown.
    function moduleSource(name) {
        var module = root.moduleRegistry[name];
        return module ? module.source : "";
    }

    function moduleKind(name) {
        var module = root.moduleRegistry[name];
        return (module && module.kind) ? module.kind : "popout";
    }

    // ── CONTROL APIS ──────────────────────────────────────────────────
    function toggleModule(name) {
        if (activeModuleName === name) closeAll();
        else activeModuleName = name;
    }

    function openModule(name) {
        if (activeModuleName === name) return;
        activeModuleName = name;
    }

    function closeAll() {
        activeModuleName = "";
    }

    // Plain toggles go through toggleModule(name); only modules needing stack
    // navigation get a wrapper.
    function toggleSettings(pageName) {
        if (activeModuleName !== "settings") {
            openModule("settings");
            if (pageName !== undefined) {
                runWhenModuleReady(() => {
                    if (activeModuleItem && typeof activeModuleItem.changePage === "function")
                        activeModuleItem.changePage(pageName);
                });
            }
            return;
        }

        if (pageName === undefined) {
            closeAll();
        } else if (activeModuleItem) {
            var stack = activeModuleItem.pageStack;
            if (stack && stack.selectedPage === pageName) closeAll();
            else if (typeof activeModuleItem.changePage === "function") activeModuleItem.changePage(pageName);
        }
    }

    // ── VOLUME TOAST ───────────────────────────────────────────────────
    // Fires on every volume or mute change once the shell has settled, and
    // closes itself again after a beat. It only ever opens when nothing else
    // is showing, so it never interrupts a popout.
    property bool _startupDelayFinished: false
    property Timer _startupTimer: Timer {
        running: true
        interval: 1000
        onTriggered: _startupDelayFinished = true
    }

    property Timer _volumeToastTimer: Timer {
        interval: 2000
        onTriggered: {
            if (activeModuleName === "volume_toast") closeAll();
        }
    }

    property Connections _volumeConnections: Connections {
        target: Audio
        function onVolumeChanged() { root.showVolumeToast(); }
        function onMutedChanged() { root.showVolumeToast(); }
    }

    function showVolumeToast() {
        if (!_startupDelayFinished) return;
        if (activeModuleName !== "" && activeModuleName !== "volume_toast") return;
        openModule("volume_toast");
        _volumeToastTimer.restart();
    }
}
