import qs
import ".."
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property real value: 0
    property real from: 0
    property real to: 1
    property real stepSize: 0

    property bool interactive: true
    property bool muted: false
    property alias pressed: mouseArea.pressed
    readonly property bool hovered: mouseArea.containsMouse

    property color trackColor: Globals.colors.well
    property color fillColor: Globals.colors.primary

    // ── SLIDER METRICS ─────────────────────────────────────────────────
    // Internal to this component — nothing else sizes a slider, so these live
    // here rather than in Globals.
    readonly property int trackHeight: 12 * Globals.shellScale
    readonly property int handleWidth: 4 * Globals.shellScale
    readonly property int handleHeight: 20 * Globals.shellScale
    readonly property int gap: 5 * Globals.shellScale

    property string icon: ""
    property color iconColor: Globals.colors.text
    property int iconSize: Globals.dimensions.iconSmall
    property int iconGap: Globals.geometry.spacing.small

    property real _animatedValue: value
    Behavior on _animatedValue {
        enabled: !mouseArea.pressed
        BaseMotion { }
    }

    readonly property real normalizedValue: (_animatedValue - from) / (to - from)

    property real breathOpacity: 1.0
    readonly property int _breathMs: 800
    readonly property bool isActive: root.hovered || root.pressed

    property real _baseOpacity: root.muted ? 0.6 : 1.0
    Behavior on _baseOpacity { BaseMotion { } }

    SequentialAnimation on breathOpacity {
        running: root.pressed
        loops: Animation.Infinite
        NumberAnimation { from: 1.0; to: 0.6; duration: root._breathMs; easing.type: Easing.InOutQuad }
        NumberAnimation { from: 0.6; to: 1.0; duration: root._breathMs; easing.type: Easing.InOutQuad }
        onStopped: root.breathOpacity = 1.0
    }

    signal valueChangedByUser()
    signal rightClicked()

    implicitHeight: Math.max(root.trackHeight, root.handleHeight, root.icon !== "" ? root.iconSize : 0)
    implicitWidth: 100

    RowLayout {
        anchors.fill: parent
        spacing: root.iconGap
        opacity: root._baseOpacity

        BaseIcon {
            Layout.alignment: Qt.AlignVCenter
            visible: root.icon !== ""
            icon: root.icon
            size: root.iconSize
            color: root.iconColor
        }

        Item {
            id: track

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 100
            height: root.trackHeight

            Rectangle {
                id: activeTrack

                x: 0
                y: 0
                width: Math.max(0, handle.x - root.gap)
                height: parent.height
                topLeftRadius: height / 2
                bottomLeftRadius: height / 2
                topRightRadius: 0
                bottomRightRadius: 0
                opacity: root.pressed ? root.breathOpacity : 1.0

                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Globals.colors.primary }
                    GradientStop { position: 1.0; color: Globals.colors.secondary }
                }
            }

            Rectangle {
                id: inactiveTrack

                x: handle.x + handle.width + root.gap
                y: 0
                width: Math.max(0, parent.width - x)
                height: parent.height
                topLeftRadius: 0
                bottomLeftRadius: 0
                topRightRadius: height / 2
                bottomRightRadius: height / 2
                color: root.trackColor
            }

            Rectangle {
                id: handle

                visible: root.interactive
                width: root.handleWidth
                height: root.handleHeight
                radius: width / 2

                x: root.normalizedValue * (track.width - width)
                y: (track.height - height) / 2

                color: root.fillColor
                z: 10

                scale: root.isActive ? 1.15 : 1.0
                Behavior on scale { BaseMotion { duration: Globals.motion.hover; easing.type: Globals.motion.easeSpring } }
            }

            MouseArea {
                id: mouseArea

                function updateValue(mousePos) {
                    var newValue = root.from + (mousePos / width) * (root.to - root.from);
                    if (root.stepSize > 0)
                        newValue = Math.round(newValue / root.stepSize) * root.stepSize;

                    newValue = Math.max(root.from, Math.min(root.to, newValue));
                    root.value = newValue;
                    root.valueChangedByUser();
                }

                anchors.fill: parent
                anchors.topMargin: -(root.handleHeight - root.trackHeight) / 2
                anchors.bottomMargin: -(root.handleHeight - root.trackHeight) / 2
                enabled: root.interactive
                hoverEnabled: true
                preventStealing: pressed
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onPressed: (mouse) => {
                    mouse.accepted = true;
                    if (mouse.button === Qt.RightButton) {
                        root.rightClicked();
                        return;
                    }
                    updateValue(mouse.x);
                }
                onPositionChanged: (mouse) => {
                    if (pressed && (mouse.buttons & Qt.LeftButton))
                        updateValue(mouse.x);
                }
            }
        }
    }
}
