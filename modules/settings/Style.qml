import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

SettingsPage {
    id: root

    title: "Style"
    description: "Adjust the core desktop environment's look, feel, and typography."

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Globals.geometry.spacing.large

        SettingsGroup {
            Layout.fillWidth: true

                SettingsRow {
                    icon: "palette"
                    label: "Theme"
                    
                    BaseComboBox {
                        Layout.fillWidth: true
                        textRole: "name"
                        model: Theme.allThemes
                        currentIndex: {
                            if (!model) return -1;
                            for (var i = 0; i < model.length; i++) {
                                if (model[i].id === Preferences.currentTheme) return i;
                            }
                            return -1;
                        }
                        onActivated: (index) => { return Theme.setTheme(model[index].id); }
                    }
                }

                SettingsRow {
                    id: colorPickerRow
                    icon: "colorize"
                    label: "Seed Hue"


                    BaseColourPicker {
                        Layout.fillWidth: true
                        value: {
                            var hue = Qt.color(Preferences.globals.dynamicSeedColor).hslHue;
                            return hue >= 0 ? hue : 0;
                        }
                        thumbColor: Preferences.globals.dynamicSeedColor
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.000; color: Qt.hsla(0.000, 0.60, 0.75, 1.0) }
                            GradientStop { position: 0.166; color: Qt.hsla(0.166, 0.60, 0.75, 1.0) }
                            GradientStop { position: 0.333; color: Qt.hsla(0.333, 0.60, 0.75, 1.0) }
                            GradientStop { position: 0.500; color: Qt.hsla(0.500, 0.60, 0.75, 1.0) }
                            GradientStop { position: 0.666; color: Qt.hsla(0.666, 0.60, 0.75, 1.0) }
                            GradientStop { position: 0.833; color: Qt.hsla(0.833, 0.60, 0.75, 1.0) }
                            GradientStop { position: 1.000; color: Qt.hsla(1.000, 0.60, 0.75, 1.0) }
                        }
                        onDragged: (v) => {
                            Preferences.globals.dynamicSeedColor = Qt.hsla(v, 0.60, 0.75, 1.0).toString();
                            Theme.setTheme(Preferences.currentTheme, true);
                        }
                        onCommitted: (v) => {
                            Theme.setTheme(Preferences.currentTheme, true);
                        }
                    }
                }

                SettingsRow {
                    id: bgBrightnessRow
                    icon: "brightness_6"
                    label: "Background"


                    BaseSpinBox {
                        from: 5
                        to: 25
                        stepSize: 1
                        suffix: "%"
                        value: Math.round(Preferences.globals.dynamicBgLightness * 100)
                        onValueChanged: {
                            let newLightness = value / 100.0;
                            if (Math.abs(Preferences.globals.dynamicBgLightness - newLightness) > 0.001) {
                                Preferences.globals.dynamicBgLightness = newLightness;
                                Theme.setTheme(Preferences.currentTheme, true);
                            }
                        }
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
                        color: shellFontRow.hovered ? Globals.colors.text : Globals.colors.muted
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
