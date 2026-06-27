import QtQuick
import QtQuick.Layouts
import qs

Item {
    id: root

    property string icon: ""
    property string label: ""
    property string description: ""
    property bool showSeparator: true
    property bool clickable: false

    default property alias content: controlContainer.data

    readonly property bool hovered: clickArea.containsMouse
    readonly property real contentCenterY: contentWrapper.y + contentWrapper.height / 2

    signal clicked()

    implicitHeight: layout.implicitHeight + (showSeparator ? Globals.geometry.spacing.large * 2 + 1 : 0)
    Layout.fillWidth: true

    MouseArea {
        id: clickArea
        anchors.fill: parent
        enabled: root.clickable
        hoverEnabled: root.clickable
        cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        z: -1
        onClicked: root.clicked()
    }

    Item {
        id: contentWrapper
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: Globals.geometry.spacing.medium
        anchors.rightMargin: Globals.geometry.spacing.medium
        height: layout.implicitHeight

        RowLayout {
            id: layout
            anchors.fill: parent
            spacing: Globals.geometry.spacing.medium

            BaseIcon {
                visible: root.icon !== ""
                icon: root.icon
            }

            ColumnLayout {
                Layout.preferredWidth: parent.width * 0.4
                Layout.alignment: Qt.AlignLeft
                spacing: 2

                BaseText {
                    text: root.label
                    pixelSize: Globals.typography.size.medium
                    weight: Globals.typography.weights.medium
                }
                BaseText {
                    visible: root.description !== ""
                    text: root.description
                    pixelSize: Globals.typography.size.small
                    muted: true
                }
            }

            RowLayout {
                id: controlContainer
                Layout.preferredWidth: parent.width * 0.6
                Layout.alignment: Qt.AlignRight
                spacing: Globals.geometry.spacing.small

                property bool hasFillWidthChild: {
                    for (var i = 0; i < children.length; i++) {
                        var child = children[i];
                        if (child === rightSpacer) continue;
                        if (child.Layout && child.Layout.fillWidth) return true;
                    }
                    return false;
                }

                Item {
                    id: rightSpacer
                    Layout.fillWidth: !controlContainer.hasFillWidthChild
                    visible: !controlContainer.hasFillWidthChild
                }
            }
        }
    }

    BaseSeparator {
        visible: root.showSeparator
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Globals.geometry.spacing.large
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: root.icon !== "" ? (Globals.geometry.spacing.medium + Globals.dimensions.iconMedium + Globals.geometry.spacing.medium) : Globals.geometry.spacing.medium
    }
}
