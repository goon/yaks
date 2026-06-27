import QtQuick
import QtQuick.Layouts
import qs

BaseText {
    id: root

    property bool isActive: true

    visible: text !== ""
    weight: Globals.typography.weights.bold
    font.letterSpacing: 3.0
    color: isActive ? Globals.colors.text : Globals.alpha(Globals.colors.text, 0.5)
    
    verticalAlignment: Text.AlignBottom
    Layout.preferredHeight: Globals.dimensions.iconMedium

    Layout.bottomMargin: Globals.geometry.spacing.small / 2
    Layout.fillWidth: true
}
