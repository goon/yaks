import QtQuick
import QtQuick.Layouts
import qs

BaseContainer {
    id: root

    property color backgroundColor: Theme.alpha(Theme.colors.surface, 1.0)
    property color hoverColor: Theme.colors.transparent
    property int blockRadius: Theme.geometry.innerRadius.medium

    property bool premiumHover: false
    property bool premiumActive: false

    Rectangle {
        parent: root
        z: -1
        anchors.fill: parent
        color: root.backgroundColor
        radius: root.blockRadius

        BaseActiveBackground {
            anchors.fill: parent
            radius: parent.radius
            baseColor: root.backgroundColor
            hoverColor: root.hoverColor
            hovered: root.containsMouse
            hoverEnabled: root.hoverEnabled
            premiumActive: root.premiumActive
            premiumHover: root.premiumHover
        }
    }
}
