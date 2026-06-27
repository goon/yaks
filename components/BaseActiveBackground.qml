import QtQuick
import Quickshell
import qs

Rectangle {
    id: root

    // Background configuration
    property color baseColor: Globals.colors.surface
    property color hoverColor: Globals.colors.transparent
    
    // Interaction states
    property bool hovered: false
    property bool hoverEnabled: true

    // Premium styling states
    property bool premiumActive: false
    property bool premiumHover: false
    
    // Derived state
    readonly property bool isPremiumActive: premiumActive || (premiumHover && hovered)

    color: (root.hoverEnabled && !root.isPremiumActive && root.hovered) 
           ? root.hoverColor 
           : Globals.colors.transparent

    Behavior on color {
        BaseAnimation { duration: Globals.animations.fast }
    }

    // Premium Selection Gradient Border Layer
    Item {
        anchors.fill: parent
        opacity: root.isPremiumActive ? 1.0 : 0.0
        visible: opacity > 0.0 || root.isPremiumActive
        layer.enabled: opacity < 1.0 && opacity > 0.0
        
        Behavior on opacity { BaseAnimation { duration: Globals.animations.fast } }
        
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
                GradientStop { position: 1.0; color: Globals.colors.transparent }
            }
        }
    }


}
