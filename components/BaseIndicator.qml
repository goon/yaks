import QtQuick
import qs

Item {
    id: root

    // ── VISUAL API (unchanged) ──────────────────────────────────────
    property Item targetItem: null

    property int orientation: Qt.Vertical
    property int edge: Qt.LeftEdge
    property real edgeOffset: 0

    property bool retainLastPosition: false

    property int duration: Theme.animations.fast
    property int easingType: Easing.OutQuart

    // ── HOVER-TRACKING API (new) ───────────────────────────────────
    // When set to a function returning the currently-hovered Item (or null),
    // the indicator derives its targetItem from the predicate instead of
    // from the `targetItem` property. The gapInterval debounces "hover lost"
    // → "drop the indicator" by `gapInterval` ms.
    // When null (default), the indicator is a pure follower of `targetItem`.
    property var hoverPredicate: null
    property int gapInterval: 100

    // ── INTERNAL STATE ──────────────────────────────────────────────
    property real _lastX: 0
    property real _lastY: 0

    // The hover-derived candidate (raw, no debounce)
    readonly property Item _hoverCandidate: hoverPredicate ? hoverPredicate() : null

    // `_hoverTarget` is the debounced hover state — set to the candidate
    // on hover, cleared after `gapInterval` ms of no hover.
    property Item _hoverTarget: null

    // Effective target: hover-derived (if predicate set) else direct
    readonly property Item _effectiveTarget: hoverPredicate ? root._hoverTarget : root.targetItem

    readonly property real targetX: {
        if (orientation === Qt.Horizontal) {
            if (!_effectiveTarget) return retainLastPosition ? _lastX : 0;
            return _effectiveTarget.x + (_effectiveTarget.width - width) / 2;
        }
        if (edge === Qt.RightEdge) {
            return (parent ? parent.width - width : 0) + edgeOffset;
        }
        return edgeOffset;
    }

    readonly property real targetY: {
        if (orientation === Qt.Vertical) {
            if (!_effectiveTarget) return retainLastPosition ? _lastY : 0;
            var centerY = (_effectiveTarget.contentCenterY !== undefined)
                ? _effectiveTarget.contentCenterY
                : _effectiveTarget.height / 2;
            return _effectiveTarget.y + centerY - height / 2;
        }
        if (edge === Qt.TopEdge) return edgeOffset;
        if (edge === Qt.BottomEdge) {
            return (parent ? parent.height - height : 0) + edgeOffset;
        }
        return edgeOffset;
    }

    x: targetX
    y: targetY

    onXChanged: if (_effectiveTarget) _lastX = x
    onYChanged: if (_effectiveTarget) _lastY = y

    Behavior on x { NumberAnimation { duration: duration; easing.type: easingType } }
    Behavior on y { NumberAnimation { duration: duration; easing.type: easingType } }

    opacity: _effectiveTarget ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: duration } }

    z: 10

    // ── HOVER STATE MACHINE ─────────────────────────────────────────
    // Only active when `hoverPredicate` is set. The gap timer debounces
    // "hover lost" → "drop the indicator" by `gapInterval` ms. If hover
    // returns within the window, the timer is cancelled and the indicator
    // stays put.
    Timer {
        id: gapTimer
        interval: root.gapInterval
        repeat: false
        onTriggered: root._hoverTarget = null
    }

    // Re-evaluate whenever the candidate changes:
    // - candidate non-null → set target, stop timer
    // - candidate null → start timer (target stays put until it fires)
    on_HoverCandidateChanged: {
        if (root._hoverCandidate) {
            root._hoverTarget = root._hoverCandidate;
            gapTimer.stop();
        } else {
            gapTimer.restart();
        }
    }
}
