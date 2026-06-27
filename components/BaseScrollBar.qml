import QtQuick
import QtQuick.Controls
import qs

ScrollBar {
    id: root

    // Customizable properties with sensible defaults
    property int thickness: 8
    property int handleInset: 2
    property int scrollbarRadius: Math.max(2, Theme.geometry.radius * 0.5)
    property color scrollbarColor: Theme.colors.muted
    property real scrollbarOpacity: 0.5
    property color trackColor: Theme.colors.border
    property real trackOpacity: 0.35

    width: orientation === Qt.Vertical ? thickness : undefined
    height: orientation === Qt.Horizontal ? thickness : undefined
    policy: ScrollBar.AsNeeded
    visible: policy !== ScrollBar.AlwaysOff && size < 0.999

    background: Rectangle {
        radius: root.scrollbarRadius
        color: root.trackColor
        opacity: root.trackOpacity
    }

    contentItem: Rectangle {
        implicitWidth: root.orientation === Qt.Vertical
            ? root.thickness - root.handleInset * 2
            : 100
        implicitHeight: root.orientation === Qt.Horizontal
            ? root.thickness - root.handleInset * 2
            : 100
        radius: root.scrollbarRadius
        color: root.scrollbarColor
        opacity: root.scrollbarOpacity
    }

}
