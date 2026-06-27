import QtQuick
import Quickshell
import qs

Rectangle {
    id: root

    // Background configuration
    property color baseColor: Theme.colors.surface
    property color hoverColor: Theme.colors.transparent
    
    // Interaction states
    property bool hovered: false
    property bool hoverEnabled: true

    // Premium styling states
    property bool premiumActive: false
    property bool premiumHover: false
    
    // Derived state
    readonly property bool isPremiumActive: premiumActive || (premiumHover && hovered)

    color: "transparent"

    // Premium Selection Gradient Border Layer
    Item {
        anchors.fill: parent
        opacity: root.isPremiumActive ? 1.0 : 0.0
        visible: opacity > 0.0 || root.isPremiumActive
        
        Behavior on opacity { BaseAnimation { } }
        
        // Outer Gradient "Border"
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Theme.colors.primary }
                GradientStop { position: 1; color: Theme.colors.secondary }
            }
        }

        // Inner "Cutout"
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1.5
            radius: Math.max(0, root.radius - 1.5)
            color: root.baseColor
            
            // Selection tint overlay
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: Qt.alpha(Theme.colors.primary, 0.08)
            }
        }

        // Inner glass highlight
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, root.radius - 1)
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.alpha(Theme.colors.text, 0.05) }
                GradientStop { position: 1.0; color: Theme.colors.transparent }
            }
        }
    }

    // Standard Hover Layer
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: {
            if (!root.hoverEnabled || root.isPremiumActive)
                return Theme.colors.transparent;

            if (root.hoverColor !== Theme.colors.transparent && root.hovered)
                return root.hoverColor;

            return Theme.colors.transparent;
        }

        Behavior on color {
            ColorAnimation { duration: Theme.animations.fast }
        }
    }
}
