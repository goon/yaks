import QtQuick
import QtQuick.Layouts
import qs

BaseBlock {
    id: root
    width: parent ? parent.width : 0
    Layout.fillWidth: true
    
    // Default properties for dashboard blocks
    borderEnabled: false
    backgroundColor: Theme.colors.transparent
    hoverEnabled: false
    padding: 0
    paddingHorizontal: 0
    paddingVertical: 0
}
