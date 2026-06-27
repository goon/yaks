import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

SettingsPage {
    id: root

    title: "Clipboard"
    description: "Clipboard history, sync, and behaviour."

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
