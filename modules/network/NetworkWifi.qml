import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
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

            readonly property var connectedList: allNetworksList.filter(function(n) { return n.active })
            readonly property var nearbyList: allNetworksList.filter(function(n) { return !n.active })

            ColumnLayout {
                id: childCol
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Globals.geometry.spacing.xs
                Layout.fillWidth: true

                Repeater {
                    model: wifiListSection.connectedList
                    delegate: wifiDelegate
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Globals.geometry.spacing.xs
                    visible: wifiListSection.nearbyList.length > 0

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
                    id: deviceRepeater
                    model: wifiListSection.nearbyList
                    delegate: wifiDelegate
                }
            }
        }

    }

    // Signal-aware wifi glyph: three arcs over a base dot, the lit-arc count
    // standing for signal strength (>0.66 → 3, >0.33 → 2, >0 → 1). Radio off
    // dims every stroke and adds a diagonal slash. File-private on purpose —
    // only the wifi rows use it. Paths live in 24×24 space, centred on both axes.
    component WifiGlyph: Item {
        id: glyphRoot

        property real level: 0
        property bool on: true

        implicitWidth: Globals.typography.icon.lg
        implicitHeight: Globals.typography.icon.lg

        readonly property int litCount: !on ? 0 : (level > 0.66 ? 3 : (level > 0.33 ? 2 : (level > 0 ? 1 : 0)))
        readonly property color litColor: Globals.colors.text
        readonly property color unlitColor: Globals.alpha(Globals.colors.text, on ? 0.4 : 0.18)

        readonly property real u: Math.min(width, height) / 24
        readonly property real stroke: (2 / glyphRoot.u) * Globals.shellScale

        readonly property real glyphX: arcs.boundingRect.width > 0
            ? glyphRoot.width / 2 - (arcs.boundingRect.x + arcs.boundingRect.width / 2) * glyphRoot.u
            : (glyphRoot.width - 24 * glyphRoot.u) / 2
        readonly property real glyphY: arcs.boundingRect.height > 0
            ? glyphRoot.height / 2 - (arcs.boundingRect.y + arcs.boundingRect.height / 2) * glyphRoot.u
            : (glyphRoot.height - 24 * glyphRoot.u) / 2

        Shape {
            id: arcs

            width: 24
            height: 24
            scale: glyphRoot.u
            transformOrigin: Item.TopLeft
            x: glyphRoot.glyphX
            y: glyphRoot.glyphY
            antialiasing: true
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeColor: glyphRoot.litCount >= 1 ? glyphRoot.litColor : glyphRoot.unlitColor
                fillColor: "transparent"
                strokeWidth: glyphRoot.stroke
                capStyle: ShapePath.RoundCap
                PathSvg { path: "M9.17 13.17 A4 4 0 0 1 14.83 13.17" }
            }
            ShapePath {
                strokeColor: glyphRoot.litCount >= 2 ? glyphRoot.litColor : glyphRoot.unlitColor
                fillColor: "transparent"
                strokeWidth: glyphRoot.stroke
                capStyle: ShapePath.RoundCap
                PathSvg { path: "M6.34 10.34 A8 8 0 0 1 17.66 10.34" }
            }
            ShapePath {
                strokeColor: glyphRoot.litCount >= 3 ? glyphRoot.litColor : glyphRoot.unlitColor
                fillColor: "transparent"
                strokeWidth: glyphRoot.stroke
                capStyle: ShapePath.RoundCap
                PathSvg { path: "M3.5 7.5 A12 12 0 0 1 20.5 7.5" }
            }
            ShapePath {
                strokeColor: "transparent"
                fillColor: glyphRoot.litCount >= 1 ? glyphRoot.litColor : glyphRoot.unlitColor
                PathSvg { path: "M12 14.1 A1.5 1.5 0 0 1 12 17.1 A1.5 1.5 0 0 1 12 14.1z" }
            }
        }

        Shape {
            id: slash

            width: 24
            height: 24
            scale: glyphRoot.u
            transformOrigin: Item.TopLeft
            x: glyphRoot.glyphX
            y: glyphRoot.glyphY
            visible: !glyphRoot.on
            antialiasing: true
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeColor: Globals.colors.faint
                fillColor: "transparent"
                strokeWidth: (1.7 / glyphRoot.u) * Globals.shellScale
                capStyle: ShapePath.RoundCap
                PathSvg { path: "M4 3 L20 19" }
            }
        }
    }

    Component {
        id: wifiDelegate

        NetworkDevice {
            deviceType: "wifi"
            property bool isPendingConnect: Network.pendingConnectSsid === modelData.ssid
            property bool isPendingDisconnect: Network.pendingDisconnectSsid === modelData.ssid
            property bool isPendingForget: Network.pendingForgetSsid === modelData.ssid

            title: modelData.ssid

            subtitle: {
                if (isPendingConnect) return "Connecting...";
                if (isPendingDisconnect) return "Disconnecting...";
                if (isPendingForget) return "Forgetting...";
                if (modelData.active) return Network.linkDetail;
                return modelData.saved ? "Saved" : "";
            }

            isSecured: modelData.secured
            isKnown: modelData.known || modelData.active || isPendingConnect
            isConnected: modelData.active || isPendingConnect

            glyph: Component {
                WifiGlyph {
                    level: modelData.signal / 100
                    on: Network.wifiEnabled
                }
            }

            onConnectClicked: (password) => Network.connect(modelData.ssid, password)
            onDisconnectClicked: Network.disconnect()
            onActionClicked: Network.connect(modelData.ssid, "")
            onForgetClicked: Network.forget(modelData.ssid)
        }
    }
}
