import QtQuick
import QtQuick.VectorImage
import QtQuick.Layouts
import Quickshell
import qs

// The weather half of the clock block: one fixed animated icon for every
// condition (the per-condition set was tried and reverted) plus the temperature.
// A vendored Meteocons SVG — plain `Image` would only ever show its first frame.
// Clicking opens the forecast popout; per-condition glyphs live there, not here.
BaseContainer {
    id: root

    Layout.alignment: Qt.AlignVCenter
    Layout.fillWidth: false
    padding: Globals.geometry.spacing.sm
    clickable: true
    onClicked: Modules.toggleModule("forecast")

    property real iconSize: 38 * Globals.shellScale

    RowLayout {
        spacing: Globals.geometry.spacing.xs

        Item {
            id: weatherIcon

            visible: Weather.ready
            Layout.alignment: Qt.AlignVCenter

            opacity: Weather.ready ? 1 : 0
            Behavior on opacity { BaseMotion {} }

            implicitWidth: root.iconSize

            VectorImage {
                width: root.iconSize
                height: root.iconSize
                fillMode: VectorImage.Stretch
                anchors.centerIn: parent
                opacity: 0.85
                preferredRendererType: VectorImage.CurveRenderer

                source: Weather.ready ? Qt.resolvedUrl("../../assets/weather.svg") : ""
                animations.loops: Animation.Infinite
            }
        }

        BaseText {
            visible: Weather.ready
            text: Weather.temp + " °"
            pixelSize: Globals.typography.size.xl
            font.letterSpacing: 0
            renderType: Text.NativeRendering
            font.features: ({ "tnum": 1 })
            Layout.alignment: Qt.AlignVCenter
        }
    }
}