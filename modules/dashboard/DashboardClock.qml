import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

BaseBento {
    id: root

    implicitWidth: 120 + (paddingHorizontal * 2)
    implicitHeight: 320 + (paddingVertical * 2)
    hoverEnabled: true

    component TimeSegment: Item {
        id: segment
        property string text: ""
        property int pixelSize: Globals.typography.size.large * 1.8
        property color textColor: Globals.colors.primary
        property int fontWeight: Globals.typography.weights.bold

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

    SystemClock {
        id: systemClock
        precision: SystemClock.Seconds
    }

    Column {
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        spacing: 8

            TimeSegment {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(systemClock.date, "hh")
                pixelSize: Globals.typography.size.large * 1.8
                fontWeight: Globals.typography.weights.bold
                textColor: Globals.colors.primary
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4

                Repeater {
                    model: 3
                    delegate: Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: Globals.colors.secondary
                        opacity: 0.8
                        property int itemIndex: index

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: true
                            PauseAnimation { duration: itemIndex * 150 }
                            NumberAnimation { to: 0.2; duration: 400; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 0.8; duration: 400; easing.type: Easing.InOutSine }
                            PauseAnimation { duration: (2 - itemIndex) * 150 + 500 }
                        }                    }
                }
            }

            TimeSegment {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(systemClock.date, "mm")
                pixelSize: Globals.typography.size.large * 1.8
                fontWeight: Globals.typography.weights.bold
                textColor: Globals.colors.primary
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4

                Repeater {
                    model: 3
                    delegate: Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: Globals.colors.secondary
                        opacity: 0.8
                        property int itemIndex: index

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: true
                            PauseAnimation { duration: itemIndex * 150 }
                            NumberAnimation { to: 0.2; duration: 400; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 0.8; duration: 400; easing.type: Easing.InOutSine }
                            PauseAnimation { duration: (2 - itemIndex) * 150 + 500 }
                        }
                    }
                }
            }

            TimeSegment {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(systemClock.date, "ss")
                pixelSize: Globals.typography.size.large * 1.8
                fontWeight: Globals.typography.weights.bold
                textColor: Globals.colors.primary
        }
    }
}
