import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

SettingsPage {
    id: root

    // Auto-scan while page is open and Wi-Fi is enabled
    Timer {
        id: scanTimer
        interval: 10000 // 10 seconds
        repeat: true
        running: root.visible && Network.wifiEnabled
        triggeredOnStart: true
        onTriggered: Network.scan()
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Theme.geometry.spacing.large

        // --- SECTION 1: HERO CONNECTION STATUS & TRAFFIC GRAPH CARD ---
        BaseBlock {
            id: heroStatusCard
            Layout.fillWidth: true
            padding: Theme.geometry.spacing.dynamicPadding
            borderWidth: 1
            borderColor: (Network.ethernetConnected || Network.connected) ? Theme.colors.transparent : Theme.colors.border
            backgroundColor: Theme.colors.surface
            premiumActive: Network.ethernetConnected || Network.connected

            Item {
                Layout.fillWidth: true
                implicitHeight: 100

                // Glowing Icon taking full height of container
                Rectangle {
                    id: iconRect
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: height // Makes it 100x100 square
                    radius: Theme.geometry.radius
                    color: Theme.alpha(
                        (Network.ethernetConnected || Network.connected) ? Theme.colors.primary : Theme.colors.warning,
                        0.15
                    )

                    BaseIcon {
                        anchors.centerIn: parent
                        icon: {
                            if (Network.ethernetConnected) return "lan";
                            if (Network.connected) return "wifi";
                            return "wifi_off";
                        }
                        size: 32
                        color: (Network.ethernetConnected || Network.connected) ? Theme.colors.primary : Theme.colors.warning
                    }
                }

                // Left Column: Active Connection Details
                ColumnLayout {
                    id: leftColumn
                    anchors.left: iconRect.right
                    anchors.leftMargin: Theme.geometry.spacing.large
                    anchors.right: (Network.ethernetConnected || Network.connected) ? verticalDivider.left : parent.right
                    anchors.rightMargin: Theme.geometry.spacing.large
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    BaseText {
                        text: {
                            if (Network.ethernetConnected) return "Wired Connection";
                            if (Network.connected) return Network.ssid;
                            return "Offline";
                        }
                        weight: Theme.typography.weights.bold
                        pixelSize: Theme.typography.size.large + 2
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
                        pixelSize: Theme.typography.size.medium
                    }
                }

                // Vertical Divider Line (only when connected)
                Rectangle {
                    id: verticalDivider
                    anchors.right: graphColumn.left
                    anchors.rightMargin: Theme.geometry.spacing.large
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: Theme.colors.border
                    visible: Network.ethernetConnected || Network.connected
                }

                // Right Column: Live Speed Metrics & Traffic Graph (only when connected)
                ColumnLayout {
                    id: graphColumn
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 320
                    spacing: Theme.geometry.spacing.small
                    visible: Network.ethernetConnected || Network.connected

                    // Live Throughput speed metrics row
                    RowLayout {
                        Layout.alignment: Qt.AlignRight
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

                    // Graph container
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        BaseGraph {
                            anchors.fill: parent
                            modelData: Stats.networkRxHistory
                            lineColor: Theme.colors.primary
                            maxValue: 1024 * 1024
                            autoScale: true
                            drawProgress: 1.0
                        }

                        BaseGraph {
                            anchors.fill: parent
                            modelData: Stats.networkTxHistory
                            lineColor: Theme.colors.secondary
                            maxValue: 1024 * 1024
                            autoScale: true
                            drawProgress: 1.0
                        }
                    }
                }
            }
        }

        // --- SECTION 2: UNIFIED INTERFACE CONTROLLERS CARD ---
        BaseBlock {
            Layout.fillWidth: true
            padding: Theme.geometry.spacing.dynamicPadding
            borderWidth: 1
            borderColor: Theme.colors.border
            backgroundColor: Theme.alpha(Theme.colors.surface, 0.4)

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.geometry.spacing.large

                // --- ETHERNET ROW ---
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.geometry.spacing.medium

                    BaseIcon {
                        icon: "lan"
                        size: Theme.dimensions.iconBase + 2
                        color: Network.ethernetConnected ? Theme.colors.primary : Theme.colors.muted
                    }

                    ColumnLayout {
                        spacing: 2

                        BaseText {
                            text: "Ethernet"
                            weight: Theme.typography.weights.bold
                            pixelSize: Theme.typography.size.medium
                            color: Theme.colors.textLighter
                        }

                        BaseText {
                            text: {
                                if (!Network.ethernetEnabled) return "No ethernet hardware interface found";
                                if (Network.ethernetConnected) return "Interface enabled and connected";
                                if (Network.wiredDevice && Network.wiredDevice.hasLink) return "Cable connected (ready)";
                                return "Cable unplugged";
                            }
                            color: {
                                if (Network.ethernetConnected) return Theme.colors.success;
                                if (Network.wiredDevice && !Network.wiredDevice.hasLink) return Theme.colors.warning;
                                return Theme.colors.muted;
                            }
                            pixelSize: Theme.typography.size.base
                        }
                    }

                    Item { Layout.fillWidth: true }

                    BaseSwitch {
                        checked: Network.ethernetConnected
                        enabled: Network.ethernetEnabled && (Network.wiredDevice ? Network.wiredDevice.hasLink : true)
                        onToggled: Network.toggleEthernet()
                    }
                }

                BaseSeparator {
                    fill: true
                    thickness: 1
                    color: Theme.alpha(Theme.colors.border, 0.3)
                    Layout.topMargin: 4
                    Layout.bottomMargin: 4
                }

                // --- WI-FI ROW ---
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.geometry.spacing.medium

                    BaseIcon {
                        icon: Network.wifiEnabled ? "wifi" : "wifi_off"
                        size: Theme.dimensions.iconBase + 2
                        color: Network.wifiEnabled ? Theme.colors.primary : Theme.colors.muted
                    }

                    ColumnLayout {
                        spacing: 2

                        BaseText {
                            text: "Wireless"
                            weight: Theme.typography.weights.bold
                            pixelSize: Theme.typography.size.medium
                            color: Theme.colors.textLighter
                        }

                        BaseText {
                            text: Network.wifiEnabled
                                ? (Network.scanning ? "Scanning for nearby access points..." : "Interface enabled")
                                : "Interface disabled"
                            color: Network.wifiEnabled ? Theme.colors.success : Theme.colors.muted
                            pixelSize: Theme.typography.size.base
                        }
                    }

                    Item { Layout.fillWidth: true }

                    BaseSwitch {
                        checked: Network.wifiEnabled
                        onToggled: Network.toggleWifi()
                    }
                }
            }
        }

        // --- SECTION 3: AVAILABLE NETWORKS ---
        ColumnLayout {
            id: wifiListSection
            Layout.fillWidth: true
            spacing: Theme.geometry.spacing.medium
            visible: Network.wifiEnabled

            readonly property var availableList: {
                var list = [];
                for (var i = 0; i < Network.availableNetworks.length; i++) {
                    var net = Network.availableNetworks[i];
                    if (!net.active) list.push(net);
                }
                return list;
            }

            // Section Header Row
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Theme.geometry.spacing.small

                BaseText {
                    text: "Available Networks"
                    weight: Theme.typography.weights.bold
                    color: Theme.colors.primary
                    pixelSize: Theme.typography.size.medium
                    Layout.fillWidth: true
                }

                // Custom premium rotating scan button
                Item {
                    width: 32
                    height: 32
                    Layout.alignment: Qt.AlignVCenter
                    visible: Network.wifiEnabled

                    Rectangle {
                        id: refreshBg
                        anchors.fill: parent
                        radius: 16
                        color: refreshMouse.containsMouse ? Theme.alpha(Theme.colors.text, 0.06) : Theme.colors.transparent
                        border.color: refreshMouse.containsMouse ? Theme.alpha(Theme.colors.border, 0.15) : Theme.colors.transparent
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    BaseIcon {
                        id: refreshIcon
                        anchors.centerIn: parent
                        icon: "refresh"
                        size: 16
                        color: refreshMouse.containsMouse ? Theme.colors.primary : Theme.colors.textLighter

                        RotationAnimation on rotation {
                            from: 0
                            to: 360
                            duration: 1000
                            loops: Animation.Infinite
                            running: Network.scanning
                        }
                    }

                    MouseArea {
                        id: refreshMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (Network.scanning) {
                                if (Network.wifiDevice) Network.wifiDevice.scannerEnabled = false;
                            } else {
                                Network.scan();
                            }
                        }
                    }
                }
            }

            // Networks List Repeater
            Repeater {
                model: wifiListSection.availableList

                delegate: ColumnLayout {
                    id: delegateRoot
                    property bool expanded: false
                    Layout.fillWidth: true
                    spacing: 0

                    // Network Row Card
                    BaseBlock {
                        id: networkItem
                        Layout.fillWidth: true
                        paddingHorizontal: Theme.geometry.spacing.dynamicPadding
                        paddingVertical: Theme.geometry.spacing.medium
                        borderWidth: 1
                        borderColor: containsMouse || delegateRoot.expanded ? Theme.alpha(Theme.colors.primary, 0.4) : Theme.colors.border
                        backgroundColor: containsMouse || delegateRoot.expanded
                            ? Theme.alpha(Theme.colors.primary, 0.06)
                            : Theme.alpha(Theme.colors.surface, 0.2)
                        clickable: true

                        onClicked: {
                            if (modelData.secured) {
                                delegateRoot.expanded = !delegateRoot.expanded;
                                if (delegateRoot.expanded)
                                    passwordInput.forceActiveFocus();
                            } else {
                                Network.connect(modelData.ssid, "");
                            }
                        }

                        RowLayout {
                            width: networkItem.width - (networkItem.paddingHorizontal * 2)
                            spacing: Theme.geometry.spacing.medium

                            BaseIcon {
                                icon: "wifi"
                                size: Theme.dimensions.iconMedium
                                color: (networkItem.containsMouse || delegateRoot.expanded) ? Theme.colors.primary : Theme.colors.text
                                opacity: 0.4 + 0.6 * (modelData.signal / 100.0)
                            }

                            ColumnLayout {
                                spacing: 2
                                Layout.fillWidth: true

                                BaseText {
                                    text: modelData.ssid
                                    weight: (networkItem.containsMouse || delegateRoot.expanded) ? Theme.typography.weights.bold : Theme.typography.weights.normal
                                    color: (networkItem.containsMouse || delegateRoot.expanded) ? Theme.colors.textLighter : Theme.colors.text
                                    pixelSize: Theme.typography.size.base
                                }

                                BaseText {
                                    text: modelData.secured ? "Secured WPA/WPA2" : "Open Network"
                                    pixelSize: Theme.typography.size.small
                                    color: Theme.colors.muted
                                }
                            }

                            RowLayout {
                                spacing: Theme.geometry.spacing.medium
                                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                                BaseText {
                                    text: modelData.signal + "%"
                                    pixelSize: Theme.typography.size.small
                                    color: Theme.colors.muted
                                }

                                BaseIcon {
                                    icon: "lock"
                                    size: 14
                                    color: Theme.colors.muted
                                    visible: modelData.secured
                                }

                                BaseIcon {
                                    icon: delegateRoot.expanded ? "expand_less" : "expand_more"
                                    size: 16
                                    color: Theme.colors.muted
                                    visible: modelData.secured
                                }
                            }
                        }
                    }

                    // Expandable Password Form Drawer
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: delegateRoot.expanded ? passwordBox.implicitHeight + 16 : 0
                        state: delegateRoot.expanded ? "expanded" : "collapsed"
                        clip: true

                        BaseBlock {
                            id: passwordBox
                            anchors.top: parent.top
                            anchors.topMargin: 8
                            anchors.left: parent.left
                            anchors.right: parent.right
                            backgroundColor: Theme.alpha(Theme.colors.surface, 0.4)
                            borderWidth: 1
                            borderColor: Theme.colors.border
                            padding: Theme.geometry.spacing.dynamicPadding
                            spacing: Theme.geometry.spacing.medium

                            BaseInput {
                                id: passwordInput
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                placeholderText: "Enter Wi-Fi network password..."
                                echoMode: TextInput.Password
                                onAccepted: connectBtn.clicked()
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.geometry.spacing.medium

                                // Spacer to push buttons to the right
                                Item { Layout.fillWidth: true }

                                // Cancel Button
                                BaseButton {
                                    text: "Cancel"
                                    Layout.preferredHeight: 32
                                    paddingHorizontal: 16
                                    normalColor: Theme.alpha(Theme.colors.text, 0.06)
                                    textColor: Theme.colors.text
                                    onClicked: {
                                        delegateRoot.expanded = false;
                                        passwordInput.text = "";
                                    }
                                }

                                // Forget Button
                                BaseButton {
                                    text: "Forget"
                                    visible: modelData.known
                                    Layout.preferredHeight: 32
                                    paddingHorizontal: 16
                                    normalColor: Theme.alpha(Theme.colors.error, 0.15)
                                    textColor: Theme.colors.error
                                    borderColor: Theme.alpha(Theme.colors.error, 0.3)
                                    borderWidth: 1
                                    onClicked: {
                                        Network.forget(modelData.ssid);
                                        delegateRoot.expanded = false;
                                    }
                                }

                                // Connect Button
                                BaseButton {
                                    id: connectBtn
                                    text: "Connect"
                                    Layout.preferredHeight: 32
                                    paddingHorizontal: 20
                                    normalColor: Theme.colors.primary
                                    textColor: Theme.colors.text
                                    textWeight: Theme.typography.weights.bold
                                    onClicked: {
                                        Network.connect(modelData.ssid, passwordInput.text);
                                        delegateRoot.expanded = false;
                                        passwordInput.text = "";
                                    }
                                }
                            }
                        }

                        Behavior on Layout.preferredHeight { BaseAnimation { duration: 200 } }
                    }
                }
            }

            // No Networks Found Placeholder
            BaseText {
                visible: !Network.scanning && wifiListSection.availableList.length === 0
                text: "No wireless networks found nearby."
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                color: Theme.colors.muted
                Layout.topMargin: 20
            }
        }
    }
}
