import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

SettingsPage {
    id: root

    title: "Bar"

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Globals.geometry.spacing.large

        SettingsGroup {
            Layout.fillWidth: true

            SettingsRow {
                icon: "panel-top"
                label: "Position"

                BaseSegmentedControl {
                    Layout.fillWidth: true
                    model: [{ "label": "Top", "value": "top" }, { "label": "Bottom", "value": "bottom" }]
                    currentValue: Preferences.bar.position
                    onActivated: (index, value) => {
                        Preferences.bar.position = value;
                    }
                }
            }


            SettingsRow {
                icon: "unfold-vertical"
                label: "Height"

                BaseSpinBox {
                    from: 30
                    to: 100
                    stepSize: 1
                    value: Preferences.bar.height
                    suffix: "px"
                    onValueChanged: Preferences.bar.height = value
                }
            }

            SettingsRow {
                icon: "grip-horizontal"
                label: "Margin"

                BaseSpinBox {
                    from: 0
                    to: 50
                    stepSize: 1
                    value: Preferences.bar.marginTop
                    suffix: "px"
                    onValueChanged: Preferences.bar.marginTop = value
                }
            }

            SettingsRow {
                icon: "picture-in-picture-2"
                label: "Overhang"
                description: "Float the bar over window content"

                BaseSwitch {
                    checked: Preferences.bar.overhang
                    onToggled: Preferences.bar.overhang = checked
                }
            }

            SettingsRow {
                icon: "move-vertical"
                label: "Reserved"
                description: "Bar height kept clear; the rest overhangs"

                BaseSpinBox {
                    from: 0
                    to: 100
                    stepSize: 5
                    value: Preferences.bar.overhangReserve
                    suffix: "%"
                    enabled: Preferences.bar.overhang
                    onValueChanged: Preferences.bar.overhangReserve = value
                }
            }

            SettingsRow {
                icon: "layout-grid"
                label: "Workspace Count"
                showSeparator: true

                BaseSpinBox {
                    from: 1
                    to: 20
                    value: Preferences.bar.workspaceCount
                    onValueChanged: Preferences.bar.workspaceCount = value
                }
            }



            SettingsRow {
                id: activeComponentsTitle
                icon: "grip-vertical"
                label: "Components"
                showSeparator: false
                Layout.fillWidth: true
            }

            ColumnLayout {
                id: componentList
                property var indicatorTarget: activeComponentsTitle
                readonly property var metadata: ({
                    "workspaces": { name: "Workspaces", icon: "columns-4" },
                    "clock":      { name: "Clock",      icon: "clock"    },
                    "dock":       { name: "Dock",        icon: "columns-2" },
                    "indicators": { name: "Indicators",  icon: "layers"   },
                })

                Layout.fillWidth: true
                Layout.margins: Globals.geometry.spacing.medium
                Layout.topMargin: Globals.geometry.spacing.large
                spacing: Globals.geometry.spacing.small

                // Swap `componentId` with its neighbour: dir -1 is up, +1 is down.
                function nudge(componentId, dir) {
                    var list = Array.from(Preferences.bar.components);
                    var i = list.indexOf(componentId);
                    var j = i + dir;
                    if (i < 0 || j < 0 || j >= list.length) return;
                    var tmp = list[i];
                    list[i] = list[j];
                    list[j] = tmp;
                    Preferences.bar.components = list;
                }

                Repeater {
                    model: Preferences.bar.components

                    Rectangle {
                        id: pill
                        readonly property bool isEnabled: Preferences.bar.componentsEnabled[modelData] === true

                        Layout.fillWidth: true
                        height: 48
                        radius: Globals.geometry.innerRadius.medium

                        // Flat well-style container pills
                        color:        isEnabled ? Globals.colors.tint : Globals.colors.disabled
                        border.width: isEnabled ? 1 : 0
                        border.color: isEnabled ? Globals.colors.primary : "transparent"

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                let map = Object.assign({}, Preferences.bar.componentsEnabled);
                                map[modelData] = !pill.isEnabled;
                                Preferences.bar.componentsEnabled = map;
                            }
                        }

                        RowLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: Globals.geometry.spacing.medium
                            anchors.rightMargin: Globals.geometry.spacing.small
                            spacing: Globals.geometry.spacing.small

                            BaseIcon {
                                icon:  componentList.metadata[modelData]?.icon || "extension"
                                size:  Globals.dimensions.iconSmall
                                color: pill.isEnabled ? Globals.colors.primary : Globals.colors.text
                            }

                            BaseText {
                                text:  componentList.metadata[modelData]?.name || modelData
                                color: pill.isEnabled ? Globals.colors.primary : Globals.colors.text
                                Layout.fillWidth: true
                            }

                            BaseButton {
                                icon: "chevron-up"
                                enabled: index > 0
                                paddingHorizontal: Globals.geometry.spacing.small
                                paddingVertical: Globals.geometry.spacing.small
                                hoverColor: Globals.alpha(Globals.colors.text, 0.1)
                                iconColor: enabled ? Globals.colors.text : Globals.colors.disabled
                                onClicked: componentList.nudge(modelData, -1)
                            }

                            BaseButton {
                                icon: "chevron-down"
                                enabled: index < repeater.count - 1
                                paddingHorizontal: Globals.geometry.spacing.small
                                paddingVertical: Globals.geometry.spacing.small
                                hoverColor: Globals.alpha(Globals.colors.text, 0.1)
                                iconColor: enabled ? Globals.colors.text : Globals.colors.disabled
                                onClicked: componentList.nudge(modelData, 1)
                            }
                        }
                    }
                }
            }
        }
    }
}