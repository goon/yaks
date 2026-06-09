import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs
import qs.services

Item {
    id: root

    required property int columns
    required property int rows
    required property real overviewScale
    required property int workspaceCount
    required property int effectiveActiveWorkspaceId
    required property real wsWidth
    required property real wsHeight
    required property real gridSpacing
    required property real reservedLeft
    required property real reservedTop
    required property var monitor
    required property real monitorW
    required property real monitorH

    readonly property real availableW: monitorW - reservedLeft

    function getWorkspaceCol(wsId) {
        return (wsId - 1) % columns;
    }
    function getWorkspaceRow(wsId) {
        return Math.floor((wsId - 1) / columns);
    }

    function findToplevel(addr) {
        if (!addr) return null;
        var target = Compositor.normalizeAddress(addr);
        var tlList = ToplevelManager.toplevels.values;
        for (var i = 0; i < tlList.length; i++) {
            var tl = tlList[i];
            var tlAddr = Compositor.normalizeAddress(tl.HyprlandToplevel ? tl.HyprlandToplevel.address : "");
            if (tlAddr === target) return tl;
        }
        return null;
    }

    ColumnLayout {
        id: gridCol
        anchors.fill: parent
        spacing: root.gridSpacing

        Repeater {
            model: root.rows

            RowLayout {
                id: rowDelegate
                required property int index
                property int rowIndex: index
                spacing: root.gridSpacing

                Repeater {
                    model: root.columns

                    Item {
                        required property int index
                        property int colIndex: index
                        property int rowIndex: rowDelegate.rowIndex
                        property int wsId: rowIndex * root.columns + colIndex + 1

                        visible: wsId <= root.workspaceCount
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        readonly property bool isWsActive: wsId === root.effectiveActiveWorkspaceId
                            || (root.effectiveActiveWorkspaceId === -1 && wsId === 1)
                        readonly property bool hasWindows: {
                            for (var i = 0; i < Compositor.workspaces.length; i++) {
                                if (Compositor.workspaces[i].id === wsId)
                                    return Compositor.workspaces[i].hasWindows;
                            }
                            return false;
                        }

                        OverviewWorkspace {
                            anchors.fill: parent
                            wsId: parent.wsId
                            isWsActive: parent.isWsActive
                            hasWindows: parent.hasWindows
                            wsWidth: root.wsWidth
                            wsHeight: root.wsHeight
                        }
                    }
                }
            }
        }
    }

    Item {
        id: windowLayer
        anchors.fill: parent
        z: 1

        Repeater {
            model: Compositor.windows

            delegate: OverviewWindow {
                required property var modelData
                property int wsId: modelData.workspaceId || -1

                visible: wsId >= 1 && wsId <= root.workspaceCount
                address: modelData.id || ""
                windowData: modelData
                captureToplevel: root.findToplevel(modelData.id)
                overviewScale: root.overviewScale
                isActiveWorkspace: wsId === root.effectiveActiveWorkspaceId
                gridColumnX: root.getWorkspaceCol(wsId)
                gridRowY: root.getWorkspaceRow(wsId)
                gridSpacing: root.gridSpacing
                wsWidth: root.wsWidth
                wsHeight: root.wsHeight
                reservedLeft: root.reservedLeft
                reservedTop: root.reservedTop
                gridPaddingH: 0
                gridPaddingV: 0
                gridTotalWidth: root.width
                gridTotalHeight: root.height
                monitorW: root.monitorW
                monitorH: root.monitorH
            }
        }
    }
}