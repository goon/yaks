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
    
    // --- Dynamic Island State ---
    readonly property bool shouldBeMorphed: PopoutService.activePanelName !== "" && 
        (PopoutService.activeScreen === barWindow.screen || (!PopoutService.activeScreen && barWindow.screen === Quickshell.screens[0]))

    property bool isMorphed: false
    property string activePanelName: ""
    property string loadedPanelName: ""

    // Gated only on capsule.height — not timers — so the bar never resizes mid-animation.
    readonly property bool isIslandMorphed: shouldBeMorphed || capsule.height > normalCapsuleHeight + 1

    // Helper functions to safely call lifecycle methods and set properties on loaded views
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
            var newName = PopoutService.activePanelName;
            if (islandRoot.loadedPanelName !== "" && islandRoot.loadedPanelName !== newName) {
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
        target: PopoutService
        function onActivePanelNameChanged() { islandRoot.updateMorphedState(); }
        function onActiveScreenChanged() { islandRoot.updateMorphedState(); }
    }

    Timer {
        id: collapseTimer
        interval: Theme.animations.normal
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

    // Active panel element reference shortcut
    readonly property alias activePanelItem: panelLoader.item

    // Expose the capsule element to Bar.qml for mask/input region
    readonly property alias capsuleItem: capsule

    readonly property real normalSideMargin: Math.max(0, (Preferences.barHeight - (Theme.dimensions.barItemHeight * Theme.barScale)) / 2)
    readonly property real normalCapsuleWidth: Preferences.barFitToContent 
        ? (centerSection.implicitWidth * Theme.barScale + normalSideMargin * 2)
        : (barWindow.width - 2 * Preferences.barMarginSide)
    readonly property real normalCapsuleHeight: Preferences.barHeight
    readonly property real normalCapsuleX: Preferences.barFitToContent
        ? (barWindow.width - normalCapsuleWidth) / 2
        : Preferences.barMarginSide
    readonly property real normalCapsuleY: Preferences.barPosition === "top"
        ? Preferences.barMarginTop
        : (barWindow.height - normalCapsuleHeight - Preferences.barMarginTop)


    // Central registry for panel paths and dimensions
    readonly property var panelRegistry: ({
        "launcher":      { source: "../modules/launcher/Launcher.qml", width: 600, height: 650 },
        "settings":      { source: "../modules/settings/Settings.qml", width: 1100, height: 850 },
        "dashboard":     { source: "../modules/dashboard/Dashboard.qml", width: 1100, height: 850 },
        "notifications": { source: "../modules/notifications/Notifications.qml", width: 550, height: 600 },
        "audio":         { source: "../modules/audio/Audio.qml", width: 420, height: 450 },
        "power":         { source: "../modules/power/Power.qml", width: 450, height: 300 }
    })

    // Expected fallback dimensions during transition before component load completes
    function getExpectedPanelWidth(name) {
        var panel = panelRegistry[name];
        return panel ? panel.width : 420;
    }

    function getExpectedPanelHeight(name) {
        var panel = panelRegistry[name];
        return panel ? panel.height : 500;
    }

    readonly property real totalWidthPadding: (Theme.geometry.spacing.large * 2)
    readonly property real totalHeightPadding: (Theme.geometry.spacing.large * 2)

    // Target Dimensions when morphed
    property real activePanelWidth: activePanelItem ? activePanelItem.implicitWidth + totalWidthPadding : getExpectedPanelWidth(activePanelName)
    property real activePanelHeight: activePanelItem ? activePanelItem.implicitHeight + totalHeightPadding : getExpectedPanelHeight(activePanelName)

    readonly property real targetCapsuleWidth: isMorphed ? activePanelWidth : normalCapsuleWidth
    readonly property real targetCapsuleHeight: isMorphed ? activePanelHeight : normalCapsuleHeight

    readonly property real targetCapsuleX: {
        if (!isMorphed) return normalCapsuleX;
        if (PopoutService.anchorX < 0) return (barWindow.width - activePanelWidth) / 2;
        
        var x = PopoutService.anchorX - (activePanelWidth / 2);
        var radiusInset = Theme.geometry.radius;
        var minX = (PopoutService.anchorMinX >= 0) ? (PopoutService.anchorMinX + radiusInset) : 0;
        var maxX = (PopoutService.anchorMaxX >= 0) ? (PopoutService.anchorMaxX - activePanelWidth - radiusInset) : (barWindow.width - activePanelWidth);
        return Math.max(minX, Math.min(x, maxX));
    }

    readonly property real targetCapsuleY: isMorphed 
        ? (Preferences.barPosition === "top" ? Preferences.barMarginTop : barWindow.height - activePanelHeight - Preferences.barMarginTop)
        : normalCapsuleY

    // --- Click Outside Shield ---
    MouseArea {
        id: clickOutsideShield
        anchors.fill: parent
        enabled: islandRoot.isMorphed
        z: 1
        onClicked: {
            PopoutService.closeAll();
        }
    }

    // --- Morphing Capsule ---
    BaseBackground {
        id: capsule
        
        x: targetCapsuleX
        y: targetCapsuleY
        width: targetCapsuleWidth
        height: targetCapsuleHeight
        z: 2
        
        color: Theme.alpha(Theme.colors.background, Theme.opacity.background)
        borderColor: Theme.colors.transparent
        radius: Preferences.cornerRadius || Theme.geometry.radius
        clip: true

        Behavior on x      { enabled: islandRoot._ready; BaseAnimation { duration: Theme.animations.normal; easing.type: Theme.animations.easingType } }
        Behavior on y      { enabled: islandRoot._ready; BaseAnimation { duration: Theme.animations.normal; easing.type: Theme.animations.easingType } }
        Behavior on width  { enabled: islandRoot._ready; BaseAnimation { duration: Theme.animations.normal; easing.type: Theme.animations.easingType } }
        Behavior on height { enabled: islandRoot._ready; BaseAnimation { duration: Theme.animations.normal; easing.type: Theme.animations.easingType } }

        // Prevent click-throughs to clickOutsideShield inside the capsule bounds
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        // --- Normal Bar Layout ---
        RowLayout {
            id: contentLayout

            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            height: implicitHeight
            width: Preferences.barFitToContent 
                ? centerSection.implicitWidth 
                : (parent.width - (normalSideMargin * 2)) / Theme.barScale
            spacing: normalSideMargin / Theme.barScale
            
            opacity: islandRoot.isIslandMorphed ? 0.0 : 1.0
            visible: true

            Behavior on opacity { BaseAnimation { duration: Theme.animations.fast } }

            transform: Scale {
                origin.x: contentLayout.width / 2
                origin.y: contentLayout.height / 2
                xScale: Theme.barScale
                yScale: Theme.barScale
            }

            // 1. Left Section
            RowLayout {
                id: leftSection

                visible: !Preferences.barFitToContent && (barWindow.leftComponents.length > 0 || barWindow.rightComponents.length > 0)
                Layout.preferredWidth: maxSideWidth
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                spacing: 0

                readonly property real maxSideWidth: Math.max(leftContent.implicitWidth, rightContent.implicitWidth)

                RowLayout {
                    id: leftContent
                    spacing: barWindow.sideMargin / Theme.barScale

                    Repeater {
                        model: barWindow.leftComponents

                        RowLayout {
                            Layout.alignment: Qt.AlignVCenter
                            visible: modelData === "dock" ? Hyprland.windows.length > 0 : (barWindow.resolveComponentSource(modelData) !== "")
                            spacing: barWindow.sideMargin / Theme.barScale

                            BaseSeparator {
                                visible: {
                                    if (!parent.visible) return false;
                                    let visibleIndex = -1;
                                    for (let i = 0; i < leftContent.visibleChildren.length; i++) {
                                        if (leftContent.visibleChildren[i] === parent) {
                                            visibleIndex = i;
                                            break;
                                        }
                                    }
                                    return visibleIndex > 0;
                                }
                                orientation: BaseSeparator.Vertical
                                fill: false
                                thickness: 1
                                Layout.preferredHeight: Theme.dimensions.iconSmall
                                Layout.preferredWidth: 1
                                Layout.alignment: Qt.AlignVCenter
                                opacity: 0.3
                                color: Theme.colors.border
                            }

                            Loader {
                                id: leftLoader
                                Layout.alignment: Qt.AlignVCenter
                                source: barWindow.resolveComponentSource(modelData)
                                Binding {
                                    target: leftLoader.item
                                    property: "barWindow"
                                    value: barWindow
                                    when: leftLoader.item !== null && modelData === "indicators"
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }

            Item {
                Layout.fillWidth: true
                visible: !Preferences.barFitToContent
            }

            // 2. Center Section
            RowLayout {
                id: centerSection

                visible: barWindow.centerComponents.length > 0
                Layout.alignment: Qt.AlignCenter | Qt.AlignVCenter
                spacing: barWindow.sideMargin / Theme.barScale

                Repeater {
                    model: barWindow.centerComponents

                    RowLayout {
                        Layout.alignment: Qt.AlignVCenter
                        visible: modelData === "dock" ? Hyprland.windows.length > 0 : (barWindow.resolveComponentSource(modelData) !== "")
                        spacing: barWindow.sideMargin / Theme.barScale

                        BaseSeparator {
                            visible: {
                                if (!parent.visible) return false;
                                let visibleIndex = -1;
                                for (let i = 0; i < centerSection.visibleChildren.length; i++) {
                                    if (centerSection.visibleChildren[i] === parent) {
                                        visibleIndex = i;
                                        break;
                                    }
                                }
                                return visibleIndex > 0;
                            }
                            orientation: BaseSeparator.Vertical
                            fill: false
                            thickness: 1
                            Layout.preferredHeight: Theme.dimensions.iconSmall
                            Layout.preferredWidth: 1
                            Layout.alignment: Qt.AlignVCenter
                            opacity: 0.3
                            color: Theme.colors.border
                        }

                        Loader {
                            id: centerLoader
                            Layout.alignment: Qt.AlignVCenter
                            source: barWindow.resolveComponentSource(modelData)
                            Binding {
                                target: centerLoader.item
                                property: "barWindow"
                                value: barWindow
                                when: centerLoader.item !== null && modelData === "indicators"
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                visible: !Preferences.barFitToContent
            }

            // 3. Right Section
            RowLayout {
                id: rightSection

                visible: !Preferences.barFitToContent && (barWindow.leftComponents.length > 0 || barWindow.rightComponents.length > 0)
                Layout.preferredWidth: leftSection.maxSideWidth
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                spacing: 0

                Item { Layout.fillWidth: true }

                RowLayout {
                    id: rightContent
                    spacing: barWindow.sideMargin / Theme.barScale

                    Repeater {
                        model: barWindow.rightComponents

                        RowLayout {
                            Layout.alignment: Qt.AlignVCenter
                            visible: modelData === "dock" ? Hyprland.windows.length > 0 : (barWindow.resolveComponentSource(modelData) !== "")
                            spacing: barWindow.sideMargin / Theme.barScale

                            BaseSeparator {
                                visible: {
                                    if (!parent.visible) return false;
                                    let visibleIndex = -1;
                                    for (let i = 0; i < rightContent.visibleChildren.length; i++) {
                                        if (rightContent.visibleChildren[i] === parent) {
                                            visibleIndex = i;
                                            break;
                                        }
                                    }
                                    return visibleIndex > 0;
                                }
                                orientation: BaseSeparator.Vertical
                                fill: false
                                thickness: 1
                                Layout.preferredHeight: Theme.dimensions.iconSmall
                                Layout.preferredWidth: 1
                                Layout.alignment: Qt.AlignVCenter
                                opacity: 0.3
                                color: Theme.colors.border
                            }

                            Loader {
                                id: rightLoader
                                Layout.alignment: Qt.AlignVCenter
                                source: barWindow.resolveComponentSource(modelData)
                                Binding {
                                    target: rightLoader.item
                                    property: "barWindow"
                                    value: barWindow
                                    when: rightLoader.item !== null && modelData === "indicators"
                                }
                            }
                        }
                    }
                }
            }
        }

        // --- Panel Content Loader ---
        Loader {
            id: panelLoader
            anchors.fill: parent
            anchors.margins: Theme.geometry.spacing.large
            
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

            opacity: islandRoot.isMorphed && status === Loader.Ready ? 1.0 : 0.0
            visible: opacity > 0.0
            Behavior on opacity { BaseAnimation { duration: Theme.animations.fast } }

            source: {
                var panel = islandRoot.panelRegistry[islandRoot.loadedPanelName];
                return panel ? Qt.resolvedUrl(panel.source) : "";
            }

            onLoaded: {
                if (item) {
                    PopoutService.activePanelItem = item;
                    if (islandRoot.isMorphed) {
                        islandRoot.setPanelState("Opening");
                        islandRoot.notifyPanel("opening");
                        openTimer.start();
                    }
                }
            }
        }

        Timer {
            id: openTimer
            interval: Theme.animations.normal
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
