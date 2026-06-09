import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs
import qs.services

Item {
    id: root

    required property string address
    required property var windowData
    required property var captureToplevel
    required property real overviewScale
    required property bool isActiveWorkspace
    required property int gridColumnX
    required property int gridRowY
    required property real gridSpacing
    required property real wsWidth
    required property real wsHeight
    required property real reservedLeft
    required property real reservedTop
    required property real gridPaddingH
    required property real gridPaddingV
    required property real gridTotalWidth
    required property real gridTotalHeight
    required property real monitorW
    required property real monitorH

    readonly property bool isFocused: windowData ? windowData.isFocused : false

    readonly property real rawX: windowData && windowData.at ? (windowData.at[0] - reservedLeft) * overviewScale : 0
    readonly property real rawY: windowData && windowData.at ? (windowData.at[1] - reservedTop) * overviewScale : 0
    readonly property real rawW: windowData && windowData.size ? windowData.size[0] * overviewScale : wsWidth * 0.5
    readonly property real rawH: windowData && windowData.size ? windowData.size[1] * overviewScale : wsHeight * 0.5
    readonly property bool isFullscreen: windowData ? (windowData.fullscreen > 0 || windowData.fullscreen === true) : false

    readonly property real relX: Math.max(0, rawX)
    readonly property real relY: Math.max(0, rawY)
    readonly property real availW: Math.max(1, wsWidth - relX)
    readonly property real availH: Math.max(1, wsHeight - relY)

    readonly property real tileX: gridColumnX * (wsWidth + gridSpacing) + gridPaddingH
    readonly property real tileY: gridRowY * (wsHeight + gridSpacing) + gridPaddingV

    readonly property string appId: windowData ? (windowData["class"] || windowData.appId || "") : ""
    readonly property string title: windowData ? (windowData.title || "") : ""

    readonly property string iconPath: {
        if (!appId) return "";
        var path = Quickshell.iconPath(appId, "application-x-executable");
        return path || "";
    }

    x: relX + tileX
    y: relY + tileY
    width: isFullscreen ? wsWidth : Math.max(1, Math.min(rawW, availW))
    height: isFullscreen ? wsHeight : Math.max(1, Math.min(rawH, availH))

    property bool hovered: false
    property bool pressed: false

    Rectangle {
        id: windowBg
        anchors.fill: parent
        radius: Theme.geometry.radius * 0.5
        color: Theme.alpha(Theme.colors.background, 0.85)

        clip: true

        border.width: root.isFocused ? 2 : (root.hovered ? 1 : 0)
        border.color: root.isFocused ? Theme.colors.primary : Theme.colors.divider

        Behavior on border.width { BaseAnimation { speed: "fast" } }
        Behavior on border.color { BaseAnimation { speed: "fast" } }

        ScreencopyView {
            id: windowPreview
            readonly property real srcAspect: {
                var w = root.windowData && root.windowData.size ? root.windowData.size[0] : 0;
                var h = root.windowData && root.windowData.size ? root.windowData.size[1] : 0;
                return (w > 0 && h > 0) ? (w / h) : 1;
            }

            anchors.centerIn: parent
            width: root.isFullscreen ? parent.width : Math.min(parent.width, parent.height * srcAspect)
            height: root.isFullscreen ? parent.height : Math.min(parent.height, parent.width / srcAspect)
            captureSource: root.captureToplevel || null
            live: true
            visible: root.captureToplevel !== null && root.captureToplevel !== undefined
            layer.enabled: root.captureToplevel !== null && root.captureToplevel !== undefined
            layer.smooth: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: previewMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }
        }

        Item {
            id: previewMask
            anchors.fill: parent
            visible: false
            layer.enabled: true
            layer.smooth: true

            Rectangle {
                anchors.fill: parent
                radius: windowBg.radius
            }
        }

        Item {
            id: fallbackIcons
            anchors.fill: parent
            visible: !windowPreview.hasContent

            Rectangle {
                anchors.centerIn: parent
                width: Theme.dimensions.iconLarge
                height: Theme.dimensions.iconLarge
                radius: Theme.geometry.radius * 0.5
                color: Theme.alpha(Theme.colors.primary, 0.2)

                Image {
                    anchors.centerIn: parent
                    source: root.iconPath
                    width: Theme.dimensions.iconMedium
                    height: Theme.dimensions.iconMedium
                    sourceSize: Qt.size(Theme.dimensions.iconMedium, Theme.dimensions.iconMedium)
                    fillMode: Image.PreserveAspectFit
                    visible: root.iconPath !== ""
                }

                BaseText {
                    anchors.centerIn: parent
                    text: root.appId ? root.appId.charAt(0).toUpperCase() : "?"
                    color: Theme.colors.primary
                    pixelSize: Theme.dimensions.iconBase
                    weight: Theme.typography.weights.bold
                    visible: root.iconPath === ""
                }
            }

            BaseText {
                anchors.top: parent.verticalCenter
                anchors.topMargin: Theme.dimensions.iconLarge * 0.6
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.title
                pixelSize: Theme.typography.size.small
                color: Theme.colors.textMuted
                maximumLineCount: 1
                elide: Text.ElideRight
                width: parent.width - Theme.geometry.spacing.medium
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: windowBg.radius
            color: "transparent"
            visible: root.hovered || root.isFocused

            Rectangle {
                anchors.fill: parent
                radius: windowBg.radius
                color: root.isFocused ? Theme.alpha(Theme.colors.primary, 0.08) : Theme.alpha(Theme.colors.primary, 0.05)
            }
        }
    }

    MouseArea {
        id: windowMouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor

        onEntered: root.hovered = true
        onExited: root.hovered = false
        onPressed: root.pressed = true
        onReleased: root.pressed = false

        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton) {
                Compositor.closeWindow(root.address);
            } else {
                Compositor.focusWindow(root.address);
                IslandService.closeAll();
            }
        }
    }
}