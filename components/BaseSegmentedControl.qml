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

    color: Theme.alpha(Theme.colors.surface, 0.5) // Deeper well look
    radius: Theme.geometry.innerRadius.medium
    border.color: "transparent" // Remove hard border
    border.width: 0

    implicitHeight: 36
    implicitWidth: rowLayout.implicitWidth + (padding * 2)

    property int padding: 4

    property real indicatorX: padding
    property real indicatorWidth: 0
    property bool isReady: false

    BaseActiveBackground {
        id: slidingIndicator
        y: root.padding
        height: root.height - (root.padding * 2)
        radius: Theme.geometry.innerRadius.medium - root.padding
        premiumActive: true

        opacity: root.isReady ? 1.0 : 0.0

        x: root.indicatorX
        width: root.indicatorWidth

        Behavior on x {
            enabled: root.isReady
            BaseAnimation { easing.type: Easing.OutQuint }
        }
        Behavior on width {
            enabled: root.isReady
            BaseAnimation { easing.type: Easing.OutQuint }
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
                property bool isHovered: mouseArea.containsMouse

                radius: Theme.geometry.innerRadius.medium - root.padding
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
                    color: itemRect.isSelected ? Theme.colors.textLighter : Theme.colors.text
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
