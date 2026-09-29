import QtQuick
import Quickshell
import qs

Rectangle {
    id: root

    property color baseColor: Globals.colors.surface
    property color hoverColor: "transparent"
    
    property bool hovered: false
    property bool hoverEnabled: true

    property bool premiumActive: false
    property bool premiumHover: false
    
    readonly property bool isPremiumActive: premiumActive || (premiumHover && hovered)

    color: (root.hoverEnabled && !root.isPremiumActive && root.hovered) 
           ? root.hoverColor 
           : "transparent"

    Behavior on color {
        BaseMotion { duration: Globals.motion.hover }
    }

    // Premium Selection Gradient Border Layer
    Item {
        anchors.fill: parent
        opacity: root.premiumActive ? 1.0 : ((root.premiumHover && root.hovered) ? 0.05 : 0.0)
        visible: opacity > 0.0 || root.isPremiumActive
        layer.enabled: opacity < 1.0 && opacity > 0.0
        
        Behavior on opacity { BaseMotion { duration: Globals.motion.hover } }
        
        // Outer Gradient "Border"
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Globals.colors.primary }
                GradientStop { position: 1; color: Globals.colors.secondary }
            }
        }

        // Inner "Cutout"
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1.5
            radius: Math.max(0, root.radius - 1.5)
            color: Qt.tint(root.baseColor, Qt.alpha(Globals.colors.primary, 0.08))
        }

        // Inner glass highlight
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, root.radius - 1)
            gradient: Gradient {
                GradientStop { position: 0.0; color: Globals.alpha(Globals.colors.text, 0.05) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }


}
