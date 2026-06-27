import QtQuick
import qs

Item {
    id: root

    implicitHeight: 24
    implicitWidth: 200

    property real value: 0.0
    property color thumbColor: Globals.colors.primary

    property alias gradient: track.gradient

    signal dragged(real value)
    signal committed(real value)

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        clip: true

        MouseArea {
            anchors.fill: parent
            property bool isDragging: false

            onPressed: (mouse) => {
                isDragging = true;
                root.dragged(_ratio(mouse.x));
            }
            onPositionChanged: (mouse) => {
                if (isDragging) root.dragged(_ratio(mouse.x));
            }
            onReleased: (mouse) => {
                isDragging = false;
                root.committed(_ratio(mouse.x));
            }

            function _ratio(xPos) {
                return Math.max(0.0, Math.min(1.0, xPos / width));
            }
        }
    }

    // Thumb
    Rectangle {
        id: thumb

        readonly property int d: 18

        width: d; height: d
        radius: d / 2
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(2, Math.min(parent.width - d - 2, root.value * parent.width - d / 2))
        color: root.thumbColor
        border.width: 3
        border.color: Globals.colors.surface

        Behavior on x { BaseAnimation { duration: Globals.animations.fast } }
    }
}
