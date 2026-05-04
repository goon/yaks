import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

BasePopoutWindow {
    id: root

    panelNamespace: "quickshell:power-popout"

    body: ScrollView {
        implicitWidth: 450 // Slightly narrower for just power actions
        implicitHeight: mainLayout.implicitHeight
        contentWidth: availableWidth
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            id: mainLayout

            width: parent.width
            spacing: Theme.geometry.spacing.large
            padding: Theme.geometry.spacing.dynamicPadding

            BaseBlock {
                id: powerSection
                Layout.fillWidth: true

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.geometry.spacing.dynamicPadding

                    BaseButton {
                        Layout.fillWidth: true
                        icon: "power_settings_new"
                        iconSize: Theme.dimensions.iconLarge
                        hoverEnabled: false
                        hoverRotate: true
                        onClicked: {
                            root.close();
                            Power.shutdown();
                        }
                    }

                    BaseButton {
                        Layout.fillWidth: true
                        icon: "restart_alt"
                        iconSize: Theme.dimensions.iconLarge
                        hoverEnabled: false
                        hoverRotate: true
                        onClicked: {
                            root.close();
                            Power.reboot();
                        }
                    }

                    BaseButton {
                        Layout.fillWidth: true
                        icon: "bedtime"
                        iconSize: Theme.dimensions.iconLarge
                        hoverEnabled: false
                        hoverRotate: true
                        onClicked: {
                            root.close();
                            Power.suspend();
                        }
                    }

                    BaseButton {
                        Layout.fillWidth: true
                        icon: "logout"
                        iconSize: Theme.dimensions.iconLarge
                        hoverEnabled: false
                        hoverRotate: true
                        onClicked: {
                            root.close();
                            Power.logout();
                        }
                    }

                    BaseButton {
                        Layout.fillWidth: true
                        icon: "settings_suggest"
                        iconSize: Theme.dimensions.iconLarge
                        hoverEnabled: false
                        hoverRotate: true
                        onClicked: {
                            root.close();
                            Power.rebootToBios();
                        }
                    }
                }
            }
        }
    }
}
