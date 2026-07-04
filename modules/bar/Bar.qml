import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs

PanelWindow {
    id: bar

    property var components: Preferences.bar.components

    function resolveComponentSource(name) {
        const map = {
            "workspaces": Qt.resolvedUrl("BarWorkspaces.qml"),
            "clock": Qt.resolvedUrl("BarClock.qml"),
            "dock": Qt.resolvedUrl("BarDock.qml"),
            "indicators": Qt.resolvedUrl("BarIndicators.qml"),
        };
        return map[name] || "";
    }

    objectName: "bar"
    color: Globals.colors.transparent
    
    WlrLayershell.keyboardFocus: island.grabsFocus ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    WlrLayershell.namespace: "yaks:bar"
    WlrLayershell.layer: WlrLayer.Top
    
    WlrLayershell.exclusiveZone: Preferences.bar.height + Preferences.bar.marginTop

    implicitHeight: bar.screen ? bar.screen.height : 1080
    implicitWidth: 0

    anchors {
        top: Preferences.bar.position === "top"
        bottom: Preferences.bar.position === "bottom"
        left: true
        right: true
    }

    margins {
        top: 0
        bottom: 0
        left: 0
        right: 0
    }

    mask: (island.isIslandMorphed && !island.isToast) ? null : capsuleRegion

    Region {
        id: capsuleRegion
        item: island.maskItem
    }

    Island {
        id: island
        barWindow: bar
        anchors.fill: parent
    }

}
