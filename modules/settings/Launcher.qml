import QtQuick
import QtQuick.Layouts
import qs

SettingsPage {
    id: root

    title: "Launcher"
    description: "Configure launcher behaviors."

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Globals.geometry.spacing.large

        SettingsGroup {
            Layout.fillWidth: true

            SettingsRow {
                icon: "file-text"
                label: "App Descriptions"
                showSeparator: false

                BaseSwitch {
                    checked: Preferences.launcher.showAppDescriptions
                    onToggled: Preferences.launcher.showAppDescriptions = checked
                }
            }
        }
    }
}
