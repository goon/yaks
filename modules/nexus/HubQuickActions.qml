import QtQuick
import QtQuick.Layouts
import qs

Item {
    id: root
    implicitHeight: mainCol.implicitHeight
    implicitWidth: mainCol.implicitWidth

    GridLayout {
        id: mainCol
        anchors.fill: parent
        columns: 2
        rowSpacing: Theme.geometry.spacing.medium
        columnSpacing: Theme.geometry.spacing.medium

    // Wi-Fi
        BaseButton {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            customRadius: Theme.geometry.radius * 1.5
            gradient: true
            selected: Network.wifiEnabled
            normalColor: Theme.alpha(Theme.colors.surface, Theme.opacity.surface)
            hoverColor: Theme.colors.background
            onClicked: IslandService.toggleNetworkPopout()

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.geometry.spacing.medium
                anchors.rightMargin: Theme.geometry.spacing.large
                spacing: Theme.geometry.spacing.medium

                // Album Art style Icon Bubble
                Item {
                    width: 48
                    height: 48
                    property bool active: Network.wifiEnabled

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Network.toggleWifi()
                    }

                    // Breathing Scale
                    property real breathScale: 1.0
                    SequentialAnimation {
                        loops: Animation.Infinite
                        running: parent.active
                        paused: !parent.active

                        NumberAnimation { target: parent; property: "breathScale"; to: 1.08; duration: 1200; easing.type: Easing.InOutSine }
                        NumberAnimation { target: parent; property: "breathScale"; to: 1.0;  duration: 1200; easing.type: Easing.InOutSine }
                    }

                    // Rotating Gradient Ring border
                    Canvas {
                        id: wifiRingCanvas
                        anchors.centerIn: parent
                        width: 48
                        height: 48
                        visible: parent.active

                        property int cornerRadius: Theme.geometry.radius
                        onCornerRadiusChanged: requestPaint()

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            var lw = 1.5;
                            var bw = 36, bh = 36;
                            var bx = (width - bw) / 2;
                            var by = (height - bh) / 2;
                            var r = Math.min(Theme.geometry.radius, bw / 2, bh / 2);
                            ctx.beginPath();
                            ctx.moveTo(bx + r, by);
                            ctx.lineTo(bx + bw - r, by);
                            ctx.arcTo(bx + bw, by, bx + bw, by + r, r);
                            ctx.lineTo(bx + bw, by + bh - r);
                            ctx.arcTo(bx + bw, by + bh, bx + bw - r, by + bh, r);
                            ctx.lineTo(bx + r, by + bh);
                            ctx.arcTo(bx, by + bh, bx, by + bh - r, r);
                            ctx.lineTo(bx, by + r);
                            ctx.arcTo(bx, by, bx + r, by, r);
                            ctx.closePath();
                            var grad = ctx.createLinearGradient(0, 0, width, height);
                            grad.addColorStop(0.0, Theme.colors.primary);
                            grad.addColorStop(1.0, Theme.colors.secondary);
                            ctx.strokeStyle = grad;
                            ctx.lineWidth = lw;
                            ctx.stroke();
                        }

                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()
                    }

                    Rectangle {
                        width: 36
                        height: 36
                        radius: Theme.geometry.radius
                        anchors.centerIn: parent
                        scale: parent.breathScale
                        color: parent.active ? Theme.alpha(Theme.colors.primary, 0.15) : Theme.alpha(Theme.colors.text, 0.1)
                        
                        BaseIcon {
                            anchors.centerIn: parent
                            icon: parent.active ? "wifi" : "wifi_off"
                            size: Theme.dimensions.iconBase
                            color: parent.active ? Theme.colors.primary : Theme.colors.text
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    BaseText {
                        text: "Wi-Fi"
                        pixelSize: Theme.typography.size.base
                        weight: Theme.typography.weights.medium
                        color: Theme.colors.text
                    }
                    BaseText {
                        text: Network.wifiEnabled ? Network.ssid : "Off"
                        pixelSize: Theme.typography.size.small
                        color: Theme.colors.muted
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                BaseIcon {
                    icon: "chevron_right"
                    size: Theme.dimensions.iconMedium
                    color: Theme.alpha(Theme.colors.text, 0.3)
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
        
        // Bluetooth
        BaseButton {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            customRadius: Theme.geometry.radius * 1.5
            gradient: true
            selected: Bluetooth.powered
            normalColor: Theme.alpha(Theme.colors.surface, Theme.opacity.surface)
            hoverColor: Theme.colors.background
            onClicked: IslandService.toggleBluetoothPopout()

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.geometry.spacing.large
                anchors.rightMargin: Theme.geometry.spacing.medium
                spacing: Theme.geometry.spacing.medium

                BaseIcon {
                    icon: "chevron_left"
                    size: Theme.dimensions.iconMedium
                    color: Theme.alpha(Theme.colors.text, 0.3)
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    BaseText {
                        text: "Bluetooth"
                        pixelSize: Theme.typography.size.base
                        weight: Theme.typography.weights.medium
                        color: Theme.colors.text
                        horizontalAlignment: Text.AlignRight
                        Layout.fillWidth: true
                    }
                    BaseText {
                        text: Bluetooth.powered ? (Bluetooth.connectedCount > 0 ? Bluetooth.connectedCount + " devices" : "On") : "Off"
                        pixelSize: Theme.typography.size.small
                        color: Theme.colors.muted
                        elide: Text.ElideLeft
                        horizontalAlignment: Text.AlignRight
                        Layout.fillWidth: true
                    }
                }

                Item {
                    width: 48
                    height: 48
                    property bool active: Bluetooth.powered

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Bluetooth.togglePower()
                    }

                    property real breathScale: 1.0
                    SequentialAnimation {
                        loops: Animation.Infinite
                        running: parent.active
                        paused: !parent.active

                        NumberAnimation { target: parent; property: "breathScale"; to: 1.08; duration: 1200; easing.type: Easing.InOutSine }
                        NumberAnimation { target: parent; property: "breathScale"; to: 1.0;  duration: 1200; easing.type: Easing.InOutSine }
                    }

                    Canvas {
                        id: btRingCanvas
                        anchors.centerIn: parent
                        width: 48
                        height: 48
                        visible: parent.active

                        property int cornerRadius: Theme.geometry.radius
                        onCornerRadiusChanged: requestPaint()

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            var lw = 1.5;
                            var bw = 36, bh = 36;
                            var bx = (width - bw) / 2;
                            var by = (height - bh) / 2;
                            var r = Math.min(Theme.geometry.radius, bw / 2, bh / 2);
                            ctx.beginPath();
                            ctx.moveTo(bx + r, by);
                            ctx.lineTo(bx + bw - r, by);
                            ctx.arcTo(bx + bw, by, bx + bw, by + r, r);
                            ctx.lineTo(bx + bw, by + bh - r);
                            ctx.arcTo(bx + bw, by + bh, bx + bw - r, by + bh, r);
                            ctx.lineTo(bx + r, by + bh);
                            ctx.arcTo(bx, by + bh, bx, by + bh - r, r);
                            ctx.lineTo(bx, by + r);
                            ctx.arcTo(bx, by, bx + r, by, r);
                            ctx.closePath();
                            var grad = ctx.createLinearGradient(0, 0, width, height);
                            grad.addColorStop(0.0, Theme.colors.primary);
                            grad.addColorStop(1.0, Theme.colors.secondary);
                            ctx.strokeStyle = grad;
                            ctx.lineWidth = lw;
                            ctx.stroke();
                        }

                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()
                    }

                    Rectangle {
                        width: 36
                        height: 36
                        radius: Theme.geometry.radius
                        anchors.centerIn: parent
                        scale: parent.breathScale
                        color: parent.active ? Theme.alpha(Theme.colors.primary, 0.15) : Theme.alpha(Theme.colors.text, 0.1)
                        
                        BaseIcon {
                            anchors.centerIn: parent
                            icon: parent.active ? "bluetooth" : "bluetooth_disabled"
                            size: Theme.dimensions.iconBase
                            color: parent.active ? Theme.colors.primary : Theme.colors.text
                        }
                    }
                }
            }
        }

        // DND
        BaseButton {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            customRadius: Theme.geometry.radius * 1.5
            gradient: true
            selected: Preferences.notificationMode === 1
            normalColor: Theme.alpha(Theme.colors.surface, Theme.opacity.surface)
            hoverColor: Theme.colors.background
            onClicked: Preferences.notificationMode = Preferences.notificationMode === 1 ? 0 : 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.geometry.spacing.medium
                anchors.rightMargin: Theme.geometry.spacing.large
                spacing: Theme.geometry.spacing.medium

                Item {
                    width: 48
                    height: 48
                    property bool active: Preferences.notificationMode === 1

                    property real breathScale: 1.0
                    SequentialAnimation {
                        loops: Animation.Infinite
                        running: parent.active
                        paused: !parent.active

                        NumberAnimation { target: parent; property: "breathScale"; to: 1.08; duration: 1200; easing.type: Easing.InOutSine }
                        NumberAnimation { target: parent; property: "breathScale"; to: 1.0;  duration: 1200; easing.type: Easing.InOutSine }
                    }

                    Canvas {
                        id: dndRingCanvas
                        anchors.centerIn: parent
                        width: 48
                        height: 48
                        visible: parent.active

                        property int cornerRadius: Theme.geometry.radius
                        onCornerRadiusChanged: requestPaint()

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            var lw = 1.5;
                            var bw = 36, bh = 36;
                            var bx = (width - bw) / 2;
                            var by = (height - bh) / 2;
                            var r = Math.min(Theme.geometry.radius, bw / 2, bh / 2);
                            ctx.beginPath();
                            ctx.moveTo(bx + r, by);
                            ctx.lineTo(bx + bw - r, by);
                            ctx.arcTo(bx + bw, by, bx + bw, by + r, r);
                            ctx.lineTo(bx + bw, by + bh - r);
                            ctx.arcTo(bx + bw, by + bh, bx + bw - r, by + bh, r);
                            ctx.lineTo(bx + r, by + bh);
                            ctx.arcTo(bx, by + bh, bx, by + bh - r, r);
                            ctx.lineTo(bx, by + r);
                            ctx.arcTo(bx, by, bx + r, by, r);
                            ctx.closePath();
                            var grad = ctx.createLinearGradient(0, 0, width, height);
                            grad.addColorStop(0.0, Theme.colors.primary);
                            grad.addColorStop(1.0, Theme.colors.secondary);
                            ctx.strokeStyle = grad;
                            ctx.lineWidth = lw;
                            ctx.stroke();
                        }

                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()
                    }

                    Rectangle {
                        width: 36
                        height: 36
                        radius: Theme.geometry.radius
                        anchors.centerIn: parent
                        scale: parent.breathScale
                        color: parent.active ? Theme.alpha(Theme.colors.primary, 0.15) : Theme.alpha(Theme.colors.text, 0.1)
                        
                        BaseIcon {
                            anchors.centerIn: parent
                            icon: parent.active ? "do_not_disturb_on" : "notifications"
                            size: Theme.dimensions.iconBase
                            color: parent.active ? Theme.colors.primary : Theme.colors.text
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    BaseText {
                        text: "Do Not Disturb"
                        pixelSize: Theme.typography.size.base
                        weight: Theme.typography.weights.medium
                        color: Theme.colors.text
                    }
                    BaseText {
                        text: Preferences.notificationMode === 1 ? "On" : "Off"
                        pixelSize: Theme.typography.size.small
                        color: Theme.colors.muted
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

            }
        }

        // Screen Record (Placeholder)
        BaseButton {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            customRadius: Theme.geometry.radius * 1.5
            gradient: true
            selected: false // Placeholder
            normalColor: Theme.alpha(Theme.colors.surface, Theme.opacity.surface)
            hoverColor: Theme.colors.background
            onClicked: { /* Placeholder hook */ }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.geometry.spacing.large
                anchors.rightMargin: Theme.geometry.spacing.medium
                spacing: Theme.geometry.spacing.medium

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    BaseText {
                        text: "Screen Record"
                        pixelSize: Theme.typography.size.base
                        weight: Theme.typography.weights.medium
                        color: Theme.colors.text
                        horizontalAlignment: Text.AlignRight
                        Layout.fillWidth: true
                    }
                    BaseText {
                        text: "Ready"
                        pixelSize: Theme.typography.size.small
                        color: Theme.colors.muted
                        horizontalAlignment: Text.AlignRight
                        Layout.fillWidth: true
                    }
                }

                Item {
                    width: 48
                    height: 48
                    property bool active: false

                    Rectangle {
                        width: 36
                        height: 36
                        radius: Theme.geometry.radius
                        anchors.centerIn: parent
                        color: parent.active ? Theme.alpha(Theme.colors.primary, 0.15) : Theme.alpha(Theme.colors.text, 0.1)
                        
                        BaseIcon {
                            anchors.centerIn: parent
                            icon: "screen_share"
                            size: Theme.dimensions.iconBase
                            color: parent.active ? Theme.colors.primary : Theme.colors.text
                        }
                    }
                }

            }
        }
    }
}
