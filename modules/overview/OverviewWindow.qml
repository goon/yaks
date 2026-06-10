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
    required property real monitorX
    required property real monitorY

    readonly property bool isFocused: windowData ? windowData.isFocused : false

    readonly property real rawX: windowData && windowData.at ? (windowData.at[0] - monitorX - reservedLeft) * overviewScale : 0
    readonly property real rawY: windowData && windowData.at ? (windowData.at[1] - monitorY - reservedTop) * overviewScale : 0
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

    property bool isDragging: false
    property point dragStartPos: Qt.point(0, 0)
    property point dragOffset: Qt.point(0, 0)

    Drag.active: isDragging
    Drag.source: root
    Drag.keys: ["window"]
    Drag.hotSpot.x: dragStartPos.x
    Drag.hotSpot.y: dragStartPos.y

    x: isDragging ? dragOffset.x : (relX + tileX)
    y: isDragging ? dragOffset.y : (relY + tileY)
    width: isFullscreen ? wsWidth : Math.max(1, Math.min(rawW, availW))
    height: isFullscreen ? wsHeight : Math.max(1, Math.min(rawH, availH))

    z: isDragging ? 100 : (isFocused ? 2 : 1)

    Behavior on x { enabled: !root.isDragging; BaseAnimation { speed: "fast" } }
    Behavior on y { enabled: !root.isDragging; BaseAnimation { speed: "fast" } }

    property bool hovered: false
    property bool pressed: false

    property int lastWorkspaceId: -1

    Timer {
        id: pendingFocusTimer
        interval: 400
        repeat: false
        onTriggered: {
            if (root.isDragging === false && root.pressed === false) {
                Compositor.focusWindow(root.address);
                IslandService.closeAll();
            }
        }
    }

    function onDroppedOnWorkspace(targetWsId) {
        dragResetTimer.stop();
        root.isDragging = false;
        Compositor.dragInProgress = false;
    }

    Timer {
        id: dragResetTimer
        interval: 300
        repeat: false
        onTriggered: {
            if (root.isDragging) {
                root.isDragging = false;
                Compositor.dragInProgress = false;
            }
        }
    }

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
        cursorShape: root.isDragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor

        onEntered: root.hovered = true
        onExited: root.hovered = false
        
        onPressed: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                root.pressed = true;
                root.dragStartPos = Qt.point(mouse.x, mouse.y);
                root.lastWorkspaceId = root.windowData ? (root.windowData.workspaceId || -1) : -1;
                pendingFocusTimer.restart();
            }
        }

        onPositionChanged: (mouse) => {
            if (root.pressed && !root.isDragging) {
                var distance = Math.sqrt(Math.pow(mouse.x - root.dragStartPos.x, 2) + Math.pow(mouse.y - root.dragStartPos.y, 2));
                if (distance > 8) {
                    pendingFocusTimer.stop();
                    root.dragOffset = Qt.point(relX + tileX, relY + tileY);
                    root.isDragging = true;
                    Compositor.dragInProgress = true;
                }
            }
            if (root.isDragging) {
                var mapped = windowMouseArea.mapToItem(root.parent, mouse.x, mouse.y);
                root.dragOffset = Qt.point(mapped.x - root.dragStartPos.x, mapped.y - root.dragStartPos.y);
            }
        }

        onReleased: (mouse) => {
            pendingFocusTimer.stop();
            root.pressed = false;
            if (root.isDragging) {
                root.Drag.drop();
                Compositor.dragInProgress = false;
                dragResetTimer.restart();
            }
        }

        onClicked: (mouse) => {
            if (!root.isDragging) {
                if (mouse.button === Qt.MiddleButton) {
                    Compositor.closeWindow(root.address);
                }
            }
        }
    }

    DropArea {
        id: windowDropArea
        anchors.fill: parent
        keys: ["window"]
        enabled: !root.isDragging

        onEntered: (drag) => {
            drag.accept();
        }

        onDropped: (drop) => {
            drop.accept();
            var draggedWindow = drop.source;
            if (draggedWindow && draggedWindow.address && draggedWindow.address !== root.address) {
                if (draggedWindow.lastWorkspaceId === root.windowData.workspaceId) {
                    Compositor.swapWindows(draggedWindow.address, root.address);
                } else {
                    Compositor.moveToWorkspace(draggedWindow.address, root.windowData.workspaceId);
                    if (draggedWindow.lastWorkspaceId >= 1) {
                        Compositor.moveToWorkspace(root.address, draggedWindow.lastWorkspaceId);
                    }
                }
                if (typeof draggedWindow.onDroppedOnWorkspace === "function") {
                    draggedWindow.onDroppedOnWorkspace(root.windowData.workspaceId);
                }
            }
        }
    }
}