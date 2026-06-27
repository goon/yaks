import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

SettingsPage {
    id: root
    
    title: "Shell Font"
    description: "Select the primary font used throughout the shell."

    property string searchText: ""
    property var allFonts: Array.from(ThemeService.allFontFamilies || [])
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
        spacing: Theme.geometry.spacing.medium

        BaseContainer {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.dimensions.launcherSearchHeight || 48
            paddingHorizontal: Theme.geometry.spacing.large

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Theme.geometry.spacing.large

                BaseIcon {
                    icon: "search"
                    color: searchInput.text.length > 0 ? Theme.colors.primary : Theme.colors.muted
                    scale: searchInput.text.length > 0 ? 1.1 : 1.0
                    Behavior on color { BaseAnimation { } }
                    Behavior on scale { BaseAnimation { } }
                }

                BaseInput {
                    id: searchInput
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    placeholderText: "Search fonts..."
                    leftPadding: 8
                    rightPadding: 8
                    onTextChanged: root.searchText = text.toLowerCase()
                }
            }
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 600)
            clip: true
            model: root.fontModel
            spacing: Theme.geometry.spacing.small
            

            delegate: BaseListItem {
                width: ListView.view.width
                
                title: modelData
                selected: root.currentValue === modelData
                rightIconVisible: selected
                rightIcon: "check"
                
                // Font preview lazy loading
                property bool loadFont: false
                Timer {
                    interval: 80
                    running: root.visible && !listView.moving
                    onTriggered: loadFont = true
                }
                titleFamily: loadFont ? modelData : Theme.typography.family
                
                onClicked: {
                    root.onSelected(modelData)
                }
            }
        }
    }
}
