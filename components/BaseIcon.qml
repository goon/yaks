import QtQuick
import qs

Item {
    id: root

    property string icon: ""
    property int size: Globals.dimensions.iconMedium
    property alias iconSize: root.size
    property color color: Globals.colors.text
    property alias iconColor: root.color
    property bool fill: false
    property int weight: 400

    implicitWidth: size
    implicitHeight: size

    BaseText {
        anchors.centerIn: parent
        text: root.icon
        font.pixelSize: root.size
        color: root.color
        font.family: Globals.typography.iconFamily
        font.variableAxes: {
            "FILL": root.fill ? 1 : 0,
            "wght": root.weight,
            "opsz": root.size
        }
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
