import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

BaseContainer {
    id: clock

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

    // While a recording runs the clock gives way to its timer, tinted with the
    // palette's warm red so the state reads at a glance without leaving the theme.
    readonly property string _displayText: Recorder.recording ? Recorder.elapsedText : _timeText
    readonly property color _tint: Recorder.recording ? Theme.currentColors.error : Globals.colors.text

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
            text: _displayText.charAt(0)
            tint: clock._tint
            pixelSize: Globals.typography.size.xl
            weight: Globals.typography.weight.demi
            Layout.alignment: Qt.AlignVCenter
        }

        DigitCell {
            text: _displayText.charAt(1)
            tint: clock._tint
            pixelSize: Globals.typography.size.xl
            weight: Globals.typography.weight.demi
            Layout.alignment: Qt.AlignVCenter
        }

        BaseText {
            text: ":"
            pixelSize: Globals.typography.size.xl
            weight: Globals.typography.weight.demi
            color: clock._tint
            font.letterSpacing: 1
            renderType: Text.NativeRendering
            font.features: ({ "tnum": 1 })
            Layout.alignment: Qt.AlignVCenter
        }

        DigitCell {
            text: _displayText.charAt(3)
            tint: clock._tint
            pixelSize: Globals.typography.size.xl
            weight: Globals.typography.weight.demi
            Layout.alignment: Qt.AlignVCenter
        }

        DigitCell {
            text: _displayText.charAt(4)
            tint: clock._tint
            pixelSize: Globals.typography.size.xl
            weight: Globals.typography.weight.demi
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
