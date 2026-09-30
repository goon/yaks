import QtQuick.Effects
import QtQuick
import qs

Text {
    id: root

    property alias pixelSize: root.font.pixelSize
    property alias bold: root.font.bold
    property alias family: root.font.family
    property alias weight: root.font.weight
    property bool muted: false

    property bool shadow: false
    property color shadowColor: Globals.effects.shadow.color
    color: root.muted ? Globals.colors.muted : Globals.colors.text
    font.family: Globals.typography.family
    font.pixelSize: Globals.typography.size.medium
    font.weight: Globals.typography.weights.normal
    wrapMode: Text.WordWrap
    layer.enabled: shadow

    Behavior on color { BaseMotion {} }

    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: root.shadowColor
        shadowBlur: Globals.effects.shadow.radius / 20.0
        shadowHorizontalOffset: Globals.effects.shadow.offsetX
        shadowVerticalOffset: Globals.effects.shadow.offsetY
    }

}
