import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services

Item {
    id: root

    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: false
    implicitWidth: background.implicitWidth
    implicitHeight: Theme.dimensions.barItemHeight

    Component.onCompleted: PopoutService.connectivityItem = root
    Component.onDestruction: PopoutService.connectivityItem = null

    BaseBlock {
        id: background

        anchors.fill: parent
        paddingVertical: 0
        implicitHeight: Theme.dimensions.barItemHeight
        clickable: true
        hoverEnabled: false
        onClicked: {
            PopoutService.toggleConnectivityPopout();
        }
        popoutOnHover: true
        onHoverAction: PopoutService.toggleConnectivityPopout



        BaseIcon {
            Layout.alignment: Qt.AlignCenter
            icon: "wifi"
            size: Theme.dimensions.iconBase
            color: background.containsMouse ? Theme.colors.primary : Theme.colors.text
        }

    }

}
