import QtQuick
import QtQuick.Controls
import qs

Item {
    id: root

    required property TextInput control
    property bool parkInPlaceholder: false

    readonly property real _depth: 0.18
    readonly property real _squash: 0.14
    readonly property real _downShare: 0.18
    readonly property real _bounce: 1.0
    readonly property int _strikeMs: 240
    readonly property real _advanceCw: 0.25
    readonly property int _advanceMs: 150

    readonly property real _blinkSpeed: 0.8
    readonly property real _blinkBalance: 0.55
    readonly property real _blinkFade: 0.35
    readonly property int _blinkHoldMs: 550
    readonly property real _blinkPeriod: 2500 / _blinkSpeed
    readonly property real _blinkHold: 1 - _blinkFade * 2
    readonly property real _blinkLit: _blinkPeriod * _blinkHold * _blinkBalance
    readonly property real _blinkDark: _blinkPeriod * _blinkHold * (1 - _blinkBalance)
    readonly property real _blinkFadeMs: _blinkPeriod * _blinkFade

    readonly property bool _blinkEnabled: Application.styleHints.cursorFlashTime > 0
    readonly property real _lineH: control.cursorRectangle.height > 0 ? control.cursorRectangle.height : control.font.pixelSize * 1.4
    readonly property real _advancePx: _advanceCw * control.font.pixelSize * 0.6

    property real _boost: 1
    property bool _appearing: false

    // ── PLACEHOLDER PARK ──────────────────────────────────────────────────
    // Qt parks an empty field's caret at position 0, i.e. before the
    // placeholder glyphs. We shift it by the placeholder's width so it reads as
    // trailing the hint, and glide that shift away on the first keystroke. The
    // glide lives on the delegate root rather than `ink` so the per-keystroke
    // strike keeps its own timings.
    readonly property real _parkOffset: {
        if (!parkInPlaceholder || control.placeholderText.length === 0)
            return 0;
        return Math.max(0, Math.min(placeholderMetrics.width,
            control.width - control.leftPadding - control.rightPadding - width));
    }

    readonly property real _placeholderOffset: control.text.length === 0 ? _parkOffset : 0

    // Animated delta, 0 at rest. The first keystroke starts it at the park width
    // and settles it to 0, which walks the caret from the end of the placeholder
    // back to Qt's real cursor position. Kept separate from the bound rest offset
    // so animating never breaks that binding.
    property real _glide: 0

    readonly property int _appearMs: Globals.motion.hover

    width: Globals.dimensions.caretWidth
    visible: control.activeFocus && !control.readOnly
             && control.selectionStart === control.selectionEnd
             && !control.inputMethodComposing

    transform: Translate { id: glideShift; x: root._placeholderOffset + root._glide }

    TextMetrics {
        id: placeholderMetrics
        font: control.font
        text: control.placeholderText
    }

    NumberAnimation {
        id: glideAnim
        target: root
        property: "_glide"
        to: 0
        duration: Globals.motion.hover
        easing.type: Globals.motion.easeStandard
    }

    Rectangle {
        id: ink

        anchors.fill: parent
        color: Globals.colors.primary
        radius: width / 2

        transform: [
            Translate { id: shift },
            Scale {
                id: squash
                origin.x: ink.width / 2
                origin.y: ink.height
            }
        ]
    }

    FrameAnimation {
        id: strike

        onTriggered: root._applyPose(strike.elapsedTime * 1000)
    }

    function _applyPose(t) {
        var dy = 0;
        var sy = 1;
        var dx = 0;

        if (t < root._strikeMs) {
            var u = t / root._strikeMs;
            var sh;
            if (u < root._downShare) {
                sh = 1 - Math.pow(1 - u / root._downShare, 2);
            } else {
                var v = (u - root._downShare) / (1 - root._downShare);
                sh = Math.cos(v * Math.PI * 1.5) * Math.pow(1 - v, 1.2);
                if (sh < 0)
                    sh *= root._bounce;
            }
            dy = sh * root._depth * root._lineH * root._boost;
            sy = sh > 0 ? 1 - root._squash * sh : 1 + root._squash * 1.8 * -sh;
        }

        if (t < root._advanceMs) {
            var a = t / root._advanceMs;
            dx = Math.sin(Math.PI * a) * (1 - a) / 0.5796 * root._advancePx * root._boost;
        }

        shift.x = dx;
        shift.y = dy;
        squash.yScale = sy;

        if (t >= root._strikeMs && t >= root._advanceMs)
            strike.stop();
    }

    function _appear() {
        if (!root.visible || !root._blinkEnabled) {
            ink.opacity = 1;
            return;
        }
        root._appearing = true;
        blinkAnim.stop();
        hold.stop();
        ink.opacity = 0;
        appearAnim.restart();
    }

    function _solid() {
        root._appearing = false;
        appearAnim.stop();
        blinkAnim.stop();
        hold.restart();
        ink.opacity = 1;
    }

    function _poke(boost) {
        root._boost = boost || 1;
        root._solid();
        strike.restart();
    }

    onVisibleChanged: {
        if (root.visible) {
            root._appear();
        } else {
            blinkAnim.stop();
            appearAnim.stop();
            root._appearing = false;
        }
    }

    Component.onCompleted: if (root.visible) root._appear()

    SequentialAnimation {
        id: blinkAnim

        loops: Animation.Infinite

        PauseAnimation { duration: root._blinkLit }
        NumberAnimation {
            target: ink
            property: "opacity"
            from: 1
            to: 0
            duration: root._blinkFadeMs
            easing.type: Easing.InOutSine
        }
        PauseAnimation { duration: root._blinkDark }
        NumberAnimation {
            target: ink
            property: "opacity"
            from: 0
            to: 1
            duration: root._blinkFadeMs
            easing.type: Easing.InOutSine
        }
    }

    NumberAnimation {
        id: appearAnim

        target: ink
        property: "opacity"
        from: 0
        to: 1
        duration: root._appearMs
        easing.type: Easing.InOutSine

        onFinished: {
            root._appearing = false;
            if (root.visible && root._blinkEnabled)
                blinkAnim.restart();
        }
    }

    Timer {
        id: hold

        interval: root._blinkHoldMs
        onTriggered: if (root.visible && root._blinkEnabled) blinkAnim.restart()
    }

    Connections {
        target: root.control

        function onTextEdited() {
            root._solid();
            // First character into an empty field: `_placeholderOffset` has just
            // collapsed to 0, so pre-seed the delta with the park width to start
            // the glide from the end of the placeholder.
            if (control.text.length === 1 && root._parkOffset > 0) {
                // Defer so the frame the character lands on still reads parked;
                // the caret would otherwise hop to 0 and back within one frame.
                Qt.callLater(function() {
                    if (root.control.text.length === 0 || !root._glideAnim.running) {
                        root._glide = root._parkOffset;
                        root.glideAnim.restart();
                    }
                });
            }
        }

        function onTextChanged() {
            // Field cleared: drop any in-flight glide and park again.
            if (root.control.text.length === 0) {
                root.glideAnim.stop();
                root._glide = 0;
            }
        }

        function onCursorPositionChanged() {
            if (!root._appearing)
                root._solid();
        }

        function onActiveFocusChanged() {
            if (root.control.activeFocus)
                root._appear();
        }

        function onCaretPulseChanged() {
            root._poke(1);
        }

        function onAccepted() {
            root._poke(1.8);
        }
    }
}
