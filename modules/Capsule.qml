import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs

// The island: the Wayland window, the capsule, and the staged loaders that
// swap modules in and out of it. Two loaders enable a true crossfade, and a
// measurement pass guarantees the capsule morphs to the exact final size
// instead of chasing it.
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

    // ── PHASE MACHINE ─────────────────────────────────────────────────
    // Each phase owns exactly one segment of the transition. A phase change
    // always aborts the running sequence and starts the next one from the
    // current visual state, so rapid toggles never queue or desync.
    enum Phase {
        Rest,
        MeasureOpen,
        MorphOpen,
        FadeInOpen,
        Open,
        FadeOutClose,
        MorphClose,
        MeasureSwap,
        FadeOutSwap,
        MorphSwap,
        FadeInSwap
    }

    property int phase: Capsule.Phase.Rest

    // `shown` is the module name the capsule is currently bound to. It is set
    // the instant the intent changes so that mode, geometry targets and kind
    // resolve correctly. The actual visible loader may still hold the previous
    // module during a swap.
    property string shown: ""

    property string pending: ""

    // Toggled after every completed transition so the "next" loader becomes
    // the "current" loader without recreating its item.
    property bool _loaderToggle: false

    // Track which module name lives in each loader so a cached re-open can
    // detect when the current loader was left holding a stale module.
    property string _loaderAContent: ""
    property string _loaderBContent: ""
    readonly property string _currentContentName: _loaderToggle ? _loaderBContent : _loaderAContent

    // ── LOADER ROLES ──────────────────────────────────────────────────
    readonly property Loader currentLoader: _loaderToggle ? loaderA : loaderB
    readonly property Loader nextLoader: _loaderToggle ? loaderB : loaderA

    readonly property Item currentItem: currentLoader.item
    readonly property Item nextItem: nextLoader.item

    // During a transition the interactive module is the one we are morphing
    // toward, so route the rest of the shell to it as soon as it exists.
    readonly property Item activeModuleItem: (pending !== "" && nextItem)
        ? nextItem
        : currentItem
    onActiveModuleItemChanged: Modules.activeModuleItem = capsuleRoot.activeModuleItem

    // ── ISLAND STATE ──────────────────────────────────────────────────
    readonly property string mode: Modules.activeModuleName !== "" ? shown : "rest"

    readonly property bool isCapsuleMorphed: mode !== "rest"
        || capsule.height > normalCapsuleHeight + 1
        || phase === Capsule.Phase.MorphClose

    readonly property bool isToast: Modules.moduleKind(shown) === "toast"
    readonly property bool grabsFocus: mode !== "rest" && Modules.moduleKind(shown) === "popout"

    // ── GEOMETRY ──────────────────────────────────────────────────────
    readonly property real capsulePad: Globals.geometry.spacing.xl
    readonly property real totalWidthPadding: capsulePad * 2
    readonly property real totalHeightPadding: capsulePad * 2

    readonly property real normalCapsuleWidth: bar.implicitWidth
    readonly property real normalCapsuleHeight: Preferences.bar.height
    readonly property real normalCapsuleX: (capsuleRoot.width - normalCapsuleWidth) / 2
    readonly property real normalCapsuleY: Preferences.bar.position === "top"
        ? Preferences.bar.marginTop
        : (capsuleRoot.height - normalCapsuleHeight - Preferences.bar.marginTop)

    // Final target size for the capsule. The next loader wins when it exists
    // (transition in progress); otherwise fall back to the current loader or
    // the registry estimate.
    readonly property real targetCapsuleWidth: mode === "rest" ? normalCapsuleWidth
        : (nextItem ? (nextItem.implicitWidth || 0) + totalWidthPadding
                    : (currentItem ? (currentItem.implicitWidth || 0) + totalWidthPadding
                                   : Modules.expectedWidth(shown)))
    readonly property real targetCapsuleHeight: mode === "rest" ? normalCapsuleHeight
        : (nextItem ? (nextItem.implicitHeight || 0) + totalHeightPadding
                    : (currentItem ? (currentItem.implicitHeight || 0) + totalHeightPadding
                                   : Modules.expectedHeight(shown)))

    readonly property real targetCapsuleX: (capsuleRoot.width - targetCapsuleWidth) / 2
    readonly property real targetCapsuleY: mode === "rest"
        ? normalCapsuleY
        : (Preferences.bar.position === "top"
            ? Preferences.bar.marginTop
            : capsuleRoot.height - targetCapsuleHeight - Preferences.bar.marginTop)

    // ── GRADIENT BAND ─────────────────────────────────────────────────
    readonly property real _gradientBand: Preferences.bar.height
    readonly property real _bandFrac: Math.min(1.0, _gradientBand / Math.max(1, capsule.height))

    // ── INPUT REGION ──────────────────────────────────────────────────
    // Gated only on capsule.height — not timers — so the bar never resizes
    // mid-animation.
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

    // ── MASK ITEM ─────────────────────────────────────────────────────
    Item {
        id: maskItem
        x: targetCapsuleX
        y: targetCapsuleY
        width: targetCapsuleWidth
        height: targetCapsuleHeight
        z: 2

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {}
        }
    }

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
        (phase === Capsule.Phase.Rest || phase === Capsule.Phase.Open)
        && Math.abs(capsule.x - targetCapsuleX) < 1
        && Math.abs(capsule.y - targetCapsuleY) < 1
        && Math.abs(capsule.width - targetCapsuleWidth) < 1
        && Math.abs(capsule.height - targetCapsuleHeight) < 1

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
        border.width: Preferences.globals.capsuleOutline ? Globals.geometry.borderWidth.hair : 0
        radius: Globals.geometry.radius
        clip: true

        layer.enabled: Preferences.globals.shadow
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
            Bar {
                id: bar
                anchors.centerIn: parent
                width: implicitWidth
                height: implicitHeight
                capsulePad: capsuleRoot.capsulePad

                opacity: capsuleRoot._barOpacity
                enabled: opacity > 0.01
            }

            // ── MODULE STAGE ───────────────────────────────────────────
            Item {
                id: moduleStage
                anchors.fill: parent
                anchors.margins: capsuleRoot.capsulePad

                Loader {
                    id: loaderA
                    anchors.fill: parent
                    active: false
                    focus: true

                    Binding {
                        target: loaderA.item
                        property: "width"
                        value: loaderA.width
                        when: loaderA.item !== null
                    }
                    Binding {
                        target: loaderA.item
                        property: "height"
                        value: loaderA.height
                        when: loaderA.item !== null
                    }

                    opacity: _loaderToggle ? _currentContentOpacity : _nextContentOpacity
                    visible: opacity > 0.0

                    source: capsuleRoot._loaderASource

                    onLoaded: capsuleRoot._onLoaderLoaded(loaderA)
                }

                Loader {
                    id: loaderB
                    anchors.fill: parent
                    active: false
                    focus: true

                    Binding {
                        target: loaderB.item
                        property: "width"
                        value: loaderB.width
                        when: loaderB.item !== null
                    }
                    Binding {
                        target: loaderB.item
                        property: "height"
                        value: loaderB.height
                        when: loaderB.item !== null
                    }

                    opacity: _loaderToggle ? _nextContentOpacity : _currentContentOpacity
                    visible: opacity > 0.0

                    source: capsuleRoot._loaderBSource

                    onLoaded: capsuleRoot._onLoaderLoaded(loaderB)
                }
            }
        }
    }

    // ── LOADER SOURCES AND OPACITIES ──────────────────────────────────
    property string _loaderASource: ""
    property string _loaderBSource: ""

    property real _currentContentOpacity: 0
    property real _nextContentOpacity: 0
    property real _barOpacity: 1

    // ── TRANSITION TIMING ─────────────────────────────────────────────
    readonly property int _morphDuration: Globals.motion.morph
    readonly property int _fadeDuration: Globals.motion.hover
    readonly property int _fadeInDelay: _fadeDuration
    readonly property int _settleDelay: Math.max(0, _morphDuration - _fadeInDelay - _fadeDuration)

    // ── SEQUENCES ─────────────────────────────────────────────────────
    SequentialAnimation {
        id: openSequence
        alwaysRunToEnd: false

        NumberAnimation { target: capsuleRoot; property: "_barOpacity"; to: 0; duration: capsuleRoot._fadeDuration }
        NumberAnimation { target: capsuleRoot; property: "_nextContentOpacity"; to: 1; duration: capsuleRoot._fadeDuration }
        PauseAnimation { duration: capsuleRoot._settleDelay }

        ScriptAction { script: capsuleRoot._finishOpen() }
    }

    SequentialAnimation {
        id: cachedOpenSequence
        alwaysRunToEnd: false

        NumberAnimation { target: capsuleRoot; property: "_barOpacity"; to: 0; duration: capsuleRoot._fadeDuration }
        NumberAnimation { target: capsuleRoot; property: "_currentContentOpacity"; to: 1; duration: capsuleRoot._fadeDuration }
        PauseAnimation { duration: capsuleRoot._settleDelay }

        ScriptAction { script: capsuleRoot._finishOpenCached() }
    }

    SequentialAnimation {
        id: closeSequence
        alwaysRunToEnd: false

        NumberAnimation { target: capsuleRoot; property: "_currentContentOpacity"; to: 0; duration: capsuleRoot._fadeDuration }
        NumberAnimation { target: capsuleRoot; property: "_barOpacity"; to: 1; duration: capsuleRoot._fadeDuration }
        PauseAnimation { duration: capsuleRoot._settleDelay }

        ScriptAction { script: capsuleRoot._finishClose() }
    }

    SequentialAnimation {
        id: swapSequence
        alwaysRunToEnd: false

        NumberAnimation { target: capsuleRoot; property: "_currentContentOpacity"; to: 0; duration: capsuleRoot._fadeDuration }
        NumberAnimation { target: capsuleRoot; property: "_nextContentOpacity"; to: 1; duration: capsuleRoot._fadeDuration }
        PauseAnimation { duration: capsuleRoot._settleDelay }

        ScriptAction { script: capsuleRoot._finishSwap() }
    }

    // ── EVICTION ──────────────────────────────────────────────────────
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
            if (Modules.activeModuleName === "" && capsuleRoot.shown !== "")
                capsuleRoot._unloadCurrent();
        }
    }

    // ── EXTERNAL CONTROL ──────────────────────────────────────────────
    Connections {
        target: Modules
        function onActiveModuleNameChanged() { capsuleRoot._onIntentChanged(); }
    }

    Component.onCompleted: {
        _ready = true;
        _onIntentChanged();
    }

    // ── INTENT HANDLER ────────────────────────────────────────────────
    function _onIntentChanged() {
        const intent = Modules.activeModuleName;

        if (intent === "") {
            _startClose();
            return;
        }

        if (intent === shown && pending === "" && _currentContentName === intent) {
            if (currentItem) {
                _startOpenCached();
            } else {
                // Evicted between checks; treat as a fresh open.
                _startLoad(intent);
            }
            return;
        }

        if (intent === pending) return;

        _startLoad(intent);
    }

    // ── LOADER CALLBACKS ──────────────────────────────────────────────
    function _onLoaderLoaded(loader) {
        if (loader !== nextLoader) return;
        if (pending === "") return;

        if (phase === Capsule.Phase.MeasureOpen) {
            _startOpenMorph();
        } else if (phase === Capsule.Phase.MeasureSwap) {
            _startSwapMorph();
        }
    }

    // ── TRANSITION STARTERS ───────────────────────────────────────────
    function _startLoad(name) {
        _stopSequences();
        pending = name;
        shown = name;

        const src = Modules.moduleSource(name);
        if (!src) {
            pending = "";
            shown = "";
            return;
        }

        // If we are at rest or on the way back to rest, this is an open from
        // the bar face. Otherwise it is a module-to-module swap.
        if (phase === Capsule.Phase.Rest
            || phase === Capsule.Phase.FadeOutClose
            || phase === Capsule.Phase.MorphClose) {
            phase = Capsule.Phase.MeasureOpen;
        } else {
            phase = Capsule.Phase.MeasureSwap;
        }

        nextLoader.active = false;
        if (nextLoader === loaderA) {
            _loaderAContent = name;
            _loaderASource = Qt.resolvedUrl(src);
        } else {
            _loaderBContent = name;
            _loaderBSource = Qt.resolvedUrl(src);
        }
        nextLoader.active = true;
    }

    function _startOpenCached() {
        if (_currentContentName !== shown) {
            _startLoad(shown);
            return;
        }

        _stopSequences();
        pending = "";
        phase = Capsule.Phase.MorphOpen;

        _currentContentOpacity = 0;
        _nextContentOpacity = 0;
        _barOpacity = 1;

        _notifyModule(currentItem, "opening");
        cachedOpenSequence.restart();
    }

    function _startOpenMorph() {
        phase = Capsule.Phase.MorphOpen;

        _nextContentOpacity = 0;
        // _barOpacity and _currentContentOpacity are left at their current
        // values so an interrupted close-to-rest continues smoothly into open.

        _notifyModule(nextItem, "opening");
        _focusModule(nextItem);
        openSequence.restart();
    }

    function _startSwapMorph() {
        phase = Capsule.Phase.MorphSwap;

        _nextContentOpacity = 0;
        _barOpacity = 0;

        _notifyModule(nextItem, "opening");
        _focusModule(nextItem);
        swapSequence.restart();
    }

    function _startClose() {
        if (shown === "" && phase === Capsule.Phase.Rest) return;

        _stopSequences();
        pending = "";

        if (shown === "") {
            _finishClose();
            return;
        }

        phase = Capsule.Phase.FadeOutClose;
        _nextContentOpacity = 0;
        // _currentContentOpacity and _barOpacity are left at their current
        // values so an interrupted open or swap reverses cleanly.

        closeSequence.restart();
    }

    // ── TRANSITION FINISHERS ──────────────────────────────────────────
    function _finishOpen() {
        if (phase !== Capsule.Phase.MorphOpen && phase !== Capsule.Phase.FadeInOpen) return;

        phase = Capsule.Phase.Open;
        pending = "";

        _loaderToggle = !_loaderToggle;
        _currentContentOpacity = 1;
        _nextContentOpacity = 0;
        _barOpacity = 0;

        // The old "current" loader is now "next"; unload it so it is ready
        // for the next swap.
        _unloadNext();

        _notifyModule(currentItem, "opened");
        _focusModule(currentItem);
    }

    function _finishOpenCached() {
        if (phase !== Capsule.Phase.MorphOpen && phase !== Capsule.Phase.FadeInOpen) return;

        phase = Capsule.Phase.Open;
        pending = "";

        _currentContentOpacity = 1;
        _nextContentOpacity = 0;
        _barOpacity = 0;

        _notifyModule(currentItem, "opened");
        _focusModule(currentItem);
    }

    function _finishSwap() {
        if (phase !== Capsule.Phase.MorphSwap && phase !== Capsule.Phase.FadeInSwap) return;

        phase = Capsule.Phase.Open;
        pending = "";

        _loaderToggle = !_loaderToggle;
        _currentContentOpacity = 1;
        _nextContentOpacity = 0;
        _barOpacity = 0;

        // nextItem is now the outgoing module after the toggle.
        _notifyModule(nextItem, "closing");
        _unloadNext();

        _notifyModule(currentItem, "opened");
        _focusModule(currentItem);
    }

    function _finishClose() {
        if (phase !== Capsule.Phase.FadeOutClose && phase !== Capsule.Phase.MorphClose) return;

        phase = Capsule.Phase.Rest;

        _notifyModule(currentItem, "closing");
        collapseTimer.restart();

        _currentContentOpacity = 0;
        _nextContentOpacity = 0;
        _barOpacity = 1;
    }

    // ── HELPERS ───────────────────────────────────────────────────────
    function _stopSequences() {
        openSequence.stop();
        cachedOpenSequence.stop();
        closeSequence.stop();
        swapSequence.stop();
    }

    function _unloadCurrent() {
        _notifyModule(currentItem, "closed");
        if (_loaderToggle) {
            _loaderASource = "";
            _loaderAContent = "";
        } else {
            _loaderBSource = "";
            _loaderBContent = "";
        }
        currentLoader.active = false;
        shown = "";
    }

    function _unloadNext() {
        if (_loaderToggle) {
            _loaderBSource = "";
            _loaderBContent = "";
        } else {
            _loaderASource = "";
            _loaderAContent = "";
        }
        nextLoader.active = false;
    }

    // ── MODULE API ────────────────────────────────────────────────────
    function _notifyModule(item, funcName) {
        if (item && typeof item[funcName] === "function")
            item[funcName]();
    }

    function _focusModule(item) {
        if (!capsuleRoot.grabsFocus) return;
        if (!item) return;
        const t = item.initialFocusItem || item;
        if (typeof t.focusInput === "function") t.focusInput();
        else if (typeof t.forceActiveFocus === "function") t.forceActiveFocus();
    }

    // Kept for compatibility with any external callers that may read `shown`
    // directly, though the lifecycle is now phase-driven.
    function syncShown() {
        _onIntentChanged();
    }
}
