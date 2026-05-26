import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs

PanelWindow {
    id: bar

    property var leftComponents: Preferences.barLeftComponents
    readonly property var centerComponents: Preferences.barCenterComponents
    readonly property var rightComponents: Preferences.barRightComponents
    readonly property real sideMargin: Math.max(0, (bar.implicitHeight - (Theme.dimensions.barItemHeight * Theme.barScale)) / 2)

    function resolveComponentSource(name) {
        const map = {
            "workspaces": "components/Workspaces.qml",
            "clock": "components/Clock.qml",
            "dock": "components/Dock.qml",
            "indicators": "components/Indicators.qml",
        };
        return map[name] || "";
    }

    objectName: "bar"
    color: Theme.colors.transparent
    focusable: false
    WlrLayershell.namespace: "quickshell:bar"
    WlrLayershell.layer: WlrLayer.Top
    implicitHeight: Preferences.barHeight
    implicitWidth: {
        if (Preferences.barFitToContent) {
            return (centerSection.implicitWidth * Theme.barScale) + (bar.sideMargin * 2);
        } else {
            return 0;
        }
    }

    anchors {
        top: Preferences.barPosition === "top"
        bottom: Preferences.barPosition === "bottom"
        left: !Preferences.barFitToContent
        right: !Preferences.barFitToContent
    }

    margins {
        top: Preferences.barPosition === "top" ? Preferences.barMarginTop : 0
        bottom: Preferences.barPosition === "bottom" ? Preferences.barMarginTop : 0
        left: Preferences.barMarginSide
        right: Preferences.barMarginSide
    }

    // Startup Fade-in Animation Opacity
    property real startupOpacity: 0.0

    Component.onCompleted: {
        startupAnimation.start();
    }

    BaseAnimation {
        id: startupAnimation
        target: bar
        property: "startupOpacity"
        to: 1.0
        duration: Theme.animations.slow
        easing.type: Easing.OutCubic
    }


    BaseBackground {
        id: barBackground

        readonly property real maxSideWidth: Math.max(leftContent.implicitWidth, rightContent.implicitWidth)

        opacity: bar.startupOpacity

        RowLayout {
            id: contentLayout

            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            width: (parent.width - (bar.sideMargin * 2)) / Theme.barScale
            spacing: bar.sideMargin / Theme.barScale
            
            transform: Scale {
                origin.x: contentLayout.width / 2
                origin.y: contentLayout.height / 2
                xScale: Theme.barScale
                yScale: Theme.barScale
            }

            // 1. Left Section
            RowLayout {
                id: leftSection

                // Visible if NOT Fit to Content AND EITHER side has components
                visible: !Preferences.barFitToContent && (bar.leftComponents.length > 0 || bar.rightComponents.length > 0)
                Layout.preferredWidth: barBackground.maxSideWidth
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                spacing: 0

                // Content Wrapper
                RowLayout {
                    id: leftContent

                    spacing: bar.sideMargin / Theme.barScale

                    Repeater {
                        model: bar.leftComponents

                        RowLayout {
                            id: leftItemWrapper
                            Layout.alignment: Qt.AlignVCenter
                            visible: leftLoader.visible
                            spacing: bar.sideMargin / Theme.barScale

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
                                source: bar.resolveComponentSource(modelData)
                                
                                visible: {
                                    const source = bar.resolveComponentSource(modelData);
                                    if (source === "") return false;

                                    switch(modelData) {
                                        case "dock": return Compositor.windows.length > 0;
                                        case "tray": return TrayService.itemCount > 0;
                                        default: return true;
                                    }
                                }

                                Binding {
                                    target: leftLoader.item
                                    property: "barWindow"
                                    value: bar
                                    when: leftLoader.item !== null && (modelData === "tray" || modelData === "indicators")
                                }
                            }
                        }
                    }

                }

                // Trailing spacer
                Item {
                    Layout.fillWidth: true
                }

            }

            Item {
                Layout.fillWidth: true
                visible: !Preferences.barFitToContent
            }

            RowLayout {
                id: centerSection

                visible: bar.centerComponents.length > 0
                Layout.alignment: Qt.AlignCenter | Qt.AlignVCenter
                spacing: bar.sideMargin / Theme.barScale

                Repeater {
                    model: bar.centerComponents

                    RowLayout {
                        id: centerItemWrapper
                        Layout.alignment: Qt.AlignVCenter
                        visible: centerLoader.visible
                        spacing: bar.sideMargin / Theme.barScale

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
                            source: bar.resolveComponentSource(modelData)
                            
                            visible: {
                                const source = bar.resolveComponentSource(modelData);
                                if (source === "") return false;

                                switch(modelData) {
                                    case "dock": return Compositor.windows.length > 0;
                                    case "tray": return TrayService.itemCount > 0;
                                    default: return true;
                                }
                            }

                            Binding {
                                target: centerLoader.item
                                property: "barWindow"
                                value: bar
                                when: centerLoader.item !== null && (modelData === "tray" || modelData === "indicators")
                            }
                        }
                    }
                }

            }

            Item {
                Layout.fillWidth: true
                visible: !Preferences.barFitToContent
            }

            RowLayout {
                id: rightSection

                visible: !Preferences.barFitToContent && (bar.leftComponents.length > 0 || bar.rightComponents.length > 0)
                Layout.preferredWidth: barBackground.maxSideWidth
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                spacing: 0

                // Leading spacer
                Item {
                    Layout.fillWidth: true
                }

                // Content Wrapper
                RowLayout {
                    id: rightContent

                    spacing: bar.sideMargin / Theme.barScale

                    Repeater {
                        model: bar.rightComponents

                        RowLayout {
                            id: rightItemWrapper
                            Layout.alignment: Qt.AlignVCenter
                            visible: rightLoader.visible
                            spacing: bar.sideMargin / Theme.barScale

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
                                source: bar.resolveComponentSource(modelData)
                                
                                visible: {
                                    const source = bar.resolveComponentSource(modelData);
                                    if (source === "") return false;

                                    switch(modelData) {
                                        case "dock": return Compositor.windows.length > 0;
                                        case "tray": return TrayService.itemCount > 0;
                                        default: return true;
                                    }
                                }

                                Binding {
                                    target: rightLoader.item
                                    property: "barWindow"
                                    value: bar
                                    when: rightLoader.item !== null && (modelData === "tray" || modelData === "indicators")
                                }
                            }
                        }
                    }

                }

            }

        }

    }

    Behavior on implicitHeight {
        BaseAnimation {
            duration: Theme.animations.fast
        }
    }

    Behavior on implicitWidth {
        enabled: Preferences.barFitToContent && !startupAnimation.running
        BaseAnimation {
            duration: Theme.animations.normal
            easing.type: Easing.OutQuint
        }
    }

    onWidthChanged: PopoutService.barWidth = width

}
