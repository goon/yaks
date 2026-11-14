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
                leftIcon: "panel-top"
                title: "Position"

                BaseSegmentedControl {
                    Layout.fillWidth: true
                    model: [{ "label": "Top", "value": "top" }, { "label": "Bottom", "value": "bottom" }]
                    currentValue: Preferences.bar.position
                    onActivated: (index, value) => {
                        Preferences.bar.position = value;
                    }
                }
            }

            BaseListItem {
                leftIcon: "unfold-vertical"
                title: "Height"

                BaseSpinBox {
                    from: 30
                    to: 100
                    value: Preferences.bar.height
                    suffix: "px"
                    onValueChanged: Preferences.bar.height = value
                }
            }

            BaseListItem {
                leftIcon: "grip-horizontal"
                title: "Margin"

                BaseSpinBox {
                    to: 50
                    value: Preferences.bar.marginTop
                    suffix: "px"
                    onValueChanged: Preferences.bar.marginTop = value
                }
            }

            BaseListItem {
                leftIcon: "layout-grid"
                title: "Workspace Count"
                showSeparator: false

                BaseSpinBox {
                    from: 1
                    to: 20
                    value: Preferences.bar.workspaceCount
                    onValueChanged: Preferences.bar.workspaceCount = value
                }
            }
        }
    }
}