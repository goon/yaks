import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs

BasePopoutWindow {
    id: root
    
    panelNamespace: "quickshell:settings"
    fixedWidth: 1100
    floating: false
    openScaleFrom: 0.05
    closeScaleTo: 0.05


    body: Item {
        id: mainContainer
        implicitWidth: root.fixedWidth
        
        readonly property real maxHeight: (root.popupWindow && root.popupWindow.screen) 
            ? Math.min(900, root.popupWindow.screen.height * 0.9)
            : 800

        implicitHeight: Math.max(500, Math.min(maxHeight, mainLayout.implicitHeight))

        property string selectedPage: "About"
        property alias pageStack: pageStack
        property Item selectedButtonItem: null

        function changePage(pageName) {
            selectedPage = pageName;
            pageStack.replace("pages/" + pageName + ".qml");
        }

        Connections {
            target: root
            function onClosed() {
                mainContainer.changePage("About");
            }
        }


        // MAIN LAYOUT
        RowLayout {
            id: mainLayout
            anchors.fill: parent
            spacing: Theme.geometry.spacing.large

            // 1. LEFT SIDEBAR
            BaseBlock {
                id: sidebar
                Layout.preferredWidth: 242
                Layout.fillWidth: false
                Layout.fillHeight: true
                padding: Theme.geometry.spacing.medium
                backgroundColor: Theme.alpha(Theme.colors.background, Theme.blur.backgroundOpacity)
                borderEnabled: true
                borderColor: Theme.colors.divider

                // Smooth Sliding Left Indicator Line (Liquid/Gooey Effect)
                Item {
                    id: slidingLine
                    parent: sidebar
                    z: 10
                    width: 3
                    height: 20

                    property real targetY: {
                        if (!mainContainer.selectedButtonItem) return 0;
                        var btnYInLayout = mainContainer.selectedButtonItem.y + (mainContainer.selectedButtonItem.parent ? mainContainer.selectedButtonItem.parent.y : 0);
                        return sidebar.paddingVertical + btnYInLayout + (mainContainer.selectedButtonItem.height - height) / 2;
                    }

                    // Position relative to sidebar coordinate space
                    x: {
                        if (!mainContainer.selectedButtonItem) return 0;
                        var btnXInLayout = mainContainer.selectedButtonItem.x + (mainContainer.selectedButtonItem.parent ? mainContainer.selectedButtonItem.parent.x : 0);
                        return sidebar.paddingHorizontal + btnXInLayout + 8;
                    }
                    y: targetY
                    visible: mainContainer.selectedButtonItem !== null

                    // Glow Effect applied to the entire combined liquid shape
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Theme.colors.primary
                        shadowBlur: 0.3
                        shadowHorizontalOffset: 0
                        shadowVerticalOffset: 0
                    }

                    Behavior on y {
                        BaseAnimation {
                            speed: "fast"
                        }
                    }

                    // 1. Lead Bubble
                    Rectangle {
                        id: bubble1
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 3
                        height: 20
                        radius: 1.5
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: Theme.colors.primary }
                            GradientStop { position: 1.0; color: Theme.colors.secondary }
                        }
                    }

                    // 2. Mid Trail Bubble (follows with a slight lag)
                    Rectangle {
                        id: bubble2
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 3
                        height: 16
                        radius: 1.5
                        color: Theme.colors.primary
                        opacity: 0.8

                        y: targetY2 - slidingLine.y

                        property real targetY2: slidingLine.targetY
                        Behavior on targetY2 {
                            BaseAnimation {
                                duration: Theme.animations.fast + 80
                                easing.type: Easing.OutQuad
                            }
                        }
                    }

                    // 3. Tail Bubble (follows with more lag)
                    Rectangle {
                        id: bubble3
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 3
                        height: 12
                        radius: 1.5
                        color: Theme.colors.secondary
                        opacity: 0.5

                        y: targetY3 - slidingLine.y

                        property real targetY3: slidingLine.targetY
                        Behavior on targetY3 {
                            BaseAnimation {
                                duration: Theme.animations.fast + 160
                                easing.type: Easing.OutQuad
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Theme.geometry.spacing.small

                    Repeater {
                        model: [
                            { text: "About",      icon: "info",             page: "About"                  },
                            { category: "Shell"                                                            },
                            { text: "Globals",    icon: "settings_suggest", page: "Globals"                },
                            { text: "Workspaces", icon: "grid_view",        page: "Workspaces"             },
                            { text: "Bar",        icon: "border_top",       page: "Bar"                    },
                            { text: "Launcher",   icon: "rocket_launch",    page: "Launcher"               },
                            { text: "Wallpaper",  icon: "image",            page: "Wallpaper"              },
                            { category: "System"                                                           },
                            { text: "Appearance", icon: "palette",          page: "Appearance"             },
                            { text: "Network",    icon: "wifi",             page: "NetworkPage"            },
                            { text: "Bluetooth",  icon: "bluetooth",        page: "Bluetooth"              }
                        ]

                        delegate: ColumnLayout {
                            spacing: 0
                            Layout.fillWidth: true

                            // Section line separator with category header
                            RowLayout {
                                visible: modelData.category !== undefined
                                Layout.fillWidth: true
                                Layout.topMargin: Theme.geometry.spacing.medium
                                Layout.bottomMargin: Theme.geometry.spacing.small
                                spacing: Theme.geometry.spacing.small

                                BaseText {
                                    text: modelData.category ? modelData.category.toUpperCase() : ""
                                    color: Theme.colors.muted
                                    pixelSize: Theme.typography.size.small
                                    weight: Theme.typography.weights.bold
                                }

                                BaseSeparator {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    color: Theme.colors.border
                                }
                            }

                            // Nav button
                            BaseButton {
                                id: navBtn
                                visible: modelData.page !== undefined
                                Layout.fillWidth: true
                                text: modelData.text || ""
                                icon: modelData.icon || ""
                                selected: modelData.page === mainContainer.selectedPage
                                gradient: false
                                hoverGradient: false
                                textColor: selected ? Theme.colors.primary : (containsMouse ? Theme.colors.primary : Theme.colors.text)
                                iconColor: selected ? Theme.colors.primary : (containsMouse ? Theme.colors.primary : Theme.colors.text)
                                contentAlignment: Qt.AlignLeft
                                normalColor: Theme.colors.transparent
                                textSize: Theme.typography.size.medium
                                iconSize: Theme.dimensions.iconMedium

                                property real shift: (containsMouse && !selected) ? 4 : 0
                                paddingHorizontal: Theme.geometry.spacing.dynamicPadding + shift

                                Behavior on shift {
                                    BaseAnimation { duration: Theme.animations.fast }
                                }

                                onSelectedChanged: {
                                    if (selected) {
                                        mainContainer.selectedButtonItem = navBtn;
                                    }
                                }
                                Component.onCompleted: {
                                    if (selected) {
                                        mainContainer.selectedButtonItem = navBtn;
                                    }
                                }

                                onClicked: {
                                    mainContainer.changePage(modelData.page);
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }

            // 2. CONTENT AREA
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: pageStack.implicitHeight

                // Mask for rounded clipping
                Rectangle {
                    id: contentMask
                    anchors.fill: parent
                    radius: Theme.geometry.radius
                    color: "white"
                    visible: false
                    layer.enabled: true
                }

                // Clipped container
                Item {
                    anchors.fill: parent
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: contentMask
                    }

                    BaseScroller {
                        id: contentScroller
                        anchors.fill: parent
                        clip: false

                        StackView {
                            id: pageStack
                            width: contentScroller.availableWidth
                            implicitHeight: currentItem ? currentItem.implicitHeight : 0
                            height: Math.max(implicitHeight, contentScroller.availableHeight)
                            initialItem: "pages/About.qml"

                            replaceEnter: Transition {
                                ParallelAnimation {
                                    BaseAnimation { property: "opacity"; from: 0; to: 1; speed: "normal"; easing.type: Easing.OutQuad }
                                    BaseAnimation { property: "scale"; from: 0.98; to: 1; speed: "normal"; easing.type: Easing.OutQuad }
                                }
                            }

                            replaceExit: Transition {
                                BaseAnimation { property: "opacity"; from: 1; to: 0; speed: "normal"; easing.type: Easing.OutQuad }
                            }
                        }
                    }
                }
            }
        }
    }
}
