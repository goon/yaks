import QtQuick
import QtQuick.Layouts
import qs

BaseBlock {
    id: root
    width: parent ? parent.width : 0
    Layout.fillWidth: true
    
    property string title: ""
    property string icon: ""
    
    // Default properties for settings blocks
    borderEnabled: false

    BaseHeader {
        title: root.title
        icon: root.icon
    }

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
