import ".."
import QtQuick
import QtQuick.Layouts
import qs

Rectangle {
    id: root

    // ── STANDARD PROPERTIES ───────────────────────────────────────────
    property string text: ""
    property string icon: ""
    property color iconColor: {
        return (root.pressed || root.containsMouse) ? Globals.colors.primary : Globals.colors.text;
    }
    property color textColor: {
        return (root.pressed || root.containsMouse) ? Globals.colors.primary : Globals.colors.text;
    }
    property int size: Globals.dimensions.iconBase
    property real iconRotation: 0
    property int weight: Globals.typography.weights.normal
    property color hoverColor: Globals.colors.transparent
    property real customRadius: -1
    property bool hoverEnabled: true
    property bool clickRotate: false
    property int paddingHorizontal: text !== "" ? Globals.geometry.padding.medium : Globals.geometry.spacing.medium
    property int paddingVertical: Globals.geometry.spacing.medium

    // ── STATE PROXIES ─────────────────────────────────────────────────
    readonly property bool containsMouse: mouseArea.containsMouse
    readonly property bool pressed: mouseArea.pressed
    property bool hovered: containsMouse

    // ── SIGNALS ───────────────────────────────────────────────────────
    signal clicked()
    signal rightClicked()
    signal pressedSignal()

    radius: {
        if (root.customRadius >= 0) return root.customRadius;
        return Globals.geometry.innerRadius.medium;
    }
    color: Globals.colors.transparent
    
    implicitWidth: childrenLayout.implicitWidth + (root.paddingHorizontal * 2)
    implicitHeight: childrenLayout.implicitHeight + (root.paddingVertical * 2)
    scale: pressed ? 0.98 : 1.0

    Behavior on scale { BaseAnimation { duration: Globals.animations.fast } }

    BaseActiveBackground {
        id: stateLayer
        anchors.fill: parent
        radius: parent.radius
        hoverColor: root.hoverColor
        hovered: mouseArea.containsMouse
        hoverEnabled: root.hoverEnabled
    }

    RowLayout {
        id: childrenLayout
        anchors.centerIn: parent
        spacing: root.text !== "" && root.icon !== "" ? Globals.geometry.spacing.medium : 0

        BaseIcon {
            icon: root.icon
            color: root.iconColor
            size: root.size
            rotation: root.iconRotation
            visible: root.icon !== ""
        }

        BaseText {
            text: root.text
            color: root.textColor
            pixelSize: Globals.typography.size.base
            weight: root.weight
            visible: root.text !== ""
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                root.rightClicked();
            } else {
                if (root.clickRotate) rotateAnim.restart();
                root.clicked();
            }
        }
        onPressed: root.pressedSignal()
    }

    SequentialAnimation {
        id: rotateAnim
        NumberAnimation {
            target: root
            property: "iconRotation"
            from: 0; to: 360
            duration: Globals.animations.normal
            easing.type: Easing.OutBack
        }
        PropertyAction { target: root; property: "iconRotation"; value: 0 }
    }
}
