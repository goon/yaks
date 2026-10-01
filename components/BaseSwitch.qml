import QtQuick
import QtQuick.Controls
import qs

Switch {
    id: control

    implicitWidth: 36 * Globals.shellScale
    implicitHeight: 20 * Globals.shellScale
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

        implicitWidth: control.implicitWidth
        implicitHeight: control.implicitHeight
        x: control.leftPadding
        y: parent.height / 2 - height / 2
        opacity: control.enabled ? 1.0 : 0.5

        Behavior on opacity { BaseMotion { } }

        readonly property color accent: Globals.colors.primary
        readonly property color faceBase: Globals.colors.text

        // ── TRACK ─────────────────────────────────────────────────────
        Rectangle {
            id: track

            anchors.fill: parent
            radius: height / 2
            color: control.checked
                ? Globals.alpha(indicatorContainer.accent, 0.75)
                : Globals.colors.well
            // A hairline only in the off state, where the knob has no fill
            // contrast to separate itself with.
            border.width: control.checked ? 0 : Globals.geometry.borderWidth.hair
            border.color: Globals.colors.border

            Behavior on color { BaseMotion { } }
        }

        // ── KNOB ──────────────────────────────────────────────────────
        Rectangle {
            id: thumb

            readonly property real inset: 3 * Globals.shellScale
            readonly property real size: 13 * Globals.shellScale

            width: size
            height: size
            radius: size / 2
            y: (parent.height - height) / 2
            x: inset + control.progress * (indicatorContainer.width - size - inset * 2)

            scale: control.pressed ? 0.92 : (control.hovered ? 1.05 : 1.0)
            Behavior on scale { BaseMotion { duration: Globals.motion.hover } }

            color: control.checked
                ? Qt.tint(indicatorContainer.faceBase, Globals.alpha(indicatorContainer.accent, 0.28))
                : indicatorContainer.faceBase

            Behavior on color { BaseMotion { } }
        }
    }
}
