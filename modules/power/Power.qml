import QtQuick
import QtQuick.Layouts
import qs
import ".."

BaseContainer {
    id: root
    spacing: 0
    implicitWidth: 240

    property Item activeHover: null

    component PowerButton: BaseButton {
        id: btn

        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 0
        hoverEnabled: true

        property string actionIcon: ""
        property string actionLabel: ""
        
        property real holdProgress: 0.0
        signal actionTriggered()

        onContainsMouseChanged: {
            if (containsMouse) root.activeHover = btn;
            else if (root.activeHover === btn) root.activeHover = null;
        }

        onPressedChanged: {
            if (pressed) {
                holdAnim.restart()
            } else {
                holdAnim.stop()
                holdAnimReverse.restart()
            }
        }

        NumberAnimation {
            id: holdAnim
            target: btn
            property: "holdProgress"
            to: 1.0
            duration: Globals.motion.heat
            easing.type: Easing.InOutQuad
        }

        NumberAnimation {
            id: holdAnimReverse
            target: btn
            property: "holdProgress"
            to: 0.0
            duration: Globals.motion.hover
            easing.type: Easing.OutQuad
        }

        onHoldProgressChanged: {
            if (holdProgress >= 1.0 && pressed) {
                btn.actionTriggered()
                holdAnim.stop()
                holdProgress = 0.0
            }
        }

        Item {
            anchors.fill: parent

            RowLayout {
                anchors.fill: parent
                spacing: Globals.geometry.spacing.medium
                
                Item {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    Layout.alignment: Qt.AlignVCenter
                    
                    BaseIcon {
                        anchors.centerIn: parent
                        icon: btn.actionIcon
                        size: Globals.dimensions.iconMedium
                        color: btn.containsMouse ? Globals.colors.primary : Globals.colors.text
                        Behavior on color { BaseMotion { } }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: baseText.implicitHeight
                        
                        BaseText {
                            id: baseText
                            text: btn.actionLabel
                            color: Globals.colors.text
                            font.weight: Globals.typography.weights.medium
                            font.pixelSize: Globals.typography.size.large
                            Behavior on color { BaseMotion { } }
                        }

                    }

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: btn.containsMouse ? subtitleText.implicitHeight : 0
                        clip: true
                        opacity: btn.containsMouse ? 1.0 : 0.0
                        Behavior on opacity { BaseMotion { } }

                        BaseText {
                            id: subtitleText
                            anchors.top: parent.top
                            anchors.left: parent.left
                            text: "Hold to " + btn.actionLabel.toLowerCase()
                            pixelSize: Globals.typography.size.medium
                            muted: true
                        }

                        Item {
                            id: revealClip
                            x: 0
                            y: 0
                            height: subtitleText.height
                            width: subtitleText.width * btn.holdProgress
                            clip: true

                            BaseText {
                                id: subtitleColoredText
                                anchors.top: subtitleText.top
                                anchors.left: subtitleText.left
                                text: subtitleText.text
                                pixelSize: Globals.typography.size.medium
                                color: Globals.colors.text
                            }
                        }
                    }
                }
            }
        }
    }

    readonly property var _actions: [
        { label: "Shutdown", icon: "power",       onClicked: function() { IslandService.closeAll(); Power.shutdown(); } },
        { label: "Restart",  icon: "rotate-cw",   onClicked: function() { IslandService.closeAll(); Power.reboot(); } },
        { label: "Sleep",    icon: "moon",        onClicked: function() { IslandService.closeAll(); Power.suspend(); } },
        { label: "Logout",   icon: "log-out",     onClicked: function() { IslandService.closeAll(); Compositor.quit(); } },
    ]

    Item {
        Layout.fillWidth: true
        implicitHeight: layout.implicitHeight

        ColumnLayout {
            id: layout
            anchors.fill: parent

        BaseHeader {
            text: "POWER"
            isActive: root.activeHover !== null
            Layout.bottomMargin: Globals.geometry.spacing.large
        }

        BaseSeparator {
            Layout.fillWidth: true
            Layout.bottomMargin: Globals.geometry.spacing.large
        }

        Repeater {
            model: root._actions
            delegate: PowerButton {
                Layout.fillWidth: true
                implicitHeight: 56
                actionIcon: modelData.icon
                actionLabel: modelData.label
                onActionTriggered: modelData.onClicked()
            }
        }
    }

        BaseIndicator {
            hoverPredicate: function() { return root.activeHover }
        }
    }
}
