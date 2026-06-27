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

    // Core Properties
    property string deviceType: "bluetooth" // "bluetooth" | "wifi"
    
    // Display Properties
    property string title: ""
    property string subtitle: ""
    property string iconName: "bluetooth"
    property real iconOpacity: 1.0
    property string signalText: ""
    
    // State Properties
    property bool isConnected: false
    property bool isConnecting: false
    property bool isSecured: false
    property bool isKnown: false // For Wi-Fi or Bluetooth (paired/bonded/trusted)
    
    // Internal State
    property bool expanded: false
    readonly property bool isHovered: mainMouseArea.containsMouse
    
    // Signals
    signal connectClicked(string password)
    signal disconnectClicked()
    signal forgetClicked()
    signal actionClicked()

    ColumnLayout {
        id: mainLayout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        // Main Row Container
        Item {
            id: rowContainer
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            implicitWidth: innerRowLayout.implicitWidth

            MouseArea {
                id: mainMouseArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
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
                        // Bluetooth
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
                spacing: Theme.geometry.spacing.medium



                // Icon Slot
                Item {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    Layout.alignment: Qt.AlignVCenter
                    
                    BaseIcon {
                        anchors.centerIn: parent
                        icon: root.iconName
                        color: root.isConnected ? Theme.colors.success : (root.deviceType === "bluetooth" && root.isKnown ? Theme.colors.warning : (root.isHovered ? Theme.colors.primary : Theme.colors.text))
                        opacity: root.iconOpacity
                        Behavior on color { BaseAnimation { } }
                    }
                }

                // Title and Subtitle
                ColumnLayout {
                    spacing: 2
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    Layout.fillWidth: true

                    BaseText {
                        text: root.title
                        weight: root.isConnected ? Theme.typography.weights.bold : Theme.typography.weights.medium
                        color: root.isConnected ? Theme.colors.primary : (root.isHovered ? Theme.colors.primary : Theme.colors.text)
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                        Layout.fillWidth: true
                        Behavior on color { BaseAnimation { } }
                    }

                    BaseText {
                        text: root.subtitle
                        visible: root.subtitle !== ""
                        pixelSize: Theme.typography.size.small
                        muted: true
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                        Layout.fillWidth: true
                    }
                }

                // Wi-Fi Status Badge (Fixed Width Pill)
                Rectangle {
                    visible: deviceType === "wifi" && (root.isSecured || root.isKnown)
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    Layout.preferredHeight: 28
                    Layout.preferredWidth: 48
                    radius: Theme.geometry.innerRadius.medium
                    color: Theme.alpha(Theme.colors.text, 0.05)
                    border.width: 1
                    border.color: Theme.alpha(Theme.colors.text, 0.1)

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        BaseIcon {
                            icon: "lock"
                            size: 12
                            visible: root.isSecured
                        }

                        BaseIcon {
                            icon: "heart_check"
                            size: 14
                            visible: root.isKnown
                        }
                    }
                }
            }
        }

        // Expandable Drawer (Wi-Fi specific)
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.expanded ? drawerBox.implicitHeight + Theme.geometry.padding.medium : 0
            state: root.expanded ? "expanded" : "collapsed"
            clip: true
            visible: deviceType === "wifi" && root.isSecured && !root.isConnected && !root.isKnown

            Rectangle {
                id: drawerBox
                anchors.top: parent.top
                anchors.topMargin: Theme.geometry.padding.medium
                anchors.left: parent.left
                anchors.right: parent.right
                color: Theme.colors.background
                border.width: 1
                border.color: Theme.alpha(Theme.colors.border, 0.5)
                radius: Theme.geometry.innerRadius.medium
                implicitHeight: innerLayout.implicitHeight + (Theme.geometry.spacing.large * 2)

                RowLayout {
                    id: innerLayout
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Theme.geometry.spacing.large
                    spacing: Theme.geometry.spacing.medium

                    // Password Input
                    BaseInput {
                        id: passwordInput
                        visible: root.isSecured && !root.isConnected && !root.isKnown
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

            Behavior on Layout.preferredHeight { BaseAnimation { duration: 200 } }
        }
    }
}
