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
                id: backgroundOpacitySlider
                Layout.fillWidth: true
                from: 0.3
                to: 1.0
                stepSize: 0.05
                value: Preferences.backgroundOpacity
                onMoved: Preferences.backgroundOpacity = value
            }

            BaseText {
                text: Math.round(backgroundOpacitySlider.value * 100) + "%"
                Layout.preferredWidth: 40
                horizontalAlignment: Text.AlignRight
            }
        }

        BaseText {
            text: "Surface Opacity:"
            pixelSize: Theme.typography.size.medium
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.geometry.spacing.large

            BaseSlider {
                id: surfaceOpacitySlider
                Layout.fillWidth: true
                from: 0.3
                to: 1.0
                stepSize: 0.05
                value: Preferences.surfaceOpacity
                onMoved: Preferences.surfaceOpacity = value
            }

            BaseText {
                text: Math.round(surfaceOpacitySlider.value * 100) + "%"
                Layout.preferredWidth: 40
                horizontalAlignment: Text.AlignRight
            }
        }

        BaseText {
            text: "Island Outline:"
            pixelSize: Theme.typography.size.medium
        }

        BaseSwitch {
            Layout.fillWidth: true
            checked: Preferences.islandOutline
            onToggled: Preferences.islandOutline = checked
        }

    }
}
