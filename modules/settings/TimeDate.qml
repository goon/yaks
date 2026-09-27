import QtQuick
import QtQuick.Layouts
import qs

SettingsPage {
    id: root

    title: "Time & Date"
    description: "Configure time formatting."

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Globals.geometry.spacing.large

        SettingsGroup {
            Layout.fillWidth: true

            SettingsRow {
                icon: "clock"
                label: "Time"
                showSeparator: false

                BaseSegmentedControl {
                    Layout.fillWidth: true
                    model: [{ "label": "12 HR", "value": "12" }, { "label": "24 HR", "value": "24" }]
                    currentValue: Preferences.timedate.format
                    onActivated: (index, value) => {
                        Preferences.timedate.format = value;
                    }
                }
            }
        }
    }
}
