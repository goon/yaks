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

    implicitHeight: layout.implicitHeight + (showSeparator ? Theme.geometry.spacing.large * 2 + 1 : 0)
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
        anchors.leftMargin: Theme.geometry.spacing.medium
        anchors.rightMargin: Theme.geometry.spacing.medium
        height: layout.implicitHeight

        RowLayout {
            id: layout
            anchors.fill: parent
            spacing: Theme.geometry.spacing.medium

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
                    pixelSize: Theme.typography.size.medium
                    weight: Theme.typography.weights.medium
                }
                BaseText {
                    visible: root.description !== ""
                    text: root.description
                    pixelSize: Theme.typography.size.small
                    muted: true
                }
            }

            RowLayout {
                id: controlContainer
                Layout.preferredWidth: parent.width * 0.6
                Layout.alignment: Qt.AlignRight
                spacing: Theme.geometry.spacing.small

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
        anchors.bottomMargin: Theme.geometry.spacing.large
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: root.icon !== "" ? (Theme.geometry.spacing.medium + Theme.dimensions.iconMedium + Theme.geometry.spacing.medium) : Theme.geometry.spacing.medium
    }
}
