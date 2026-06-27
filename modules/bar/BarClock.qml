import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

BaseContainer {
    id: root
    
    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: false
    
    implicitWidth: layout.implicitWidth + (paddingHorizontal * 2)
    hoverEnabled: false
    clickable: true
    onClicked: {
        IslandService.toggleDashboardPopout();
    }

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }

    Item {
        id: layout
        implicitWidth: Math.max(timeText.implicitWidth, dateText.implicitWidth - dateText.font.letterSpacing)
        implicitHeight: timeText.implicitHeight + dateText.implicitHeight - 2

        BaseText {
            id: timeText
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(systemClock.date, "hh:mm AP")
            pixelSize: Globals.typography.size.large * 0.9
            weight: Globals.typography.weights.bold
        }

        BaseText {
            id: dateText
            anchors.top: timeText.bottom
            anchors.topMargin: -2
            anchors.horizontalCenter: parent.horizontalCenter
            // Trailing letter spacing shifts the visual centre left by letterSpacing/2;
            // offset corrects this without any layout width arithmetic.
            anchors.horizontalCenterOffset: font.letterSpacing / 2
            text: Qt.formatDateTime(systemClock.date, "ddd dd MMM").toUpperCase()
            pixelSize: Globals.typography.size.small * 0.9
            font.letterSpacing: 3
            muted: true
        }
    }
}
