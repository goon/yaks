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
                if (activePanelItem && activePanelItem.bodyItem) {
                    var mainContainer = activePanelItem.bodyItem;
                    if (mainContainer.selectedPage === pageName) {
                        closeAll();
                    } else {
                        mainContainer.changePage(pageName);
                    }
                }
            } else {
                closeAll();
            }
        } else {
            openPanel("settings");
            if (pageName !== undefined) {
                runWhenPanelReady(() => {
                    if (activePanelItem && activePanelItem.bodyItem && typeof activePanelItem.bodyItem.changePage === "function") {
                        activePanelItem.bodyItem.changePage(pageName);
                    }
                });
            }
        }
    }

    function toggleDashboardPopout(screenX, barLeft, barRight) {
        togglePanel("dashboard");
    }

    function toggleNotificationPopout(screenX, barLeft, barRight) {
        togglePanel("notifications");
    }

    function toggleAudioPopout(screenX, barLeft, barRight) {
        togglePanel("audio");
    }

    function togglePowerPopout(screenX, barLeft, barRight) {
        togglePanel("power");
    }

    function toggleNetworkPopout(screenX, barLeft, barRight) {
        toggleSettings("NetworkPage");
    }

    function toggleBluetoothPopout(screenX, barLeft, barRight) {
        toggleSettings("Bluetooth");
    }

}
