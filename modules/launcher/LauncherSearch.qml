import QtQuick
import QtQuick.Layouts
import qs

BaseBlock {
    id: root

    property alias text: input.text
    property alias inputItem: input
    property alias placeholderText: input.placeholderText
    property var tabModel: []
    property int currentIndex: 0
    property list<Item> activePageHints: []

    signal accepted()
    signal downPressed()
    signal tabClicked(int index)

    // Expose forceActiveFocus so parent can focus it
    function focusInput() {
        input.forceActiveFocus();
        input.cursorPosition = input.text.length;
    }

    Layout.fillWidth: true
    Layout.preferredHeight: Theme.dimensions.launcherSearchHeight
    paddingHorizontal: 20
    paddingVertical: 0
    borderEnabled: false

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.leftMargin: 0
        Layout.rightMargin: 0
        Layout.topMargin: 0
        Layout.bottomMargin: 0
        spacing: Theme.geometry.spacing.large

        BaseIcon {
            icon: "search"
            size: Theme.dimensions.iconMedium
            color: input.text.length > 0 ? Theme.colors.primary : Theme.colors.muted
            
            Behavior on color { BaseAnimation { speed: "fast" } }
            
            // Subtle pulse when typing
            scale: input.text.length > 0 ? 1.1 : 1.0
            Behavior on scale { BaseAnimation { speed: "fast" } }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true



            BaseInput {
                id: input
                anchors.fill: parent
                borderRadius: root.blockRadius
                clip: true
                inputPadding: 0
                leftPadding: 8
                rightPadding: 8
                placeholderText: "Search..."
                color: Theme.colors.text
                verticalAlignment: Text.AlignVCenter
                focus: true
                activeFocusOnTab: false
                backgroundColor: Theme.colors.transparent
                borderWidth: 0

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Down) {
                        root.downPressed();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Backspace && input.text.length === 0) {
                        if (LauncherService.activeUtilityMode !== "") {
                            LauncherService.activeUtilityMode = "";
                            event.accepted = true;
                        } else if (root.currentIndex !== 0) {
                            root.tabClicked(0);
                            event.accepted = true;
                        }
                    }
                }
            }
        }

        RowLayout {
            id: hintsArea
            spacing: Theme.geometry.spacing.small
            Layout.alignment: Qt.AlignVCenter
            
            Repeater {
                model: root.activePageHints
                
                delegate: Item {
                    implicitWidth: modelData.implicitWidth
                    Layout.preferredHeight: Theme.dimensions.iconLarge
                    Layout.alignment: Qt.AlignVCenter

                    Component.onCompleted: {
                        modelData.parent = this;
                        // Use Layout properties instead of anchors inside Layout
                        // But modelData might be a generic Item. 
                        // If it's being parented to 'this' (an Item in a RowLayout), it's fine.
                        modelData.anchors.fill = this;
                    }
                }
            }
        }



    }
}

