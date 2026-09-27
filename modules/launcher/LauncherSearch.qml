import QtQuick
import QtQuick.Layouts
import qs

BaseContainer {
    id: root

    property alias text: input.text

    // Expose forceActiveFocus so parent can focus it
    function focusInput() {
        input.forceActiveFocus();
        input.cursorPosition = input.text.length;
    }

    Layout.fillWidth: true
    Layout.preferredHeight: Globals.dimensions.launcherSearchHeight
    paddingHorizontal: Globals.geometry.spacing.large
    clickable: true

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.leftMargin: 0
        Layout.rightMargin: 0
        Layout.topMargin: 0
        Layout.bottomMargin: 0
        spacing: Globals.geometry.spacing.large

        BaseIcon {
            icon: "search"
            color: input.text.length > 0 ? Globals.colors.primary : Globals.colors.muted

            Behavior on color { BaseAnimation { } }

            // Subtle pulse when typing
            scale: input.text.length > 0 ? 1.1 : 1.0
            Behavior on scale { BaseAnimation { } }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            BaseInput {
                id: input
                anchors.fill: parent
                clip: true
                leftPadding: 8
                rightPadding: 8
                placeholderText: "Search..."
                verticalAlignment: Text.AlignVCenter
                focus: true
                activeFocusOnTab: false
            }
        }
    }
}
