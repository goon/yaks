import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

SettingsPage {

    ColumnLayout {
        spacing: Globals.geometry.spacing.md
        Layout.fillWidth: true

        SettingsGroup {
            Layout.fillWidth: true

            BaseListItem {
                id: appsTitleRow
                leftIcon: "layout-grid"
                title: "Applications"
            }

            Repeater {
                model: Theme.applications

                delegate: BaseListItem {
                    id: appRow

                    readonly property bool isInstalled: Theme.installedApps[modelData.id] !== false
                    readonly property bool isEnabled: (Preferences.applications.themedApps[modelData.id] || false) && isInstalled

                    leftIcon: isEnabled ? "check" : "circle"
                    title: modelData.name
                    subtitle: isInstalled ? "" : "Not installed"
                    clickable: isInstalled
                    enabled: isInstalled
                    opacity: isInstalled ? 1.0 : 0.5

                    BaseSwitch {
                        checked: appRow.isEnabled
                        enabled: appRow.isInstalled
                        onToggled: {
                            let apps = Object.assign({}, Preferences.applications.themedApps);
                            apps[modelData.id] = !appRow.isEnabled;
                            Preferences.applications.themedApps = apps;
                        }
                    }
                }
            }
        }
    }
}
