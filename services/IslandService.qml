import QtQuick
import Quickshell
import qs
pragma Singleton

QtObject {
    id: root

    // ── STATE PROPERTIES ──────────────────────────────────────────────
    property string activePanelName: ""
    property var activeScreen: null
    property Item activePanelItem: null
    property bool isIslandHovered: false

    property real anchorX: -1
    property real anchorMinX: -1
    property real anchorMaxX: -1

    property var _pendingCallbacks: []

    function runWhenPanelReady(callback) {
        if (activePanelItem && (activePanelItem.panelState === "Opening" || activePanelItem.panelState === "Open")) {
            Qt.callLater(callback);
        } else {
            _pendingCallbacks.push(callback);
        }
    }

    onActivePanelItemChanged: {
        if (activePanelItem) {
            if (typeof activePanelItem.panelStateChanged === "undefined") {
                while (_pendingCallbacks.length > 0) {
                    var cb = _pendingCallbacks.shift();
                    if (typeof cb === "function") Qt.callLater(cb);
                }
                return;
            }
            var checkState = () => {
                if (activePanelItem && (activePanelItem.panelState === "Opening" || activePanelItem.panelState === "Open")) {
                    while (_pendingCallbacks.length > 0) {
                        var cb = _pendingCallbacks.shift();
                        if (typeof cb === "function") Qt.callLater(cb);
                    }
                    activePanelItem.panelStateChanged.disconnect(checkState);
                }
            };
            activePanelItem.panelStateChanged.connect(checkState);
            checkState();
        } else {
            // The panel unloaded and its item was destroyed; drop any callbacks
            // that were waiting for it so they can't fire against a stale item.
            _pendingCallbacks = [];
        }
    }

    // ── PANEL REGISTRY ──────────────────────────────────────────────────
    // Single source of truth for a panel's QML source and its expected
    // dimensions. The dimensions are the pre-load estimate the island morphs
    // toward before the panel's own implicitWidth/Height is available; keep
    // them in step with each panel's declared implicit size.
    readonly property var panelRegistry: ({
        "launcher":      { source: "../modules/launcher/Launcher.qml",      width: 500, height: 500 },
        "settings":      { source: "../modules/settings/Settings.qml",      width: 460, height: 500 },
        "wallpaper":     { source: "../modules/wallpaper/Wallpaper.qml" },
        "fullbar":       { source: "../modules/bar/Full.qml" },
        "power":         { source: "../modules/power/Power.qml",            width: 240 },
        "network":       { source: "../modules/network/Network.qml",        width: 400 },
        "notifications_island": { source: "../modules/notifications/NotificationsIsland.qml", width: 460 },
        "volumetoast":   { source: "../modules/toasts/VolumeToast.qml",     width: 300 },
        "notificationtoast": { source: "../modules/toasts/NotificationToast.qml", width: 420 }
    })

    // Fallback dimensions used while a panel is still loading, so the morph has
    // a sane target. Prefer the registry entry, then a generic default.
    function expectedWidth(name) {
        var panel = root.panelRegistry[name];
        return (panel && panel.width) ? panel.width : 420;
    }

    function expectedHeight(name) {
        var panel = root.panelRegistry[name];
        return (panel && panel.height) ? panel.height : 500;
    }

    // Resolve a panel's QML file from the registry; empty string if unknown.
    function panelSource(name) {
        var panel = root.panelRegistry[name];
        return panel ? panel.source : "";
    }

    // ── CONTROL APIS ──────────────────────────────────────────────────
    function togglePanel(name, screenX, barLeft, barRight, screen) {
        if (activePanelName === name) {
            closeAll();
        } else {
            activePanelName = name;
            activeScreen = screen || Quickshell.screens[0];
            anchorX = (screenX !== undefined) ? screenX : -1;
            anchorMinX = (barLeft !== undefined) ? barLeft : -1;
            anchorMaxX = (barRight !== undefined) ? barRight : -1;
        }
    }

    function openPanel(name, screenX, barLeft, barRight, screen) {
        if (activePanelName === name) return;
        activePanelName = name;
        activeScreen = screen || Quickshell.screens[0];
        anchorX = (screenX !== undefined) ? screenX : -1;
        anchorMinX = (barLeft !== undefined) ? barLeft : -1;
        anchorMaxX = (barRight !== undefined) ? barRight : -1;
    }

    function closeAll() {
        activePanelName = "";
        activeScreen = null;
        activePanelItem = null;
        anchorX = -1;
        anchorMinX = -1;
        anchorMaxX = -1;
    }

    // ── PANEL WRAPPER APIS ────────────────────────────────────────────
    function toggleLauncher() {
        togglePanel("launcher");
    }

    function toggleWallpaper() {
        togglePanel("wallpaper");
    }

    function toggleSettings(pageName) {
        var isCurrentlyOpen = (activePanelName === "settings");

        if (isCurrentlyOpen) {
            if (pageName !== undefined) {
                if (activePanelItem) {
                    if (activePanelItem.selectedPage === pageName) {
                        closeAll();
                    } else if (typeof activePanelItem.changePage === "function") {
                        activePanelItem.changePage(pageName);
                    }
                }
            } else {
                closeAll();
            }
        } else {
            openPanel("settings");
            if (pageName !== undefined) {
                runWhenPanelReady(() => {
                    if (activePanelItem && typeof activePanelItem.changePage === "function") {
                        activePanelItem.changePage(pageName);
                    }
                });
            }
        }
    }

    function toggleNetworkPopout() {
        togglePanel("network");
    }

    function toggleBluetoothPopout() {
        var isCurrentlyOpen = (activePanelName === "network");
        
        if (isCurrentlyOpen) {
            if (activePanelItem && activePanelItem.pageStack && activePanelItem.pageStack.currentItem && activePanelItem.pageStack.currentItem.objectName === "NetworkBluetooth.qml") {
                closeAll();
            } else {
                if (activePanelItem && typeof activePanelItem.pushPage === "function") {
                    activePanelItem.pushPage("bluetooth");
                }
            }
        } else {
            openPanel("network");
            runWhenPanelReady(() => {
                if (activePanelItem && typeof activePanelItem.pushPage === "function") {
                    activePanelItem.pushPage("bluetooth");
                }
            });
        }
    }

    function togglePowerPopout() {
        togglePanel("power");
    }

    function toggleNotificationsPopout() {
        togglePanel("notifications_island");
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
            if (activePanelName === "volumetoast" && !isIslandHovered) {
                closeAll();
            }
        }
    }

    property Connections _volumeConnections: Connections {
        target: Volume
        function onVolumeChanged() {
            if (!_startupDelayFinished) return;
            
            if (activePanelName === "" || activePanelName === "volumetoast") {
                openPanel("volumetoast");
                _volumeToastTimer.restart();
            }
        }
        function onMutedChanged() {
            if (!_startupDelayFinished) return;
            
            if (activePanelName === "" || activePanelName === "volumetoast") {
                openPanel("volumetoast");
                _volumeToastTimer.restart();
            }
        }
    }
}

