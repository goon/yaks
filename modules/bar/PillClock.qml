import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

BaseContainer {
    id: root
    
    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: false
    
    implicitWidth: 200
    implicitHeight: Globals.dimensions.barItemHeight

    hoverEnabled: false
    clickable: true
    onClicked: {
        IslandService.toggleDashboardPopout();
    }

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }

    RowLayout {
        id: layout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 0

        BaseText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: Qt.formatDateTime(systemClock.date, "hh:mm AP")
            pixelSize: 22
            weight: Globals.typography.weights.bold
        }
    }
}
