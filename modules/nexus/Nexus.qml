import QtQuick
import QtQuick.Layouts
import qs

FocusScope {
    id: root

    implicitWidth: 500
    implicitHeight: mainLayout.implicitHeight

    property string panelState: "Closed"

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
