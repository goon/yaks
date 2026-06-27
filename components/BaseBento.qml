import QtQuick
import QtQuick.Layouts
import qs

BaseContainer {
    id: root

    property color backgroundColor: Globals.alpha(Globals.colors.surface, 0.4)
    property color hoverColor: Globals.colors.transparent
    property int blockRadius: Globals.geometry.innerRadius.medium

    property bool premiumHover: true
    property bool premiumActive: false
    
    padding: Globals.geometry.padding.medium



    Rectangle {
        parent: root
        z: -1
        anchors.fill: parent
        color: root.backgroundColor
        radius: root.blockRadius
        
        border.color: root.containsMouse 
            ? Globals.alpha(Globals.colors.primary, 0.4) 
            : Globals.alpha(Globals.colors.border, 0.75)
        border.width: 1
        
        Behavior on border.color { BaseAnimation { } }

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
