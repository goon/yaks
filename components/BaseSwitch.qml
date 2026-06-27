import QtQuick
import QtQuick.Controls
import qs

Switch {
    id: control

    implicitWidth: 44
    implicitHeight: 24
    hoverEnabled: true
    padding: 0

    // Disable default background
    background: null
    

    // Animating progress between 0.0 (unchecked) and 1.0 (checked)
    property real progress: control.checked ? 1.0 : 0.0
    Behavior on progress {
        BaseAnimation { easing.type: Easing.OutQuint }
    }

    // Helper to ensure cursor changes
    HoverHandler {
        cursorShape: control.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    indicator: Item {
        id: indicatorContainer
        implicitWidth: 44
        implicitHeight: 24
        x: control.leftPadding
        y: parent.height / 2 - height / 2

        // Outer Gradient/Border Layer
        Rectangle {
            id: outerBorder
            anchors.fill: parent
            radius: Globals.geometry.innerRadius.small
            
            // Gradient is active on checked OR hovered
            gradient: (control.checked || control.hovered) ? trackGradient : null
            
            // Standard border color when unchecked and not hovered
            color: Globals.alpha(Globals.colors.border, 0.5)
        }

        // Inner Fill/Cutout
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: outerBorder.radius - 1
            
            color: {
                if (control.checked) return "transparent"; // Let the gradient show through
                if (!control.enabled) return Globals.alpha(Globals.colors.surface, 0.2);
                return control.hovered ? Globals.alpha(Globals.colors.surface, 0.6) : Globals.alpha(Globals.colors.surface, 0.4);
            }

            Behavior on color { BaseAnimation { } }
        }

        Gradient {
            id: trackGradient
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0.0
                color: {
                    if (!control.enabled) return Globals.alpha(Globals.colors.surface, 0.2);
                    return control.hovered ? Globals.alpha(Globals.colors.primary, 0.9) : Globals.colors.primary;
                }
            }
            GradientStop {
                position: 1.0
                color: {
                    if (!control.enabled) return Globals.alpha(Globals.colors.surface, 0.2);
                    var sec = Globals.colors.secondary;
                    return control.hovered ? Globals.alpha(sec, 0.9) : sec;
                }
            }
        }

        // Thumb
        Rectangle {
            id: thumb

            // Tactile press size (stretches to 22px on press)
            property real baseWidth: control.pressed ? 22 : 16
            Behavior on baseWidth {
                BaseAnimation { }
            }
            
            // Calculate center position based on progress
            property real centerX: 4 + baseWidth / 2 + control.progress * (parent.width - baseWidth - 8)
            
            // Squash & stretch physics based on progress
            property real travelStretch: Math.sin(control.progress * Math.PI) * 8

            x: centerX - width / 2
            y: 4
            width: baseWidth + travelStretch
            height: 16
            radius: Math.max(0, Globals.geometry.innerRadius.small - 4)
            
            // Thumb Color (keeps the knob white when enabled)
            color: control.enabled ? Globals.colors.textLighter : Globals.colors.muted

            // Subtle border definition
            border.width: 1
            border.color: control.checked ? Globals.alpha(Globals.colors.primary, 0.2) : Globals.alpha(Globals.colors.base, 0.1)

            Behavior on color { BaseAnimation { } }
            Behavior on border.color { BaseAnimation { } }
        }
    }
}
