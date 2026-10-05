import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

SettingsPage {
    id: root

    // Fixed display order of the bar components. The render order lives in
    // modules/bar/Bar.qml's componentOrder; this page is toggle-only, no reorder.
    readonly property var componentList: [
        { id: "weather",    name: "Weather",    icon: "cloud-sun" },
        { id: "workspaces", name: "Workspaces", icon: "columns-4" },
        { id: "clock",      name: "Clock",      icon: "clock"     },
        { id: "dock",       name: "Dock",       icon: "columns-2"  }
    ]

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
                leftIcon: "picture-in-picture-2"
                title: "Overhang"

                BaseSwitch {
                    checked: Preferences.bar.overhang
                    onToggled: Preferences.bar.overhang = checked
                }
            }

            BaseListItem {
                leftIcon: "move-vertical"
                title: "Reserved"

                BaseSpinBox {
                    to: 100
                    stepSize: 5
                    value: Preferences.bar.overhangReserve
                    suffix: "%"
                    enabled: Preferences.bar.overhang
                    onValueChanged: Preferences.bar.overhangReserve = value
                }
            }

            BaseListItem {
                leftIcon: "layout-grid"
                title: "Workspace Count"

                BaseSpinBox {
                    from: 1
                    to: 20
                    value: Preferences.bar.workspaceCount
                    onValueChanged: Preferences.bar.workspaceCount = value
                }
            }



            Repeater {
                model: root.componentList

                delegate: BaseListItem {
                    id: componentRow

                    readonly property bool isEnabled: Preferences.bar.componentsEnabled[modelData.id] === true

                    leftIcon: modelData.icon
                    title: modelData.name
                    showSeparator: index < root.componentList.length - 1

                    BaseSwitch {
                        checked: componentRow.isEnabled
                        onToggled: {
                            let map = Object.assign({}, Preferences.bar.componentsEnabled);
                            map[modelData.id] = !componentRow.isEnabled;
                            Preferences.bar.componentsEnabled = map;
                        }
                    }
                }
            }
        }
    }
}