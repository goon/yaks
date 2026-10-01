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

    width: 3 * Globals.shellScale
    height: 20 * Globals.shellScale

    Rectangle {
        anchors.fill: parent
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
