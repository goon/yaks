import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

SettingsPage {
    id: root

    title: "Clipboard"
    description: "Clipboard history, sync, and behaviour."

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Globals.geometry.spacing.large

        SettingsGroup {
            Layout.fillWidth: true

            SettingsRow {
                label: "Auto Close on Copy"
                BaseSwitch {
                    checked: Preferences.clipboard.autoClose
                    onCheckedChanged: {
                        if (Preferences.clipboard.autoClose !== checked) {
                            Preferences.clipboard.autoClose = checked;
                        }
                    }
                }
            }

            SettingsRow {
                label: "Time Based Cleanup"
                BaseSpinBox {
                    value: Preferences.clipboard.cleanupDays
                    from: 0
                    to: 14
                    suffix: "d"
                    onValueChanged: {
                        if (Preferences.clipboard.cleanupDays !== value) {
                            Preferences.clipboard.cleanupDays = value;
                        }
                    }
                }
            }

            SettingsRow {
                label: "UI Display Limit"
                showSeparator: false
                BaseSpinBox {
                    value: Preferences.clipboard.displayLimit
                    from: 25
                    to: 100
                    onValueChanged: {
                        if (Preferences.clipboard.displayLimit !== value) {
                            Preferences.clipboard.displayLimit = value;
                            Clipboard.reloadCliphist(); // Force reload to reflect limit change
                        }
                    }
                }
            }
        }
    }
}
