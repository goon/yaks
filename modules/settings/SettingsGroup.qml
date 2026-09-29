import QtQuick
import QtQuick.Layouts
import qs

Item {
    id: root
    Layout.fillWidth: true
    implicitHeight: col.implicitHeight

    default property alias content: col.data

    ColumnLayout {
        id: col
        anchors.fill: parent
        spacing: 0
    }

    HoverHandler {
        id: hoverTracker
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }

    function _hoverPredicate() {
        // Keyboard navigation wins over hover: if the focused row belongs to
        // this group, the indicator follows it.
        var navTarget = root._navTarget();
        if (navTarget) return navTarget;

        if (!hoverTracker.hovered) return null;
        var my = hoverTracker.point.position.y;
        for (var i = 0; i < col.children.length; i++) {
            var child = col.children[i];
            if (!child.visible || child.height === 0) continue;
            if (my >= child.y && my <= child.y + child.height) {
                return child.indicatorTarget !== undefined ? child.indicatorTarget : child;
            }
        }
        return null;
    }

    function _navTarget() {
        var item = SettingsNav.items[SettingsNav.index];
        if (!item || !item.navFocused)
            return null;
        // Only claim the indicator if the focused row is a descendant here.
        for (var i = 0; i < col.children.length; i++) {
            var child = col.children[i];
            if (child === item)
                return child.indicatorTarget !== undefined ? child.indicatorTarget : child;
        }
        return null;
    }

    BaseIndicator {
        parent: root
        hoverPredicate: root._hoverPredicate
        gapInterval: 80
    }
}
