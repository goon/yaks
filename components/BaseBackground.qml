import QtQuick
import QtQuick.Shapes
import Quickshell
import qs

/**
 * BaseBackground - Standardized background component for top-level windows.
 * Used by Bar and BasePopoutWindow to provide consistent styling and support
 * for complex shapes and future effects like blur and opacity.
 */
Item {
    id: root

    property color color: Globals.alpha(Globals.colors.background, Globals.opacity.background)
    property color borderColor: Globals.colors.transparent
    property real borderWidth: 1
    property real radius: Globals.geometry.radius
    clip: true


    Rectangle {
        anchors.fill: parent
        color: root.color
        radius: root.radius
        clip: root.clip
        border.color: root.borderColor
        border.width: root.borderWidth
    }
}
