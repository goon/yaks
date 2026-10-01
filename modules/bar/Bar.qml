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
    color: "transparent"
    
    WlrLayershell.keyboardFocus: capsule.grabsFocus ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    WlrLayershell.namespace: "yaks:bar"
    WlrLayershell.layer: WlrLayer.Top
    
    WlrLayershell.exclusiveZone: Preferences.bar.reservedZone

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

    // While the pill is settled (collapsed or fully expanded / a surface is
    // open) the input region can be the exact capsule rect or the whole layer.
    // While it is mid-morph the moving capsule can briefly leave the capsule
    // rect, so the union of the rest pill and the animating capsule is used
    // instead, keeping input stable across the transition.
    mask: {
        if (capsule.isCapsuleMorphed && !capsule.isToast)
            return null;
        if (!capsule.isSettled)
            return unionRegion;
        return capsuleRegion;
    }

    Region {
        id: capsuleRegion
        item: capsule.maskItem
    }

    Region {
        id: unionRegion
        item: capsule.maskItemUnion
    }

    Capsule {
        id: capsule
        barWindow: bar
        anchors.fill: parent
    }

}
