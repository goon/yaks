import QtQuick
import QtQuick.Controls
import qs

Switch {
    id: control

    implicitWidth: 44
    implicitHeight: 24
    hoverEnabled: true

    // Disable default background
    background: null
    
    // Customizable colors
    property color checkedColor: Theme.colors.primary
    property color uncheckedColor: Theme.alpha(Theme.colors.surface, 0.4)
    property color uncheckedBorderColor: Theme.alpha(Theme.colors.border, 0.5)

    // Animating progress between 0.0 (unchecked) and 1.0 (checked)
    property real progress: control.checked ? 1.0 : 0.0
    Behavior on progress {
        BaseAnimation { speed: "fast"; easing.type: Easing.OutQuint }
    }

    // Helper to ensure cursor changes
    MouseArea {
        anchors.fill: parent
        cursorShape: control.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.NoButton // Let clicks pass through to the Switch
    }

    indicator: Rectangle {
        id: indicatorContainer
        implicitWidth: 44
        implicitHeight: 24
        x: control.leftPadding
        y: parent.height / 2 - height / 2
        radius: Math.max(2, Theme.geometry.radius * 0.5)
        color: "transparent"

        // Outer Gradient/Border Layer
        Rectangle {
            id: outerBorder
            anchors.fill: parent
            radius: parent.radius
            
            // Gradient is active on checked OR hovered
            gradient: (control.checked || control.hovered) ? trackGradient : null
            
            // Standard border color when unchecked and not hovered
            color: control.uncheckedBorderColor

            Behavior on color { BaseAnimation { speed: "fast" } }
        }

        // Inner Fill/Cutout
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: parent.radius - 1
            
            // Fill color
            color: {
                if (control.checked) return "transparent"; // Let the gradient show through
                if (!control.enabled) return Theme.alpha(Theme.colors.surface, 0.2);
                return control.hovered ? Theme.alpha(Theme.colors.surface, 0.6) : control.uncheckedColor;
            }

            Behavior on color { BaseAnimation { speed: "fast" } }
        }

        Gradient {
            id: trackGradient
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0.0
                color: {
                    if (!control.enabled) return Theme.alpha(Theme.colors.surface, 0.2);
                    return control.hovered ? Theme.alpha(control.checkedColor, 0.9) : control.checkedColor;
                }
            }
            GradientStop {
                position: 1.0
                color: {
                    if (!control.enabled) return Theme.alpha(Theme.colors.surface, 0.2);
                    var sec = Theme.colors.secondary;
                    return control.hovered ? Theme.alpha(sec, 0.9) : sec;
                }
            }
        }

        // Thumb
        Rectangle {
            id: thumb

            // Tactile press size (stretches to 22px on press)
            property real baseWidth: control.pressed ? 22 : 16
            Behavior on baseWidth {
                BaseAnimation { speed: "fast" }
            }
            
            // Calculate center position based on progress
            property real centerX: 4 + baseWidth / 2 + control.progress * (parent.width - baseWidth - 8)
            
            // Squash & stretch physics based on progress
            property real travelStretch: Math.sin(control.progress * Math.PI) * 8

            x: centerX - width / 2
            y: 4
            width: baseWidth + travelStretch
            height: 16
            radius: Math.max(0, Math.max(2, Theme.geometry.radius * 0.5) - 2)
            
            // Thumb Color (keeps the knob white when enabled)
            color: control.enabled ? Theme.colors.textLighter : Theme.colors.muted

            // Subtle border definition
            border.width: 1
            border.color: control.checked ? Theme.alpha(Theme.colors.primary, 0.2) : Theme.alpha(Theme.colors.base, 0.1)

            Behavior on color {
                BaseAnimation { speed: "fast" }
            }
        }
    }
}
