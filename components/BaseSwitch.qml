import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import qs

Switch {
    id: control

    implicitWidth: 56
    implicitHeight: 28
    hoverEnabled: true
    padding: 0

    background: null

    // A programmatic `checked` assignment does not emit `toggled` on this Qt
    // build (only `checkedChanged`), which makes keyboard activation miss
    // call sites wired to onToggled. Override toggle() so it flips `checked`
    // and always emits toggled, giving callers one consistent signal.
    function toggle() {
        if (!control.enabled) return;
        control.checked = !control.checked;
        control.toggled();
    }

    property real progress: control.checked ? 1.0 : 0.0
    Behavior on progress {
        BaseMotion { }
    }

    HoverHandler {
        cursorShape: control.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    indicator: Item {
        id: indicatorContainer

        implicitWidth: 56
        implicitHeight: 28
        x: control.leftPadding
        y: parent.height / 2 - height / 2
        opacity: control.enabled ? 1.0 : 0.5

        Behavior on opacity { BaseMotion { } }

        readonly property color accent: Globals.colors.primary
        readonly property color faceBase: Globals.colors.text
        readonly property color ink: Globals.colors.bg

        // ── TRACK ─────────────────────────────────────────────────────
        Rectangle {
            id: track

            anchors.fill: parent
            radius: height / 2
            color: control.checked
                ? Globals.alpha(indicatorContainer.accent, 0.75)
                : Globals.colors.well
            border.width: 2
            border.color: Globals.colors.border

            Behavior on color { BaseMotion { } }
        }

        // ── KNOB ──────────────────────────────────────────────────────
        Rectangle {
            id: thumb

            readonly property real inset: 3
            readonly property real size: 22

            width: size
            height: size
            radius: size / 2
            y: (parent.height - height) / 2
            x: inset + control.progress * (indicatorContainer.width - size - inset * 2)
            rotation: control.progress * 360

            scale: control.pressed ? 0.92 : (control.hovered ? 1.05 : 1.0)
            Behavior on scale { BaseMotion { duration: Globals.motion.hover } }

            color: control.checked
                ? Qt.tint(indicatorContainer.faceBase, Globals.alpha(indicatorContainer.accent, 0.28))
                : indicatorContainer.faceBase
            border.width: 2
            border.color: Globals.colors.border

            Behavior on color { BaseMotion { } }

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Globals.alpha(Globals.effects.shadow.color, 0.5)
                shadowBlur: Globals.effects.shadow.radius / 20.0
                shadowHorizontalOffset: Globals.effects.shadow.offsetX
                shadowVerticalOffset: Globals.effects.shadow.offsetY
            }

            // X (OFF) -> tick (ON)
            BaseText {
                anchors.centerIn: parent
                text: "✘"
                pixelSize: Math.round(parent.height * 0.5)
                color: indicatorContainer.ink
                opacity: 1 - control.progress
                scale: 1 - 0.5 * control.progress
            }

            BaseText {
                anchors.centerIn: parent
                text: "✔"
                pixelSize: Math.round(parent.height * 0.5)
                color: indicatorContainer.ink
                opacity: control.progress
                scale: 0.5 + 0.5 * control.progress
            }
        }
    }
}
