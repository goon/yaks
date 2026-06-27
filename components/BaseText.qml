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
    // Muted text mode (overrides color to Theme.colors.muted)
    property bool muted: false

    // Shadow support
    property bool shadow: false
    property color shadowColor: Theme.effects.shadow.color
    property int shadowRadius: Theme.effects.shadow.radius
    color: root.muted ? Theme.colors.muted : Theme.colors.text
    font.family: Theme.typography.family
    font.pixelSize: Theme.typography.size.base
    font.weight: Theme.typography.weights.normal
    wrapMode: Text.WordWrap
    layer.enabled: shadow

    Behavior on color { BaseAnimation {} }

    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: root.shadowColor
        shadowBlur: root.shadowRadius / 20.0
        shadowHorizontalOffset: Theme.effects.shadow.offsetX
        shadowVerticalOffset: Theme.effects.shadow.offsetY
    }

}
