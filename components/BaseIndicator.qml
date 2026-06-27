import QtQuick
import qs

Item {
    id: root

    // ── VISUAL API ──────────────────────────────────────────────────
    property Item targetItem: null

    property int orientation: Qt.Vertical
    property bool retainLastPosition: false

    // ── HOVER-TRACKING API ─────────────────────────────────────────
    property var hoverPredicate: null
    property int gapInterval: 100

    // ── INTERNAL STATE ──────────────────────────────────────────────
    property real _lastX: 0
    property real _lastY: 0

    readonly property Item _hoverCandidate: hoverPredicate ? hoverPredicate() : null
    property Item _hoverTarget: null
    readonly property Item _effectiveTarget: hoverPredicate ? root._hoverTarget : root.targetItem

    readonly property real targetX: {
        if (orientation === Qt.Horizontal) {
            if (!_effectiveTarget) return retainLastPosition ? _lastX : 0;
            return _effectiveTarget.x + (_effectiveTarget.width - width) / 2;
        }
        return 0;
    }

    readonly property real targetY: {
        if (orientation === Qt.Vertical) {
            if (!_effectiveTarget) return retainLastPosition ? _lastY : 0;
            var centerY = (_effectiveTarget.contentCenterY !== undefined)
                ? _effectiveTarget.contentCenterY
                : _effectiveTarget.height / 2;
            return _effectiveTarget.y + centerY - height / 2;
        }
        return parent ? parent.height - height : 0;
    }

    x: targetX
    y: targetY

    onXChanged: if (_effectiveTarget) _lastX = x
    onYChanged: if (_effectiveTarget) _lastY = y

    Behavior on x { NumberAnimation { duration: Theme.animations.fast; easing.type: Easing.OutQuart } }
    Behavior on y { NumberAnimation { duration: Theme.animations.fast; easing.type: Easing.OutQuart } }

    opacity: _effectiveTarget ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: Theme.animations.fast } }

    z: 10

    width: 3
    height: 20

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Theme.colors.primary }
            GradientStop { position: 1.0; color: Theme.colors.secondary }
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
