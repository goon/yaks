import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

SettingsPage {
    id: root

    title: "Launcher"

    ColumnLayout {
        width: parent.width
        spacing: Theme.geometry.spacing.large

        // --- SECTION 1: General Settings ---
        GridLayout {
            columns: 2
            rowSpacing: Theme.geometry.spacing.dynamicPadding
            columnSpacing: Theme.geometry.spacing.dynamicPadding
            Layout.fillWidth: true

            BaseText {
                text: "Configure search engines, default terminal, and launcher behaviors."
                color: Theme.colors.text
                pixelSize: Theme.typography.size.medium
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.columnSpan: 2
                Layout.bottomMargin: Theme.geometry.spacing.small
            }

            BaseText {
                text: "Web Search URL:"
                pixelSize: Theme.typography.size.medium
            }
            BaseInput {
                Layout.fillWidth: true
                implicitHeight: 42
                inputPadding: 10
                text: Preferences.webSearchUrl
                placeholderText: "e.g. https://google.com/search?q="
                onEditingFinished: Preferences.webSearchUrl = text
            }

            BaseText {
                text: "Terminal:"
                pixelSize: Theme.typography.size.medium
            }
            BaseInput {
                Layout.fillWidth: true
                implicitHeight: 42
                inputPadding: 10
                text: Preferences.terminal
                placeholderText: "e.g. alacritty"
                onEditingFinished: Preferences.terminal = text
            }

            BaseText {
                text: "Global Prefix:"
                pixelSize: Theme.typography.size.medium
            }
            BaseInput {
                Layout.fillWidth: true
                implicitHeight: 42
                inputPadding: 10
                text: Preferences.launcherGlobalPrefix
                placeholderText: "e.g. >"
                onEditingFinished: Preferences.launcherGlobalPrefix = text
            }

            BaseText {
                text: "Show App Descriptions:"
                pixelSize: Theme.typography.size.medium
            }
            BaseSwitch {
                Layout.alignment: Qt.AlignLeft
                checked: Preferences.launcherShowAppDescriptions
                onToggled: Preferences.launcherShowAppDescriptions = checked
            }
        }



    }
}
