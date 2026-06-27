import QtQuick
import QtQuick.Controls
import qs

TextField {
    id: root

    color: Globals.colors.text
    font.family: Globals.typography.family
    font.pixelSize: Globals.typography.size.base
    font.letterSpacing: (root.echoMode === TextInput.Password && root.text.length > 0) ? 4 : 0
    placeholderTextColor: Globals.colors.muted
    leftPadding: Globals.geometry.padding.small
    rightPadding: Globals.geometry.padding.small
    topPadding: 0
    bottomPadding: 0
    verticalAlignment: Text.AlignVCenter
    background: Item { }
}
