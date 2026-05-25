import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

BasePopoutWindow {
    id: root

    panelNamespace: "quickshell:bluetooth-popout"

    body: ScrollView {
        implicitWidth: 600
        implicitHeight: Math.min(800, mainLayout.implicitHeight)
        contentWidth: availableWidth
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            id: mainLayout

            width: parent.width
            spacing: Theme.geometry.spacing.large

            BluetoothContent {
                Layout.fillWidth: true
            }
        }
    }
}
