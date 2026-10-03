import QtQuick
import QtQuick.VectorImage
import QtQuick.Layouts
import Quickshell
import qs

BaseContainer {

    property real iconSize: 38 * Globals.shellScale

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

            implicitWidth: iconSize
            implicitHeight: clockText.height

            VectorImage {
                width: iconSize
                height: iconSize
                fillMode: VectorImage.Stretch
                anchors.centerIn: parent
                opacity: 0.85
                preferredRendererType: VectorImage.CurveRenderer

                source: {
                    if (!Weather.ready)
                        return "";
                    return Qt.resolvedUrl("../../assets/weather.svg");
                }
                animations.loops: Animation.Infinite
            }
        }

        BaseText {
            visible: Weather.ready
            text: Weather.temp + "°"
            pixelSize: Globals.typography.size.xl
            weight: Globals.typography.weight.normal
            font.letterSpacing: 1
            renderType: Text.NativeRendering
            font.features: ({ "tnum": 1 })
            Layout.alignment: Qt.AlignBottom
        }

        BaseText {
            id: clockText
            Layout.leftMargin: Globals.geometry.spacing.md
            text: Qt.formatDateTime(systemClock.date, "HH:mm")
            pixelSize: Globals.typography.size.xl
            weight: Globals.typography.weight.normal
            font.letterSpacing: 1
            renderType: Text.NativeRendering
            font.features: ({ "tnum": 1 })
            Layout.alignment: Qt.AlignBottom
        }
    }
}
