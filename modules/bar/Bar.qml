import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs

PanelWindow {
    id: bar

    property var leftComponents: Preferences.barLeftComponents
    readonly property var centerComponents: Preferences.barCenterComponents
    readonly property var rightComponents: Preferences.barRightComponents
    readonly property real sideMargin: Math.max(0, (Preferences.barHeight - (Theme.dimensions.barItemHeight * Theme.barScale)) / 2)

    function resolveComponentSource(name) {
        const map = {
            "workspaces": Qt.resolvedUrl("components/Workspaces.qml"),
            "clock": Qt.resolvedUrl("components/Clock.qml"),
            "dock": Qt.resolvedUrl("components/Dock.qml"),
            "indicators": Qt.resolvedUrl("components/Indicators.qml"),
        };
        return map[name] || "";
    }

    objectName: "bar"
    color: Theme.colors.transparent
    
    // Dynamic keyboard focus grabbing when morphed
    WlrLayershell.keyboardFocus: island.isIslandMorphed ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    WlrLayershell.namespace: "quickshell:bar"
    WlrLayershell.layer: WlrLayer.Top
    
    // Crucial: Set fixed exclusive zone so full-screen expansion does not push user windows
    WlrLayershell.exclusiveZone: Preferences.barHeight + Preferences.barMarginTop

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
        top: Preferences.barPosition === "top"
        bottom: Preferences.barPosition === "bottom"
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

    // Input mask: Lock clicks to the capsule when not morphed, allowing the sides to be click-through.
    mask: island.isIslandMorphed ? null : capsuleRegion

    Region {
        id: capsuleRegion
        item: island.capsuleItem
    }

    // Centralized Island framework component
    Island {
        id: island
        barWindow: bar
        anchors.fill: parent
    }

}
