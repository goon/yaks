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

    implicitHeight: Math.min(maxHeight, mainRow.implicitHeight)

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

                    RowLayout {
                        id: mainRow
                        Layout.fillWidth: true
                        spacing: Theme.geometry.spacing.large

                        // Left + Middle Column Group
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: Theme.geometry.spacing.large

                            // Top Row: Weather & User Panel
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 160
                                spacing: Theme.geometry.spacing.large

                                DashboardUserPanel {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                }

                                DashboardWeather {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                }
                            }

                            // Bottom Row: Clock & Calendar & Resource Bars
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 320
                                spacing: Theme.geometry.spacing.large

                                DashboardClock {
                                    Layout.fillHeight: true
                                }

                                DashboardCalendar {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                }

                                DashboardResourceBars {
                                    Layout.fillHeight: true
                                }
                            }
                        }

                        // Right Column: Media Player
                        DashboardMedia {
                            Layout.fillHeight: true
                        }
                    }
                }
            }
        }
    }
}
