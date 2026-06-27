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
        spacing: Theme.geometry.spacing.large

        SettingsGroup {
            Layout.fillWidth: true

            SettingsRow {
                icon: "construction"
                label: "Coming Soon"
                showSeparator: false
            }
        }
    }
}
