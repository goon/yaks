import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs
BaseContainer {
    id: root
    width: parent ? parent.width : 0
    spacing: Globals.geometry.spacing.small
    
    property string title: ""
    property string icon: ""
    property string description: ""

    onRightClicked: {
        if (root.StackView.view && root.StackView.view.depth > 1) {
            root.StackView.view.pop(null);
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: Globals.geometry.spacing.small / 2
        spacing: Globals.geometry.spacing.small

        RowLayout {
            Layout.fillWidth: true
            spacing: Globals.geometry.spacing.small

            BaseIcon {
                icon: "chevron_left"
                color: backMouseArea.containsMouse ? Globals.colors.primary : Globals.colors.text
                Layout.alignment: Qt.AlignVCenter
                Behavior on color { BaseAnimation { } }

                MouseArea {
                    id: backMouseArea
                    anchors.fill: parent
                    anchors.margins: -8
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.StackView.view) {
                            root.StackView.view.pop();
                        }
                    }
                }
            }

            BaseHeader {
                id: pageHeader
                text: root.title.toUpperCase()
                Layout.fillWidth: true
            }
        }
        
        BaseSeparator {
            Layout.fillWidth: true
        }
    } // End of header ColumnLayout
}
