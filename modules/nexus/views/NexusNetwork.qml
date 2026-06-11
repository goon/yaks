import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

BaseScroller {
    id: root
    clip: true
    implicitHeight: mainLayout.implicitHeight



    ColumnLayout {
        id: mainLayout
        width: root.availableWidth
        spacing: Theme.geometry.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.geometry.spacing.medium

            // Left side: Wi-Fi toggle (acts as back)
            BaseButton {
                Layout.preferredWidth: (parent.width - parent.spacing) / 2
                Layout.fillWidth: true
                buttonMode: "toggle"
                title: "Wi-Fi"
                subtitle: Network.wifiEnabled ? "On" : "Off"
                icon: active ? "wifi" : "wifi_off"
                active: Network.wifiEnabled
                mirrored: true
                onClicked: {
                    if (root.StackView.view)
                        root.StackView.view.pop();
                }
                onActionClicked: Network.toggleWifi()
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
                onClicked: {
                    if (Network.scanning) {
                        if (Network.wifiDevice) Network.wifiDevice.scannerEnabled = false;
                    } else {
                        Network.scan();
                    }
                }
                visible: !!Network.wifiEnabled
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
                    opacity: Network.scanning ? 0.0 : 1.0
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
                    running: Network.scanning
                    easing.type: Easing.Linear
                    onFinished: {
                        if (Network.scanning && Network.wifiDevice)
                            Network.wifiDevice.scannerEnabled = false;
                    }
                }

                Canvas {
                    id: scanCanvas
                    anchors.fill: parent
                    z: -1
                    opacity: Network.scanning ? 1 : 0
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

        // --- SECTION 1: HERO CONNECTION STATUS & TRAFFIC GRAPH CARD ---
        BaseBlock {
            id: heroStatusCard
            Layout.fillWidth: true
            padding: Theme.geometry.spacing.dynamicPadding
            borderWidth: 1
            borderColor: (Network.ethernetConnected || Network.connected) ? Theme.colors.transparent : Theme.colors.border
            backgroundColor: Theme.colors.surface
            premiumActive: Network.ethernetConnected || Network.connected

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.geometry.spacing.medium

                // Top: Active Connection Details
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.geometry.spacing.medium

                    // Glowing Icon / Ethernet Toggle
                    BaseButton {
                        width: 64
                        height: 64
                        
                        // Original visual styling
                        customRadius: Theme.geometry.radius
                        icon: {
                            if (Network.ethernetConnected) return "lan";
                            if (Network.connected) return "wifi";
                            return "wifi_off";
                        }
                        size: 32
                        iconColor: (Network.ethernetConnected || Network.connected) ? Theme.colors.primary : Theme.colors.warning
                        normalColor: Theme.alpha(iconColor, 0.15)
                        hoverColor: Theme.alpha(iconColor, 0.25)

                        onClicked: {
                            if (Network.wiredDevice) {
                                Network.toggleEthernet();
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        BaseText {
                            text: {
                                if (Network.ethernetConnected) return "Wired Connection";
                                if (Network.connected) return Network.ssid;
                                return "Offline";
                            }
                            weight: Theme.typography.weights.bold
                            pixelSize: Theme.typography.size.large
                            color: Theme.colors.textLighter
                        }

                        BaseText {
                            text: {
                                if (Network.ethernetConnected || Network.connected) {
                                    var ip = Network.ipv4 ? Network.ipv4 : "No IP Address";
                                    var speed = (Network.ethernetConnected && Network.wiredDevice && Network.wiredDevice.linkSpeed > 0)
                                        ? " • " + Network.wiredDevice.linkSpeed + " Mbps"
                                        : "";
                                    var strength = (Network.connected && !Network.ethernetConnected && Network.signalStrength > 0)
                                        ? " • Signal: " + Network.signalStrength + "%"
                                        : "";
                                    return ip + speed + strength;
                                }
                                return "No active internet connection detected.";
                            }
                            color: Theme.colors.text
                            pixelSize: Theme.typography.size.small
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                        }
                    }
                }

                // Horizontal Divider (only when connected)
                BaseSeparator {
                    Layout.fillWidth: true
                    visible: Network.ethernetConnected || Network.connected
                    opacity: 0.1
                }

                // Bottom: Live Speed Metrics & Traffic Graph (only when connected)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.geometry.spacing.small
                    visible: Network.ethernetConnected || Network.connected

                    // Live Throughput speed metrics row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        RowLayout {
                            spacing: 4
                            BaseIcon {
                                icon: "arrow_downward"
                                size: 14
                                color: Theme.colors.primary
                            }
                            BaseText {
                                text: Stats.formatBytes(Stats.currentNetworkRx) + "/s"
                                weight: Theme.typography.weights.bold
                                pixelSize: Theme.typography.size.small
                                color: Theme.colors.textLighter
                            }
                            BaseText {
                                text: "Down"
                                pixelSize: Theme.typography.size.small - 1
                                color: Theme.colors.muted
                            }
                        }

                        Item { Layout.fillWidth: true }

                        RowLayout {
                            spacing: 4
                            BaseIcon {
                                icon: "arrow_upward"
                                size: 14
                                color: Theme.colors.secondary
                            }
                            BaseText {
                                text: Stats.formatBytes(Stats.currentNetworkTx) + "/s"
                                weight: Theme.typography.weights.bold
                                pixelSize: Theme.typography.size.small
                                color: Theme.colors.textLighter
                            }
                            BaseText {
                                text: "Up"
                                pixelSize: Theme.typography.size.small - 1
                                color: Theme.colors.muted
                            }
                        }
                    }


                }
            }
        }



        // --- SECTION 3: AVAILABLE NETWORKS ---
        BaseBlock {
            id: wifiListSection
            Layout.fillWidth: true
            clip: true
            visible: Network.wifiEnabled && availableList.length > 0

            readonly property var availableList: {
                var list = [];
                for (var i = 0; i < Network.availableNetworks.length; i++) {
                    var net = Network.availableNetworks[i];
                    if (!net.active) list.push(net);
                }
                list.sort(function(a, b) {
                    return b.signal - a.signal;
                });
                return list;
            }

            ColumnLayout {
                spacing: Theme.geometry.spacing.medium
                Layout.fillWidth: true

                // Section Header
                BaseText {
                    text: "Available Networks"
                    weight: Theme.typography.weights.bold
                    color: Theme.colors.primary
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.geometry.spacing.medium
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    // Networks List Repeater
                    Repeater {
                        model: wifiListSection.availableList

                        delegate: BaseDevice {
                            deviceType: "wifi"
                            title: modelData.ssid
                            subtitle: ""
                            iconName: {
                                var sig = modelData.signal;
                                if (sig > 75) return "wifi";
                                if (sig > 50) return "network_wifi_3_bar";
                                if (sig > 25) return "network_wifi_2_bar";
                                return "network_wifi_1_bar";
                            }
                            iconOpacity: 1.0
                            signalText: modelData.signal + "%"
                            isSecured: modelData.secured
                            isKnown: modelData.known
                            isConnected: false

                            onConnectClicked: function(password) {
                                Network.connect(modelData.ssid, password);
                            }
                            onActionClicked: {
                                Network.connect(modelData.ssid, "");
                            }
                            onForgetClicked: {
                                Network.forget(modelData.ssid);
                            }
                        }
                    }
                }
            }
        }

    }
}
