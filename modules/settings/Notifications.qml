import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

SettingsPage {
    id: root

    title: "Notifications"
    description: "Notification behaviour, sounds, and display."

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Globals.geometry.spacing.large

        SettingsGroup {
            Layout.fillWidth: true

            SettingsRow {
                icon: "volume_up"
                label: "Sound Enabled"
                
                BaseSwitch {
                    checked: Preferences.notifications.soundEnabled
                    onToggled: Preferences.notifications.soundEnabled = checked
                }
            }

            SettingsRow {
                icon: "graphic_eq"
                label: "Volume"

                BaseSpinBox {
                    from: 0
                    to: 100
                    stepSize: 5
                    value: Preferences.notifications.soundVolume
                    suffix: "%"
                    onValueChanged: Preferences.notifications.soundVolume = value
                }
            }

            SettingsRow {
                icon: "timer"
                label: "Timeout"
                showSeparator: false

                BaseSpinBox {
                    from: 2
                    to: 8
                    stepSize: 1
                    value: Preferences.notifications.timeout / 1000
                    suffix: "s"
                    onValueChanged: Preferences.notifications.timeout = value * 1000
                }
            }
        }
    }
}
