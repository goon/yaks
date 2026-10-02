import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs

// The island: the Wayland window, the capsule, and the loader that swaps a
// module in and out of it. One file because there is only ever one object here
// — the window is the island, and the island lives in the window.
PanelWindow {
    id: capsuleRoot

    readonly property int itemHeight: 32 * Globals.shellScale
    property bool _ready: false

    color: "transparent"

    WlrLayershell.keyboardFocus: capsuleRoot.grabsFocus ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "yaks:bar"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: Preferences.bar.reservedZone

    implicitHeight: capsuleRoot.screen ? capsuleRoot.screen.height : 1080
    implicitWidth: 0

    anchors {
        top: Preferences.bar.position === "top"
        bottom: Preferences.bar.position === "bottom"
        left: true
        right: true
    }

    margins {
        top: 0
        bottom: 0
        left: 0
        right: 0
    }

    // ── ISLAND STATE ──────────────────────────────────────────────────
    // `Modules.activeModuleName` is the intent — a name means open, "" means
    // closed. `shown` is what the Loader actually holds. They differ for
    // exactly one reason: on close the intent clears immediately, so the bar
    // starts fading back in, while `shown` lingers for the shrink animation
    // and is only cleared once the module has been evicted.
    property string shown: ""

    readonly property string mode: Modules.activeModuleName !== "" ? shown : "rest"

    // Gated only on capsule.height — not timers — so the bar never resizes
    // mid-animation.
    readonly property bool isCapsuleMorphed: mode !== "rest" || capsule.height > normalCapsuleHeight + 1

    // A toast is informational: it must not take keyboard focus, and clicks
    // outside it fall through to whatever is underneath.
    readonly property bool isToast: Modules.moduleKind(shown) === "toast"
    readonly property bool grabsFocus: mode !== "rest" && Modules.moduleKind(shown) === "popout"

    // Follow the intent. A module swap happens the moment the name changes,
    // rather than after the old module has animated out.
    function syncShown() {
        const want = Modules.activeModuleName;

        if (want === "") {
            // Closing. `mode` is already "rest" and the bar is fading in;
            // hold the item just long enough for the capsule to shrink.
            collapseTimer.restart();
            return;
        }

        collapseTimer.stop();
        evictionTimer.stop();

        if (shown === want) {
            // Cached from a previous open and not yet evicted — re-enter it
            // without paying for a reload.
            notifyModule("opening");
            openTimer.restart();
            return;
        }

        // A direct swap. The outgoing module simply goes; it gets no closing
        // hook, because nothing runs during those 420 ms that could read one.
        shown = want;
    }

    // Lifecycle hooks are optional: a module implements `opening` (its item now
    // exists) and/or `opened` (the morph has settled), and nothing else.
    function notifyModule(funcName) {
        if (moduleLoader.item && typeof moduleLoader.item[funcName] === "function") {
            moduleLoader.item[funcName]();
        }
    }

    Connections {
        target: Modules
        function onActiveModuleNameChanged() { capsuleRoot.syncShown(); }
    }

    Component.onCompleted: {
        _ready = true;
        capsuleRoot.syncShown();
    }

    Timer {
        id: collapseTimer
        interval: Globals.motion.morph
        repeat: false
        onTriggered: {
            evictionTimer.interval = Modules.evictionTime(capsuleRoot.shown);
            evictionTimer.start();
        }
    }

    Timer {
        id: evictionTimer
        repeat: false
        onTriggered: {
            // Guard against a new module having opened while this was pending.
            if (Modules.activeModuleName === "" && capsuleRoot.shown !== "")
                capsuleRoot.shown = "";
        }
    }

    readonly property alias activeModuleItem: moduleLoader.item

    // Mirror the loader's item into the singleton everything else reads, so it can
    // never point at a destroyed module. Loading and unloading both flow through
    // this one handler, which is why there is nothing to hook on the Loader itself.
    onActiveModuleItemChanged: Modules.activeModuleItem = capsuleRoot.activeModuleItem

    readonly property real normalCapsuleWidth: bar.implicitWidth
    readonly property real normalCapsuleHeight: Preferences.bar.height
    readonly property real normalCapsuleX: (capsuleRoot.width - normalCapsuleWidth) / 2
    readonly property real normalCapsuleY: Preferences.bar.position === "top"
        ? Preferences.bar.marginTop
        : (capsuleRoot.height - normalCapsuleHeight - Preferences.bar.marginTop)

    // The capsule's own inset, and the only one. Every module lays its content
    // out against this one value, handed to the bar rather than read out of
    // Globals by two readers. A module must not stack an inset of its own on top.
    readonly property real capsulePad: Globals.geometry.spacing.xl
    readonly property real totalWidthPadding: capsulePad * 2
    readonly property real totalHeightPadding: capsulePad * 2

    // The capsule gradient ramps over a fixed band (the bar's height) instead of
    // the whole capsule, so every module shows the same sheen no matter how tall
    // it is; past the band the surface stays flat. The ramp is pinned to the
    // capsule's bottom, so the dark edge is always the module's lower edge.
    readonly property real _gradientBand: Preferences.bar.height
    readonly property real _bandFrac: Math.min(1.0, _gradientBand / Math.max(1, capsule.height))

    // The registry's size is the morph target until the module reports its own.
    readonly property real activeModuleWidth: activeModuleItem
        ? (activeModuleItem.implicitWidth || 0) + totalWidthPadding
        : Modules.expectedWidth(shown)
    readonly property real activeModuleHeight: activeModuleItem
        ? (activeModuleItem.implicitHeight || 0) + totalHeightPadding
        : Modules.expectedHeight(shown)

    readonly property real targetCapsuleWidth: mode === "rest" ? normalCapsuleWidth : activeModuleWidth
    readonly property real targetCapsuleHeight: mode === "rest" ? normalCapsuleHeight : activeModuleHeight

    // The island is always centred on its screen. It was once anchored to
    // whichever bar element opened it; nothing ever passed an anchor, so the
    // clamp that bounded it never ran.
    readonly property real targetCapsuleX: (capsuleRoot.width
        - (mode === "rest" ? normalCapsuleWidth : activeModuleWidth)) / 2

    readonly property real targetCapsuleY: mode === "rest"
        ? normalCapsuleY
        : (Preferences.bar.position === "top"
            ? Preferences.bar.marginTop
            : capsuleRoot.height - activeModuleHeight - Preferences.bar.marginTop)

    // While the pill is settled (collapsed or fully expanded / a surface is
    // open) the input region can be the exact capsule rect or the whole layer.
    // While it is mid-morph the moving capsule can briefly leave the capsule
    // rect, so the union of the rest pill and the animating capsule is used
    // instead, keeping input stable across the transition.
    mask: {
        if (capsuleRoot.isCapsuleMorphed && !capsuleRoot.isToast)
            return null;
        if (!capsuleRoot.isSettled)
            return unionRegion;
        return capsuleRegion;
    }

    Region {
        id: capsuleRegion
        item: maskItem
    }

    Region {
        id: unionRegion
        item: maskUnion
    }

    // ── CLICK OUTSIDE SHIELD ──────────────────────────────────────────
    MouseArea {
        id: clickOutsideShield
        anchors.fill: parent
        enabled: capsuleRoot.mode !== "rest" && !capsuleRoot.isToast
        z: 1
        onClicked: Modules.closeAll()
    }

    // ── INPUT REGION ──────────────────────────────────────────────────
    Item {
        id: maskItem
        x: targetCapsuleX
        y: targetCapsuleY
        width: targetCapsuleWidth
        height: targetCapsuleHeight
        z: 2

        // Swallow clicks so they cannot reach the clickOutsideShield beneath
        // the capsule's own bounds.
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {}
        }
    }

    // Union of the rest pill and the current (possibly mid-animation) capsule.
    // While the pill is morphing the moving capsule can momentarily leave the
    // single maskItem rect, which would drop input mid-animation; this union
    // covers both extremes for the whole morph.
    Item {
        id: maskUnion
        visible: false
        z: 2

        readonly property real restLeft: Math.min(normalCapsuleX, capsule.x)
        readonly property real restRight: Math.max(normalCapsuleX + normalCapsuleWidth, capsule.x + capsule.width)
        readonly property real topEdge: Math.min(normalCapsuleY, capsule.y)
        readonly property real bottomEdge: Math.max(normalCapsuleY + normalCapsuleHeight, capsule.y + capsule.height)

        x: restLeft
        y: topEdge
        width: Math.max(0, restRight - restLeft)
        height: Math.max(0, bottomEdge - topEdge)
    }

    readonly property bool isSettled:
        mode === "rest"
        || (Math.abs(capsule.x - targetCapsuleX) < 1
            && Math.abs(capsule.y - targetCapsuleY) < 1
            && Math.abs(capsule.width - targetCapsuleWidth) < 1
            && Math.abs(capsule.height - targetCapsuleHeight) < 1)

    // ── MORPHING CAPSULE ──────────────────────────────────────────────
    Rectangle {
        id: capsule

        gradient: Gradient {
            GradientStop { position: 0.0; color: Globals.colors.top }
            GradientStop { position: 1.0 - capsuleRoot._bandFrac; color: Globals.colors.top }
            GradientStop { position: 1.0; color: Globals.colors.bottom }
        }

        x: targetCapsuleX
        y: targetCapsuleY
        width: targetCapsuleWidth
        height: targetCapsuleHeight
        z: 2

        border.color: Preferences.globals.capsuleOutline ? Globals.colors.outline : "transparent"
        border.width: Preferences.globals.capsuleOutline ? 1 : 0
        radius: Globals.geometry.radius
        clip: true

        // Optional soft drop shadow (Settings > Bar), like Uki's pill. The
        // offscreen layer is dropped while the capsule morphs so the shadow
        // never re-renders per animation frame; it returns once settled.
        layer.enabled: Preferences.globals.shadow && capsuleRoot.isSettled
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Globals.alpha(Globals.effects.shadow.color, Globals.effects.shadow.opacity)
            shadowBlur: 0.6
            shadowHorizontalOffset: Globals.effects.shadow.offsetX
            shadowVerticalOffset: 2.5 * Globals.shellScale
        }

        Behavior on x      { enabled: capsuleRoot._ready; NumberAnimation { duration: Globals.motion.morph; easing.type: Easing.BezierSpline; easing.bezierCurve: Globals.motion.easeEmphasis } }
        Behavior on y      { enabled: capsuleRoot._ready; NumberAnimation { duration: Globals.motion.morph; easing.type: Easing.BezierSpline; easing.bezierCurve: Globals.motion.easeEmphasis } }
        Behavior on width  { enabled: capsuleRoot._ready; NumberAnimation { duration: Globals.motion.morph; easing.type: Easing.BezierSpline; easing.bezierCurve: Globals.motion.easeEmphasis } }
        Behavior on height { enabled: capsuleRoot._ready; NumberAnimation { duration: Globals.motion.morph; easing.type: Easing.BezierSpline; easing.bezierCurve: Globals.motion.easeEmphasis } }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton

            // ── DEFAULT FACE ───────────────────────────────────────────
            // What the island shows when nothing else is open. It is a literal
            // child rather than a registry module: never loaded, never
            // evicted, it just fades out of the way.
            Bar {
                id: bar
                anchors.centerIn: parent
                width: implicitWidth
                height: implicitHeight
                capsulePad: capsuleRoot.capsulePad

                opacity: capsuleRoot.isCapsuleMorphed ? 0.0 : 1.0
                enabled: opacity > 0.01

                Behavior on opacity { BaseMotion { duration: Globals.motion.hover } }
            }

            // ── MODULE CONTENT ─────────────────────────────────────────
            Loader {
                id: moduleLoader
                anchors.fill: parent
                anchors.margins: capsuleRoot.capsulePad

                active: capsuleRoot.shown !== ""
                focus: true

                Binding {
                    target: moduleLoader.item
                    property: "width"
                    value: moduleLoader.width
                    when: moduleLoader.item !== null
                }

                Binding {
                    target: moduleLoader.item
                    property: "height"
                    value: moduleLoader.height
                    when: moduleLoader.item !== null
                }

                opacity: capsuleRoot.mode !== "rest" && status === Loader.Ready ? 1.0 : 0.0
                visible: opacity > 0.0
                Behavior on opacity { BaseMotion { duration: Globals.motion.hover } }

                source: {
                    var src = Modules.moduleSource(capsuleRoot.shown);
                    return src ? Qt.resolvedUrl(src) : "";
                }

                onLoaded: {
                    if (!item) return;
                    notifyModule("opening");
                    openTimer.restart();
                }
            }

            Timer {
                id: openTimer
                interval: Globals.motion.morph
                repeat: false
                onTriggered: {
                    notifyModule("opened");

                    // Hand initial focus to whatever the module nominated.
                    const target = activeModuleItem;
                    if (target && target.initialFocusItem) {
                        if (typeof target.initialFocusItem.focusInput === "function")
                            target.initialFocusItem.focusInput();
                        else
                            target.initialFocusItem.forceActiveFocus();
                    }
                }
            }
        }
    }
}
