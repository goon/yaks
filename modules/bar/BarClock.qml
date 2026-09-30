import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

BaseContainer {

    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: false

    padding: Globals.geometry.padding.small
    hoverEnabled: false

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }

    RowLayout {
        spacing: Globals.geometry.spacing.small

        BaseText {
            text: Qt.formatDateTime(systemClock.date, "HH:mm")
            pixelSize: Math.round(24 * Globals.shellScale)
            weight: Globals.typography.weights.medium
            font.letterSpacing: 1
            renderType: Text.NativeRendering
            font.features: ({ "tnum": 1 })
            Layout.alignment: Qt.AlignBottom
        }
    }
}
