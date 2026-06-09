import QtQuick
import Quickshell
import qs
pragma Singleton

QtObject {
    id: root

    // --- State Properties ---
    property string activePanelName: ""
    property var activeScreen: null
    property Item activePanelItem: null

    property real anchorX: -1
    property real anchorMinX: -1
    property real anchorMaxX: -1

    // Callback Queue for panel-specific navigation on load
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
        }
    }

    // --- COORDINATE MATH ---
    // --- CONTROL APIs ---
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

    // --- WRAPPER APIs FOR INDIVIDUAL PANELS ---
    function toggleLauncher() {
        togglePanel("launcher");
    }

    function toggleWallpaper() {
        togglePanel("wallpaper");
    }

    function toggleClipboard() {
        if (activePanelName !== "launcher") {
            openPanel("launcher");
        }
        runWhenPanelReady(() => {
            if (activePanelItem && typeof activePanelItem.switchToTab === "function") {
                activePanelItem.switchToTab(1);
            }
        });
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

    function toggleDashboardPopout(screenX, barLeft, barRight) {
        togglePanel("dashboard");
    }

    function toggleNetworkPopout(screenX, barLeft, barRight) {
        var isCurrentlyOpen = (activePanelName === "nexus");
        
        if (isCurrentlyOpen) {
            if (activePanelItem && activePanelItem.pageStack && activePanelItem.pageStack.currentItem && activePanelItem.pageStack.currentItem.objectName === "views/NexusNetwork.qml") {
                closeAll();
            } else {
                if (activePanelItem && typeof activePanelItem.pushPage === "function") {
                    activePanelItem.pushPage("network");
                }
            }
        } else {
            openPanel("nexus");
            runWhenPanelReady(() => {
                if (activePanelItem && typeof activePanelItem.pushPage === "function") {
                    activePanelItem.pushPage("network");
                }
            });
        }
    }

    function toggleBluetoothPopout(screenX, barLeft, barRight) {
        var isCurrentlyOpen = (activePanelName === "nexus");
        
        if (isCurrentlyOpen) {
            if (activePanelItem && activePanelItem.pageStack && activePanelItem.pageStack.currentItem && activePanelItem.pageStack.currentItem.objectName === "views/NexusBluetooth.qml") {
                closeAll();
            } else {
                if (activePanelItem && typeof activePanelItem.pushPage === "function") {
                    activePanelItem.pushPage("bluetooth");
                }
            }
        } else {
            openPanel("nexus");
            runWhenPanelReady(() => {
                if (activePanelItem && typeof activePanelItem.pushPage === "function") {
                    activePanelItem.pushPage("bluetooth");
                }
            });
        }
    }

    function toggleNexusPopout(screenX, barLeft, barRight) {
        togglePanel("nexus");
    }

    // --- Volume Toast Logic ---
    property bool _startupDelayFinished: false
    property Timer _startupTimer: Timer {
        running: true
        interval: 1000
        onTriggered: _startupDelayFinished = true
    }

    property Timer _volumeToastTimer: Timer {
        interval: 2000
        onTriggered: {
            if (activePanelName === "volumetoast") {
                closeAll();
            }
        }
    }

    property Connections _volumeConnections: Connections {
        target: Volume
        function onVolumeChanged() {
            if (!_startupDelayFinished) return;
            
            // Only open toast if no other panel is open, or if the toast is already open
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
