import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import "../notifications"

NotificationCard {

    // Default card width is 350. Increased by 20% = 420
    implicitWidth: 420

    notification: Notifications.activeToastNotification
    clickable: true
    
    onClicked: {
        if (Notifications.activeToastNotification) {
            Notifications.activeToastNotification.dismiss();
        }
        Notifications.closeActiveToast();
    }

}
