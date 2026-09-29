import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.services
import qs

Item {
    id: islandRoot

    required property var barWindow
    property bool _ready: false
    Component.onCompleted: Qt.callLater(() => { _ready = true; })
    
    // ── DYNAMIC ISLAND STATE ──────────────────────────────────────────
    readonly property bool shouldBeMorphed: IslandService.activePanelName !== "" && 
        (IslandService.activeScreen === barWindow.screen || (!IslandService.activeScreen && barWindow.screen === Quickshell.screens[0]))

    property bool isMorphed: false
    property string activePanelName: ""
    property string loadedPanelName: ""

    // ── HOVER EXPAND STATE ────────────────────────────────────────────
    // Whether the pointer is over the visible pill. Published to
    // IslandService.isIslandHovered, which the volume toast reads to avoid
    // auto-dismissing while the pointer rests on the island. Tracked directly
    // off the capsule's HoverHandler — no settle delay, so the state is always
    // current rather than lagging a trailing timer.
    readonly property bool isMouseOverCapsule: typeof capsuleHoverHandler !== "undefined" ? capsuleHoverHandler.hovered : false
    property bool isHovered: isMouseOverCapsule
    onIsHoveredChanged: IslandService.isIslandHovered = isHovered;

    // Gated only on capsule.height — not timers — so the bar never resizes mid-animation.
    readonly property bool isIslandMorphed: shouldBeMorphed || capsule.height > normalCapsuleHeight + 1

    // Identify toast-like panels that should not capture full screen mouse inputs
    readonly property bool isFullBar: loadedPanelName === "fullbar" || activePanelName === "fullbar"
    readonly property bool isToast: loadedPanelName === "volumetoast" || loadedPanelName === "notificationtoast" ||
                                    activePanelName === "volumetoast" || activePanelName === "notificationtoast" ||
                                    isFullBar

    // Determine whether the island should grab keyboard focus (toasts shouldn't)
    readonly property bool grabsFocus: isIslandMorphed &&
        loadedPanelName !== "volumetoast" &&
        loadedPanelName !== "notificationtoast" &&
        loadedPanelName !== "fullbar" &&
        loadedPanelName !== ""

    // Safely call lifecycle methods and set properties on loaded views
    function notifyPanel(funcName) {
        if (panelLoader.item && typeof panelLoader.item[funcName] === "function") {
            panelLoader.item[funcName]();
        }
    }

    function setPanelState(state) {
        if (panelLoader.item) {
            if (panelLoader.item.hasOwnProperty("panelState")) {
                panelLoader.item.panelState = state;
            }
            if (panelLoader.item.hasOwnProperty("interactive")) {
                panelLoader.item.interactive = (state === "Open");
            }
        }
    }

    function updateMorphedState() {
        if (islandRoot.shouldBeMorphed) {
            var newName = IslandService.activePanelName;
            var wasAlreadyLoaded = (islandRoot.loadedPanelName !== "" && islandRoot.loadedPanelName === newName);
            
            if (islandRoot.loadedPanelName !== "" && !wasAlreadyLoaded) {
                // Transitioning directly between two panels
                if (panelLoader.item) {
                    islandRoot.setPanelState("Closing");
                    islandRoot.notifyPanel("closing");
                    islandRoot.setPanelState("Closed");
                    islandRoot.notifyPanel("closed");
                }
            }
            islandRoot.activePanelName = newName;
            islandRoot.loadedPanelName = newName;
            islandRoot.isMorphed = true;
            collapseTimer.stop();
            
            if (wasAlreadyLoaded && panelLoader.item) {
                islandRoot.setPanelState("Opening");
                islandRoot.notifyPanel("opening");
                openTimer.start();
            }
        } else {
            if (islandRoot.isMorphed) {
                islandRoot.isMorphed = false;
                if (panelLoader.item) {
                    islandRoot.setPanelState("Closing");
                    islandRoot.notifyPanel("closing");
                }
                collapseTimer.start();
            }
        }
    }

    Connections {
        target: IslandService
        function onActivePanelNameChanged() { islandRoot.updateMorphedState(); }
        function onActiveScreenChanged() { islandRoot.updateMorphedState(); }
    }

    Timer {
        id: collapseTimer
        interval: Globals.motion.morph
        repeat: false
        onTriggered: {
            if (!islandRoot.isMorphed) {
                if (panelLoader.item) {
                    islandRoot.setPanelState("Closed");
                    islandRoot.notifyPanel("closed");
                }
                loadedPanelName = "";
                activePanelName = "";
            }
        }
    }

    readonly property alias activePanelItem: panelLoader.item

    // Expose the mask element to Bar.qml for input region
    readonly property alias maskItem: maskItem

    readonly property real normalSideMargin: Math.max(0, (Preferences.bar.height - (Globals.dimensions.barItemHeight)) / 2)
    readonly property real normalCapsuleWidth: staticFull.implicitWidth
    readonly property real normalCapsuleHeight: Preferences.bar.height
    readonly property real normalCapsuleX: (barWindow.width - normalCapsuleWidth) / 2
    readonly property real normalCapsuleY: Preferences.bar.position === "top"
        ? Preferences.bar.marginTop
        : (barWindow.height - normalCapsuleHeight - Preferences.bar.marginTop)


    // Expected fallback dimensions during transition before component load completes
    function getExpectedPanelWidth(name) {
        return IslandService.expectedWidth(name);
    }

    function getExpectedPanelHeight(name) {
        return IslandService.expectedHeight(name);
    }

    readonly property real totalWidthPadding: (Globals.geometry.padding.island * 2)
    readonly property real totalHeightPadding: (Globals.geometry.padding.island * 2)

    property real activePanelWidth: activePanelItem ? (activePanelItem.implicitWidth || 0) + totalWidthPadding : getExpectedPanelWidth(activePanelName)
    property real activePanelHeight: activePanelItem ? (activePanelItem.implicitHeight || 0) + totalHeightPadding : getExpectedPanelHeight(activePanelName)

    readonly property real targetCapsuleWidth: {
        if (isMorphed) {
            if (activePanelName === "fullbar") {
                return (activePanelItem ? activePanelItem.implicitWidth : barWindow.width);
            }
            return activePanelWidth;
        }
        return normalCapsuleWidth;
    }

    readonly property real targetCapsuleHeight: {
        if (isMorphed) {
            if (activePanelName === "fullbar") {
                return normalCapsuleHeight;
            }
            return activePanelHeight;
        }
        return normalCapsuleHeight;
    }

    readonly property real targetCapsuleX: {
        if (!isMorphed) return normalCapsuleX;
        let actualPanelWidth = (activePanelName === "fullbar") ? targetCapsuleWidth : activePanelWidth;
        if (IslandService.anchorX < 0) return (barWindow.width - actualPanelWidth) / 2;
        
        var x = IslandService.anchorX - (actualPanelWidth / 2);
        var radiusInset = Globals.geometry.radius;
        var minX = (IslandService.anchorMinX >= 0) ? (IslandService.anchorMinX + radiusInset) : 0;
        var maxX = (IslandService.anchorMaxX >= 0) ? (IslandService.anchorMaxX - actualPanelWidth - radiusInset) : (barWindow.width - actualPanelWidth);
        return Math.max(minX, Math.min(x, maxX));
    }

    readonly property real targetCapsuleY: isMorphed 
        ? (Preferences.bar.position === "top" ? Preferences.bar.marginTop : barWindow.height - (activePanelName === "fullbar" ? targetCapsuleHeight : activePanelHeight) - Preferences.bar.marginTop)
        : normalCapsuleY

    // ── CLICK OUTSIDE SHIELD ──────────────────────────────────────────
    MouseArea {
        id: clickOutsideShield
        anchors.fill: parent
        enabled: islandRoot.isMorphed && !islandRoot.isToast
        z: 1
        onClicked: {
            IslandService.closeAll();
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
            id: capsuleHoverArea
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
        !isMorphed
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
    BaseBackground {
        id: capsule
        
        HoverHandler {
            id: capsuleHoverHandler
        }
        
        x: targetCapsuleX
        y: targetCapsuleY
        width: targetCapsuleWidth
        height: targetCapsuleHeight
        z: 2
        

        // Outline baked to an opaque colour: the same 40%-border-over-fill blend
        // the translucent stroke showed, but opaque so the shadow behind the
        // capsule can't tint it (layer.effect below).
        readonly property color _outline: Qt.tint(Globals.colors.surface, Globals.alpha(Globals.colors.border, 0.4))
        borderColor: Preferences.globals.islandOutline ? _outline : "transparent"
        borderWidth: Preferences.globals.islandOutline ? 1 : 0
        radius: Globals.geometry.radius
        clip: true

        // Optional soft drop shadow (Settings > Bar), like Uki's pill. The
        // offscreen layer is dropped while the capsule morphs so the shadow
        // never re-renders per animation frame; it returns once settled.
        layer.enabled: Preferences.globals.shadow && islandRoot.isSettled
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.4)
            shadowBlur: 0.6
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 2.5 * Globals.shellScale
        }

        Behavior on x      { enabled: islandRoot._ready; NumberAnimation { duration: Globals.motion.morph; easing.type: Easing.BezierSpline; easing.bezierCurve: Globals.motion.easeEmphasis } }
        Behavior on y      { enabled: islandRoot._ready; NumberAnimation { duration: Globals.motion.morph; easing.type: Easing.BezierSpline; easing.bezierCurve: Globals.motion.easeEmphasis } }
        Behavior on width  { enabled: islandRoot._ready; NumberAnimation { duration: Globals.motion.morph; easing.type: Easing.BezierSpline; easing.bezierCurve: Globals.motion.easeEmphasis } }
        Behavior on height { enabled: islandRoot._ready; NumberAnimation { duration: Globals.motion.morph; easing.type: Easing.BezierSpline; easing.bezierCurve: Globals.motion.easeEmphasis } }



        MouseArea {
            id: capsuleInnerHoverArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton

            // ── NORMAL BAR LAYOUT ──────────────────────────────────────
            RowLayout {
                id: contentLayout

                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                height: implicitHeight
                width: normalCapsuleWidth
                spacing: normalSideMargin
                
                opacity: islandRoot.isIslandMorphed ? 0.0 : 1.0
                enabled: opacity > 0.01

                Behavior on opacity { BaseMotion { duration: Globals.motion.hover } }

                Full {
                    id: staticFull
                    barWindow: islandRoot.barWindow
                    Layout.alignment: Qt.AlignCenter
                }
            }

            // ── PANEL CONTENT LOADER ───────────────────────────────────
            Loader {
                id: panelLoader
                anchors.fill: parent
                anchors.margins: islandRoot.loadedPanelName === "fullbar" ? 0 : Globals.geometry.padding.island
                
                active: islandRoot.loadedPanelName !== ""
                focus: true

                Binding {
                    target: panelLoader.item
                    property: "width"
                    value: panelLoader.width
                    when: panelLoader.item !== null
                }

                Binding {
                    target: panelLoader.item
                    property: "height"
                    value: panelLoader.height
                    when: panelLoader.item !== null
                }

                Binding {
                    target: panelLoader.item
                    property: "barWindow"
                    value: islandRoot.barWindow
                    when: panelLoader.item !== null && typeof panelLoader.item.barWindow !== "undefined"
                }

                opacity: islandRoot.isMorphed && status === Loader.Ready ? 1.0 : 0.0
                visible: opacity > 0.0
                Behavior on opacity { BaseMotion { duration: Globals.motion.hover } }

                source: {
                    var src = IslandService.panelSource(islandRoot.loadedPanelName);
                    return src ? Qt.resolvedUrl(src) : "";
                }

                onLoaded: {
                    if (item) {
                        IslandService.activePanelItem = item;
                        if (islandRoot.isMorphed) {
                            islandRoot.setPanelState("Opening");
                            islandRoot.notifyPanel("opening");
                            openTimer.start();
                        }
                        if (item.forceActiveFocus && item !== islandRoot) {
                            item.forceActiveFocus();
                        }
                    }
                }

                // When the loader deactivates (panel closed, or switched to a
                // different source) the item is destroyed. Clear the shared
                // reference so consumers (Binds, runWhenPanelReady, toasts) never
                // see a dangling item pointing at a destroyed object.
                onItemChanged: {
                    if (panelLoader.item === null && IslandService.activePanelItem !== null)
                        IslandService.activePanelItem = null;
                }
            }

            Timer {
                id: openTimer
                interval: Globals.motion.morph
                repeat: false
                onTriggered: {
                    if (islandRoot.isMorphed && panelLoader.item) {
                        islandRoot.setPanelState("Open");
                        islandRoot.notifyPanel("opened");

                        // Handle initial focus delegation
                        if (panelLoader.item.hasOwnProperty("initialFocusItem") && panelLoader.item.initialFocusItem) {
                            var focusTarget = panelLoader.item.initialFocusItem;
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
