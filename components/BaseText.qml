import QtQuick.Effects
import QtQuick
import qs

Text {
    id: root

    // Convenience properties for common overrides
    property alias pixelSize: root.font.pixelSize
    property alias bold: root.font.bold
    property alias family: root.font.family
    property alias weight: root.font.weight
    // Muted text mode (overrides color to Globals.colors.muted)
    property bool muted: false

    // Shadow support
    property bool shadow: false
    property color shadowColor: Globals.effects.shadow.color
    property int shadowRadius: Globals.effects.shadow.radius
    color: root.muted ? Globals.colors.muted : Globals.colors.text
    font.family: Globals.typography.family
    font.pixelSize: Globals.typography.size.base
    font.weight: Globals.typography.weights.normal
    wrapMode: Text.WordWrap
    layer.enabled: shadow

    Behavior on color { BaseAnimation {} }

    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: root.shadowColor
        shadowBlur: root.shadowRadius / 20.0
        shadowHorizontalOffset: Globals.effects.shadow.offsetX
        shadowVerticalOffset: Globals.effects.shadow.offsetY
    }

}
