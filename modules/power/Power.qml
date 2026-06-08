import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

FocusScope {
    id: root

    property string panelState: "Closed"

    implicitWidth: 410
    implicitHeight: 260

    ScrollView {
        anchors.fill: parent
        implicitHeight: mainLayout.implicitHeight
        contentWidth: availableWidth
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            id: mainLayout

            width: parent.width
            spacing: Theme.geometry.spacing.large

            BaseBlock {
                Layout.fillWidth: true
                spacing: Theme.geometry.spacing.large
                paddingVertical: Theme.geometry.spacing.large

                BaseText {
                    text: "DISPLAY"
                    color: Theme.colors.muted
                    pixelSize: Theme.typography.size.base
                    weight: Theme.typography.weights.bold
                    Layout.alignment: Qt.AlignHCenter
                    font.letterSpacing: 2
                }

                BaseSlider {
                    id: brightnessSlider
                    Layout.fillWidth: true
                    trackHeight: 38
                    value: Display.brightness
                    icon: "light_mode"
                    suffix: Math.round(Display.brightness * 100)
                    iconColor: Theme.colors.text
                    suffixColor: Theme.colors.text
                    iconSize: Theme.dimensions.iconMedium
                    from: 0
                    to: 1
                    stepSize: 0.01
                    onValueChangedByUser: Display.setBrightness(value)

                    Binding on value {
                        value: Display.brightness
                        when: !brightnessSlider.pressed
                        restoreMode: Binding.RestoreBinding
                    }
                }
            }

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
                            IslandService.closeAll();
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
                            IslandService.closeAll();
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
                            IslandService.closeAll();
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
                            IslandService.closeAll();
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
                            IslandService.closeAll();
                            Power.rebootToBios();
                        }
                    }
                }
            }
        }
    }
}
