import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs
import qs.services

SettingsPage {
    id: root

    title: "Wallpaper & Effects"
    description: "Configure your desktop background and dynamic theming."

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Theme.geometry.spacing.large

        SettingsGroup {
            Layout.fillWidth: true

            SettingsRow {
                icon: "palette"
                label: "Gowall"

                BaseSwitch {
                    checked: Preferences.wallpaper.gowallEnabled
                    onToggled: Preferences.wallpaper.gowallEnabled = checked
                }
            }

            SettingsRow {
                icon: "open_with"
                label: "Parallax"

                BaseSpinBox {
                    from: 0
                    to: 100
                    stepSize: 1
                    value: Preferences.wallpaper.parallaxStrength
                    suffix: "px"
                    onValueChanged: Preferences.wallpaper.parallaxStrength = value
                }
            }

            SettingsRow {
                icon: "folder"
                label: "Directory"
                showSeparator: false

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.geometry.spacing.small

                    BaseText {
                        Layout.fillWidth: true
                        wrapMode: Text.NoWrap
                        text: Preferences.wallpaper.directory || "No directory selected"
                        color: Preferences.wallpaper.directory ? Theme.colors.text : Theme.colors.muted
                        elide: Text.ElideMiddle
                    }

                    BaseButton {
                        icon: "folder"
                        text: "Browse"
                        onClicked: {
                            Zenity.selectFolder(function(path) {
                                Preferences.wallpaper.directory = path;
                            });
                        }
                    }
                }
            }
        }

        // Warning when no directory is set
        RowLayout {
            visible: Preferences.wallpaper.directory === ""
            Layout.fillWidth: true
            spacing: Theme.geometry.spacing.small

            BaseIcon {
                icon: "warning"
                color: Theme.colors.warning
            }

            BaseText {
                text: "No Wallpaper Directory Set: The wallpaper gallery is disabled until you select a folder containing images."
                pixelSize: Theme.typography.size.medium
                color: Theme.colors.warning
                Layout.fillWidth: true
            }
        }
    }
}
