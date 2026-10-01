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
                    stepSize: 1
                    value: Preferences.bar.height
                    suffix: "px"
                    onValueChanged: Preferences.bar.height = value
                }
            }

            BaseListItem {
                leftIcon: "grip-horizontal"
                title: "Margin"

                BaseSpinBox {
                    from: 0
                    to: 50
                    stepSize: 1
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
                    from: 0
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



            BaseListItem {
                id: activeComponentsTitle
                leftIcon: "grip-vertical"
                title: "Components"
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
                Layout.margins: Globals.geometry.spacing.sm
                Layout.topMargin: Globals.geometry.spacing.md
                spacing: Globals.geometry.spacing.xs

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
                    id: repeater
                    model: Preferences.bar.components

                    Rectangle {
                        id: pill
                        readonly property bool isEnabled: Preferences.bar.componentsEnabled[modelData] === true

                        Layout.fillWidth: true
                        height: 48
                        radius: Globals.innerRadius(Globals.geometry.spacing.sm)

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
                            anchors.leftMargin: Globals.geometry.spacing.sm
                            anchors.rightMargin: Globals.geometry.spacing.xs
                            spacing: Globals.geometry.spacing.xs

                            BaseIcon {
                                icon:  componentList.metadata[modelData]?.icon || "extension"
                                size:  Globals.typography.icon.md
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
                                paddingHorizontal: Globals.geometry.spacing.xs
                                paddingVertical: Globals.geometry.spacing.xs
                                hoverColor: Globals.colors.hover
                                iconColor: enabled ? Globals.colors.text : Globals.colors.disabled
                                onClicked: componentList.nudge(modelData, -1)
                            }

                            BaseButton {
                                icon: "chevron-down"
                                enabled: index < repeater.count - 1
                                paddingHorizontal: Globals.geometry.spacing.xs
                                paddingVertical: Globals.geometry.spacing.xs
                                hoverColor: Globals.colors.hover
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