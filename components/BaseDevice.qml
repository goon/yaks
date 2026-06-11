import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

BaseBlock {
    id: root

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
    
    // Signals
    signal connectClicked(string password)
    signal disconnectClicked()
    signal forgetClicked()
    signal actionClicked()

    Layout.fillWidth: true
    paddingHorizontal: Theme.geometry.spacing.dynamicPadding
    paddingVertical: Theme.geometry.spacing.dynamicPadding
    spacing: 0
    borderWidth: 0
    property bool isEffectivelyHovered: containsMouse || (actionConnectBtn && actionConnectBtn.hovered) || (actionForgetBtn && actionForgetBtn.hovered)
    
    backgroundColor: (isEffectivelyHovered || expanded) ? Theme.colors.surface : Theme.colors.transparent
    clickable: true
    premiumHover: true
    premiumActive: expanded || (isEffectivelyHovered && !expanded)

    onClicked: {
        if (deviceType === "wifi" && isSecured && !isConnected) {
            expanded = !expanded;
            if (expanded) {
                passwordInput.forceActiveFocus();
            }
        } else {
            actionClicked();
        }
    }

    // Main Card Content
    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.geometry.spacing.medium

        // Left Icon
        BaseIcon {
            icon: root.iconName
            size: Theme.dimensions.iconMedium
            color: (root.containsMouse || root.expanded) ? Theme.colors.primary : (deviceType === "bluetooth" ? Theme.colors.muted : Theme.colors.text)
            opacity: root.iconOpacity
            Layout.preferredWidth: 20
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
        }

        // Title and Subtitle
        ColumnLayout {
            spacing: 2
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

            BaseText {
                text: root.title
                weight: (root.containsMouse || root.expanded) ? Theme.typography.weights.bold : Theme.typography.weights.normal
                color: (root.containsMouse || root.expanded) ? (deviceType === "bluetooth" ? Theme.colors.text : Theme.colors.textLighter) : (deviceType === "bluetooth" ? Theme.colors.muted : Theme.colors.text)
                pixelSize: Theme.typography.size.base
                elide: Text.ElideRight
            }

            BaseText {
                text: root.subtitle
                visible: root.subtitle !== ""
                pixelSize: Theme.typography.size.small
                color: root.containsMouse ? Theme.alpha(Theme.colors.text, 0.7) : Theme.colors.muted
            }
        }

        Item { Layout.fillWidth: true }

        // Trailing Content (Wi-Fi Signal / Bluetooth Buttons)
        RowLayout {
            spacing: Theme.geometry.spacing.medium
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

            // Wi-Fi Status Badge (Fixed Width Pill)
            Rectangle {
                visible: deviceType === "wifi" && (root.isSecured || root.signalText !== "")
                Layout.fillHeight: true
                Layout.preferredWidth: 64
                radius: Theme.geometry.radius
                color: Theme.alpha(Theme.colors.text, 0.05)
                border.width: 1
                border.color: Theme.alpha(Theme.colors.text, 0.1)

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    BaseIcon {
                        icon: "lock"
                        size: 12
                        color: Theme.colors.muted
                        visible: root.isSecured
                    }

                    BaseText {
                        text: root.signalText
                        pixelSize: 10
                        weight: Theme.typography.weights.bold
                        color: Theme.colors.muted
                        visible: root.signalText !== ""
                    }
                }
            }

            // Universal Connect/Disconnect Button
            BaseButton {
                id: actionConnectBtn
                text: root.isConnecting ? "Connecting" : (root.isConnected ? "Disconnect" : "Connect")
                textSize: 10
                textWeight: Theme.typography.weights.bold
                textColor: root.isConnected ? Theme.colors.error : Theme.colors.text
                paddingHorizontal: Theme.geometry.spacing.dynamicPadding
                paddingVertical: Theme.geometry.spacing.medium
                
                borderWidth: root.isConnected ? 1 : 0
                borderColor: root.isConnected ? Theme.alpha(Theme.colors.text, 0.1) : "transparent"
                normalColor: root.isConnected ? Theme.alpha(Theme.colors.text, 0.05) : Theme.colors.transparent
                
                Item {
                    anchors.fill: parent
                    z: -1
                    visible: !root.isConnected
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.geometry.radius
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: Theme.colors.primary }
                            GradientStop { position: 1; color: Theme.colors.secondary }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1.5
                        radius: Math.max(0, Theme.geometry.radius - 1.5)
                        color: Theme.colors.background
                    }
                }

                onClicked: {
                    if (root.isConnected) {
                        root.disconnectClicked();
                    } else if (deviceType === "wifi" && root.isSecured) {
                        root.expanded = !root.expanded;
                        if (root.expanded) {
                            passwordInput.forceActiveFocus();
                        }
                    } else {
                        root.actionClicked();
                    }
                }
            }

            // Universal Forget Button
            BaseButton {
                id: actionForgetBtn
                visible: root.isKnown
                text: "Forget"
                textSize: 10
                textWeight: Theme.typography.weights.bold
                textColor: Theme.colors.textLighter
                paddingHorizontal: Theme.geometry.spacing.dynamicPadding
                paddingVertical: Theme.geometry.spacing.medium
                
                borderWidth: 1
                borderColor: Theme.alpha(Theme.colors.text, 0.1)
                normalColor: Theme.alpha(Theme.colors.text, 0.05)
                
                onClicked: root.forgetClicked()
            }
        }
    }

    // Expandable Drawer (Wi-Fi specific)
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: root.expanded ? passwordBox.implicitHeight + Theme.geometry.spacing.dynamicPadding : 0
        state: root.expanded ? "expanded" : "collapsed"
        clip: true
        visible: deviceType === "wifi"

        Rectangle {
            id: passwordBox
            anchors.top: parent.top
            anchors.topMargin: Theme.geometry.spacing.dynamicPadding
            anchors.left: parent.left
            anchors.right: parent.right
            color: Theme.colors.background // Recessed dark box
            border.width: 1
            border.color: Theme.alpha(Theme.colors.border, 0.5)
            radius: Theme.geometry.radius
            implicitHeight: innerLayout.implicitHeight + (Theme.geometry.spacing.large * 2)

            RowLayout {
                id: innerLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Theme.geometry.spacing.large
                spacing: Theme.geometry.spacing.medium

                BaseInput {
                    id: passwordInput
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    borderRadius: Theme.geometry.radius
                    borderWidth: 0
                    backgroundColor: Theme.alpha(Theme.colors.surface, 0.3)
                    placeholderText: "Enter Wi-Fi network password..."
                    echoMode: TextInput.Password
                    onAccepted: connectBtn.clicked()
                }

                BaseButton {
                    text: "Cancel"
                    Layout.preferredHeight: 36
                    paddingHorizontal: 16
                    borderWidth: 1
                    borderColor: Theme.alpha(Theme.colors.text, 0.1)
                    normalColor: Theme.alpha(Theme.colors.text, 0.05)
                    textColor: Theme.colors.text
                    onClicked: {
                        root.expanded = false;
                        passwordInput.text = "";
                    }
                }

                BaseButton {
                    id: connectBtn
                    text: "Connect"
                    Layout.preferredHeight: 36
                    paddingHorizontal: 20
                    normalColor: Theme.colors.transparent
                    hoverColor: Theme.alpha(Theme.colors.text, 0.1)
                    textColor: Theme.colors.text
                    textWeight: Theme.typography.weights.bold

                    Item {
                        anchors.fill: parent
                        z: -1
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.geometry.radius
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: Theme.colors.primary }
                                GradientStop { position: 1; color: Theme.colors.secondary }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 1.5
                            radius: Math.max(0, Theme.geometry.radius - 1.5)
                            color: Theme.colors.background
                        }
                    }

                    onClicked: {
                        if (passwordInput.text.length > 0) {
                            root.connectClicked(passwordInput.text);
                            root.expanded = false;
                            passwordInput.text = "";
                        }
                    }
                }
            }
        }

        Behavior on Layout.preferredHeight { BaseAnimation { duration: 200 } }
    }
}
