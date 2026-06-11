import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

SettingsPage {
    id: root

    title: "Workspaces"

    GridLayout {
        columns: 2
        rowSpacing: Theme.geometry.spacing.dynamicPadding
        columnSpacing: Theme.geometry.spacing.dynamicPadding
        Layout.fillWidth: true

        BaseText {
            text: "Configure workspace display and navigation behaviour."
            color: Theme.colors.text
            pixelSize: Theme.typography.size.medium
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            Layout.columnSpan: 2
            Layout.bottomMargin: Theme.geometry.spacing.small
        }

        BaseText {
            text: "Workspace Style:"
            pixelSize: Theme.typography.size.medium
        }

        BaseComboBox {
            id: workspaceStyleSelector
            Layout.fillWidth: true
            textRole: "label"
            model: [
                { "label": "English (1)", "value": 0 },
                { "label": "Roman (I)",   "value": 1 },
                { "label": "Kanji (\u4E00)",   "value": 2 }
            ]
            currentIndex: {
                for (var i = 0; i < model.length; i++) {
                    if (model[i].value === Preferences.workspaceStyle)
                        return i;
                }
                return 0;
            }
            onActivated: (index) => {
                Preferences.workspaceStyle = model[index].value;
            }
        }

        BaseText {
            text: "Workspace Count:"
            pixelSize: Theme.typography.size.medium
        }

        BaseSpinBox {
            Layout.fillWidth: true
            from: 1
            to: 20
            value: Preferences.workspaceCount
            onValueChanged: Preferences.workspaceCount = value
        }


    }
}