import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

BaseContainer {

    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: false

    padding: Globals.geometry.spacing.sm
    hoverEnabled: false

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }

    RowLayout {
        spacing: Globals.geometry.spacing.xs

        BaseText {
            text: Qt.formatDateTime(systemClock.date, "HH:mm")
            pixelSize: Globals.typography.size.xl
            weight: Globals.typography.weight.demi
            font.letterSpacing: 1
            renderType: Text.NativeRendering
            font.features: ({ "tnum": 1 })
            Layout.alignment: Qt.AlignBottom
        }
    }
}
