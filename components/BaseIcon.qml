import QtQuick
import qs

Item {
    id: root

    property string icon: ""
    property int size: Globals.dimensions.iconMedium
    property alias iconSize: root.size
    property color color: Globals.colors.text
    property alias iconColor: root.color

    implicitWidth: size
    implicitHeight: size

    BaseText {
        anchors.centerIn: parent
        text: root.icon
        font.pixelSize: root.size
        color: root.color
        font.family: Globals.typography.iconFamily
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
