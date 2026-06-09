import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs

FocusScope {
    id: root

    implicitWidth: 500
    // Dynamic height based on current item
    implicitHeight: Math.max(header.height + (pageStack.currentItem ? pageStack.currentItem.implicitHeight : 0), 100)

    property string panelState: "Closed"

    function pushPage(pageName) {
        var pagePath = "views/" + pageName + ".qml";
        
        // Map custom aliases back to specific views if needed
        if (pageName === "network" || pageName === "wifi") pagePath = "views/NexusNetwork.qml";
        if (pageName === "bluetooth") pagePath = "views/NexusBluetooth.qml";

        // Don't push if already there
        if (pageStack.currentItem && pageStack.currentItem.objectName === pagePath) return;

        pageStack.push(pagePath, { objectName: pagePath });
    }

    function popPage() {
        if (pageStack.depth > 1) {
            pageStack.pop();
        }
    }

    onPanelStateChanged: {
        if (panelState === "Closed") {
            // Reset to main view when panel closes
            while (pageStack.depth > 1) {
                pageStack.pop();
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Navigation Header (only visible when deeper than 1)
        Item {
            id: header
            Layout.fillWidth: true
            Layout.preferredHeight: pageStack.depth > 1 ? 52 : 0
            visible: pageStack.depth > 1
            clip: true

            Behavior on Layout.preferredHeight { BaseAnimation { duration: Theme.animations.fast } }

            RowLayout {
                anchors.fill: parent
                spacing: Theme.geometry.spacing.medium

                BaseButton {
                    icon: "arrow_back"
                    text: "Back"
                    Layout.preferredHeight: 36
                    normalColor: Theme.colors.transparent
                    hoverColor: Theme.alpha(Theme.colors.text, 0.1)
                    textColor: Theme.colors.text
                    iconColor: Theme.colors.text
                    onClicked: root.popPage()
                }

                Item { Layout.fillWidth: true }
            }
        }

        StackView {
            id: pageStack
            Layout.fillWidth: true
            Layout.fillHeight: true

            initialItem: NexusMain {}

            pushEnter: Transition {
                ParallelAnimation {
                    BaseAnimation { property: "opacity"; from: 0; to: 1; speed: "normal"; easing.type: Easing.OutQuad }
                    BaseAnimation { property: "scale"; from: 0.95; to: 1; speed: "normal"; easing.type: Easing.OutQuad }
                }
            }

            pushExit: Transition {
                BaseAnimation { property: "opacity"; from: 1; to: 0; speed: "normal"; easing.type: Easing.OutQuad }
            }

            popEnter: Transition {
                ParallelAnimation {
                    BaseAnimation { property: "opacity"; from: 0; to: 1; speed: "normal"; easing.type: Easing.OutQuad }
                    BaseAnimation { property: "scale"; from: 1.05; to: 1; speed: "normal"; easing.type: Easing.OutQuad }
                }
            }

            popExit: Transition {
                BaseAnimation { property: "opacity"; from: 1; to: 0; speed: "normal"; easing.type: Easing.OutQuad }
            }
        }
    }
}
