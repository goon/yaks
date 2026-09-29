import QtQuick
import Quickshell
import qs

/**
 * BaseBackground - Standardized background component for top-level windows.
 * Used by Bar and BasePopoutWindow to provide consistent styling and support
 * for complex shapes and future effects like blur and opacity.
 */
Rectangle {
    id: root

    property color borderColor: "transparent"
    property real borderWidth: 1

    gradient: Gradient {
        GradientStop { position: 0.0; color: Globals.colors.top }
        GradientStop { position: 1.0; color: Globals.colors.bottom }
    }
    radius: Globals.geometry.radius
    border.color: borderColor
    border.width: borderWidth
}
