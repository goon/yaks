import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs

FocusScope {
    id: root

    property string panelState: "Closed"

    readonly property var popupWindow: Window.window

    implicitWidth: 1060
    
    readonly property real maxHeight: (root.popupWindow && root.popupWindow.screen) 
        ? Math.min(860, root.popupWindow.screen.height * 0.9 - 40)
        : 760

    implicitHeight: Math.min(maxHeight, pageStack.implicitHeight)

    onImplicitHeightChanged: console.log("DEBUG: root implicitHeight changed to:", implicitHeight, "pageStack implicitHeight:", pageStack.implicitHeight, "currentItem:", pageStack.currentItem)

    property alias pageStack: pageStack

    function closed() {
        pageStack.replace("views/Dashboard.qml");
    }

        // CONTENT AREA
        Item {
            anchors.fill: parent

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

                    ColumnLayout {
                        id: centeredContainer
                        width: parent.width
                        spacing: 0

                        StackView {
                            id: pageStack
                            Layout.fillWidth: true
                            implicitHeight: currentItem ? currentItem.implicitHeight : 0
                            initialItem: "views/Dashboard.qml"

                            onCurrentItemChanged: console.log("DEBUG: pageStack currentItem changed to:", currentItem, "currentItem implicitHeight:", currentItem ? currentItem.implicitHeight : "null")
                            onImplicitHeightChanged: console.log("DEBUG: pageStack implicitHeight changed to:", implicitHeight)

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
