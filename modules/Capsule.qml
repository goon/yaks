import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.services
import qs

Item {
    id: capsuleRoot

    required property var barWindow
    readonly property int itemHeight: 32 * Globals.shellScale
    property bool _ready: false
    Component.onCompleted: Qt.callLater(() => { _ready = true; })
    
    // ── DYNAMIC CAPSULE STATE ──────────────────────────────────────────
    readonly property bool shouldBeMorphed: Modules.activeModuleName !== "" && 
        (Modules.activeScreen === barWindow.screen || (!Modules.activeScreen && barWindow.screen === Quickshell.screens[0]))

    property bool isMorphed: false
    property string activeModuleName: ""
    property string loadedModuleName: ""

    readonly property string mode: isMorphed ? activeModuleName : "rest"

    // ── HOVER EXPAND STATE ────────────────────────────────────────────
    // Whether the pointer is over the visible pill. Published to
    // Modules.isCapsuleHovered, which the volume toast reads to avoid
    // auto-dismissing while the pointer rests on the capsule. Tracked directly
    // off the capsule's HoverHandler — no settle delay, so the state is always
    // current rather than lagging a trailing timer.
    property bool isHovered: typeof capsuleHoverHandler !== "undefined" ? capsuleHoverHandler.hovered : false
    onIsHoveredChanged: Modules.isCapsuleHovered = isHovered;

    // Gated only on capsule.height — not timers — so the bar never resizes mid-animation.
    readonly property bool isCapsuleMorphed: mode !== "rest" || capsule.height > normalCapsuleHeight + 1

    // Identify toast-like modules that should not capture full screen mouse inputs
    readonly property bool isFullBar: mode === "full_bar"
    readonly property bool isToast: mode === "volume_toast" || mode === "notification_toast" || mode === "full_bar"

    readonly property bool grabsFocus: mode !== "rest" &&
        mode !== "volume_toast" &&
        mode !== "notification_toast" &&
        mode !== "full_bar"

    // Safely call lifecycle methods and set properties on loaded views
    function notifyModule(funcName) {
        if (moduleLoader.item && typeof moduleLoader.item[funcName] === "function") {
            moduleLoader.item[funcName]();
        }
    }

    function setModuleState(state) {
        if (moduleLoader.item) {
            if (moduleLoader.item.hasOwnProperty("moduleState")) {
                moduleLoader.item.moduleState = state;
            }
        }
    }

    function updateMorphedState() {
        if (capsuleRoot.shouldBeMorphed) {
            var newName = Modules.activeModuleName;
            var wasAlreadyLoaded = (capsuleRoot.loadedModuleName !== "" && capsuleRoot.loadedModuleName === newName);
            
            if (capsuleRoot.loadedModuleName !== "" && !wasAlreadyLoaded) {
                // Transitioning directly between two modules
                if (moduleLoader.item) {
                    capsuleRoot.setModuleState("Closing");
                    capsuleRoot.notifyModule("closing");
                    capsuleRoot.setModuleState("Closed");
                    capsuleRoot.notifyModule("closed");
                }
            }
            capsuleRoot.activeModuleName = newName;
            capsuleRoot.loadedModuleName = newName;
            capsuleRoot.isMorphed = true;
            collapseTimer.stop();
            evictionTimer.stop();
            
            if (wasAlreadyLoaded && moduleLoader.item) {
                capsuleRoot.setModuleState("Opening");
                capsuleRoot.notifyModule("opening");
                openTimer.start();
            }
        } else {
            if (capsuleRoot.isMorphed) {
                capsuleRoot.isMorphed = false;
                if (moduleLoader.item) {
                    capsuleRoot.setModuleState("Closing");
                    capsuleRoot.notifyModule("closing");
                }
                collapseTimer.start();
            }
        }
    }

    Connections {
        target: Modules
        function onActiveModuleNameChanged() { capsuleRoot.updateMorphedState(); }
        function onActiveScreenChanged() { capsuleRoot.updateMorphedState(); }
    }

    Timer {
        id: collapseTimer
        interval: Globals.motion.morph
        repeat: false
        onTriggered: {
            if (!capsuleRoot.isMorphed) {
                if (moduleLoader.item) {
                    capsuleRoot.setModuleState("Closed");
                    capsuleRoot.notifyModule("closed");
                }
                evictionTimer.interval = Modules.evictionTime(capsuleRoot.loadedModuleName);
                evictionTimer.start();
            }
        }
    }

    Timer {
        id: evictionTimer
        repeat: false
        onTriggered: {
            if (!capsuleRoot.isMorphed && capsuleRoot.loadedModuleName !== "") {
                capsuleRoot.loadedModuleName = "";
                capsuleRoot.activeModuleName = "";
            }
        }
    }

    readonly property alias activeModuleItem: moduleLoader.item

    // Expose the mask element to Bar.qml for input region
    readonly property alias maskItem: maskItem

    readonly property real normalSideMargin: Math.max(0, (Preferences.bar.height - capsuleRoot.itemHeight) / 2)
    readonly property real normalCapsuleWidth: staticFull.implicitWidth
    readonly property real normalCapsuleHeight: Preferences.bar.height
    readonly property real normalCapsuleX: (barWindow.width - normalCapsuleWidth) / 2
    readonly property real normalCapsuleY: Preferences.bar.position === "top"
        ? Preferences.bar.marginTop
        : (barWindow.height - normalCapsuleHeight - Preferences.bar.marginTop)


    readonly property real _modulePad: Globals.geometry.padding.capsule
    readonly property real totalWidthPadding: _modulePad * 2
    readonly property real totalHeightPadding: _modulePad * 2

    // The capsule gradient ramps over a fixed band (the bar's height) instead of
    // the whole capsule, so every module shows the same sheen no matter how tall
    // it is; past the band the surface stays flat. The ramp is pinned to the
    // capsule's bottom, so the dark edge is always the module's lower edge.
    readonly property real _gradientBand: Preferences.bar.height
    readonly property real _bandFrac: Math.min(1.0, _gradientBand / Math.max(1, capsule.height))

    // Fall back to the registry's expected size until the loaded module reports its own.
    property real activePanelWidth: activeModuleItem ? (activeModuleItem.implicitWidth || 0) + totalWidthPadding : Modules.expectedWidth(activeModuleName)
    property real activePanelHeight: activeModuleItem ? (activeModuleItem.implicitHeight || 0) + totalHeightPadding : Modules.expectedHeight(activeModuleName)

    readonly property real targetCapsuleWidth: {
        if (mode !== "rest") {
            if (mode === "full_bar") {
                return (activeModuleItem ? activeModuleItem.implicitWidth : barWindow.width);
            }
            return activePanelWidth;
        }
        return normalCapsuleWidth;
    }

    readonly property real targetCapsuleHeight: {
        if (mode !== "rest") {
            if (mode === "full_bar") {
                return normalCapsuleHeight;
            }
            return activePanelHeight;
        }
        return normalCapsuleHeight;
    }

    readonly property real targetCapsuleX: {
        if (mode === "rest") return normalCapsuleX;
        let actualPanelWidth = (mode === "full_bar") ? targetCapsuleWidth : activePanelWidth;
        if (Modules.anchorX < 0) return (barWindow.width - actualPanelWidth) / 2;

        var x = Modules.anchorX - (actualPanelWidth / 2);
        var radiusInset = Globals.geometry.radius;
        var minX = (Modules.anchorMinX >= 0) ? (Modules.anchorMinX + radiusInset) : 0;
        var maxX = (Modules.anchorMaxX >= 0) ? (Modules.anchorMaxX - actualPanelWidth - radiusInset) : (barWindow.width - actualPanelWidth);
        return Math.max(minX, Math.min(x, maxX));
    }

    readonly property real targetCapsuleY: mode !== "rest"
        ? (Preferences.bar.position === "top" ? Preferences.bar.marginTop : barWindow.height - (mode === "full_bar" ? targetCapsuleHeight : activePanelHeight) - Preferences.bar.marginTop)
        : normalCapsuleY

    // ── CLICK OUTSIDE SHIELD ──────────────────────────────────────────
    MouseArea {
        id: clickOutsideShield
        anchors.fill: parent
        enabled: capsuleRoot.mode !== "rest" && !capsuleRoot.isToast
        z: 1
        onClicked: {
            Modules.closeAll();
        }
    }

    // ── MASK ITEM (INPUT REGION) ──────────────────────────────────────
    Item {
        id: maskItem
        x: targetCapsuleX
        y: targetCapsuleY
        width: targetCapsuleWidth
        height: targetCapsuleHeight
        z: 2

        // Prevent click-throughs to clickOutsideShield inside the capsule bounds
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {}
        }
    }

    // Union of the rest pill and the current (possibly mid-animation) capsule,
    // spanning the top of the screen. While the pill is morphing the moving
    // capsule can momentarily leave the single maskItem rect, which would drop
    // input mid-animation; this union covers both extremes for the whole morph.
    readonly property bool isSettled:
        mode === "rest"
        || (Math.abs(capsule.x - targetCapsuleX) < 1
            && Math.abs(capsule.y - targetCapsuleY) < 1
            && Math.abs(capsule.width - targetCapsuleWidth) < 1
            && Math.abs(capsule.height - targetCapsuleHeight) < 1)

    readonly property alias maskItemUnion: maskUnion

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

    // ── MORPHING CAPSULE ──────────────────────────────────────────────
    Rectangle {
        id: capsule

        gradient: Gradient {
            GradientStop { position: 0.0; color: Globals.colors.top }
            GradientStop { position: 1.0 - capsuleRoot._bandFrac; color: Globals.colors.top }
            GradientStop { position: 1.0; color: Globals.colors.bottom }
        }

        HoverHandler {
            id: capsuleHoverHandler
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
            shadowColor: Globals.alpha(Globals.effects.shadow.color, 0.4)
            shadowBlur: 0.6
            shadowHorizontalOffset: 0
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

            // ── NORMAL BAR LAYOUT ──────────────────────────────────────
            RowLayout {

                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                height: implicitHeight
                width: normalCapsuleWidth
                spacing: normalSideMargin
                
                opacity: capsuleRoot.isCapsuleMorphed ? 0.0 : 1.0
                enabled: opacity > 0.01

                Behavior on opacity { BaseMotion { duration: Globals.motion.hover } }

                Full {
                    id: staticFull
                    barWindow: capsuleRoot.barWindow
                    Layout.alignment: Qt.AlignCenter
                }
            }

            // ── MODULE CONTENT LOADER ───────────────────────────────────
            Loader {
                id: moduleLoader
                anchors.fill: parent
                anchors.margins: capsuleRoot.loadedModuleName === "full_bar" ? 0 : capsuleRoot._modulePad

                active: capsuleRoot.loadedModuleName !== ""
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

                Binding {
                    target: moduleLoader.item
                    property: "barWindow"
                    value: capsuleRoot.barWindow
                    when: moduleLoader.item !== null && typeof moduleLoader.item.barWindow !== "undefined"
                }

                opacity: capsuleRoot.isMorphed && status === Loader.Ready ? 1.0 : 0.0
                visible: opacity > 0.0
                Behavior on opacity { BaseMotion { duration: Globals.motion.hover } }

                source: {
                    var src = Modules.moduleSource(capsuleRoot.loadedModuleName);
                    return src ? Qt.resolvedUrl(src) : "";
                }

                onLoaded: {
                    if (item) {
                        Modules.activeModuleItem = item;
                        if (capsuleRoot.mode !== "rest") {
                            capsuleRoot.setModuleState("Opening");
                            capsuleRoot.notifyModule("opening");
                            openTimer.start();
                        }
                        if (item.forceActiveFocus && item !== capsuleRoot) {
                            item.forceActiveFocus();
                        }
                    }
                }

                // When the loader deactivates (module closed, or switched to a
                // different source) the item is destroyed. Clear the shared
                // reference so consumers (Binds, runWhenModuleReady, toasts) never
                // see a dangling item pointing at a destroyed object.
                onItemChanged: {
                    if (moduleLoader.item === null && Modules.activeModuleItem !== null)
                        Modules.activeModuleItem = null;
                }
            }

            Timer {
                id: openTimer
                interval: Globals.motion.morph
                repeat: false
                onTriggered: {
                    if (capsuleRoot.mode !== "rest" && moduleLoader.item) {
                        capsuleRoot.setModuleState("Open");
                        capsuleRoot.notifyModule("opened");

                        // Handle initial focus delegation
                        if (moduleLoader.item.hasOwnProperty("initialFocusItem") && moduleLoader.item.initialFocusItem) {
                            var focusTarget = moduleLoader.item.initialFocusItem;
                            if (typeof focusTarget.focusInput === "function") {
                                focusTarget.focusInput();
                            } else {
                                focusTarget.forceActiveFocus();
                            }
                        }
                    }
                }
            }
        }
    }
}
