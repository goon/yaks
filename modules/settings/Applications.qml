import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

SettingsPage {
    id: root

    title: "Applications"
    description: "Enabling applications inherit the current shell theme. This overrides various configuration files and can be destructive." 

    ColumnLayout {
        spacing: Globals.geometry.spacing.large
        Layout.fillWidth: true

        RowLayout {
            Layout.fillWidth: true
            spacing: Globals.geometry.spacing.small

            BaseIcon {
                icon: "warning"
                color: Globals.colors.warning
                Layout.alignment: Qt.AlignTop
            }

            BaseText {
                text: "Enabling applications below inherit the currently applied theme. This overrides various configuration files and can be destructive."
                pixelSize: Globals.typography.size.medium
                color: Globals.colors.warning
                Layout.fillWidth: true
            }
        }

        BaseSeparator {
            Layout.fillWidth: true
        }

        SettingsGroup {
            Layout.fillWidth: true

            SettingsRow {
                icon: "opacity"
                label: "Themed Apps Opacity"
                showSeparator: false

                BaseSpinBox {
                    from: 30
                    to: 100
                    stepSize: 5
                    value: Math.round(Preferences.applications.themedAppsOpacity * 100)
                    suffix: "%"
                    onValueChanged: Preferences.applications.themedAppsOpacity = value / 100.0
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: Globals.geometry.spacing.small

            Repeater {
                model: Theme.applications

                delegate: Item {
                    id: pill

                    readonly property bool isInstalled: Theme.installedApps[modelData.id] !== false
                    readonly property bool isEnabled: (Preferences.applications.themedApps[modelData.id] || false) && isInstalled

                    width: innerRow.width + Globals.geometry.spacing.medium * 2
                    height: innerRow.height + Globals.geometry.spacing.small * 2
                    opacity: isInstalled ? 1 : 0.5

                    // 1. Premium Selection Gradient Border (Active)
                    Rectangle {
                        anchors.fill: parent
                        radius: Globals.geometry.radius
                        visible: pill.isEnabled
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: Globals.colors.primary }
                            GradientStop { position: 1; color: Globals.colors.secondary }
                        }
                    }

                    // 2. Inner Cutout (Active)
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1.5
                        radius: Globals.geometry.radius - 1.5
                        visible: pill.isEnabled
                        color: Globals.colors.surface

                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: Qt.alpha(Globals.colors.primary, 0.08)
                        }
                    }

                    // 3. Inactive Border (Inactive)
                    Rectangle {
                        anchors.fill: parent
                        radius: Globals.geometry.radius
                        visible: !pill.isEnabled
                        color: Globals.colors.transparent
                        border.width: 1
                        border.color: Globals.colors.border
                    }

                    Row {
                        id: innerRow
                        anchors.centerIn: parent
                        spacing: 6

                        BaseIcon {
                            icon: pill.isEnabled ? "check_circle" : "circle"
                            size: 14
                            color: pill.isEnabled ? Globals.colors.primary : Globals.colors.border
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        BaseText {
                            id: label
                            text: modelData.name
                            color: pill.isEnabled ? Globals.colors.textLighter : Globals.colors.text
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }



                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        enabled: pill.isInstalled
                        hoverEnabled: true
                        onClicked: {
                            let apps = JSON.parse(JSON.stringify(Preferences.applications.themedApps));
                            apps[modelData.id] = !pill.isEnabled;
                            Preferences.applications.themedApps = apps;
                        }
                    }
                }
            }
        }
    }
}
