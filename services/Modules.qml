import QtQuick
import Quickshell
import qs
pragma Singleton

QtObject {
    id: root

    // ── STATE PROPERTIES ──────────────────────────────────────────────
    property string activeModuleName: ""
    property var activeScreen: null
    property Item activeModuleItem: null
    property bool isCapsuleHovered: false

    property real anchorX: -1
    property real anchorMinX: -1
    property real anchorMaxX: -1

    property var _pendingCallbacks: []

    function runWhenModuleReady(callback) {
        if (activeModuleItem && (activeModuleItem.moduleState === "Opening" || activeModuleItem.moduleState === "Open")) {
            Qt.callLater(callback);
        } else {
            _pendingCallbacks.push(callback);
        }
    }

    onActiveModuleItemChanged: {
        if (activeModuleItem) {
            if (typeof activeModuleItem.moduleStateChanged === "undefined") {
                while (_pendingCallbacks.length > 0) {
                    var cb = _pendingCallbacks.shift();
                    if (typeof cb === "function") Qt.callLater(cb);
                }
                return;
            }
            var checkState = () => {
                if (activeModuleItem && (activeModuleItem.moduleState === "Opening" || activeModuleItem.moduleState === "Open")) {
                    while (_pendingCallbacks.length > 0) {
                        var cb = _pendingCallbacks.shift();
                        if (typeof cb === "function") Qt.callLater(cb);
                    }
                    activeModuleItem.moduleStateChanged.disconnect(checkState);
                }
            };
            activeModuleItem.moduleStateChanged.connect(checkState);
            checkState();
        } else {
            // The module unloaded and its item was destroyed; drop any callbacks
            // that were waiting for it so they can't fire against a stale item.
            _pendingCallbacks = [];
        }
    }

    // ── MODULE REGISTRY ──────────────────────────────────────────────────
    // Single source of truth for a module's QML source and its expected
    // dimensions. The dimensions are the pre-load estimate the capsule morphs
    // toward before the module's own implicitWidth/Height is available; keep
    // them in step with each module's declared implicit size.
    readonly property var moduleRegistry: ({
        "launcher":      { source: "../modules/launcher/Launcher.qml",      width: 500, height: 500, evictionTime: 10000 },
        "settings":      { source: "../modules/settings/Settings.qml",      width: 460, height: 500, evictionTime: 10000 },
        "wallpaper":     { source: "../modules/wallpaper/Wallpaper.qml",    evictionTime: 3000 },
        "full_bar":       { source: "../modules/bar/Full.qml",               evictionTime: 10000 },
        "power":         { source: "../modules/power/Power.qml",            width: 240, evictionTime: 5000 },
        "network":       { source: "../modules/network/Network.qml",        width: 400, evictionTime: 5000 },
        "notifications": { source: "../modules/notifications/NotificationsIsland.qml", width: 460, evictionTime: 5000 },
        "volume_toast":   { source: "../modules/toasts/VolumeToast.qml",     width: 300, evictionTime: 3000 },
        "notification_toast": { source: "../modules/toasts/NotificationToast.qml", width: 420, evictionTime: 3000 }
    })

    // Fallback dimensions used while a module is still loading, so the morph has
    // a sane target. Prefer the registry entry, then a generic default.
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

    // ── CONTROL APIS ──────────────────────────────────────────────────
    function toggleModule(name, screenX, barLeft, barRight, screen) {
        if (activeModuleName === name) {
            closeAll();
        } else {
            activeModuleName = name;
            activeScreen = screen || Quickshell.screens[0];
            anchorX = (screenX !== undefined) ? screenX : -1;
            anchorMinX = (barLeft !== undefined) ? barLeft : -1;
            anchorMaxX = (barRight !== undefined) ? barRight : -1;
        }
    }

    function openModule(name, screenX, barLeft, barRight, screen) {
        if (activeModuleName === name) return;
        activeModuleName = name;
        activeScreen = screen || Quickshell.screens[0];
        anchorX = (screenX !== undefined) ? screenX : -1;
        anchorMinX = (barLeft !== undefined) ? barLeft : -1;
        anchorMaxX = (barRight !== undefined) ? barRight : -1;
    }

    function closeAll() {
        activeModuleName = "";
        activeScreen = null;
        activeModuleItem = null;
        anchorX = -1;
        anchorMinX = -1;
        anchorMaxX = -1;
    }

    // Plain toggles go through toggleModule(name); only modules needing stack
    // navigation get a wrapper.
    function toggleSettings(pageName) {
        var isCurrentlyOpen = (activeModuleName === "settings");

        if (isCurrentlyOpen) {
            if (pageName !== undefined) {
                if (activeModuleItem) {
                    var stack = activeModuleItem.pageStack;
                    if (stack && stack.selectedPage === pageName) {
                        closeAll();
                    } else if (typeof activeModuleItem.changePage === "function") {
                        activeModuleItem.changePage(pageName);
                    }
                }
            } else {
                closeAll();
            }
        } else {
            openModule("settings");
            if (pageName !== undefined) {
                runWhenModuleReady(() => {
                    if (activeModuleItem && typeof activeModuleItem.changePage === "function") {
                        activeModuleItem.changePage(pageName);
                    }
                });
            }
        }
    }

    // ── VOLUME TOAST LOGIC ────────────────────────────────────────────
    property bool _startupDelayFinished: false
    property Timer _startupTimer: Timer {
        running: true
        interval: 1000
        onTriggered: _startupDelayFinished = true
    }

    property Timer _volumeToastTimer: Timer {
        interval: 2000
        onTriggered: {
            if (activeModuleName === "volume_toast" && !isCapsuleHovered) {
                closeAll();
            }
        }
    }

    property Connections _volumeConnections: Connections {
        target: Audio
        function onVolumeChanged() {
            if (!_startupDelayFinished) return;
            
            if (activeModuleName === "" || activeModuleName === "volume_toast") {
                openModule("volume_toast");
                _volumeToastTimer.restart();
            }
        }
        function onMutedChanged() {
            if (!_startupDelayFinished) return;
            
            if (activeModuleName === "" || activeModuleName === "volume_toast") {
                openModule("volume_toast");
                _volumeToastTimer.restart();
            }
        }
    }
}

