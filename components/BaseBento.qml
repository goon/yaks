import QtQuick
import QtQuick.Layouts
import qs

BaseContainer {
    id: root

    property color backgroundColor: Globals.alpha(Globals.colors.surface, 0.4)
    property int blockRadius: Globals.geometry.innerRadius.medium

    property bool premiumHover: true
    
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
        
        Behavior on border.color { BaseMotion { } }

        BaseActiveBackground {
            anchors.fill: parent
            radius: parent.radius
            baseColor: root.backgroundColor
            hovered: root.containsMouse
            hoverEnabled: root.hoverEnabled
            premiumHover: root.premiumHover
        }
    }
}
