import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs

/**
 * BasePopoutWindow - a modular panel window. 
 * Inlines logic from BaseFloating and BasePopout for better maintainability.
 */
Item {
    id: root

    // --- State Management ---
    property string panelState: "Closed"
    property bool interactive: panelState === "Open"
    property string panelNamespace: ""
    property bool floating: false
    
    signal opening()
    signal opened()
    signal closing()
    signal closed()

    // --- Positioning & Sizing ---
    property real anchorX: -1
    property real anchorMinX: -1
    property real anchorMaxX: -1
    
    property real fixedWidth: -1
    property real fixedHeight: -1

    property real manualX: -1
    property real manualY: -1
    
    // Internal size trackers
    property real _contentImplicitWidth: 0
    property real _contentImplicitHeight: 0
    Behavior on _contentImplicitHeight {
        BaseAnimation {
            duration: Theme.animations.normal
            easing.type: Theme.animations.easingType
        }
    }
    property alias bodyItem: contentLoader.item

    readonly property real maxContentHeight: {
        var screenH = (popupWindow && popupWindow.screen) ? popupWindow.screen.height : 1080;
        var barSpace = Preferences.barHeight + (Preferences.barMarginTop * 2);
        
        return screenH - barSpace - Preferences.barMarginTop - Theme.geometry.spacing.large;
    }

    // --- Sizing & Margins ---
    readonly property real totalWidthPadding: (root.layoutMargin * 2) + (root.layoutPadding * 2)
    readonly property real totalHeightPadding: (root.layoutMargin * 2) + (root.layoutPadding * 2)

    readonly property real contentWidth: fixedWidth > 0 ? fixedWidth : (_contentImplicitWidth + totalWidthPadding)
    readonly property real contentHeight: {
        var h = fixedHeight > 0 ? fixedHeight : (_contentImplicitHeight + totalHeightPadding);
        return Math.min(h, maxContentHeight);
    }

    readonly property real contentX: {
        if (manualX >= 0) return manualX;
        if (!popupWindow || !popupWindow.screen) return 0;
        var screenW = popupWindow.screen.width;
        if (anchorX < 0) return (screenW - contentWidth) / 2;
        var x = anchorX - (contentWidth / 2);
        var radiusInset = Theme.geometry.radius;
        var minX = (anchorMinX >= 0) ? (anchorMinX + radiusInset) : 0;
        var maxX = (anchorMaxX >= 0) ? (anchorMaxX - contentWidth - radiusInset) : (screenW - contentWidth);
        return Math.max(minX, Math.min(x, maxX));
    }

    readonly property real verticalGap: floating ? 0 : Preferences.barMarginTop

    readonly property real floatingY: (popupWindow && popupWindow.screen) ? (popupWindow.screen.height - contentHeight) / 2 : 0

    readonly property real contentY: {
        if (manualY >= 0) return manualY;
        if (!popupWindow || !popupWindow.screen) return 0;

        if (floating) return floatingY;

        var barSpace = Preferences.barHeight + Preferences.barMarginTop;

        if (Preferences.barPosition === "top") {
            return barSpace;
        } else {
            return popupWindow.screen.height - contentHeight - barSpace - verticalGap;
        }
    }

    // --- Styling & Layout ---
    property color color: Theme.alpha(Theme.colors.background, Theme.blur.backgroundOpacity)
    property real layoutMargin: Theme.geometry.spacing.large
    property real layoutPadding: 0
    property real radius: Theme.geometry.radius

    // --- Bar Cutout Geometry ---
    readonly property real barW: {
        if (!popupWindow || !popupWindow.screen) return 0;
        return Preferences.barFitToContent ? PopoutService.barWidth : (popupWindow.screen.width - 2 * Preferences.barMarginSide);
    }
    readonly property real barX: {
        if (!popupWindow || !popupWindow.screen) return 0;
        return (popupWindow.screen.width - barW) / 2;
    }
    readonly property real barY: {
        if (!popupWindow || !popupWindow.screen) return 0;
        return Preferences.barPosition === "top" ? Preferences.barMarginTop : (popupWindow.screen.height - Preferences.barHeight - Preferences.barMarginTop);
    }
    readonly property real barH: Preferences.barHeight

    // Content Slot
    property Component body: null
    default property alias _body: root.body

    // --- Internal Helpers ---
    function open() {
        if (panelState === "Open" || panelState === "Opening") return;
        
        // Stabilize dimensions for animation
        var h = root.contentHeight + root.verticalGap;
        var startOffset;
        
        if (root.floating) {
            if (Preferences.barPosition === "top") {
                // Bar at top -> Slide from bottom
                startOffset = popupWindow.screen.height - root.floatingY;
            } else {
                // Bar at bottom -> Slide from top
                startOffset = -root.floatingY - root.contentHeight;
            }
        } else {
            startOffset = Preferences.barPosition === "top" ? -h : h;
        }
        
        slideInAnimation.from = startOffset;
        slideInAnimation.to = 0;
        
        panelState = "Opening";
        popupWindow.visible = true;
        opening();
        
        // Use a slight delay to ensure window is mapped and properties are settled
        Qt.callLater(() => {
            slideInAnimation.start();
            opacityAnimation.from = 0;
            opacityAnimation.to = 1;
            opacityAnimation.start();
            scaleAnimation.from = root.openScaleFrom;
            scaleAnimation.to = 1.0;
            scaleAnimation.start();
            root.animFadeOpacity = 0.0;
            fadeInAnimation.start();
        });
    }

    function close() {
        if (panelState === "Closed" || panelState === "Closing") return;
        
        // Capture current stable height for the exit animation
        var h = root.contentHeight + root.verticalGap;
        var endOffset;
        
        if (root.floating) {
            if (Preferences.barPosition === "top") {
                endOffset = popupWindow.screen.height - root.floatingY;
            } else {
                endOffset = -root.floatingY - root.contentHeight;
            }
        } else {
            endOffset = Preferences.barPosition === "top" ? -h : h;
        }
        
        slideOutAnimation.from = root.animOffset;
        slideOutAnimation.to = endOffset;
        
        panelState = "Closing";
        closing();
        
        slideOutAnimation.start();
        opacityAnimation.from = 1;
        opacityAnimation.to = 0;
        opacityAnimation.start();
        scaleAnimation.from = 1.0;
        scaleAnimation.to = root.closeScaleTo;
        scaleAnimation.start();
        root.animFadeOpacity = 1.0;
        fadeOutAnimation.start();
    }

    function toggle() {
        if (panelState === "Open" || panelState === "Opening") close();
        else open();
    }

    // --- Animations ---
    property real animOffset: 0
    property real animOpacity: 0
    property real animScale: 1.0
    property real animFadeOpacity: 1.0

    // Per-popout scale configuration (default 1.0 = no scaling effect)
    property real openScaleFrom: 1.0
    property real closeScaleTo: 1.0

    // Fade duration = 20% of total animation duration
    readonly property int _fadeDuration: Math.round(Theme.animations.normal * 0.2)
    readonly property int _holdDuration: Theme.animations.normal - _fadeDuration
    
    BaseAnimation {
        id: slideInAnimation
        target: root
        property: "animOffset"
        easing.type: Easing.OutSine
        easing.bezierCurve: []
        onFinished: {
            panelState = "Open";
            opened();
        }
    }

    BaseAnimation {
        id: slideOutAnimation
        target: root
        property: "animOffset"
        easing.type: Easing.OutSine
        easing.bezierCurve: []
        onFinished: {
            panelState = "Closed";
            popupWindow.visible = false;
            closed();
        }
    }

    BaseAnimation {
        id: opacityAnimation
        target: root
        property: "animOpacity"
    }

    // Fade in: 0→1 over first 20% of animation duration
    SequentialAnimation {
        id: fadeInAnimation
        PropertyAnimation {
            target: root
            property: "animFadeOpacity"
            from: 0.0
            to: 1.0
            duration: root._fadeDuration
            easing.type: Easing.OutQuad
        }
    }

    // Fade out: hold at 1 for 80%, then fade 1→0 over last 20%
    SequentialAnimation {
        id: fadeOutAnimation
        PauseAnimation {
            duration: root._holdDuration
        }
        PropertyAnimation {
            target: root
            property: "animFadeOpacity"
            from: 1.0
            to: 0.0
            duration: root._fadeDuration
            easing.type: Easing.InQuad
        }
    }

    BaseAnimation {
        id: scaleAnimation
        target: root
        property: "animScale"
        easing.type: Easing.OutSine
        easing.bezierCurve: []
    }

    // --- Window Structure ---
    property alias popupWindow: popup
    
    PanelWindow {
        id: popup
        visible: false
        screen: Quickshell.screens[0]
        color: Theme.colors.transparent
        focusable: true
        WlrLayershell.namespace: root.panelNamespace
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.exclusiveZone: -1

        anchors { top: true; bottom: true; left: true; right: true }


        // Click-outside-to-close
        MouseArea {
            anchors.fill: parent
            enabled: root.interactive
            onClicked: root.close()
        }

        // Panel Content Area (Static & Clipped)
        Item {
            id: container
            x: root.contentX
            y: root.floating ? 0 : root.contentY
            width: root.contentWidth
            height: root.floating ? (popup.screen ? popup.screen.height : 1080) : (root.contentHeight + root.verticalGap)
            clip: !root.floating // Always clip for anchored panels, disable for floating to allow off-screen slide

            // Synthetic item tracing the absolute visible bounds for the Wayland Region API which ignores QML clip
            Item {
                id: visibleBlurArea
                x: contentWrapper.x
                y: Math.max(0, contentWrapper.y)
                width: contentWrapper.width
                height: Math.max(0, Math.min(container.height, contentWrapper.y + contentWrapper.height) - y)
            }

            // Moving Content Wrapper
            Item {
                id: contentWrapper
                width: parent.width
                height: root.contentHeight
                y: (root.floating ? root.floatingY : root.verticalGap) + root.animOffset
                transformOrigin: Item.Center
                scale: root.animScale
                opacity: root.animFadeOpacity

                // Background Shape
                BaseBackground {
                    id: bgLoader
                    anchors.fill: parent
                    color: root.color
                    radius: root.radius
                }

                // Internal click shield to prevent closing when clicking on empty panel space
                MouseArea {
                    anchors.fill: parent
                    onClicked: {}
                }

                // UI Content
                Loader {
                    id: contentLoader
                    anchors.fill: parent
                    sourceComponent: root.body
                    
                    anchors.leftMargin: root.layoutMargin + root.layoutPadding
                    anchors.rightMargin: root.layoutMargin + root.layoutPadding
                    anchors.topMargin: root.layoutMargin + root.layoutPadding
                    anchors.bottomMargin: root.layoutMargin + root.layoutPadding

                    Binding {
                        target: root
                        property: "_contentImplicitHeight"
                        value: contentLoader.item ? contentLoader.item.implicitHeight : 0
                    }
                    Binding {
                        target: root
                        property: "_contentImplicitWidth"
                        value: contentLoader.item ? contentLoader.item.implicitWidth : 0
                    }
                }
            }
            
            focus: true
            Keys.onEscapePressed: root.close()
        }
    }

}


