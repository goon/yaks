import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

BaseScrolling {
    id: root
    clip: true
    implicitWidth: 325
    implicitHeight: mainLayout.implicitHeight

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
            enabled: Network.wifiEnabled
            scanning: Network.scanning
            onScanClicked: Network.toggleScan()
            onToggleClicked: Network.toggleWifi()
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
                spacing: Globals.geometry.spacing.sm
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
