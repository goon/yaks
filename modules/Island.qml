import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.services
import qs

Item {
    id: islandRoot

    required property var barWindow
    readonly property int itemHeight: 32 * Globals.shellScale
    property bool _ready: false
    Component.onCompleted: Qt.callLater(() => { _ready = true; })
    
    // ── DYNAMIC ISLAND STATE ──────────────────────────────────────────
    readonly property bool shouldBeMorphed: Panels.activePanelName !== "" && 
        (Panels.activeScreen === barWindow.screen || (!Panels.activeScreen && barWindow.screen === Quickshell.screens[0]))

    property bool isMorphed: false
    property string activePanelName: ""
    property string loadedPanelName: ""

    // ── HOVER EXPAND STATE ────────────────────────────────────────────
    // Whether the pointer is over the visible pill. Published to
    // Panels.isIslandHovered, which the volume toast reads to avoid
    // auto-dismissing while the pointer rests on the island. Tracked directly
    // off the capsule's HoverHandler — no settle delay, so the state is always
    // current rather than lagging a trailing timer.
    property bool isHovered: typeof capsuleHoverHandler !== "undefined" ? capsuleHoverHandler.hovered : false
    onIsHoveredChanged: Panels.isIslandHovered = isHovered;

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
        }
    }

    function updateMorphedState() {
        if (islandRoot.shouldBeMorphed) {
            var newName = Panels.activePanelName;
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
        target: Panels
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

    readonly property real normalSideMargin: Math.max(0, (Preferences.bar.height - islandRoot.itemHeight) / 2)
    readonly property real normalCapsuleWidth: staticFull.implicitWidth
    readonly property real normalCapsuleHeight: Preferences.bar.height
    readonly property real normalCapsuleX: (barWindow.width - normalCapsuleWidth) / 2
    readonly property real normalCapsuleY: Preferences.bar.position === "top"
        ? Preferences.bar.marginTop
        : (barWindow.height - normalCapsuleHeight - Preferences.bar.marginTop)


    readonly property real totalWidthPadding: (Globals.geometry.padding.island * 2)
    readonly property real totalHeightPadding: (Globals.geometry.padding.island * 2)

    // Fall back to the registry's expected size until the loaded panel reports its own.
    property real activePanelWidth: activePanelItem ? (activePanelItem.implicitWidth || 0) + totalWidthPadding : Panels.expectedWidth(activePanelName)
    property real activePanelHeight: activePanelItem ? (activePanelItem.implicitHeight || 0) + totalHeightPadding : Panels.expectedHeight(activePanelName)

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
        if (Panels.anchorX < 0) return (barWindow.width - actualPanelWidth) / 2;
        
        var x = Panels.anchorX - (actualPanelWidth / 2);
        var radiusInset = Globals.geometry.radius;
        var minX = (Panels.anchorMinX >= 0) ? (Panels.anchorMinX + radiusInset) : 0;
        var maxX = (Panels.anchorMaxX >= 0) ? (Panels.anchorMaxX - actualPanelWidth - radiusInset) : (barWindow.width - actualPanelWidth);
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
            Panels.closeAll();
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
    Rectangle {
        id: capsule

        gradient: Gradient {
            GradientStop { position: 0.0; color: Globals.colors.top }
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
        

        border.color: Preferences.globals.islandOutline ? Globals.colors.outline : "transparent"
        border.width: Preferences.globals.islandOutline ? 1 : 0
        radius: Globals.geometry.radius
        clip: true

        // Optional soft drop shadow (Settings > Bar), like Uki's pill. The
        // offscreen layer is dropped while the capsule morphs so the shadow
        // never re-renders per animation frame; it returns once settled.
        layer.enabled: Preferences.globals.shadow && islandRoot.isSettled
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Globals.alpha(Globals.effects.shadow.color, 0.4)
            shadowBlur: 0.6
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 2.5 * Globals.shellScale
        }

        Behavior on x      { enabled: islandRoot._ready; NumberAnimation { duration: Globals.motion.morph; easing.type: Easing.BezierSpline; easing.bezierCurve: Globals.motion.easeEmphasis } }
        Behavior on y      { enabled: islandRoot._ready; NumberAnimation { duration: Globals.motion.morph; easing.type: Easing.BezierSpline; easing.bezierCurve: Globals.motion.easeEmphasis } }
        Behavior on width  { enabled: islandRoot._ready; NumberAnimation { duration: Globals.motion.morph; easing.type: Easing.BezierSpline; easing.bezierCurve: Globals.motion.easeEmphasis } }
        Behavior on height { enabled: islandRoot._ready; NumberAnimation { duration: Globals.motion.morph; easing.type: Easing.BezierSpline; easing.bezierCurve: Globals.motion.easeEmphasis } }



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
                    var src = Panels.panelSource(islandRoot.loadedPanelName);
                    return src ? Qt.resolvedUrl(src) : "";
                }

                onLoaded: {
                    if (item) {
                        Panels.activePanelItem = item;
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
                    if (panelLoader.item === null && Panels.activePanelItem !== null)
                        Panels.activePanelItem = null;
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
