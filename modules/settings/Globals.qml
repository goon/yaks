import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

SettingsPage {
    id: root

    title: "Globals"
    description: "Adjust the core desktop environment's look, feel, and typography."

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Theme.geometry.spacing.large

        SettingsGroup {
            Layout.fillWidth: true

                SettingsRow {
                    icon: "palette"
                    label: "Theme"
                    
                    BaseComboBox {
                        Layout.fillWidth: true
                        textRole: "name"
                        model: ThemeService.allThemes
                        currentIndex: {
                            if (!model) return -1;
                            for (var i = 0; i < model.length; i++) {
                                if (model[i].id === Preferences.currentTheme) return i;
                            }
                            return -1;
                        }
                        onActivated: (index) => { return ThemeService.setTheme(model[index].id); }
                    }
                }

                SettingsRow {
                    id: shellFontRow
                    icon: "text_fields"
                    label: "Font"
                    clickable: true
                    onClicked: root.StackView.view.push("Font.qml")

                    BaseText {
                        text: Preferences.globals.shellFont
                        muted: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                    }

                    BaseIcon {
                        icon: "chevron_right"
                        color: shellFontRow.hovered ? Theme.colors.text : Theme.colors.muted
                        Behavior on color { BaseAnimation { } }
                    }
                }

                SettingsRow {
                    icon: "rounded_corner"
                    label: "Rounding"

                    BaseSpinBox {
                        from: 0
                        to: 30
                        stepSize: 1
                        value: Preferences.globals.cornerRadius
                        suffix: "px"
                        onValueChanged: Preferences.globals.cornerRadius = value
                    }
                }

                SettingsRow {
                    icon: "opacity"
                    label: "Opacity"

                    BaseSpinBox {
                        from: 50
                        to: 100
                        stepSize: 5
                        value: Math.round(Preferences.globals.backgroundOpacity * 100)
                        suffix: "%"
                        onValueChanged: Preferences.globals.backgroundOpacity = value / 100.0
                    }
                }

                SettingsRow {
                    icon: "border_outer"
                    label: "Outline"
                    showSeparator: false

                    BaseSwitch {
                        checked: Preferences.globals.islandOutline
                        onToggled: Preferences.globals.islandOutline = checked
                    }
                }
        }
    }
}
