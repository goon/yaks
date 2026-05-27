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

        BaseSeparator {
            Layout.fillWidth: true
            Layout.topMargin: Theme.geometry.spacing.medium
            Layout.bottomMargin: Theme.geometry.spacing.medium
        }

        // --- SECTION 2: System Shortcuts (Read-Only) ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.geometry.spacing.medium

            BaseText {
                text: "System Shortcuts"
                weight: Theme.typography.weights.bold
                pixelSize: Theme.typography.size.large
            }

            BaseText {
                text: "Built-in launcher shortcuts triggered using the Global Prefix (e.g. `>`). These cannot be modified or removed."
                color: Theme.colors.muted
                pixelSize: Theme.typography.size.base
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.bottomMargin: Theme.geometry.spacing.small
            }

            GridLayout {
                columns: 3
                Layout.fillWidth: true
                columnSpacing: Theme.geometry.spacing.large
                rowSpacing: Theme.geometry.spacing.small

                // Header Row
                BaseText {
                    text: "Trigger"
                    weight: Theme.typography.weights.bold
                    color: Theme.colors.muted
                    Layout.preferredWidth: 90
                }
                BaseText {
                    text: "Action / Name"
                    weight: Theme.typography.weights.bold
                    color: Theme.colors.muted
                    Layout.preferredWidth: 160
                }
                BaseText {
                    text: "Description"
                    weight: Theme.typography.weights.bold
                    color: Theme.colors.muted
                    Layout.fillWidth: true
                }

                // Row 1: s -> Web Search
                BaseText { text: "s"; color: Theme.colors.primary; weight: Theme.typography.weights.bold }
                BaseText { text: "Web Search" }
                BaseText { text: "Search the web" }

                // Row 2: c -> Calculator
                BaseText { text: "c"; color: Theme.colors.primary; weight: Theme.typography.weights.bold }
                BaseText { text: "Calculator" }
                BaseText { text: "Evaluate mathmatical expressions" }

                // Row 3: w -> Wallpaper Switcher
                BaseText { text: "w"; color: Theme.colors.primary; weight: Theme.typography.weights.bold }
                BaseText { text: "Wallpaper Switcher" }
                BaseText { text: "Change your wallpaper" }

                // Row 4: [space] -> Terminal Command
                BaseText { text: "[space]"; color: Theme.colors.primary; weight: Theme.typography.weights.bold }
                BaseText { text: "Terminal Command" }
                BaseText { text: "Run terminal commands" }
            }
        }

        BaseSeparator {
            Layout.fillWidth: true
            Layout.topMargin: Theme.geometry.spacing.medium
            Layout.bottomMargin: Theme.geometry.spacing.medium
        }

        // --- SECTION 3: Custom Bangs & Shortcuts ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.geometry.spacing.medium

            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true

                    BaseText {
                        text: "Custom Bangs & Shortcuts"
                        weight: Theme.typography.weights.bold
                        pixelSize: Theme.typography.size.large
                    }
                    BaseText {
                        text: "Create additional shortcut triggers (e.g. `>gh` for GitHub Search) to invoke custom search URLs."
                        color: Theme.colors.muted
                        pixelSize: Theme.typography.size.base
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                    }
                }

                BaseButton {
                    text: "Add Bang"
                    icon: "add"
                    onClicked: Preferences.addLauncherBang("new", "New Shortcut", "https://google.com/search?q=")
                }
            }

            // Bangs list rows
            ColumnLayout {
                id: bangsList
                Layout.fillWidth: true
                spacing: Theme.geometry.spacing.small

                Repeater {
                    model: Preferences.launcherBangs || []

                    delegate: RowLayout {
                        id: bangRow
                        Layout.fillWidth: true
                        spacing: Theme.geometry.spacing.medium

                        readonly property int itemIndex: index
                        readonly property string triggerVal: modelData.trigger
                        readonly property string nameVal: modelData.name
                        readonly property string urlVal: modelData.url

                        BaseInput {
                            id: triggerInput
                            Layout.preferredWidth: 90
                            implicitHeight: 40
                            inputPadding: 8
                            text: bangRow.triggerVal
                            placeholderText: "Trigger"

                            onEditingFinished: {
                                if (text.trim() !== "" && text.trim() !== bangRow.triggerVal) {
                                    Preferences.updateLauncherBang(bangRow.itemIndex, text.trim(), nameInput.text, urlInput.text);
                                }
                            }
                        }

                        BaseInput {
                            id: nameInput
                            Layout.preferredWidth: 160
                            implicitHeight: 40
                            inputPadding: 8
                            text: bangRow.nameVal
                            placeholderText: "Name"

                            onEditingFinished: {
                                if (text.trim() !== "" && text.trim() !== bangRow.nameVal) {
                                    Preferences.updateLauncherBang(bangRow.itemIndex, triggerInput.text, text.trim(), urlInput.text);
                                }
                            }
                        }

                        BaseInput {
                            id: urlInput
                            Layout.fillWidth: true
                            implicitHeight: 40
                            inputPadding: 8
                            text: bangRow.urlVal
                            placeholderText: "Search URL Template (e.g. https://google.com/search?q=)"

                            onEditingFinished: {
                                if (text.trim() !== "" && text.trim() !== bangRow.urlVal) {
                                    Preferences.updateLauncherBang(bangRow.itemIndex, triggerInput.text, nameInput.text, text.trim());
                                }
                            }
                        }

                        BaseButton {
                            icon: "delete"
                            hoverColor: Theme.colors.error
                            iconColor: Theme.colors.text
                            implicitWidth: 40
                            implicitHeight: 40

                            onClicked: {
                                Preferences.deleteLauncherBang(bangRow.itemIndex);
                            }
                        }
                    }
                }
            }
        }
    }
}
