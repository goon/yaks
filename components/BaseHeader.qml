import QtQuick
import QtQuick.Layouts
import qs

BaseText {
    id: root

    pixelSize: Globals.typography.size.xs
    font.capitalization: Font.AllUppercase
    font.letterSpacing: 1.5
    muted: true

    visible: root.text !== ""
    Layout.fillWidth: true
    Layout.bottomMargin: Globals.geometry.spacing.xs
}
