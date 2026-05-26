import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

SettingsPage {
    id: root

    title: "Globals"

    GridLayout {
        columns: 2
        rowSpacing: Theme.geometry.spacing.dynamicPadding
        columnSpacing: Theme.geometry.spacing.dynamicPadding
        Layout.fillWidth: true

        BaseText {
            text: "Adjust the core desktop environment's look, feel, and typography."
            color: Theme.colors.text
            pixelSize: Theme.typography.size.medium
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            Layout.columnSpan: 2
            Layout.bottomMargin: Theme.geometry.spacing.small
        }

        BaseText {
            text: "Theme Preset:"
            pixelSize: Theme.typography.size.medium
        }

        BaseComboBox {
            Layout.fillWidth: true
            textRole: "name"
            model: ThemeService.availableStockThemes
            currentIndex: {
                if (!model)
                    return -1;
                for (var i = 0; i < model.length; i++) {
                    if (model[i].id === Preferences.currentTheme)
                        return i;
                }
                return -1;
            }
            onActivated: (index) => {
                return ThemeService.setTheme(model[index].id);
            }
        }

        BaseText {
            text: "Shell Font:"
            pixelSize: Theme.typography.size.medium
        }

        BaseComboBox {
            Layout.fillWidth: true
            model: ThemeService.allFontFamilies
            searchable: true
            previewFonts: true
            currentIndex: {
                var current = Preferences.shellFont;
                for (var i = 0; i < model.length; i++) {
                    if (current === model[i])
                        return i;
                }
                return -1;
            }
            onActivated: (index) => {
                Preferences.shellFont = model[index];
            }
        }

        BaseText {
            text: "Corner Radius:"
            pixelSize: Theme.typography.size.medium
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.geometry.spacing.large

            BaseSlider {
                id: barRadiusSlider
                Layout.fillWidth: true
                from: 0
                to: 30
                stepSize: 1
                value: Preferences.cornerRadius
                onMoved: Preferences.cornerRadius = value
            }

            BaseText {
                text: Math.round(barRadiusSlider.value) + "px"
                Layout.preferredWidth: 40
                horizontalAlignment: Text.AlignRight
            }
        }

        BaseText {
            text: "Popout Trigger:"
            pixelSize: Theme.typography.size.medium
        }

        BaseComboBox {
            Layout.fillWidth: true
            textRole: "label"
            model: [{ "label": "On Click", "value": 0 }, { "label": "On Hover", "value": 1 }]
            currentIndex: Preferences.popoutTrigger
            onActivated: (index) => {
                Preferences.popoutTrigger = model[index].value;
            }
        }

        BaseText {
            text: "Background Opacity:"
            pixelSize: Theme.typography.size.medium
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.geometry.spacing.large

            BaseSlider {
                id: blurOpacitySlider
                Layout.fillWidth: true
                from: 0.3
                to: 1.0
                stepSize: 0.05
                value: Preferences.blurOpacity
                onMoved: Preferences.blurOpacity = value
            }

            BaseText {
                text: Math.round(blurOpacitySlider.value * 100) + "%"
                Layout.preferredWidth: 40
                horizontalAlignment: Text.AlignRight
            }
        }

        BaseText {
            text: "Block Opacity:"
            pixelSize: Theme.typography.size.medium
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.geometry.spacing.large

            BaseSlider {
                id: blockOpacitySlider
                Layout.fillWidth: true
                from: 0.3
                to: 1.0
                stepSize: 0.05
                value: Preferences.blockOpacity
                onMoved: Preferences.blockOpacity = value
            }

            BaseText {
                text: Math.round(blockOpacitySlider.value * 100) + "%"
                Layout.preferredWidth: 40
                horizontalAlignment: Text.AlignRight
            }
        }

        BaseSeparator {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            Layout.topMargin: Theme.geometry.spacing.large
        }

        BaseText {
            text: "External Services"
            weight: Theme.typography.weights.bold
            color: Theme.colors.primary
            pixelSize: Theme.typography.size.large
            Layout.columnSpan: 2
            Layout.topMargin: Theme.geometry.spacing.medium
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
    }
}
