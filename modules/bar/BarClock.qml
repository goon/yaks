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
        implicitWidth: timeText.implicitWidth
        implicitHeight: timeText.implicitHeight

        BaseText {
            id: timeText
            anchors.centerIn: parent
            text: Qt.formatDateTime(systemClock.date, "hh mm AP")
            pixelSize: 18
            weight: Globals.typography.weights.bold
        }
    }
}
