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
    color: Theme.colors.transparent
    
    // Dynamic keyboard focus grabbing when morphed
    WlrLayershell.keyboardFocus: island.grabsFocus ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    WlrLayershell.namespace: "yaks:bar"
    WlrLayershell.layer: WlrLayer.Top
    
    // Crucial: Set fixed exclusive zone so full-screen expansion does not push user windows
    WlrLayershell.exclusiveZone: Preferences.bar.height + Preferences.bar.marginTop

    // The bar is permanently full-screen height.
    //
    // Root cause of the "trailing rectangle" artifact: when implicitHeight snapped
    // from screen height back to barHeight after a panel closed, Hyprland rendered
    // a frame of the old large surface (including its blur region) before the resize
    // was processed — visually appearing as a rectangle sliding upward.
    //
    // Keeping the height constant eliminates the resize entirely.
    // The input mask restricts clicks to the capsule when not morphed, so the
    // transparent area above/below is fully click-through.
    implicitHeight: bar.screen ? bar.screen.height : 1080
    implicitWidth: 0

    // Anchors: Width is locked to full screen at all times to prevent relative coordinate shifts.
    anchors {
        top: Preferences.bar.position === "top"
        bottom: Preferences.bar.position === "bottom"
        left: true
        right: true
    }

    // Margins: Lock margins to prevent vertical window movement.
    margins {
        top: 0
        bottom: 0
        left: 0
        right: 0
    }

    // Input mask: Lock clicks to the capsule when not morphed or when showing a toast, allowing the sides to be click-through.
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
