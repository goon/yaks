import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

BaseContainer {
    id: root

    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: false

    padding: Globals.geometry.padding.small
    hoverEnabled: false

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }

    BaseText {
        text: Qt.formatDateTime(systemClock.date, "HH:mm")
        pixelSize: Math.round(Globals.typography.size.large)
        weight: Globals.typography.weights.medium
        renderType: Text.NativeRendering
        font.features: ({ "tnum": 1 })
    }
}
