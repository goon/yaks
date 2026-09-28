import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

SettingsPage {
    id: root

    title: "Notifications"

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Globals.geometry.spacing.large

        SettingsGroup {
            Layout.fillWidth: true

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
