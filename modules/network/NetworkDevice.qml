import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

Item {
    id: root

    implicitHeight: mainLayout.implicitHeight
    implicitWidth: mainLayout.implicitWidth
    Layout.fillWidth: true

    property string deviceType: "bluetooth" // "bluetooth" | "wifi" | "peripheral"
    
    property string title: ""
    property string subtitle: ""
    property string iconName: "bluetooth"
    property bool isConnected: false
    property bool isSecured: false
    property bool isKnown: false // For Wi-Fi or Bluetooth (paired/bonded/trusted)
    property real batteryPct: -1
    property string badge: ""
    property string actionText: ""
    
    property bool expanded: false
    // A peripheral row is informational: no connect/disconnect/forget, so it
    // must not advertise an action it cannot perform.
    readonly property bool interactive: deviceType !== "peripheral"
    readonly property bool isHovered: mainMouseArea.containsMouse && root.interactive
    
    signal connectClicked(string password)
    signal disconnectClicked()
    signal forgetClicked()
    signal actionClicked()

    ColumnLayout {
        id: mainLayout
        anchors.left: parent.left
        anchors.right: parent.right

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: innerRowLayout.implicitHeight
            implicitWidth: innerRowLayout.implicitWidth

            MouseArea {
                id: mainMouseArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: root.interactive ? (Qt.LeftButton | Qt.RightButton) : Qt.NoButton
                cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        if (root.isKnown || root.isConnected) {
                            root.forgetClicked();
                        }
                        return;
                    }

                    if (deviceType === "wifi") {
                        if (root.isSecured && !root.isConnected && !root.isKnown) {
                            root.expanded = !root.expanded;
                            if (root.expanded) {
                                passwordInput.forceActiveFocus();
                            }
                        } else {
                            if (root.isConnected) {
                                root.disconnectClicked();
                            } else {
                                root.actionClicked();
                            }
                        }
                    } else {
                        if (root.isConnected) {
                            root.disconnectClicked();
                        } else {
                            root.actionClicked(); // connect
                        }
                    }
                }
            }

            RowLayout {
                id: innerRowLayout
                anchors.fill: parent
                spacing: Globals.geometry.spacing.medium

                Item {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        anchors.fill: parent
                        visible: root.deviceType !== "wifi"
                        radius: Globals.geometry.innerRadius.medium
                        color: Globals.colors.deep
                        opacity: 0.75
                    }

                    BaseIcon {
                        anchors.centerIn: parent
                        icon: root.iconName
                        color: root.isConnected ? Globals.colors.primary : (root.deviceType === "bluetooth" && root.isKnown ? Globals.colors.muted : (root.isHovered ? Globals.colors.primary : Globals.colors.text))
                        Behavior on color { BaseMotion { } }
                    }
                }

                ColumnLayout {
                    spacing: 2
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    Layout.fillWidth: true

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Globals.geometry.spacing.small

                        BaseText {
                            text: root.title
                            weight: root.isConnected ? Globals.typography.weights.bold : Globals.typography.weights.medium
                            color: root.isConnected ? Globals.colors.primary : (root.isHovered ? Globals.colors.primary : Globals.colors.text)
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            Layout.fillWidth: true
                            Behavior on color { BaseMotion { } }
                        }

                        Rectangle {
                            visible: root.badge !== ""
                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: badgeText.implicitWidth + Globals.geometry.spacing.small * 2
                            implicitHeight: badgeText.implicitHeight + Globals.geometry.spacing.small / 2
                            radius: height / 2
                            color: Globals.colors.hover
                            border.width: 1
                            border.color: Globals.colors.hair

                            BaseText {
                                id: badgeText
                                anchors.centerIn: parent
                                text: root.badge
                                pixelSize: Globals.typography.size.small
                                muted: true
                            }
                        }

                        Rectangle {
                            visible: deviceType === "wifi" && (root.isSecured || root.isKnown)
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            Layout.preferredHeight: 28
                            Layout.preferredWidth: 48
                            radius: Globals.geometry.innerRadius.medium
                            color: Globals.colors.hover
                            border.width: 1
                            border.color: Globals.colors.hair

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 4

                                BaseIcon {
                                    icon: "lock"
                                    size: Globals.dimensions.iconSmall
                                    visible: root.isSecured
                                }

                                BaseIcon {
                                    icon: "heart-pulse"
                                    size: Globals.dimensions.iconSmall
                                    visible: root.isKnown
                                }
                            }
                        }

                        BaseText {
                            visible: root.batteryPct >= 0
                            Layout.alignment: Qt.AlignVCenter
                            text: Math.round(root.batteryPct) + "%"
                            weight: Globals.typography.weights.bold
                        }

                        BaseButton {
                            visible: root.actionText !== ""
                            Layout.alignment: Qt.AlignVCenter
                            text: root.actionText
                            border.width: 1
                            border.color: Globals.colors.hair
                            onClicked: root.actionClicked()
                        }
                    }

                    BaseSlider {
                        visible: root.batteryPct >= 0
                        Layout.fillWidth: true
                        interactive: false
                        trackHeight: Globals.geometry.spacing.small
                        value: root.batteryPct
                        from: 0
                        to: 100
                    }

                    BaseText {
                        text: root.subtitle
                        visible: root.subtitle !== ""
                        pixelSize: Globals.typography.size.small
                        muted: true
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                        Layout.fillWidth: true
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.expanded ? drawerBox.implicitHeight + Globals.geometry.padding.medium : 0
            clip: true
            visible: deviceType === "wifi" && root.isSecured && !root.isConnected && !root.isKnown

            Rectangle {
                id: drawerBox
                anchors.top: parent.top
                anchors.topMargin: Globals.geometry.padding.medium
                anchors.left: parent.left
                anchors.right: parent.right
                color: Globals.colors.raised
                border.width: 1
                border.color: Globals.colors.hair
                radius: Globals.geometry.innerRadius.medium
                implicitHeight: innerLayout.implicitHeight + (Globals.geometry.spacing.large * 2)

                RowLayout {
                    id: innerLayout
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Globals.geometry.spacing.large
                    spacing: Globals.geometry.spacing.medium

                    BaseInput {
                        id: passwordInput
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        placeholderText: "Network password..."
                        echoMode: TextInput.Password
                        onAccepted: {
                            if (text.length > 0) {
                                root.connectClicked(text);
                                text = "";
                                root.expanded = false;
                            }
                        }
                    }
                }
            }

            Behavior on Layout.preferredHeight { BaseMotion { duration: Globals.motion.standard } }
        }
    }
}
