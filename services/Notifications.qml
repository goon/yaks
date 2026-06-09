import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs

pragma Singleton

Item {
    id: root

    // The core notification server provided by Quickshell
    property NotificationServer server: NotificationServer {}
    
    // History model
    property alias notificationHistory: historyModel
    readonly property alias unreadCount: historyModel.count

    ListModel {
        id: historyModel
    }

    // Signal for the UI (Overlay) to listen to
    signal notificationReceived(var notification)

    Connections {
        target: server
        
        function onNotification(notification) {
            notification.tracked = true;
            
            // Add to history (at the top)
            historyModel.insert(0, {
                "modelData": notification,
                "receivedAt": new Date()
            });

            // Handle dismissal/closing
            notification.onClosed.connect(() => {
                for (var i = 0; i < historyModel.count; i++) {
                    if (historyModel.get(i).modelData === notification) {
                        historyModel.remove(i);
                        break;
                    }
                }
            });

            // Sound logic
            if (Preferences.notificationMode === 0) {
                if (Config.notificationSoundEnabled) {
                    ProcessService.runDetached([
                        "pw-play", 
                        "--volume", (Config.notificationSoundVolume / 100.0).toString(), 
                        Config.notificationSoundPath
                    ]);
                }
                
                // Queue for morph island
                root._toastQueue.push(notification);
                root._processQueue();
            }
        }
    }
    
    // --- Toast Queue Logic ---
    property var activeToastNotification: null
    property var _toastQueue: []
    
    Timer {
        id: toastTimer
        interval: Config.notificationTimeout || 5000
        onTriggered: {
            root.closeActiveToast();
        }
    }
    
    function _processQueue() {
        if (root.activeToastNotification === null && root._toastQueue.length > 0) {
            root.activeToastNotification = root._toastQueue.shift();
            
            // Only open panel if no other panel is open, or if it's already notificationtoast
            if (IslandService.activePanelName === "" || IslandService.activePanelName === "notificationtoast") {
                IslandService.openPanel("notificationtoast");
                toastTimer.restart();
            } else {
                // If another panel is open, we skip showing the toast to avoid interrupting the user.
                // Or we could wait. For now, we just discard the toast.
                root.activeToastNotification = null;
                root._processQueue();
            }
        }
    }
    
    function closeActiveToast() {
        root.activeToastNotification = null;
        toastTimer.stop();
        
        if (root._toastQueue.length > 0) {
            // Immediately process the next one without closing the island
            root._processQueue();
        } else {
            // Queue is empty, safely close the island
            if (IslandService.activePanelName === "notificationtoast") {
                IslandService.closeAll();
            }
        }
    }
    
    function clearAll() {
        for (let i = historyModel.count - 1; i >= 0; i--) {
            let notif = historyModel.get(i).modelData;
            if (notif) notif.dismiss();
        }
    }
}
