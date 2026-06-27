import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

SettingsPage {
    id: root

    title: "Animations"
    description: "Animation speed, transitions, and motion."

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Theme.geometry.spacing.large

        SettingsGroup {
            Layout.fillWidth: true

            SettingsRow {
                icon: "animation"
                label: "Speed"
                showSeparator: false

                BaseSegmentedControl {
                    Layout.fillWidth: true
                    currentValue: Preferences.animations.profile
                    model: [
                        { label: "Slow", value: "slow" },
                        { label: "Normal", value: "normal" },
                        { label: "Fast", value: "fast" }
                    ]
                    onActivated: (index, value) => { Preferences.animations.profile = value; }
                }
            }
        }
    }
}
