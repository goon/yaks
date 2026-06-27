import qs
import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root
    
    enum Orientation {
        Horizontal,
        Vertical
    }
    
    property int orientation: BaseSeparator.Horizontal
    
    implicitWidth: orientation === BaseSeparator.Vertical ? 1 : 20
    implicitHeight: orientation === BaseSeparator.Horizontal ? 1 : 20
    
    // Support for Layout.fillWidth/fillHeight
    Layout.fillWidth: orientation === BaseSeparator.Horizontal
    Layout.fillHeight: orientation === BaseSeparator.Vertical
    
    color: Theme.colors.border
    opacity: 0.3
}
