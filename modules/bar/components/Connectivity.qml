import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services

Item {
    id: root

    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: false
    implicitWidth: background.implicitWidth
    implicitHeight: Theme.dimensions.barItemHeight

    Component.onCompleted: {
        PopoutService.networkItem = wifiButton;
        PopoutService.bluetoothItem = bluetoothButton;
    }
    Component.onDestruction: {
        PopoutService.networkItem = null;
        PopoutService.bluetoothItem = null;
    }

    BaseBlock {
        id: background

        anchors.fill: parent
        paddingVertical: 0
        paddingHorizontal: Theme.geometry.spacing.small
        implicitHeight: Theme.dimensions.barItemHeight
        hoverEnabled: false
        clickable: false

        RowLayout {
            id: rowLayout
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.geometry.spacing.small

            Item {
                id: wifiButton
                Layout.fillHeight: true
                implicitWidth: Theme.dimensions.iconBase + 8
                Layout.alignment: Qt.AlignVCenter

                BaseIcon {
                    anchors.centerIn: parent
                    icon: "wifi"
                    size: Theme.dimensions.iconBase
                    color: wifiMouse.containsMouse ? Theme.colors.primary : Theme.colors.text
                }

                MouseArea {
                    id: wifiMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: PopoutService.toggleNetworkPopout()
                }

                Timer {
                    id: wifiHoverTimer
                    interval: 250
                    repeat: false
                    onTriggered: PopoutService.openNetworkPopout()
                }

                Connections {
                    target: wifiMouse
                    function onContainsMouseChanged() {
                        if (wifiMouse.containsMouse && Preferences.popoutTrigger === 1) {
                            wifiHoverTimer.restart();
                        } else {
                            wifiHoverTimer.stop();
                        }
                    }
                }
            }

            Item {
                id: bluetoothButton
                Layout.fillHeight: true
                implicitWidth: Theme.dimensions.iconBase + 8
                Layout.alignment: Qt.AlignVCenter

                BaseIcon {
                    anchors.centerIn: parent
                    icon: Bluetooth.powered ? "bluetooth" : "bluetooth_disabled"
                    size: Theme.dimensions.iconBase
                    color: bluetoothMouse.containsMouse ? Theme.colors.primary : Theme.colors.text
                }

                MouseArea {
                    id: bluetoothMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: PopoutService.toggleBluetoothPopout()
                }

                Timer {
                    id: bluetoothHoverTimer
                    interval: 250
                    repeat: false
                    onTriggered: PopoutService.openBluetoothPopout()
                }

                Connections {
                    target: bluetoothMouse
                    function onContainsMouseChanged() {
                        if (bluetoothMouse.containsMouse && Preferences.popoutTrigger === 1) {
                            bluetoothHoverTimer.restart();
                        } else {
                            bluetoothHoverTimer.stop();
                        }
                    }
                }
            }
        }
    }
}
