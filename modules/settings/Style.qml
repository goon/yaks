import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

SettingsPage {
    id: root

    title: "Style"

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Globals.geometry.spacing.large

        SettingsGroup {
            Layout.fillWidth: true

                SettingsRow {
                    id: shellFontRow
                    icon: "type"
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
                        icon: "chevron-right"
                        color: shellFontRow.hovered ? Globals.colors.text : Globals.colors.muted
                        Behavior on color { BaseMotion { } }
                    }
                }

                SettingsRow {
                    icon: "layout-grid"
                    label: "Scale"

                    BaseSegmentedControl {
                        Layout.fillWidth: true
                        model: [
                            { "label": "0.9x", "value": 0 },
                            { "label": "1.0x", "value": 1 },
                            { "label": "1.1x", "value": 2 }
                        ]
                        currentValue: Preferences.globals.scale
                        onActivated: (index, value) => {
                            Preferences.globals.scale = value;
                        }
                    }
                }

                SettingsRow {
                    icon: "spline"
                    label: "Rounding"

                    BaseSegmentedControl {
                        Layout.fillWidth: true
                        model: [
                            { "label": "Sharp", "value": "sharp" },
                            { "label": "Soft",  "value": "soft" },
                            { "label": "Round", "value": "round" }
                        ]
                        currentValue: Preferences.globals.rounding
                        onActivated: (index, value) => {
                            Preferences.globals.rounding = value;
                        }
                    }
                }

                SettingsRow {
                    icon: "droplet"
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
                    icon: "frame"
                    label: "Outline"

                    BaseSwitch {
                        checked: Preferences.globals.islandOutline
                        onToggled: Preferences.globals.islandOutline = checked
                    }
                }

                SettingsRow {
                    icon: "layers"
                    label: "Shadow"
                    showSeparator: false

                    BaseSwitch {
                        checked: Preferences.globals.shadow
                        onToggled: Preferences.globals.shadow = checked
                    }
                }
        }
    }
}
