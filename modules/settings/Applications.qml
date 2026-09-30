import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

SettingsPage {

    title: "Applications"

    ColumnLayout {
        spacing: Globals.geometry.spacing.large
        Layout.fillWidth: true

        SettingsGroup {
            Layout.fillWidth: true

            BaseListItem {
                id: appsTitleRow
                leftIcon: "layout-grid"
                title: "Applications"
            }

            GridLayout {
                property var indicatorTarget: appsTitleRow
                Layout.fillWidth: true
                Layout.margins: Globals.geometry.spacing.medium
                Layout.topMargin: Globals.geometry.spacing.large
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

                        backgroundColor: isEnabled ? Globals.colors.tint : Globals.colors.disabled
                        opacity: isInstalled ? 1.0 : 0.5
                        blockRadius: Globals.geometry.innerRadius.medium

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Globals.geometry.spacing.small
                            spacing: Globals.geometry.spacing.small

                            BaseIcon {
                                icon: bento.isEnabled ? "check" : "circle"
                                size: Globals.dimensions.iconLarge
                                color: bento.isEnabled ? Globals.colors.primary : Globals.colors.text
                                Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                            }

                            BaseText {
                                text: modelData.name
                                color: bento.isEnabled ? Globals.colors.primary : Globals.colors.text
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
                                let apps = structuredClone(Preferences.applications.themedApps);
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
