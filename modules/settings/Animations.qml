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

                BaseSpinBox {
                    Layout.alignment: Qt.AlignRight
                    from: 5
                    to: 25
                    stepSize: 1
                    suffix: "x"
                    
                    value: Math.round(Preferences.animations.speedMultiplier * 10)
                    
                    textFromValue: function(v, locale) {
                        return Number(v / 10).toLocaleString(locale, 'f', 1);
                    }
                    
                    valueFromText: function(text, locale) {
                        return Math.round(Number.fromLocaleString(locale, text) * 10);
                    }
                    
                    onValueChanged: {
                        Preferences.animations.speedMultiplier = value / 10.0;
                    }
                }
            }
        }
    }
}
