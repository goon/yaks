import ".."
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs

Rectangle {
    id: root

    // Styling
    // Styling
    property color backgroundColor: Theme.alpha(Theme.colors.surface, Theme.opacity.surface)
    property color hoverColor: Theme.colors.transparent
    property bool borderEnabled: true
    property color borderColor: Theme.colors.background
    property int borderWidth: 0
    property int blockRadius: Theme.geometry.radius
    // Removed header properties
    // Layout
    property real padding: Theme.geometry.spacing.dynamicPadding
    property real paddingHorizontal: padding
    property real paddingVertical: padding
    property real spacing: Theme.geometry.spacing.medium
    // Interactivity
    property bool clickable: false
    property bool hoverEnabled: true
    property bool premiumHover: false
    property bool premiumActive: false
    property bool popoutOnHover: false
    property var onHoverAction: null
    readonly property alias containsMouse: mouseArea.containsMouse
    readonly property alias pressed: mouseArea.pressed
    // Internal layout control
    default property alias contentData: contentContainer.data
    property alias _contentContainer: contentContainer

    signal clicked()
    signal rightClicked()
    signal middleClicked()
    signal pressedSignal()
    signal releasedSignal()

    Layout.fillWidth: true
    implicitWidth: mainLayout.implicitWidth + (paddingHorizontal * 2)
    implicitHeight: mainLayout.implicitHeight + (paddingVertical * 2)
    color: backgroundColor
    radius: blockRadius
    border.color: borderEnabled ? (premiumActive ? Theme.colors.transparent : borderColor) : Theme.colors.transparent
    border.width: borderEnabled ? borderWidth : 0
    scale: (root.clickable && pressed) ? 0.98 : 1.0

    Behavior on scale {
        BaseAnimation {
            duration: Theme.animations.fast
        }
    }

    onContainsMouseChanged: {
        if (containsMouse && Preferences.popoutTrigger === 1 && popoutOnHover && onHoverAction) {
            hoverTimer.restart();
        } else {
            hoverTimer.stop();
        }
    }

    Timer {
        id: hoverTimer
        interval: 250
        repeat: false
        onTriggered: {
            if (root.onHoverAction)
                root.onHoverAction();

        }
    }

    // State Layer
    BaseActiveBackground {
        id: stateLayer
        anchors.fill: parent
        radius: parent.radius
        baseColor: root.backgroundColor
        hoverColor: root.hoverColor
        hovered: mouseArea.containsMouse
        hoverEnabled: root.hoverEnabled
        premiumActive: root.premiumActive
        premiumHover: root.premiumHover
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        enabled: root.clickable
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton)
                root.rightClicked();
            else if (mouse.button === Qt.MiddleButton)
                root.middleClicked();
            else
                root.clicked();
        }
        onPressed: (mouse) => {
            root.pressedSignal();
        }
        onReleased: root.releasedSignal()
    }

    ColumnLayout {
        id: mainLayout

        anchors.fill: parent
        anchors.leftMargin: root.paddingHorizontal
        anchors.rightMargin: root.paddingHorizontal
        anchors.topMargin: root.paddingVertical
        anchors.bottomMargin: root.paddingVertical
        spacing: root.spacing

        // Removed built-in header layout

        ColumnLayout {
            id: contentContainer

            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: root.spacing
        }



    }

}
