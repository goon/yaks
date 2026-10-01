import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs

BaseScrolling {
    id: root
    clip: true
    implicitWidth: 325
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

    readonly property var connectedRows: root.rows.filter(function(r) { return r.bt ? r.bt.connected : true; })
    readonly property var pairedRows: root.rows.filter(function(r) { return r.bt && !r.bt.connected && (r.bt.paired || r.bt.bonded || r.bt.trusted); })
    readonly property var nearbyRows: root.rows.filter(function(r) { return r.bt && !r.bt.connected && !(r.bt.paired || r.bt.bonded || r.bt.trusted); })

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: Modules.closeAll()
        z: -1
    }

    focus: true
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Backspace) {
            Modules.closeAll();
            event.accepted = true;
        }
    }

    ColumnLayout {
        id: mainLayout
        width: root.availableWidth
        spacing: Globals.geometry.spacing.sm

        NetworkHeader {
            Layout.fillWidth: true
            enabled: !!Bluetooth.powered
            scanning: Bluetooth.scanning
            onScanClicked: Bluetooth.scan()
            onToggleClicked: Bluetooth.togglePower()
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 64 : 0
            visible: !!Bluetooth.powered && root.rows.length === 0
            clip: true

            BaseText {
                text: "Searching devices..."
                muted: true
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
                var repeaters = [connectedRepeater, pairedRepeater, nearbyRepeater];
                for (var r = 0; r < repeaters.length; r++) {
                    for (var i = 0; i < repeaters[r].count; i++) {
                        var item = repeaters[r].itemAt(i);
                        if (item && item.hovered) return item;
                    }
                }
                return null;
            }

            ColumnLayout {
                id: childCol
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Globals.geometry.spacing.sm
                Layout.fillWidth: true

                BaseIndicator {
                    hoverPredicate: bluetoothBlock._hoverPredicate
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.connectedRows.length > 0
                    spacing: Globals.geometry.spacing.xs

                    Repeater {
                        id: connectedRepeater
                        model: root.connectedRows
                        delegate: deviceDelegate
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.pairedRows.length > 0
                    spacing: Globals.geometry.spacing.xs

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Globals.geometry.spacing.xs

                        BaseHeader {
                            text: "Paired"
                            Layout.fillWidth: false
                            Layout.bottomMargin: 0
                        }

                        BaseSeparator {
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    Repeater {
                        id: pairedRepeater
                        model: root.pairedRows
                        delegate: deviceDelegate
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.nearbyRows.length > 0
                    spacing: Globals.geometry.spacing.xs

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Globals.geometry.spacing.xs

                        BaseHeader {
                            text: "Nearby"
                            Layout.fillWidth: false
                            Layout.bottomMargin: 0
                        }

                        BaseSeparator {
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    Repeater {
                        id: nearbyRepeater
                        model: root.nearbyRows
                        delegate: deviceDelegate
                    }
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
                if (up && Peripherals.charging(up))
                    return "Charging";
                return "";
            }
            iconName: bt ? root.resolveBluetoothIcon(bt.icon) : root.resolvePeripheralIcon(up.type)
            isConnected: !!bt && bt.connected
            isKnown: !!bt && (bt.paired || bt.bonded || bt.trusted)
            batteryPct: up ? Peripherals.pct(up) : -1

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
