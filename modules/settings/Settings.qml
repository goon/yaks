import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.services
import qs

FocusScope {
    id: root

    property string panelState: "Closed"

    readonly property var popupWindow: Window.window

    implicitWidth: 460
    
    readonly property real maxHeight: (root.popupWindow && root.popupWindow.screen) 
        ? Math.min(860, root.popupWindow.screen.height * 0.9 - 40)
        : 760

    implicitHeight: Math.min(maxHeight, mainCol.implicitHeight)

    property alias pageStack: pageStack

    function changePage(pageFile) {
        pageStack.pushPage(Qt.resolvedUrl(pageFile), pageFile);
    }

    function closed() {
        pageStack.pop(null); // Return to root when closed
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            IslandService.closeAll();
            event.accepted = true;
        } else if (event.key === Qt.Key_Backspace && pageStack.depth > 1) {
            pageStack.pop(null);
            event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            if (SettingsNav.move(1)) event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            if (SettingsNav.move(-1)) event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            if (SettingsNav.adjust(-1)) event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            if (SettingsNav.adjust(1)) event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            if (SettingsNav.activate()) event.accepted = true;
        }
    }

    // Feed the active StackView page to the shared navigator. `currentItem`
    // changes on push/pop and when the panel first populates the stack, so a
    // single Connections covers every case; a page that adds navigable rows
    // after it is built must call SettingsNav.rebuild() itself.
    Connections {
        target: pageStack
        function onCurrentItemChanged() { SettingsNav.bind(pageStack.currentItem); }
    }

    Component.onCompleted: SettingsNav.bind(pageStack.currentItem)

    // Once the panel is fully open the page's rows have settled (visible), so
    // recollect — this catches rows the initial bind saw while still hidden.
    onPanelStateChanged: {
        if (panelState === "Open")
            SettingsNav.rebuild();
    }

    // Moving the pointer over the surface hands control back to the mouse:
    // clear the keyboard selection so the indicator follows the pointer again.
    // Keyboard use re-establishes it on the next arrow/enter press.
    HoverHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onPointChanged: SettingsNav.releaseFocus()
    }


    BaseContainer {
        id: mainCol
        anchors.fill: parent
        spacing: Globals.geometry.spacing.large

        // ── CONTENT AREA ──────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: pageStack.implicitHeight

            Item {
                anchors.fill: parent

                BaseScrolling {
                    id: contentScroller
                    anchors.fill: parent
                    clip: true
                    implicitHeight: 0

                    BaseStackView {
                        id: pageStack
                        width: contentScroller.availableWidth
                        implicitHeight: currentItem ? currentItem.implicitHeight : 0
                        initialItem: "Menu.qml"
                    }
                }
            }
        }
    }
}
