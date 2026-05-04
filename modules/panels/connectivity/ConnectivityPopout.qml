import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

BasePopoutWindow {
    id: root

    property int currentTabIndex: 0

    // Helper to switch tabs externally
    function switchToTab(index) {
        root.currentTabIndex = index;
    }

    panelNamespace: "quickshell:connectivity-popout"

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

            // --- Header Section (Tabs) ---
            BaseBlock {
                id: tabBlock

                Layout.fillWidth: true
                padding: 4

                BaseMultiButton {
                    id: multiButton

                    model: [{
                        "text": "Network",
                        "icon": "wifi"
                    }, {
                        "text": "Bluetooth",
                        "icon": "bluetooth"
                    }]
                    selectedIndex: root.currentTabIndex
                    buttonCustomRadius: tabBlock.blockRadius - tabBlock.padding
                    onButtonClicked: (index) => {
                        root.currentTabIndex = index;
                    }
                }
            }

            // --- Body / Content Stack ---
            StackLayout {
                id: mainStack

                Layout.fillWidth: true
                currentIndex: root.currentTabIndex
                Layout.preferredHeight: currentIndex >= 0 ? children[currentIndex].implicitHeight : 0

                // Network Tab
                NetworkContent {
                    Layout.fillWidth: true
                }

                // Bluetooth Tab
                BluetoothContent {
                    Layout.fillWidth: true
                }
            }
        }
    }
}
