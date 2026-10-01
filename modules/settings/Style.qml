import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

SettingsPage {
    id: root

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Globals.geometry.spacing.md

        SettingsGroup {
            Layout.fillWidth: true

                BaseListItem {
                    id: shellFontRow
                    leftIcon: "type"
                    title: "Font"
                    clickable: true
                    onClicked: root.StackView.view.pushPage(Qt.resolvedUrl("Font.qml"), "Font.qml")

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

                BaseListItem {
                    leftIcon: "layout-grid"
                    title: "Scale"

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

                BaseListItem {
                    leftIcon: "spline"
                    title: "Rounding"

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

                BaseListItem {
                    leftIcon: "droplet"
                    title: "Opacity"

                    BaseSpinBox {
                        from: 50
                        to: 100
                        stepSize: 5
                        value: Math.round(Preferences.globals.backgroundOpacity * 100)
                        suffix: "%"
                        onValueChanged: Preferences.globals.backgroundOpacity = value / 100.0
                    }
                }

                BaseListItem {
                    leftIcon: "frame"
                    title: "Outline"

                    BaseSwitch {
                        checked: Preferences.globals.capsuleOutline
                        onToggled: Preferences.globals.capsuleOutline = checked
                    }
                }

                BaseListItem {
                    leftIcon: "layers"
                    title: "Shadow"
                    showSeparator: false

                    BaseSwitch {
                        checked: Preferences.globals.shadow
                        onToggled: Preferences.globals.shadow = checked
                    }
                }
        }
    }
}
