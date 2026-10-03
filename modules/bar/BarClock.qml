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
        spacing: Globals.geometry.spacing.xs

        Item {
            id: weatherIcon

            visible: Weather.ready
            Layout.alignment: Qt.AlignBottom

            opacity: Weather.ready ? 1 : 0
            Behavior on opacity { BaseMotion {} }

            implicitWidth: weatherImg.implicitWidth
            implicitHeight: weatherImg.implicitHeight

            Image {
                id: weatherImg

                anchors.centerIn: parent
                source: {
                    if (!Weather.ready)
                        return "";
                    return Qt.resolvedUrl("../../assets/weather/" + Weather.iconFor(Weather.code, Weather.isDay) + ".svg");
                }
                sourceSize.width: Globals.typography.size.xl
                sourceSize.height: Globals.typography.size.xl
                asynchronous: true
            }
        }

        BaseText {
            visible: Weather.ready
            text: Weather.temp + "°"
            muted: true
            Layout.alignment: Qt.AlignBottom
        }

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
