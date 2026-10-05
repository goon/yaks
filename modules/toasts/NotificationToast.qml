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

    // The toast is the whole notification system now: closing it dismisses
    // the server object, so nothing outlives its 5 seconds on screen.
    onClicked: {
        Notifications.closeActiveToast();
    }

}
