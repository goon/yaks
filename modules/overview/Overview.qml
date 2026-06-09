import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.services

FocusScope {
    id: root

    property string panelState: "Closed"
    property var barWindow: null

    readonly property var monitor: barWindow ? Hyprland.monitorFor(barWindow.screen) : null

    readonly property int columns: Preferences.overviewColumns
    readonly property int workspaceCount: Preferences.workspaceCount
    readonly property int rows: Math.ceil(workspaceCount / columns)
    readonly property real overviewScale: Preferences.overviewScale

    readonly property real reservedLeft: monitor ? monitor.reserved.left : 0
    readonly property real reservedRight: monitor ? monitor.reserved.right : 0
    readonly property real reservedTop: monitor ? monitor.reserved.top : 0
    readonly property real reservedBottom: monitor ? monitor.reserved.bottom : 0

    readonly property real monitorW: monitor ? monitor.width / monitor.scale : 1920
    readonly property real monitorH: monitor ? monitor.height / monitor.scale : 1080
    readonly property real monitorX: monitor ? monitor.x : 0
    readonly property real monitorY: monitor ? monitor.y : 0
    readonly property real availableW: monitorW - reservedLeft - reservedRight
    readonly property real availableH: monitorH - reservedTop - reservedBottom

    readonly property real wsWidth: Math.round(availableW * overviewScale)
    readonly property real wsHeight: Math.round(availableH * overviewScale)
    readonly property real gridSpacing: Theme.geometry.spacing.medium

    readonly property int effectiveActiveWorkspaceId: Math.max(1, Compositor.activeWorkspaceId)

    implicitWidth: columns * wsWidth + (columns - 1) * gridSpacing
    implicitHeight: rows * wsHeight + (rows - 1) * gridSpacing + 35

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            IslandService.closeAll();
            event.accepted = true;
            return;
        }

        var currentId = Compositor.activeWorkspaceId;
        var columns_ = columns;
        var workspaceCount_ = workspaceCount;
        var rows_ = rows;

        var clampedIndex = Math.max(0, Math.min(workspaceCount_ - 1, currentId - 1));
        var currentRow = Math.floor(clampedIndex / columns_);
        var currentCol = clampedIndex % columns_;

        var targetRow = currentRow;
        var targetCol = currentCol;
        var targetId = null;

        if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
            targetCol = (targetCol - 1 + columns_) % columns_;
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
            targetCol = (targetCol + 1) % columns_;
        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
            targetRow = (targetRow - 1 + rows_) % rows_;
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
            targetRow = (targetRow + 1) % rows_;
        } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
            var position = event.key - Qt.Key_0;
            if (position <= workspaceCount_) {
                targetId = position;
            }
        } else if (event.key === Qt.Key_0) {
            if (workspaceCount_ >= 10) {
                targetId = 10;
            }
        }

        if (targetId === null && (
            event.key === Qt.Key_Left || event.key === Qt.Key_H ||
            event.key === Qt.Key_Right || event.key === Qt.Key_L ||
            event.key === Qt.Key_Up || event.key === Qt.Key_K ||
            event.key === Qt.Key_Down || event.key === Qt.Key_J
        )) {
            targetId = targetRow * columns_ + targetCol + 1;
        }

        if (targetId !== null) {
            var clampedTarget = Math.max(1, Math.min(workspaceCount_, targetId));
            Compositor.switchToWorkspace(clampedTarget);
            event.accepted = true;
        }
    }

    OverviewGrid {
        id: grid
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: rows * wsHeight + (rows - 1) * gridSpacing

        columns: root.columns
        rows: root.rows
        overviewScale: root.overviewScale
        workspaceCount: root.workspaceCount
        effectiveActiveWorkspaceId: root.effectiveActiveWorkspaceId
        wsWidth: root.wsWidth
        wsHeight: root.wsHeight
        gridSpacing: root.gridSpacing
        reservedLeft: root.reservedLeft
        reservedTop: root.reservedTop
        monitor: root.monitor
        monitorW: root.monitorW
        monitorH: root.monitorH
        monitorX: root.monitorX
        monitorY: root.monitorY
    }

    BaseText {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.geometry.spacing.small
        text: "Windows can be dragged/dropped to move between workspaces or reposition/reorder on same workspace."
        color: Theme.colors.textMuted
        pixelSize: Theme.typography.size.small
        weight: Theme.typography.weights.normal
        opacity: 0.8
    }
}