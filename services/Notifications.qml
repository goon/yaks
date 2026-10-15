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
            notification.closed.connect((reason) => root._onClosed(notification, reason));
            root._toastQueue.push(notification);
            root._processQueue();
        }
    }
    
    // ── TOAST QUEUE LOGIC ─────────────────────────────────────────────
    property var activeToastNotification: null
    property var _toastQueue: []
    // True while our own dismiss() is on the stack. The closed() it emits is
    // ours, so _onClosed must ignore it — otherwise one close advances the
    // queue twice and skips a toast.
    property bool _selfClosing: false
    
    Timer {
        id: toastTimer
        interval: 5000
        onTriggered: {
            root.closeActiveToast();
        }
    }
    
    // The sender withdrew or expired this notification, or an action closed
    // it. A destroyed object reads as empty text, so cut it short instead of
    // showing a blank card for the rest of the 5 seconds — and never give a
    // dead queued entry its own 5 seconds either.
    function _onClosed(notification, reason) {
        if (root._selfClosing) return;
        if (root.activeToastNotification === notification) {
            root.activeToastNotification = null;
            toastTimer.stop();
            if (root._toastQueue.length > 0) root._processQueue();
            else if (Modules.activeModuleName === "notification_toast") Modules.closeAll();
        } else {
            root._toastQueue = root._toastQueue.filter((n) => n !== notification);
        }
    }

    // No text and no image renders as an empty card. Showing it teaches
    // nothing, and a chatty sender turns the chain into a stuck blank toast,
    // so these are dismissed without island time.
    function _isBlank(notification) {
        if (!notification) return true;
        const text = ((notification.summary || "") + (notification.body || "")).trim();
        if (text !== "") return false;
        return !(notification.image || notification.appIcon);
    }

    function _processQueue() {
        while (root.activeToastNotification === null && root._toastQueue.length > 0) {
            const next = root._toastQueue.shift();

            if (root._isBlank(next)) {
                root._dismiss(next);
                continue;
            }

            root.activeToastNotification = next;

            if (Modules.activeModuleName === "" || Modules.activeModuleName === "notification_toast") {
                Modules.openModule("notification_toast");
                toastTimer.restart();
            } else {
                // Another module holds the island, so the toast is dropped
                // rather than interrupting it: missed means gone. Dismiss the
                // server object so the tracked set does not grow.
                root._dismiss(next);
                root.activeToastNotification = null;
            }
        }
    }

    function _dismiss(notification) {
        if (!notification) return;
        root._selfClosing = true;
        notification.dismiss();
        root._selfClosing = false;
    }

    function closeActiveToast() {
        // The toast is the whole system now: dismiss the server object so
        // nothing outlives its 5 seconds on screen.
        root._dismiss(root.activeToastNotification);
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
