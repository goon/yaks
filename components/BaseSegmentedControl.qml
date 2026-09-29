import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

Rectangle {
    id: root

    property var model: []
    property var currentValue: undefined
    property string textRole: "label"
    property string valueRole: "value"

    signal activated(int index, var value)

    color: Globals.colors.well
    border.width: 1
    border.color: Globals.colors.hair
    radius: Globals.geometry.innerRadius.medium

    implicitHeight: 36
    implicitWidth: rowLayout.implicitWidth + (padding * 2)

    property int padding: 4

    property real indicatorX: padding
    property real indicatorWidth: 0
    property bool isReady: false

    Rectangle {
        id: slidingIndicator
        y: root.padding
        height: root.height - (root.padding * 2)
        radius: Globals.geometry.innerRadius.medium - root.padding
        color: Globals.colors.tint
        border.width: 1
        border.color: Globals.colors.primary

        opacity: root.isReady ? 1.0 : 0.0

        x: root.indicatorX
        width: root.indicatorWidth

        Behavior on x {
            enabled: root.isReady
            BaseMotion { }
        }
        Behavior on width {
            enabled: root.isReady
            BaseMotion { }
        }
    }

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: 4

        Repeater {
            model: root.model

            Rectangle {
                id: itemRect
                Layout.fillWidth: true
                Layout.fillHeight: true

                property bool isSelected: root.currentValue === (modelData[root.valueRole] !== undefined ? modelData[root.valueRole] : modelData)
                readonly property bool hovered: mouseArea.containsMouse

                radius: Globals.geometry.innerRadius.medium - root.padding
                color: "transparent"

                onIsSelectedChanged: {
                    if (isSelected) {
                        root.indicatorX = Qt.binding(function() { return itemRect.x + root.padding })
                        root.indicatorWidth = Qt.binding(function() { return itemRect.width })
                        root.isReady = true;
                    }
                }

                Component.onCompleted: {
                    if (isSelected) {
                        root.indicatorX = Qt.binding(function() { return itemRect.x + root.padding })
                        root.indicatorWidth = Qt.binding(function() { return itemRect.width })
                        root.isReady = true;
                    }
                }

                BaseText {
                    anchors.centerIn: parent
                    text: modelData[root.textRole] !== undefined ? modelData[root.textRole] : modelData
                    color: itemRect.isSelected ? Globals.colors.primary
                         : (itemRect.hovered ? Globals.colors.text : Globals.colors.muted)
                    weight: itemRect.isSelected ? Globals.typography.weights.medium : Globals.typography.weights.normal
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        let val = modelData[root.valueRole] !== undefined ? modelData[root.valueRole] : modelData;
                        root.currentValue = val;
                        root.activated(index, val);
                    }
                }
            }
        }
    }
}
