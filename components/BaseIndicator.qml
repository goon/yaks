import QtQuick
import qs

Item {
    id: root

    // ── VISUAL API ──────────────────────────────────────────────────
    property Item targetItem: null

    // ── HOVER-TRACKING API ─────────────────────────────────────────
    property var hoverPredicate: null
    property int gapInterval: 100

    // ── INTERNAL STATE ──────────────────────────────────────────────
    property real _lastY: 0
    property bool _hasPositioned: false

    readonly property Item _hoverCandidate: hoverPredicate ? hoverPredicate() : null
    property Item _hoverTarget: null
    readonly property Item _effectiveTarget: hoverPredicate ? root._hoverTarget : root.targetItem

    readonly property real targetY: {
        if (!_effectiveTarget || !root.parent) return _lastY;
        var centerY = (_effectiveTarget.contentCenterY !== undefined)
            ? _effectiveTarget.contentCenterY
            : _effectiveTarget.height / 2;
        return _effectiveTarget.mapToItem(root.parent, 0, centerY).y - height / 2;
    }

    x: 0
    y: targetY

    onYChanged: if (_effectiveTarget) { _lastY = y; _hasPositioned = true; }

    Behavior on y { enabled: root._hasPositioned; NumberAnimation { duration: Globals.motion.standard; easing.type: Easing.OutQuart } }

    opacity: _effectiveTarget ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: Globals.motion.hover } }

    z: 10

    width: 0
    // Deliberately zero-sized. Two constraints a call site has to satisfy:
    // (1) the item must be a SIBLING of any ColumnLayout, never a child — a
    // layout is a positioner that writes `x`/`y` on every child and clobbers
    // the `y: targetY` binding, parking the pill at the end of the column.
    // Roots that are a plain `Item` (e.g. `SettingsGroup`) satisfy this for
    // free; roots rooted in a `BaseContainer` (whose default property is the
    // inner ColumnLayout) need a zero-height wrapper Item as the first child
    // of that layout. (2) the 0×0 box keeps the layout from reserving any
    // space. The visible pill carries its own size and centres on this anchor
    // point.

    Rectangle {
        x: 0
        width: 3 * Globals.shellScale
        height: 20 * Globals.shellScale
        anchors.verticalCenter: parent.verticalCenter
        radius: width / 2
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Globals.colors.primary }
            GradientStop { position: 1.0; color: Globals.colors.secondary }
        }
    }

    Timer {
        id: gapTimer
        interval: root.gapInterval
        repeat: false
        onTriggered: root._hoverTarget = null
    }

    on_HoverCandidateChanged: {
        if (root._hoverCandidate) {
            root._hoverTarget = root._hoverCandidate;
            gapTimer.stop();
        } else {
            gapTimer.restart();
        }
    }
}
