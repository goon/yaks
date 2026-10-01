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
    // Optional custom icon (e.g. the wifi signal glyph). Wifi has no Lucide
    // equivalent for signal strength, so it hands the row a Component instead.
    property Component glyph: null
    property bool isConnected: false
    property bool isSecured: false
    property bool isKnown: false // For Wi-Fi or Bluetooth (paired/bonded/trusted)
    property real batteryPct: -1
    
    property bool expanded: false
    // A peripheral row is informational: no connect/disconnect/forget, so it
    // must not advertise an action it cannot perform.
    readonly property bool interactive: deviceType !== "peripheral"
    readonly property bool isHovered: mainMouseArea.containsMouse && root.interactive
    
    signal connectClicked(string password)
    signal disconnectClicked()
    signal forgetClicked()
    signal actionClicked()

    Rectangle {
        // Sized to the row, which is already taller than its text, so the tile
        // never reaches into the list gap above or below.
        anchors.fill: parent
        radius: Globals.innerRadius(Globals.geometry.spacing.sm)
        // The tile only shows under the pointer (or while the password drawer is
        // open, so the input never sits on a bare background).
        color: Globals.colors.hover
        opacity: root.isHovered || root.expanded ? 1 : 0
        Behavior on opacity { BaseMotion { duration: Globals.motion.hover } }
    }

    ColumnLayout {
        id: mainLayout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        Item {
            Layout.fillWidth: true
            // One step of air above and below the row's content, so the hover
            // tile (which is exactly this row's box) stands clear of its text.
            Layout.preferredHeight: innerRowLayout.implicitHeight + Globals.geometry.spacing.md * 2
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
                spacing: Globals.geometry.spacing.sm
                // Anchored, not layout-managed: Layout.*Margin would be ignored
                // here, so the inset that keeps content off the tile's edge is
                // an anchors margin.
                anchors.leftMargin: Globals.geometry.spacing.lg
                anchors.rightMargin: Globals.geometry.spacing.lg

                Item {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    Layout.alignment: Qt.AlignVCenter
                    visible: root.deviceType !== "wifi"

                    Rectangle {
                        anchors.fill: parent
                        radius: Globals.innerRadius(Globals.geometry.spacing.sm)
                        color: Globals.colors.deep
                        opacity: 0.75
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Globals.innerRadius(Globals.geometry.spacing.sm)
                        color: "transparent"
                        border.width: Globals.geometry.borderWidth.hair
                        border.color: Globals.colors.hair
                    }

                    BaseIcon {
                        anchors.centerIn: parent
                        icon: root.iconName
                        color: (root.isConnected || root.deviceType === "peripheral") ? Globals.colors.primary : (root.deviceType === "bluetooth" && root.isKnown ? Globals.colors.muted : (root.isHovered ? Globals.colors.primary : Globals.colors.text))
                        Behavior on color { BaseMotion { } }
                    }
                }

                ColumnLayout {
                    spacing: 2
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    Layout.fillWidth: true
                    Layout.leftMargin: root.deviceType === "wifi" ? Globals.geometry.spacing.xs : 0

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Globals.geometry.spacing.xs

                        BaseText {
                            text: root.title
                            pixelSize: Globals.typography.size.md
                            weight: root.isConnected ? Globals.typography.weight.demi : Globals.typography.weight.normal
                            font.capitalization: Font.AllUppercase
                            color: root.isConnected ? Globals.colors.primary : (root.isHovered ? Globals.colors.primary : Globals.colors.text)
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            Layout.fillWidth: true
                            Behavior on color { BaseMotion { } }
                        }

                        RowLayout {
                            visible: deviceType === "wifi" && (root.isSecured || root.isKnown || root.glyph !== null)
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            spacing: Globals.geometry.spacing.sm

                            BaseIcon {
                                icon: "heart"
                                size: Globals.typography.icon.sm
                                color: Globals.colors.muted
                                visible: root.isKnown
                            }

                            BaseIcon {
                                icon: "lock"
                                size: Globals.typography.icon.sm
                                color: Globals.colors.muted
                                visible: root.isSecured
                            }

                            Loader {
                                Layout.alignment: Qt.AlignVCenter
                                // Signal arcs read light next to the 16px badge
                                // icons, so the glyph gets a small bump.
                                width: Globals.typography.icon.lg + Globals.geometry.spacing.xs
                                height: width
                                visible: root.glyph !== null
                                sourceComponent: root.glyph
                            }
                        }

                        BaseText {
                            visible: root.batteryPct >= 0
                            Layout.alignment: Qt.AlignVCenter
                            text: Math.round(root.batteryPct) + "%"
                            pixelSize: Globals.typography.size.lg
                        }
                    }

                    BaseSlider {
                        visible: root.batteryPct >= 0
                        Layout.fillWidth: true
                        Layout.topMargin: Globals.geometry.spacing.xs
                        interactive: false
                        roundActiveEnd: true
                        trackHeight: 6 * Globals.shellScale
                        value: root.batteryPct
                        from: 0
                        to: 100
                    }

                    BaseText {
                        text: root.subtitle
                        visible: root.subtitle !== ""
                        pixelSize: Globals.typography.size.sm
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
            Layout.preferredHeight: root.expanded ? drawerBox.implicitHeight + Globals.geometry.spacing.xs : 0
            clip: true
            visible: deviceType === "wifi" && root.isSecured && !root.isConnected && !root.isKnown

            Item {
                id: drawerBox
                anchors.top: parent.top
                anchors.topMargin: Globals.geometry.spacing.xs
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Globals.geometry.spacing.xs
                anchors.left: parent.left
                anchors.leftMargin: Globals.geometry.spacing.lg
                anchors.right: parent.right
                anchors.rightMargin: Globals.geometry.spacing.lg
                implicitHeight: innerLayout.implicitHeight

                function _submit() {
                    if (passwordInput.text.length > 0) {
                        root.connectClicked(passwordInput.text);
                        passwordInput.text = "";
                        root.expanded = false;
                    }
                }

                RowLayout {
                    id: innerLayout
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Globals.geometry.spacing.sm

                    BaseInput {
                        id: passwordInput
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        leftPadding: 0
                        placeholderText: "Password"
                        echoMode: TextInput.Password
                        onAccepted: drawerBox._submit()
                    }

                    BaseIcon {
                        icon: "corner-down-left"
                        size: Globals.typography.icon.md
                        color: Globals.colors.primary

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: drawerBox._submit()
                        }
                    }
                }
            }

            Behavior on Layout.preferredHeight { BaseMotion { duration: Globals.motion.standard } }
        }
    }
}
