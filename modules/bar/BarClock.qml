import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

BaseContainer {

    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: false

    padding: Globals.geometry.spacing.sm
    clickable: true

    onClicked: Modules.toggleModule("calendar")

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }

    readonly property string _timeText: Qt.formatDateTime(systemClock.date, "HH:mm")

    component DigitCell: Item {
        id: cell

        property string text: ""
        property int pixelSize: Globals.typography.size.md
        property int weight: Globals.typography.weight.demi
        property color tint: Globals.colors.text

        implicitWidth: cur.implicitWidth
        implicitHeight: cur.implicitHeight

        BaseText {
            id: prev
            anchors.centerIn: parent
            transformOrigin: Item.Center
            pixelSize: cell.pixelSize
            weight: cell.weight
            color: cell.tint
            font.letterSpacing: 1
            renderType: Text.NativeRendering
            font.features: ({ "tnum": 1 })
            opacity: 0
        }

        BaseText {
            id: cur
            anchors.centerIn: parent
            transformOrigin: Item.Center
            text: cell.text
            pixelSize: cell.pixelSize
            weight: cell.weight
            color: cell.tint
            font.letterSpacing: 1
            renderType: Text.NativeRendering
            font.features: ({ "tnum": 1 })
        }

        ParallelAnimation {
            id: popAnim

            NumberAnimation {
                target: prev
                property: "scale"
                from: 1.0
                to: 0.9
                duration: Globals.motion.hover
                easing.type: Globals.motion.easeStandard
            }

            NumberAnimation {
                target: prev
                property: "opacity"
                from: 1.0
                to: 0
                duration: Globals.motion.hover
                easing.type: Globals.motion.easeStandard
            }

            NumberAnimation {
                target: cur
                property: "scale"
                from: 1.1
                to: 1.0
                duration: Globals.motion.standard
                easing.type: Globals.motion.easeStandard
            }

            NumberAnimation {
                target: cur
                property: "opacity"
                from: 0
                to: 1
                duration: Globals.motion.standard
                easing.type: Globals.motion.easeStandard
            }
        }

        onTextChanged: {
            prev.text = cur.text
            cur.text = cell.text
            popAnim.restart()
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignVCenter
        spacing: 0

        DigitCell {
            text: _timeText.charAt(0)
            pixelSize: Globals.typography.size.xl
            weight: Globals.typography.weight.demi
            Layout.alignment: Qt.AlignVCenter
        }

        DigitCell {
            text: _timeText.charAt(1)
            pixelSize: Globals.typography.size.xl
            weight: Globals.typography.weight.demi
            Layout.alignment: Qt.AlignVCenter
        }

        BaseText {
            text: ":"
            pixelSize: Globals.typography.size.xl
            weight: Globals.typography.weight.demi
            font.letterSpacing: 1
            renderType: Text.NativeRendering
            font.features: ({ "tnum": 1 })
            Layout.alignment: Qt.AlignVCenter
        }

        DigitCell {
            text: _timeText.charAt(3)
            pixelSize: Globals.typography.size.xl
            weight: Globals.typography.weight.demi
            Layout.alignment: Qt.AlignVCenter
        }

        DigitCell {
            text: _timeText.charAt(4)
            pixelSize: Globals.typography.size.xl
            weight: Globals.typography.weight.demi
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
