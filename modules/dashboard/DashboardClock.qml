import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

BaseBlock {
    id: root

    implicitWidth: 120
    implicitHeight: 320

    padding: 0
    paddingHorizontal: 0
    paddingVertical: 0

    // Individual segment for animated time units
    component TimeSegment: Item {
        id: segment
        property string text: ""
        property int pixelSize: Theme.typography.size.large * 1.8
        property color textColor: Theme.colors.primary
        property int fontWeight: Theme.typography.weights.bold

        implicitWidth: widthDummy.implicitWidth
        implicitHeight: widthDummy.implicitHeight
        clip: true

        BaseText {
            id: widthDummy
            visible: false
            text: segment.text
            pixelSize: segment.pixelSize
            weight: segment.fontWeight
        }

        readonly property real centerY: (segment.height - currentText.height) / 2
        property string displayedText: text

        onTextChanged: {
            nextText.text = text;
            anim.restart();
        }

        BaseText {
            id: currentText
            anchors.horizontalCenter: segment.horizontalCenter
            y: segment.centerY
            text: segment.displayedText
            pixelSize: segment.pixelSize
            weight: segment.fontWeight
            color: segment.textColor
        }

        BaseText {
            id: nextText
            anchors.horizontalCenter: segment.horizontalCenter
            y: segment.centerY - segment.height
            opacity: 0
            text: segment.text
            pixelSize: segment.pixelSize
            weight: segment.fontWeight
            color: segment.textColor
        }

        SequentialAnimation {
            id: anim
            
            ParallelAnimation {
                BaseAnimation {
                    target: currentText
                    property: "y"
                    to: segment.centerY + segment.height
                    duration: 250
                    easing.type: Easing.OutCubic
                }
                BaseAnimation {
                    target: currentText
                    property: "opacity"
                    to: 0
                    duration: 250
                    easing.type: Easing.OutCubic
                }
                BaseAnimation {
                    target: nextText
                    property: "y"
                    from: segment.centerY - segment.height
                    to: segment.centerY
                    duration: 250
                    easing.type: Easing.OutCubic
                }
                BaseAnimation {
                    target: nextText
                    property: "opacity"
                    to: 1
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }

            ScriptAction {
                script: {
                    segment.displayedText = segment.text;
                    currentText.y = segment.centerY;
                    currentText.opacity = 1;
                    nextText.y = segment.centerY - segment.height;
                    nextText.opacity = 0;
                }
            }
        }
    }

    // Single fill-item that takes up the whole contentContainer
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        SystemClock {
            id: systemClock
            precision: SystemClock.Seconds
        }

        // Inner column centered in the available space
        Column {
            anchors.centerIn: parent
            spacing: 8

            // Hour Label
            TimeSegment {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(systemClock.date, "hh")
                pixelSize: Theme.typography.size.large * 1.8
                fontWeight: Theme.typography.weights.bold
                textColor: Theme.colors.primary
            }

            // First Horizontal Dots separator
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4

                Repeater {
                    model: 3
                    delegate: Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: Theme.colors.secondary
                        opacity: 0.8
                    }
                }
            }

            // Minute Label
            TimeSegment {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(systemClock.date, "mm")
                pixelSize: Theme.typography.size.large * 1.8
                fontWeight: Theme.typography.weights.bold
                textColor: Theme.colors.primary
            }

            // Second Horizontal Dots separator
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4

                Repeater {
                    model: 3
                    delegate: Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: Theme.colors.secondary
                        opacity: 0.8
                    }
                }
            }

            // Seconds Label
            TimeSegment {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(systemClock.date, "ss")
                pixelSize: Theme.typography.size.large * 1.8
                fontWeight: Theme.typography.weights.bold
                textColor: Theme.colors.primary
            }
        }
    }
}
