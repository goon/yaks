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

    RowLayout {
        Layout.alignment: Qt.AlignVCenter
        spacing: Globals.geometry.spacing.xs

        BaseText {
            text: Preferences.bar.clock12Hour
                ? Qt.formatDateTime(systemClock.date, "hh:mm")
                : Qt.formatDateTime(systemClock.date, "HH:mm")
            pixelSize: Globals.typography.size.xl
            weight: Globals.typography.weight.demi
            font.letterSpacing: 1
            renderType: Text.NativeRendering
            font.features: ({ "tnum": 1 })
        }

        BaseText {
            visible: Preferences.bar.clock12Hour
            text: Qt.formatDateTime(systemClock.date, "ap").toLowerCase()
            pixelSize: Globals.typography.size.md
            weight: Globals.typography.weight.demi
            font.letterSpacing: 1
            renderType: Text.NativeRendering
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
