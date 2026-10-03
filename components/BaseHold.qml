import QtQuick
import qs

// Headless hold-to-confirm. A caller drives it with press()/release() from its
// own pointer or key handler and watches `hold` to render progress; `confirmed`
// fires only when the fill completes. Releasing or cancelling early drains.
//
// Set `tapThreshold` when the same hitbox also has a click meaning: a release
// below it fires `tapped`, so a hold that is abandoned part-way cannot be
// misread as a click on whatever the tap does. Left at 0, `tapped` never fires.
//
// The drain is short and the `fired` latch keeps a release that lands just
// after a confirm from being read as a second gesture.
Item {
    id: root

    // A controller, never a visual — invisible so it does not paint and so the
    // layout it sits in ignores it. It has to be an Item rather than a
    // QtObject so a tile can hold it as a child instead of a sibling.
    visible: false

    // ── STATE ─────────────────────────────────────────────────────────
    property real hold: 0
    readonly property bool holding: hold > 0.001
    property real duration: Globals.motion.heat
    property bool fired: false
    // Fraction of the fill below which a release counts as a tap. 0 disables
    // `tapped` entirely, which is what a hold-only hitbox wants: it has no
    // click meaning to preserve.
    property real tapThreshold: 0

    signal confirmed()
    signal tapped()

    function press() {
        fired = false;
        drain.stop();
        fill.restart();
    }

    function release() {
        fill.stop();
        if (fired || hold >= 1)
            return;
        if (tapThreshold > 0 && hold < tapThreshold)
            tapped();
        drain.restart();
    }

    function cancel() {
        fill.stop();
        drain.restart();
    }

    // Linear, not eased: an eased fill reads as accelerating, which misreports
    // how much of the hold is actually left.
    NumberAnimation {
        id: fill
        target: root
        property: "hold"
        from: 0
        to: 1
        duration: root.duration
        onFinished: {
            root.fired = true;
            root.confirmed();
            drain.restart();
        }
    }

    NumberAnimation {
        id: drain
        target: root
        property: "hold"
        to: 0
        duration: Globals.motion.hover
    }
}