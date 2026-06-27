import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import "../notifications"

NotificationCard {
    id: root

    property string panelState: "Closed"

    // Default card width is 350. Increased by 20% = 420
    implicitWidth: 420

    notification: Notifications.activeToastNotification
    showCloseButton: false
    showTime: false
    clickable: true
    
    // When clicking the notification, we close the toast
    onClicked: {
        if (Notifications.activeToastNotification) {
            Notifications.activeToastNotification.dismiss();
        }
        Notifications.closeActiveToast();
    }

    // It doesn't need to close via the X button because we hid it, 
    // but just in case:
    onCloseClicked: {
        if (Notifications.activeToastNotification) {
            Notifications.activeToastNotification.dismiss();
        }
        Notifications.closeActiveToast();
    }
}
