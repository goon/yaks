import QtQuick
import qs

Text {
    id: root

    property alias pixelSize: root.font.pixelSize
    property alias family: root.font.family
    property alias weight: root.font.weight
    property bool muted: false

    color: root.muted ? Globals.colors.muted : Globals.colors.text
    font.family: Globals.typography.family
    font.pixelSize: Globals.typography.size.medium
    font.weight: Globals.typography.weights.normal
    wrapMode: Text.WordWrap

    Behavior on color { BaseMotion {} }
}