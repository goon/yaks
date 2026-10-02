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
    // Queued callbacks are dropped when the item dies, so one can never fire
    // against a destroyed module.
    function runWhenModuleReady(callback) {
        if (activeModuleItem) Qt.callLater(callback);
        else _pendingCallbacks.push(callback);
    }

    onActiveModuleItemChanged: {
        if (!activeModuleItem) {
            _pendingCallbacks = [];
            return;
        }
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
        "wifi":          { source: "../modules/network/NetworkWifi.qml",    width: 325, height: 500, kind: "popout", evictionTime: 5000 },
        "bluetooth":     { source: "../modules/network/NetworkBluetooth.qml", width: 325, height: 500, kind: "popout", evictionTime: 5000 },
        "notifications": { source: "../modules/notifications/NotificationsIsland.qml", width: 460, height: 500, kind: "popout", evictionTime: 5000 },
        "volume_toast":   { source: "../modules/toasts/VolumeToast.qml",     width: 300, height: 100, kind: "toast",  evictionTime: 3000 },
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
        activeModuleItem = null;
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
