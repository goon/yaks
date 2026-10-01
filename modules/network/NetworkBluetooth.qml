import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs

BaseScrolling {
    id: root
    clip: true
    implicitHeight: mainLayout.implicitHeight
    readonly property int _spinMs: 1000

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
            return "gamepad-2";
        default:
            return "bluetooth";
        }
    }

    function resolvePeripheralIcon(type) {
        switch (type) {
        case UPowerDeviceType.Mouse:
        case UPowerDeviceType.Touchpad:
            return "mouse";
        case UPowerDeviceType.Keyboard:
            return "keyboard";
        case UPowerDeviceType.GamingInput:
        case UPowerDeviceType.RemoteControl:
            return "gamepad-2";
        case UPowerDeviceType.Headset:
        case UPowerDeviceType.Headphones:
        case UPowerDeviceType.Speakers:
        case UPowerDeviceType.OtherAudio:
            return "headset";
        case UPowerDeviceType.MediaPlayer:
            return "music";
        case UPowerDeviceType.Monitor:
        case UPowerDeviceType.Computer:
            return "monitor";
        default:
            return "battery-medium";
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

    // One row per device: a Bluetooth device is joined with its UPower battery
    // entry by MAC so it stays a single row, and peripherals with no MAC in
    // their native path (USB dongles) are appended on their own.
    readonly property var rows: {
        var out = [];
        for (var i = 0; i < root.sortedDevices.length; i++) {
            var d = root.sortedDevices[i];
            var key = String(d.address || "").toUpperCase().replace(/:/g, "");
            out.push({ bt: d, up: Peripherals.byMac[key] || null });
        }
        for (var j = 0; j < Peripherals.unmatched.length; j++)
            out.push({ bt: null, up: Peripherals.unmatched[j] });
        return out;
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
                    icon: "chevron-left"
                    color: backMouseArea.containsMouse ? Globals.colors.primary : Globals.colors.text
                    Layout.alignment: Qt.AlignVCenter
                    Behavior on color { BaseMotion { } }

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
                    icon: "refresh-cw"
                    width: 28
                    height: 28
                    hoverEnabled: false
                    onClicked: Bluetooth.scan()

                    NumberAnimation {
                        target: refreshButton
                        property: "iconRotation"
                        from: 0; to: 360
                        duration: root._spinMs
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

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 64 : 0
            visible: !!Bluetooth.powered && root.rows.length === 0
            clip: true

            BaseText {
                text: "Searching devices..."
                color: Globals.colors.muted
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
            visible: root.rows.length > 0

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
                    model: root.rows
                    delegate: deviceDelegate
                }
            }
        }
    }

    Component {
        id: deviceDelegate

        NetworkDevice {
            property bool hovered: isHovered

            readonly property var bt: modelData.bt
            readonly property var up: modelData.up

            deviceType: bt ? "bluetooth" : "peripheral"
            title: bt ? (bt.name || bt.address) : (up.model || up.nativePath)
            subtitle: {
                if (bt && bt.connecting)
                    return "Connecting...";
                if (!up)
                    return "";
                var s = Peripherals.pct(up) + "%";
                return Peripherals.charging(up) ? s + " · Charging" : s;
            }
            iconName: bt ? root.resolveBluetoothIcon(bt.icon) : root.resolvePeripheralIcon(up.type)
            isConnected: !!bt && bt.connected
            isKnown: !!bt && (bt.paired || bt.bonded || bt.trusted)

            onActionClicked: {
                if (bt && !bt.connected) {
                    Bluetooth.connectDevice(bt.address);
                }
            }
            onDisconnectClicked: if (bt) Bluetooth.disconnectDevice(bt.address)
            onForgetClicked: if (bt) Bluetooth.removeDevice(bt.address)
        }
    }
}
