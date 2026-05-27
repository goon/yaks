import QtQuick
import QtQuick.Layouts
import qs

BaseBlock {
    id: root
    width: parent ? parent.width : 0
    Layout.fillWidth: true
    
    // Default properties for settings blocks
    borderEnabled: false

    Component {
        id: spacerComponent
        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
        }
    }

    Component.onCompleted: {
        spacerComponent.createObject(_contentContainer);
    }
}
