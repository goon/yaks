import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

FocusScope {
    id: root

    property string panelState: "Closed"

    implicitWidth: 500
    implicitHeight: {
        var searchHeight = Globals.dimensions.launcherSearchHeight;
        var padLarge = Globals.geometry.spacing.large;

        var count = apps.listCount;
        var visibleItems = Math.min(count, 8);

        if (visibleItems === 0) {
            return searchHeight + padLarge;
        }

        var itemHeight = Globals.dimensions.launcherItemHeight;
        var listHeight = (visibleItems * itemHeight) + (Math.max(0, visibleItems - 1) * padLarge);
        return searchHeight + (2 * padLarge) + 1 + listHeight;
    }

    property Item initialFocusItem: searchBar

    function opening() {
        LauncherService.resetInputStates();
        LauncherService.lastInputMethod = "keyboard";
        searchBar.text = "";
        apps.performSearch();
    }

    function closing() {
        searchBar.text = "";
    }

    function getCurrentListView() {
        return apps.listView;
    }

    function navigateDown() {
        var listView = getCurrentListView();
        if (listView && listView.count > 0) {
            LauncherService.resetInputStates();
            listView.forceActiveFocus();
            if (listView.currentIndex === -1)
                listView.currentIndex = 0;
            else
                listView.incrementCurrentIndex();
        }
    }

    function navigateUp() {
        var listView = getCurrentListView();
        if (listView) {
            if (listView.currentIndex > 0) {
                LauncherService.resetInputStates();
                listView.decrementCurrentIndex();
            } else {
                backToSearch("");
            }
        }
    }

    function activateCurrentItem() {
        apps.activateCurrentItem();
    }

    function backToSearch(text) {
        LauncherService.resetInputStates();
        searchBar.focusInput();
        if (text === "\b") {
            if (searchBar.text.length > 0)
                searchBar.text = searchBar.text.substring(0, searchBar.text.length - 1);
        } else if (text && text.length > 0) {
            searchBar.text += text;
        }
    }

    function handleListMouseMove(listView, index, mouse) {
        var globalPos = listView.mapToGlobal(mouse.x, mouse.y);
        if (LauncherService.handleMouseMove(globalPos.x, globalPos.y))
            listView.currentIndex = index;
    }

    Keys.onPressed: (event) => Binds.handleKey(event)

    anchors.fill: parent
    focus: true

    ColumnLayout {
        anchors.fill: parent
        spacing: Globals.geometry.spacing.large

        LauncherSearch {
            id: searchBar
        }

        BaseSeparator {
            Layout.fillWidth: true
            visible: apps.listCount > 0
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: apps.listCount > 0
            clip: true

            LauncherApps {
                id: apps
                anchors.fill: parent
                isActive: true
                searchText: searchBar.text
                onCloseRequested: IslandService.closeAll()
                onMouseMoveRequested: (index, mouse) => root.handleListMouseMove(apps.listView, index, mouse)
            }
        }
    }
}
