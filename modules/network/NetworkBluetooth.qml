import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

BaseScrolling {
    id: root
    clip: true
    implicitHeight: mainLayout.implicitHeight

    function resolveBluetoothIcon(bluezIcon) {
        if (!bluezIcon)
            return "bluetooth";

        switch (bluezIcon) {
        case "audio-card":
        case "audio-headphones":
        case "audio-headset":
            return "headset";
        case "phone":
            return "smartphone";
        case "video-display":
            return "computer";
        case "input-keyboard":
            return "keyboard";
        case "input-mouse":
            return "mouse";
        case "input-gaming":
            return "videogame_asset";
        default:
            return "bluetooth";
        }
    }

    function isResolvable(name, address) {
        if (!name)
            return false;

        var cleanName = name.replace(/[:\-]/g, "").toLowerCase();
        var cleanAddress = address.replace(/[:\-]/g, "").toLowerCase();
        if (cleanName === cleanAddress)
            return false;

        return !/^[0-9a-f]{12}$/.test(cleanName);
    }

    property var sortedDevices: {
        var list = [];
        for (var i = 0; i < Bluetooth.devices.length; i++) {
            var dev = Bluetooth.devices[i];
            var isPaired = dev.paired || dev.bonded || dev.trusted;
            if (isPaired || root.isResolvable(dev.name, dev.address)) {
                list.push(dev);
            }
        }
        return list.sort((a, b) => {
            var aPaired = a.paired || a.bonded || a.trusted;
            var bPaired = b.paired || b.bonded || b.trusted;
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            if (aPaired !== bPaired) return aPaired ? -1 : 1;
            return (a.name || a.address).localeCompare(b.name || b.address);
        });
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: {
            if (root.StackView.view && root.StackView.view.depth > 1) {
                root.StackView.view.pop(null);
            }
        }
        z: -1
    }

    focus: true
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Backspace) {
            if (root.StackView.view && root.StackView.view.depth > 1) {
                root.StackView.view.pop(null);
            }
            event.accepted = true;
        }
    }

    ColumnLayout {
        id: mainLayout
        width: root.availableWidth
        spacing: Globals.geometry.spacing.medium

        Item {
            Layout.fillWidth: true
            Layout.bottomMargin: Globals.geometry.spacing.small / 2
            implicitHeight: Math.max(pageHeader.implicitHeight, 28)

            RowLayout {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: Globals.geometry.spacing.small

                BaseIcon {
                    icon: "chevron_left"
                    color: backMouseArea.containsMouse ? Globals.colors.primary : Globals.colors.text
                    Layout.alignment: Qt.AlignVCenter
                    Behavior on color { BaseAnimation { } }

                    MouseArea {
                        id: backMouseArea
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.StackView.view) {
                                root.StackView.view.pop();
                            }
                        }
                    }
                }

                BaseHeader {
                    id: pageHeader
                    text: "BLUETOOTH"
                }
            }

            RowLayout {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Globals.geometry.spacing.small

                BaseButton {
                    id: refreshButton
                    icon: "refresh"
                    width: 28
                    height: 28
                    customRadius: Globals.geometry.innerRadius.medium
                    hoverEnabled: false
                    onClicked: Bluetooth.scan()

                    NumberAnimation {
                        target: refreshButton
                        property: "iconRotation"
                        from: 0; to: 360
                        duration: 1000
                        loops: Animation.Infinite
                        running: Bluetooth.scanning
                    }
                }

                BaseSwitch {
                    checked: Bluetooth.powered
                    onClicked: Bluetooth.togglePower()
                }
            }
        }

        BaseSeparator {
            Layout.fillWidth: true
            visible: !!Bluetooth.powered
        }



        // Searching Placeholder
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 64 : 0
            visible: !!Bluetooth.powered && root.sortedDevices.length === 0
            clip: true

            BaseText {
                text: "Searching devices..."
                color: Globals.alpha(Globals.colors.text, 0.4)
                font.pixelSize: Globals.typography.size.small
                anchors.centerIn: parent
            }
        }

        // ── BLUETOOTH DEVICES ─────────────────────────────────────────
        Item {
            id: bluetoothBlock
            Layout.fillWidth: true
            implicitHeight: childCol.implicitHeight
            clip: true
            visible: !!Bluetooth.powered && root.sortedDevices.length > 0

            function _hoverPredicate() {
                for (var i = 0; i < deviceRepeater.count; i++) {
                    var item = deviceRepeater.itemAt(i);
                    if (item && item.hovered) return item;
                }
                return null;
            }

            ColumnLayout {
                id: childCol
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Globals.geometry.spacing.medium
                Layout.fillWidth: true

                Item {
                    z: 100
                    Layout.preferredWidth: 0
                    Layout.preferredHeight: 0

                    BaseIndicator {
                        hoverPredicate: bluetoothBlock._hoverPredicate
                    }
                }

                Repeater {
                    id: deviceRepeater
                    model: root.sortedDevices
                    delegate: deviceDelegate
                }
            }
        }
    }

    Component {
        id: deviceDelegate

        NetworkDevice {
            property bool hovered: isHovered

            title: modelData.name || modelData.address
            subtitle: modelData.connecting ? "Connecting..." : ""
            iconName: root.resolveBluetoothIcon(modelData.icon)
            isConnected: modelData.connected
            isKnown: modelData.paired || modelData.bonded || modelData.trusted

            onActionClicked: {
                if (!modelData.connected) {
                    Bluetooth.connectDevice(modelData.address);
                }
            }
            onDisconnectClicked: Bluetooth.disconnectDevice(modelData.address)
            onForgetClicked: Bluetooth.removeDevice(modelData.address)
        }
    }
}
