import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

BaseScroller {
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

    property var availableDevices: {
        var list = [];
        for (var i = 0; i < Bluetooth.devices.length; i++) {
            var dev = Bluetooth.devices[i];
            if (!dev.paired && !dev.bonded && !dev.trusted && root.isResolvable(dev.name, dev.address))
                list.push(dev);
        }
        return list;
    }

    property var pairedDevices: {
        var list = [];
        for (var i = 0; i < Bluetooth.devices.length; i++) {
            var dev = Bluetooth.devices[i];
            if (dev.paired || dev.bonded || dev.trusted)
                list.push(dev);
        }
        return list;
    }

    ColumnLayout {
        id: mainLayout
        width: root.availableWidth
        spacing: Theme.geometry.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.geometry.spacing.medium

            // Left side: Bluetooth toggle (acts as back)
            BaseButton {
                Layout.preferredWidth: (parent.width - parent.spacing) / 2
                Layout.fillWidth: true
                buttonMode: "toggle"
                title: "Bluetooth"
                subtitle: Bluetooth.powered ? (Bluetooth.connectedCount > 0 ? Bluetooth.connectedCount + " devices" : "On") : "Off"
                icon: active ? "bluetooth" : "bluetooth_disabled"
                active: Bluetooth.powered
                mirrored: true
                onClicked: {
                    if (root.StackView.view)
                        root.StackView.view.pop();
                }
                onActionClicked: Bluetooth.togglePower()
            }

            // Search Button
            BaseButton {
                id: searchButton

                property real scanProgress: 0

                Layout.preferredWidth: (parent.width - parent.spacing) / 2
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                hoverEnabled: false
                text: ""
                icon: ""
                onClicked: Bluetooth.toggleScan()
                visible: !!Bluetooth.powered
                customRadius: Theme.geometry.radius * 1.5

                Item {
                    anchors.fill: parent
                    z: -2
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.geometry.radius * 1.5
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: Theme.colors.primary }
                            GradientStop { position: 1; color: Theme.colors.secondary }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1.5
                        radius: (Theme.geometry.radius * 1.5) - 1.5
                        color: Theme.colors.surface
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: Qt.alpha(Theme.colors.primary, 0.08)
                        }
                    }
                }

                BaseText {
                    id: idleLabel
                    anchors.centerIn: parent
                    text: "Search"
                    color: Theme.colors.text
                    pixelSize: searchButton.textSize
                    weight: searchButton.weight
                    opacity: Bluetooth.scanning ? 0.0 : 1.0
                    visible: opacity > 0
                    
                    Behavior on opacity {
                        BaseAnimation { duration: Theme.animations.normal }
                    }
                }

                BaseAnimation {
                    target: searchButton
                    property: "scanProgress"
                    from: 0
                    to: 1
                    duration: 15000
                    running: Bluetooth.scanning
                    easing.type: Easing.Linear
                    onFinished: {
                        if (Bluetooth.scanning)
                            Bluetooth.toggleScan();
                    }
                }

                Canvas {
                    id: scanCanvas
                    anchors.fill: parent
                    z: -1
                    opacity: Bluetooth.scanning ? 1 : 0
                    visible: opacity > 0
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        var r = Math.min(Theme.geometry.radius * 1.5, height / 2, width / 2);
                        ctx.beginPath();
                        ctx.moveTo(r, 0);
                        ctx.lineTo(width - r, 0);
                        ctx.arcTo(width, 0, width, r, r);
                        ctx.lineTo(width, height - r);
                        ctx.arcTo(width, height, width - r, height, r);
                        ctx.lineTo(r, height);
                        ctx.arcTo(0, height, 0, height - r, r);
                        ctx.lineTo(0, r);
                        ctx.arcTo(0, 0, r, 0, r);
                        ctx.closePath();
                        ctx.clip();

                        var fillHeight = height * searchButton.scanProgress;
                        var surfaceY = height - fillHeight;
                        ctx.beginPath();
                        ctx.moveTo(-10, height + 10);
                        ctx.lineTo(-10, surfaceY);
                        var amplitude = 6 * Math.sin(searchButton.scanProgress * Math.PI);
                        for (var x = -10; x <= width + 10; x += 5) {
                            var sine = Math.sin(x / 15 + Date.now() / 150) * amplitude;
                            ctx.lineTo(x, surfaceY + sine);
                        }
                        ctx.lineTo(width + 10, height + 10);
                        ctx.closePath();
                        var grad = ctx.createLinearGradient(0, 0, width, 0);
                        grad.addColorStop(0, Theme.colors.primary);
                        grad.addColorStop(1, Theme.colors.secondary);
                        ctx.fillStyle = grad;
                        ctx.fill();
                    }

                    Timer {
                        interval: 16
                        repeat: true
                        running: scanCanvas.visible
                        onTriggered: scanCanvas.requestPaint()
                    }

                    Behavior on opacity {
                        BaseAnimation { duration: 500 }
                    }
                }
            }
        }

        // --- BLUETOOTH DEVICES BLOCK ---
        BaseBlock {
            id: bluetoothBlock
            Layout.fillWidth: true
            clip: true
            visible: !!Bluetooth.powered && (root.pairedDevices.length > 0 || root.availableDevices.length > 0)

            ColumnLayout {
                spacing: Theme.geometry.spacing.medium
                Layout.fillWidth: true

                // Paired Devices
                BaseText {
                    visible: !!Bluetooth.powered && root.pairedDevices.length > 0
                    text: "Paired Devices"
                    weight: Theme.typography.weights.bold
                    color: Theme.colors.primary
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.geometry.spacing.medium
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    visible: !!Bluetooth.powered && root.pairedDevices.length > 0

                    Repeater {
                        model: root.pairedDevices
                        delegate: deviceDelegate
                    }
                }

                // Available Devices
                BaseText {
                    visible: !!Bluetooth.powered && root.availableDevices.length > 0
                    text: "Available Devices"
                    weight: Theme.typography.weights.bold
                    color: Theme.colors.primary
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.geometry.spacing.medium
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    visible: !!Bluetooth.powered && root.availableDevices.length > 0

                    Repeater {
                        model: root.availableDevices
                        delegate: deviceDelegate
                    }
                }
            }
        }
    }

    Component {
        id: deviceDelegate

        BaseDevice {
            deviceType: "bluetooth"
            title: modelData.name || modelData.address
            subtitle: modelData.connected ? "Connected" : (modelData.paired || modelData.bonded || modelData.trusted ? "Paired" : "Available")
            iconName: root.resolveBluetoothIcon(modelData.icon)
            isConnected: modelData.connected
            isConnecting: modelData.connecting
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
