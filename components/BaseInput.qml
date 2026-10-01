import QtQuick
import QtQuick.Controls
import qs

TextField {
    id: root

    color: Globals.colors.text
    font.family: Globals.typography.family
    font.pixelSize: Globals.typography.size.medium
    font.letterSpacing: (root.echoMode === TextInput.Password && root.text.length > 0) ? 4 : 0
    placeholderTextColor: Globals.colors.muted
    leftPadding: Globals.geometry.padding.small
    rightPadding: Globals.geometry.padding.small
    topPadding: 0
    bottomPadding: 0
    verticalAlignment: Text.AlignVCenter
    background: Item { }

    // ── TYPEWRITER INK ──────────────────────────────────────────────────
    property int caretPulse: 0
    property string _prevText: ""
    property var _pending: null

    readonly property real _inkAlpha: 0.9
    readonly property real _inkScale: 1.3
    readonly property int _inkMs: 400
    readonly property real _inkGrowShare: 0.45

    Item {
        id: stampLayer

        anchors.fill: parent
        enabled: false
        z: 1

        ListModel { id: stamps }

        Repeater {
            model: stamps

            delegate: Text {
                id: stamp

                required property int index
                required property string inkChar
                required property real inkX
                required property real inkY
                required property real inkW
                required property real inkH
                required property real inkSize

                x: stamp.inkX
                y: stamp.inkY
                width: stamp.inkW
                height: stamp.inkH

                text: stamp.inkChar
                color: root.color
                font.family: root.font.family
                font.pixelSize: stamp.inkSize
                font.weight: Globals.typography.weights.bold
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                transformOrigin: Item.Center
                scale: 1
                opacity: 0

                SequentialAnimation {
                    running: true

                    ParallelAnimation {
                        NumberAnimation {
                            target: stamp
                            property: "scale"
                            from: root._inkScale
                            to: 1
                            duration: Math.round(root._inkMs * root._inkGrowShare)
                            easing.type: Easing.OutQuad
                        }
                        NumberAnimation {
                            target: stamp
                            property: "opacity"
                            from: root._inkAlpha
                            to: 0
                            duration: root._inkMs
                            easing.type: Easing.InOutSine
                        }
                    }
                    ScriptAction { script: stamps.remove(stamp.index) }
                }
            }
        }
    }

    Timer {
        id: syncText

        interval: 0
        onTriggered: root._prevText = root.text
    }

    Timer {
        id: inkTimer

        interval: 0
        onTriggered: root._spawnInk()
    }

    function _findInserted(prev, now) {
        if (now.length <= prev.length)
            return null;
        var p = 0;
        var maxP = prev.length;
        while (p < maxP && prev.charAt(p) === now.charAt(p))
            p++;
        return { start: p, len: now.length - prev.length };
    }

    function _spawnInk() {
        if (!root._pending)
            return;
        var start = root._pending.start;
        var len = root._pending.len;
        root._pending = null;

        var ox = root.leftPadding;
        var oy = root.topPadding;

        for (var i = 0; i < len; i++) {
            var idx = start + i;
            var ch = root.text.charAt(idx);
            if (!ch || !ch.trim())
                continue;
            var cell = root.positionToRectangle(idx);
            var next = root.positionToRectangle(idx + 1);
            var w = (next.x > cell.x) ? next.x - cell.x : root.font.pixelSize * 0.6;
            stamps.append({
                "inkChar": ch,
                "inkX": cell.x + ox,
                "inkY": cell.y + oy,
                "inkW": Math.max(1, w),
                "inkH": cell.height,
                "inkSize": root.font.pixelSize
            });
        }
    }

    onTextChanged: syncText.restart()

    onTextEdited: {
        if (root.echoMode !== TextInput.Normal || !root.activeFocus)
            return;

        root._pending = root._findInserted(root._prevText, root.text);
        if (root._pending)
            inkTimer.restart();
        root.caretPulse += 1;
    }

    // ── CARET ────────────────────────────────────────────────────────────
    // Inlined rather than a standalone component: it reads `caretPulse` (the
    // per-keystroke strike trigger), which only exists here, so it could never
    // work against a plain TextField anyway. Carve it out only if a second
    // input surface actually wants it — and drop the caretPulse dependency then.
    property bool caretParksInPlaceholder: false

    cursorDelegate: Component {
        Item {
            id: caret

            // Caret metrics live here rather than in Globals: only this caret
            // exists, so they're tuned in one place.
            readonly property real _depth: 0.18
            readonly property real _squash: 0.14
            readonly property real _downShare: 0.18
            readonly property real _bounce: 1.0
            readonly property int _strikeMs: 240
            readonly property real _advanceCw: 0.25
            readonly property int _advanceMs: 150

            readonly property real _blinkBalance: 0.55
            readonly property real _blinkFade: 0.35
            readonly property int _blinkHoldMs: 550
            readonly property real _blinkPeriod: 2500 / 0.8
            readonly property real _blinkHold: 1 - _blinkFade * 2
            readonly property real _blinkLit: _blinkPeriod * _blinkHold * _blinkBalance
            readonly property real _blinkDark: _blinkPeriod * _blinkHold * (1 - _blinkBalance)
            readonly property real _blinkFadeMs: _blinkPeriod * _blinkFade

            readonly property bool _blinkEnabled: Application.styleHints.cursorFlashTime > 0
            readonly property real _lineH: root.cursorRectangle.height > 0 ? root.cursorRectangle.height : root.font.pixelSize * 1.4
            readonly property real _advancePx: _advanceCw * root.font.pixelSize * 0.6

            property real _boost: 1
            property bool _appearing: false

            // ── PLACEHOLDER PARK ──────────────────────────────────────────
            // Qt parks an empty field's caret at position 0, i.e. before the
            // placeholder glyphs. We shift it by the placeholder's width so it reads as
            // trailing the hint, and glide that shift away on the first keystroke. The
            // glide lives on the delegate root rather than `ink` so the per-keystroke
            // strike keeps its own timings.
            readonly property real _parkOffset: {
                if (!root.caretParksInPlaceholder || root.placeholderText.length === 0)
                    return 0;
                return Math.max(0, Math.min(placeholderMetrics.width,
                    root.width - root.leftPadding - root.rightPadding - width));
            }

            readonly property real _placeholderOffset: root.text.length === 0 ? _parkOffset : 0

            // Animated delta, 0 at rest. The first keystroke starts it at the park width
            // and settles it to 0, which walks the caret from the end of the placeholder
            // back to Qt's real cursor position. Kept separate from the bound rest offset
            // so animating never breaks that binding.
            property real _glide: 0

            width: Math.max(2, Math.round(2 * Globals.shellScale))
            visible: root.activeFocus && !root.readOnly
                     && root.selectionStart === root.selectionEnd
                     && !root.inputMethodComposing

            transform: Translate { id: glideShift; x: caret._placeholderOffset + caret._glide }

            TextMetrics {
                id: placeholderMetrics
                font: root.font
                text: root.placeholderText
            }

            NumberAnimation {
                id: glideAnim
                target: caret
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

                onTriggered: caret._applyPose(strike.elapsedTime * 1000)
            }

            function _applyPose(t) {
                var dy = 0;
                var sy = 1;
                var dx = 0;

                if (t < caret._strikeMs) {
                    var u = t / caret._strikeMs;
                    var sh;
                    if (u < caret._downShare) {
                        sh = 1 - Math.pow(1 - u / caret._downShare, 2);
                    } else {
                        var v = (u - caret._downShare) / (1 - caret._downShare);
                        sh = Math.cos(v * Math.PI * 1.5) * Math.pow(1 - v, 1.2);
                        if (sh < 0)
                            sh *= caret._bounce;
                    }
                    dy = sh * caret._depth * caret._lineH * caret._boost;
                    sy = sh > 0 ? 1 - caret._squash * sh : 1 + caret._squash * 1.8 * -sh;
                }

                if (t < caret._advanceMs) {
                    var a = t / caret._advanceMs;
                    dx = Math.sin(Math.PI * a) * (1 - a) / 0.5796 * caret._advancePx * caret._boost;
                }

                shift.x = dx;
                shift.y = dy;
                squash.yScale = sy;

                if (t >= caret._strikeMs && t >= caret._advanceMs)
                    strike.stop();
            }

            function _appear() {
                if (!caret.visible || !caret._blinkEnabled) {
                    ink.opacity = 1;
                    return;
                }
                caret._appearing = true;
                blinkAnim.stop();
                hold.stop();
                ink.opacity = 0;
                appearAnim.restart();
            }

            function _solid() {
                caret._appearing = false;
                appearAnim.stop();
                blinkAnim.stop();
                hold.restart();
                ink.opacity = 1;
            }

            function _poke(boost) {
                caret._boost = boost || 1;
                caret._solid();
                strike.restart();
            }

            onVisibleChanged: {
                if (caret.visible) {
                    caret._appear();
                } else {
                    blinkAnim.stop();
                    appearAnim.stop();
                    caret._appearing = false;
                }
            }

            Component.onCompleted: if (caret.visible) caret._appear()

            SequentialAnimation {
                id: blinkAnim

                loops: Animation.Infinite

                PauseAnimation { duration: caret._blinkLit }
                NumberAnimation {
                    target: ink
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: caret._blinkFadeMs
                    easing.type: Easing.InOutSine
                }
                PauseAnimation { duration: caret._blinkDark }
                NumberAnimation {
                    target: ink
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: caret._blinkFadeMs
                    easing.type: Easing.InOutSine
                }
            }

            NumberAnimation {
                id: appearAnim

                target: ink
                property: "opacity"
                from: 0
                to: 1
                duration: Globals.motion.hover
                easing.type: Easing.InOutSine

                onFinished: {
                    caret._appearing = false;
                    if (caret.visible && caret._blinkEnabled)
                        blinkAnim.restart();
                }
            }

            Timer {
                id: hold

                interval: caret._blinkHoldMs
                onTriggered: if (caret.visible && caret._blinkEnabled) blinkAnim.restart()
            }

            Connections {
                target: root

                function onTextEdited() {
                    caret._solid();
                    // First character into an empty field: `_placeholderOffset` has just
                    // collapsed to 0, so pre-seed the delta with the park width to start
                    // the glide from the end of the placeholder.
                    if (root.text.length === 1 && caret._parkOffset > 0) {
                        // Defer so the frame the character lands on still reads parked;
                        // the caret would otherwise hop to 0 and back within one frame.
                        Qt.callLater(function() {
                            if (root.text.length === 0 || !caret.glideAnim || !caret.glideAnim.running) {
                                caret._glide = caret._parkOffset;
                                if (caret.glideAnim) caret.glideAnim.restart();
                            }
                        });
                    }
                }

                function onTextChanged() {
                    // Field cleared: drop any in-flight glide and park again.
                    if (root.text.length === 0) {
                        if (caret.glideAnim) caret.glideAnim.stop();
                        caret._glide = 0;
                    }
                }

                function onCursorPositionChanged() {
                    if (!caret._appearing)
                        caret._solid();
                }

                function onActiveFocusChanged() {
                    if (root.activeFocus)
                        caret._appear();
                }

                function onCaretPulseChanged() {
                    caret._poke(1);
                }

                function onAccepted() {
                    caret._poke(1.8);
                }
            }
        }
    }
}
