import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs
import qs.services

Item {
    id: root

    required property int wsId
    required property bool isWsActive
    required property bool hasWindows
    required property real wsWidth
    required property real wsHeight

    readonly property string wsLabel: {
        if (Preferences.workspaceStyle === 1) return toRoman(wsId);
        if (Preferences.workspaceStyle === 2) return toKanji(wsId);
        return wsId.toString();
    }

    function toRoman(n) {
        if (n <= 0) return n;
        var mapping = [[10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]];
        var res = "";
        for (var i = 0; i < mapping.length; i++) {
            while (n >= mapping[i][0]) { res += mapping[i][1]; n -= mapping[i][0]; }
        }
        return res;
    }

    function toKanji(n) {
        if (n <= 0) return n;
        var digits = ["", "\u4E00", "\u4E8C", "\u4E09", "\u56DB", "\u4E94", "\u516D", "\u4E03", "\u516B", "\u4E5D"];
        if (n < 10) return digits[n];
        if (n === 10) return "\u5341";
        return n.toString();
    }

    DropArea {
        id: dropArea
        anchors.fill: parent
        keys: ["window"]

        onEntered: (drag) => {
            drag.accept();
        }

        onDropped: (drop) => {
            drop.accept();
            var draggedWindow = drop.source;
            if (draggedWindow && draggedWindow.address) {
                Compositor.moveToWorkspace(draggedWindow.address, root.wsId);
                if (typeof draggedWindow.onDroppedOnWorkspace === "function") {
                    draggedWindow.onDroppedOnWorkspace(root.wsId);
                }
            }
        }
    }

    Rectangle {
        id: wsBackground
        anchors.fill: parent
        radius: Theme.geometry.radius
        color: Theme.alpha(Theme.colors.surface, Theme.opacity.surface)
        border.width: root.isWsActive || dropArea.containsDrag ? 2 : (mouseArea.containsMouse ? 1 : 0)
        border.color: dropArea.containsDrag ? Theme.colors.success : (root.isWsActive ? Theme.colors.primary : Theme.colors.divider)

        Behavior on border.width { BaseAnimation { speed: "fast" } }
        Behavior on border.color { BaseAnimation { speed: "fast" } }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            onClicked: {
                Compositor.switchToWorkspace(wsId);
                IslandService.closeAll();
            }
        }
    }

    BaseText {
        anchors.centerIn: parent
        visible: !root.hasWindows
        text: root.wsLabel
        color: root.isWsActive ? Theme.colors.primary : Theme.colors.muted
        pixelSize: Theme.typography.size.large
        weight: root.isWsActive ? Theme.typography.weights.bold : Theme.typography.weights.normal
        opacity: root.isWsActive ? 1 : 0.5
    }
}