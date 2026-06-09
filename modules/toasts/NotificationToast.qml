import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services

Item {
    id: root

    property string panelState: "Closed"

    // Default card width is 350. Increased by 20% = 420
    implicitWidth: 420
    implicitHeight: card.implicitHeight

    NotificationCard {
        id: card

        width: 420
        anchors.centerIn: parent

        notification: Notifications.activeToastNotification
        showCloseButton: false
        showTime: false
        clickable: true
        borderWidth: 0
        
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
}
