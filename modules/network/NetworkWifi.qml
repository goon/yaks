import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

BaseScrolling {
    id: root
    clip: true
    implicitHeight: mainLayout.implicitHeight

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
                    text: "WI-FI"
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
                    onClicked: Network.toggleScan()

                    NumberAnimation {
                        target: refreshButton
                        property: "iconRotation"
                        from: 0; to: 360
                        duration: 1000
                        loops: Animation.Infinite
                        running: Network.scanning
                    }
                }

                BaseSwitch {
                    checked: Network.wifiEnabled
                    onClicked: Network.toggleWifi()
                }
            }
        }

        BaseSeparator {
            Layout.fillWidth: true
            visible: Network.wifiEnabled
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 64 : 0
            visible: Network.wifiEnabled && wifiListSection.allNetworksList.length === 0
            clip: true

            BaseText {
                anchors.centerIn: parent
                text: "Searching networks..."
                muted: true
            }
        }
        // --- SECTION 3: AVAILABLE NETWORKS ---
        Item {
            id: wifiListSection
            Layout.fillWidth: true
            implicitHeight: childCol.implicitHeight
            clip: true
            visible: Network.wifiEnabled && allNetworksList.length > 0

            readonly property var allNetworksList: {
                var list = [];
                for (var i = 0; i < Network.availableNetworks.length; i++) {
                    var net = Network.availableNetworks[i];
                    if (net.known || net.active || net.secured) list.push(net);
                }
                list.sort(function(a, b) {
                    if (a.active && !b.active) return -1;
                    if (!a.active && b.active) return 1;
                    if (a.known && !b.known) return -1;
                    if (!a.known && b.known) return 1;
                    return b.signal - a.signal;
                });
                return list;
            }

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
                            hoverPredicate: wifiListSection._hoverPredicate
                        }
                    }

                    Repeater {
                        id: deviceRepeater
                        model: wifiListSection.allNetworksList
                        delegate: wifiDelegate
                    }
            }
        }

    }

    Component {
        id: wifiDelegate

        NetworkDevice {
            id: delegateRoot
            deviceType: "wifi"
            property bool hovered: isHovered

            property bool isPendingConnect: Network.pendingConnectSsid === modelData.ssid
            property bool isPendingDisconnect: Network.pendingDisconnectSsid === modelData.ssid
            property bool isPendingForget: Network.pendingForgetSsid === modelData.ssid

            title: modelData.ssid

            subtitle: {
                if (isPendingConnect) return "Connecting...";
                if (isPendingDisconnect) return "Disconnecting...";
                if (isPendingForget) return "Forgetting...";
                return modelData.active ? "" : (modelData.saved ? "Saved" : "");
            }

            iconName: {
                var sig = modelData.signal;
                if (sig > 75) return "wifi";
                if (sig > 50) return "network_wifi_3_bar";
                if (sig > 25) return "network_wifi_2_bar";
                return "network_wifi_1_bar";
            }
            isSecured: modelData.secured
            isKnown: modelData.known || modelData.active || isPendingConnect
            isConnected: modelData.active || isPendingConnect

            onConnectClicked: (password) => Network.connect(modelData.ssid, password)
            onDisconnectClicked: Network.disconnect()
            onActionClicked: Network.connect(modelData.ssid, "")
            onForgetClicked: Network.forget(modelData.ssid)
        }
    }
}
