import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

FloatingWindow {
    id: root

    property Component body: null
    property alias color: bg.color
    property real radius: Theme.geometry.radius
    property int layoutMargin: Theme.geometry.spacing.large
    property string title: ""

    visible: false
    implicitWidth: 800
    implicitHeight: 600
    color: Theme.colors.background

    // Background surface
    BaseBackground {
        id: bg
        anchors.fill: parent
        radius: 0
        color: Theme.colors.background
        opacity: 0
    }

    // Title Bar (only rendered when title is set)
    Item {
        id: titleBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.title.length > 0 ? 42 : 0
        visible: root.title.length > 0

        // Drag to move via system move
        MouseArea {
            anchors.fill: parent
            onPressed: root.startSystemMove()
            cursorShape: Qt.SizeAllCursor
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.geometry.spacing.large
            anchors.rightMargin: Theme.geometry.spacing.small
            spacing: Theme.geometry.spacing.small

            BaseText {
                text: root.title
                font.pixelSize: Theme.typography.size.base
                weight: Theme.typography.weights.medium
                color: Theme.colors.textMuted
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            // Minimize
            BaseButton {
                id: minimizeBtn
                implicitWidth: 22
                implicitHeight: 22
                circular: true
                normalColor: Theme.alpha(Theme.colors.warning, 0.0)
                hoverColor: Theme.alpha(Theme.colors.warning, 0.25)
                paddingHorizontal: 0
                paddingVertical: 0
                icon: "remove"
                size: 12
                iconColor: minimizeBtn.containsMouse ? Theme.colors.warning : Theme.colors.textMuted
                onClicked: root.minimized = true
            }

            // Maximize / Restore
            BaseButton {
                id: maximizeBtn
                implicitWidth: 22
                implicitHeight: 22
                circular: true
                normalColor: Theme.alpha(Theme.colors.success, 0.0)
                hoverColor: Theme.alpha(Theme.colors.success, 0.25)
                paddingHorizontal: 0
                paddingVertical: 0
                icon: root.maximized ? "fullscreen_exit" : "open_in_full"
                size: 12
                iconColor: maximizeBtn.containsMouse ? Theme.colors.success : Theme.colors.textMuted
                onClicked: root.maximized = !root.maximized
            }

            // Close
            BaseButton {
                id: closeBtn
                implicitWidth: 22
                implicitHeight: 22
                circular: true
                normalColor: Theme.alpha(Theme.colors.error, 0.0)
                hoverColor: Theme.alpha(Theme.colors.error, 0.25)
                paddingHorizontal: 0
                paddingVertical: 0
                icon: "close"
                size: 12
                iconColor: closeBtn.containsMouse ? Theme.colors.error : Theme.colors.textMuted
                onClicked: root.visible = false
            }
        }

        // Bottom divider
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Theme.alpha(Theme.colors.border, 0.5)
        }
    }

    property bool wasEverVisible: false
    onVisibleChanged: if (visible) wasEverVisible = true

    Loader {
        id: contentLoader
        active: root.wasEverVisible
        anchors.top: titleBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        sourceComponent: root.body
        opacity: 0

        onLoaded: {
            if (item) {
                item.width = contentLoader.width;
                item.height = contentLoader.height;
            }
        }
    }

    // Entry animations
    NumberAnimation {
        target: bg
        property: "opacity"
        from: 0
        to: 1.0
        duration: Theme.animations.normal
        running: root.visible
    }

    NumberAnimation {
        target: contentLoader
        property: "opacity"
        from: 0
        to: 1
        duration: Theme.animations.normal
        running: root.visible
    }

    // Escape to close
    Item {
        focus: true
        Keys.onEscapePressed: root.visible = false
    }
}
