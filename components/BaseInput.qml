import QtQuick
import QtQuick.Controls
import qs

TextField {
    id: root

    color: Globals.colors.text
    font.family: Globals.typography.family
    font.pixelSize: Globals.typography.size.base
    font.letterSpacing: (root.echoMode === TextInput.Password && root.text.length > 0) ? 4 : 0
    placeholderTextColor: Globals.colors.muted
    leftPadding: Globals.geometry.padding.small
    rightPadding: Globals.geometry.padding.small
    topPadding: 0
    bottomPadding: 0
    verticalAlignment: Text.AlignVCenter
    background: Item { }

    // ── TYPEWRITER CARET ─────────────────────────────────────────────────
    property int caretPulse: 0
    property string _prevText: ""
    property var _pending: null

    readonly property real _inkAlpha: 0.9
    readonly property real _inkScale: 1.3
    readonly property int _inkMs: 400
    readonly property real _inkGrowShare: 0.45

    cursorDelegate: Component {
        BaseCaret { control: root }
    }

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
}
