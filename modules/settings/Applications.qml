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
                showSeparator: true

                BaseSpinBox {
                    from: 30
                    to: 100
                    stepSize: 5
                    value: Math.round(Preferences.applications.themedAppsOpacity * 100)
                    suffix: "%"
                    onValueChanged: Preferences.applications.themedAppsOpacity = value / 100.0
                }
            }

            SettingsRow {
                id: appsTitleRow
                icon: "apps"
                label: "Applications"
                showSeparator: false
            }

            GridLayout {
                property var indicatorTarget: appsTitleRow
                Layout.fillWidth: true
                Layout.margins: Globals.geometry.spacing.medium
                columns: 3
                columnSpacing: Globals.geometry.spacing.small
                rowSpacing: Globals.geometry.spacing.small

                Repeater {
                    model: Theme.applications

                    delegate: BaseBento {
                        id: bento
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1 // Force equal column distribution
                        Layout.preferredHeight: 80
                        
                        readonly property bool isInstalled: Theme.installedApps[modelData.id] !== false
                        readonly property bool isEnabled: (Preferences.applications.themedApps[modelData.id] || false) && isInstalled

                        backgroundColor: isEnabled ? Globals.alpha(Globals.colors.primary, 0.1) : Globals.alpha(Globals.colors.surface, 0.5)
                        premiumActive: false // Disable the overwhelming pink gradient block
                        opacity: isInstalled ? 1.0 : 0.5
                        blockRadius: Globals.geometry.innerRadius.medium

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Globals.geometry.spacing.small
                            spacing: Globals.geometry.spacing.small

                            BaseIcon {
                                icon: bento.isEnabled ? "check_circle" : "radio_button_unchecked"
                                size: 24
                                color: bento.isEnabled ? Globals.colors.primary : Globals.colors.text
                                Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                            }

                            BaseText {
                                text: modelData.name
                                color: bento.isEnabled ? Globals.colors.textLighter : Globals.colors.text
                                pixelSize: Globals.typography.size.small
                                weight: Globals.typography.weights.medium
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: bento.isInstalled
                            hoverEnabled: true
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                let apps = JSON.parse(JSON.stringify(Preferences.applications.themedApps));
                                apps[modelData.id] = !bento.isEnabled;
                                Preferences.applications.themedApps = apps;
                            }
                        }
                    }
                }
            }
        }
    }
}
