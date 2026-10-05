import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs

pragma Singleton

Item {
    id: root

    // keepOnReload off: the server re-emits every tracked notification on reload,
    // which would replay them as toasts. Nothing persists, so starting empty is fine.
    property NotificationServer server: NotificationServer { keepOnReload: false }

    Connections {
        target: server

        function onNotification(notification) {
            // DND suppresses on arrival: with no history there is nowhere to
            // keep a suppressed notification, so it is dropped outright.
            if (Preferences.notifications.mode !== 0) return;

            notification.tracked = true;
            root._toastQueue.push(notification);
            root._processQueue();
        }
    }
    
    // ── TOAST QUEUE LOGIC ─────────────────────────────────────────────
    property var activeToastNotification: null
    property var _toastQueue: []
    
    Timer {
        id: toastTimer
        interval: 5000
        onTriggered: {
            root.closeActiveToast();
        }
    }
    
    function _processQueue() {
        if (root.activeToastNotification === null && root._toastQueue.length > 0) {
            root.activeToastNotification = root._toastQueue.shift();
            
            if (Modules.activeModuleName === "" || Modules.activeModuleName === "notification_toast") {
                Modules.openModule("notification_toast");
                toastTimer.restart();
            } else {
                // Another module holds the island, so the toast is dropped
                // rather than interrupting it: missed means gone. Dismiss the
                // server object so the tracked set does not grow.
                root.activeToastNotification.dismiss();
                root.activeToastNotification = null;
                root._processQueue();
            }
        }
    }
    
    function closeActiveToast() {
        // The toast is the whole system now: dismiss the server object so
        // nothing outlives its 5 seconds on screen.
        if (root.activeToastNotification) root.activeToastNotification.dismiss();
        root.activeToastNotification = null;
        toastTimer.stop();
        
        if (root._toastQueue.length > 0) {
            // Immediately process the next one without closing the capsule
            root._processQueue();
        } else {
            // Queue is empty, safely close the capsule
            if (Modules.activeModuleName === "notification_toast") {
                Modules.closeAll();
            }
        }
    }
    

}
