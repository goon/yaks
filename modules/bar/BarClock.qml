import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

BaseContainer {
    id: root

    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: false

    padding: Globals.geometry.padding.small
    implicitWidth: layout.implicitWidth + (paddingHorizontal * 2)
    hoverEnabled: false

    component TimeSegment: Item {
        id: segment
        property string text: ""
        property int pixelSize: 18
        property int fontWeight: Globals.typography.weights.bold
        property color textColor: Globals.colors.text

        implicitWidth: widthDummy.implicitWidth + 6
        implicitHeight: widthDummy.implicitHeight + 12
        clip: true

        BaseText {
            id: widthDummy
            visible: false
            text: "88"
            pixelSize: segment.pixelSize
            weight: segment.fontWeight
        }

        readonly property real centerY: Math.max(0, (segment.height - currentText.height) / 2)
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
                BaseMotion {
                    target: currentText
                    property: "y"
                    to: segment.centerY + segment.height
                    duration: Globals.motion.standard
                    easing.type: Globals.motion.easeStandard
                }
                BaseMotion {
                    target: currentText
                    property: "opacity"
                    to: 0
                    duration: Globals.motion.standard
                    easing.type: Globals.motion.easeStandard
                }
                BaseMotion {
                    target: nextText
                    property: "y"
                    from: segment.centerY - segment.height
                    to: segment.centerY
                    duration: Globals.motion.standard
                    easing.type: Globals.motion.easeStandard
                }
                BaseMotion {
                    target: nextText
                    property: "opacity"
                    to: 1
                    duration: Globals.motion.standard
                    easing.type: Globals.motion.easeStandard
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

    component DotSeparator: Column {
        id: dots
        spacing: 4
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined

        readonly property int _colonFadeMs: 400
        readonly property int _colonStaggerMs: 200
        readonly property int _colonHoldMs: 500

        Repeater {
            model: 2
            delegate: Rectangle {
                width: 6
                height: 6
                radius: width / 2
                color: Globals.colors.secondary
                opacity: 0.8
                property int itemIndex: index

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: true
                    PauseAnimation { duration: itemIndex * dots._colonStaggerMs }
                    NumberAnimation { to: 0.2; duration: dots._colonFadeMs; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.8; duration: dots._colonFadeMs; easing.type: Easing.InOutSine }
                    PauseAnimation { duration: (1 - itemIndex) * dots._colonStaggerMs + dots._colonHoldMs }
                }
            }
        }
    }

    SystemClock {
        id: systemClock
        precision: SystemClock.Seconds
    }

    Row {
        id: layout
        spacing: Globals.geometry.spacing.medium
        anchors.verticalCenter: parent.verticalCenter

        TimeSegment {
            text: Qt.formatDateTime(systemClock.date, "HH")
        }

        DotSeparator {}

        TimeSegment {
            text: Qt.formatDateTime(systemClock.date, "mm")
        }

        DotSeparator {}

        TimeSegment {
            text: Qt.formatDateTime(systemClock.date, "ss")
        }
    }
}
