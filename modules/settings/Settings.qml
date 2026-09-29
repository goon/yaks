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

    function changePage(pageName) {
        pageStack.push(pageName + ".qml");
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

    // Feed the current StackView page to the shared navigator. The StackView's
    // initialItem is assigned after this component completes, so bind on both
    // the page change and the panel opening, and retry once on completion.
    readonly property Item _currentPage: pageStack.currentItem

    function _bindCurrentPage() {
        if (root._currentPage)
            SettingsNav.bind(root._currentPage);
        else
            bindRetry.restart();
    }

    on_CurrentPageChanged: root._bindCurrentPage()

    onPanelStateChanged: {
        if (panelState === "Opening" || panelState === "Open")
            root._bindCurrentPage();
    }

    Component.onCompleted: root._bindCurrentPage()

    Timer {
        id: bindRetry
        interval: 60
        repeat: true
        property int tries: 0
        onTriggered: {
            tries++;
            if (root._currentPage || tries > 30) {
                stop();
                if (root._currentPage)
                    SettingsNav.bind(root._currentPage);
            }
        }
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
