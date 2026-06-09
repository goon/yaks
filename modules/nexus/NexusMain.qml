import QtQuick
import QtQuick.Layouts
import qs

Item {
    id: root
    implicitWidth: 500
    implicitHeight: mainLayout.implicitHeight

    BaseScroller {
        anchors.fill: parent
        clip: false
        
        ColumnLayout {
            id: mainLayout
            width: parent.width
            spacing: Theme.geometry.spacing.large
            
            HubQuickActions {
                Layout.fillWidth: true
            }

            HubPower {
                Layout.fillWidth: true
            }

            HubSliders {
                Layout.fillWidth: true
            }

            HubNotifications {
                Layout.fillWidth: true
            }
        }
    }
}
