import QtQuick
import QtQuick.Layouts
import qs

BaseContainer {
    id: root

    property alias text: input.text
    property alias placeholderText: input.placeholderText

    function focusInput() {
        input.forceActiveFocus();
        input.cursorPosition = input.text.length;
    }

    implicitHeight: 30 * Globals.shellScale
    paddingHorizontal: Globals.geometry.spacing.large
    clickable: true

    onClicked: root.focusInput()

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Globals.geometry.spacing.large

        BaseIcon {
            icon: "search"
            color: input.text.length > 0 ? Globals.colors.primary : Globals.colors.muted
            scale: input.text.length > 0 ? 1.1 : 1.0
            Behavior on color { BaseMotion { } }
            Behavior on scale { BaseMotion { } }
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
                font.pixelSize: Globals.typography.size.large
                placeholderText: "Search..."
                caretParksInPlaceholder: false
                verticalAlignment: Text.AlignVCenter
                activeFocusOnTab: false
            }
        }
    }
}
