import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

BaseBlock {
    id: root
    
    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: false
    backgroundColor: Theme.colors.transparent
    // Explicitly bind width for stable hover and layout in the bar
    implicitWidth: layout.implicitWidth + (paddingHorizontal * 2)
    implicitHeight: Theme.dimensions.barItemHeight
    paddingVertical: 0
    hoverEnabled: false
    clickable: true
    
    onClicked: {
        PopoutService.toggleDashboardPopout();
    }
    popoutOnHover: true
    onHoverAction: () => PopoutService.openPanel("dashboard")

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }

    // Individual segment for animated time units
    component TimeSegment: Item {
        id: segment
        property string text: ""
        property color textColor: root.containsMouse ? Theme.colors.primary : Theme.colors.text
        
        implicitWidth: widthDummy.implicitWidth
        implicitHeight: widthDummy.implicitHeight
        clip: true

        BaseText {
            id: widthDummy
            visible: false
            text: "00"
            
            pixelSize: Theme.typography.size.large
            weight: Theme.typography.weights.normal
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
            
            pixelSize: Theme.typography.size.large
            weight: Theme.typography.weights.normal
            color: segment.textColor
        }

        BaseText {
            id: nextText
            anchors.horizontalCenter: segment.horizontalCenter
            y: segment.centerY - segment.height
            opacity: 0
            text: segment.text
            
            pixelSize: Theme.typography.size.large
            weight: Theme.typography.weights.normal
            color: segment.textColor
        }

        SequentialAnimation {
            id: anim
            
            ParallelAnimation {
                BaseAnimation {
                    target: currentText
                    property: "y"
                    to: segment.centerY + segment.height
                    duration: 200
                    easing.type: Easing.OutCubic
                }
                BaseAnimation {
                    target: currentText
                    property: "opacity"
                    to: 0
                    duration: 200
                    easing.type: Easing.OutCubic
                }
                BaseAnimation {
                    target: nextText
                    property: "y"
                    from: segment.centerY - segment.height
                    to: segment.centerY
                    duration: 200
                    easing.type: Easing.OutCubic
                }
                BaseAnimation {
                    target: nextText
                    property: "opacity"
                    to: 1
                    duration: 200
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

    // Centering wrapper to ensure proper alignment and hover area
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        implicitWidth: layout.implicitWidth
        implicitHeight: layout.implicitHeight

        RowLayout {
            id: layout
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 1
            spacing: Theme.geometry.spacing.medium

            // Time Segments
            RowLayout {
                spacing: 0

                TimeSegment {
                    text: Qt.formatDateTime(systemClock.date, "hh")
                }

                TimeSegment {
                    text: Qt.formatDateTime(systemClock.date, "mm")
                }
            }

            }
    }
}
