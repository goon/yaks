import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

SettingsPage {
    id: root

    // Row metrics, so the delegate and the list's height cap cannot drift apart.
    readonly property int rowHeight: 44 * Globals.shellScale
    // A scan list wants a visible bottom edge, so it is capped at a screenful of
    // rows rather than filling the capsule.
    readonly property int visibleRows: 10

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
        spacing: Globals.geometry.spacing.sm

        BaseSearch {
            Layout.fillWidth: true
            onTextChanged: root.searchText = text.toLowerCase()
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            // This IS the page's height: BaseContainer's implicitHeight comes
            // from its ColumnLayout, and a fillHeight ListView contributes only
            // its implicitHeight (0), so without an explicit preferredHeight the
            // page collapses to the search field and the list shows nothing.
            // contentHeight is the model's full scroll extent, not the viewport,
            // so reading it here is stable.
            Layout.preferredHeight: Math.min(contentHeight, root.rowHeight * root.visibleRows)
            clip: true
            model: root.fontModel
            // A scan list: the rows carry the rule, so the list must not also
            // gap them. `BaseListItem.showSeparator` defaults to true.
            spacing: 0
            // A 3000-row list is ~150000px of travel; Qt's default rubber-band
            // then animates an overshoot at each end while the delegates are
            // still alive, which is where the flick visibly hitched.
            boundsBehavior: Flickable.StopAtBounds

            delegate: BaseListItem {
                width: ListView.view.width

                title: modelData
                clickable: true
                itemHeight: root.rowHeight
                verticalPadding: 0
                selected: root.currentValue === modelData
                rightIconVisible: selected
                rightIcon: "check"

                // The row renders in its own family the moment the delegate
                // exists. This used to wait on a timer until `!listView.moving`,
                // which stays true through the whole flick and its deceleration,
                // so every row showed in the shell font for the entire scroll and
                // then all swapped at once when the momentum died.
                titleFamily: modelData

                onClicked: {
                    root.onSelected(modelData)
                }
            }
        }
    }
}
