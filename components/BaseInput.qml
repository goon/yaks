import QtQuick
import QtQuick.Controls
import qs

TextField {
    id: root

    color: Theme.colors.text
    font.family: Theme.typography.family
    font.pixelSize: Theme.typography.size.base
    font.letterSpacing: (root.echoMode === TextInput.Password && root.text.length > 0) ? 4 : 0
    placeholderTextColor: Theme.colors.muted
    leftPadding: Theme.geometry.padding.small
    rightPadding: Theme.geometry.padding.small
    topPadding: 0
    bottomPadding: 0
    verticalAlignment: Text.AlignVCenter
    background: Item { }
}
