import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

SettingsPage {
    id: root
    
    title: "Shell Font"

    property string searchText: ""
    property var allFonts: Array.from(Theme.allFontFamilies || [])
    property string currentValue: Preferences.globals.shellFont
    property var onSelected: function(family) {
        Preferences.globals.shellFont = family;
    }

    property var fontModel: {
        if (searchText === "") return allFonts;
        return allFonts.filter(f => f.toLowerCase().includes(searchText));
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Globals.geometry.spacing.medium

        BaseSearch {
            Layout.fillWidth: true
            placeholderText: "Search fonts..."
            onTextChanged: root.searchText = text.toLowerCase()
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 600)
            clip: true
            model: root.fontModel
            spacing: Globals.geometry.spacing.small
            

            delegate: BaseListItem {
                width: ListView.view.width

                title: modelData
                clickable: true
                itemHeight: 44 * Globals.shellScale
                verticalPadding: 0
                selected: root.currentValue === modelData
                rightIconVisible: selected
                rightIcon: "check"
                
                property bool loadFont: false
                Timer {
                    interval: 80
                    running: root.visible && !listView.moving
                    onTriggered: loadFont = true
                }
                titleFamily: loadFont ? modelData : Globals.typography.family
                
                onClicked: {
                    root.onSelected(modelData)
                }
            }
        }
    }
}
