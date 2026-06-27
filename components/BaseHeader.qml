import QtQuick
import QtQuick.Layouts
import qs

BaseText {
    id: root

    property bool isActive: true

    visible: text !== ""
    weight: Theme.typography.weights.bold
    font.letterSpacing: 3.0
    color: isActive ? Theme.colors.text : Theme.alpha(Theme.colors.text, 0.5)
    
    verticalAlignment: Text.AlignBottom
    Layout.preferredHeight: Theme.dimensions.iconMedium

    Layout.bottomMargin: Theme.geometry.spacing.small / 2
    Layout.fillWidth: true
}
