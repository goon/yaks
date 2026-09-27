import QtQuick
import Quickshell
import qs

FocusScope {
    id: root

    // ── PUBLIC INTERFACE ──────────────────────────────────────────────
    property string searchText: ""
    property bool isActive: false
    property var listView: appListView

    readonly property int listCount: cachedModel.length

    signal closeRequested()
    signal mouseMoveRequested(int index, var mouse)

    // ── INTERNAL STATE ────────────────────────────────────────────────
    property var cachedModel: []
    property string _lastQuery: ""

    onSearchTextChanged: searchDebounceTimer.restart()

    function performSearch() {
        var query = searchText.trim();
        var queryChanged = query !== _lastQuery;
        _lastQuery = query;

        cachedModel = LauncherService.searchApps(query, DesktopEntries.applications.values, 100);
        updateCurrentIndex(queryChanged);
    }

    function updateCurrentIndex(queryChanged) {
        if (queryChanged || appListView.currentIndex === -1) {
            if (cachedModel.length > 0)
                appListView.currentIndex = 0;
            else
                appListView.currentIndex = -1;
        }
    }

    function activateCurrentItem() {
        searchDebounceTimer.stop();
        performSearch();

        if (appListView.currentIndex < 0 && cachedModel.length > 0)
            appListView.currentIndex = 0;

        if (appListView.currentIndex >= 0 && appListView.currentIndex < cachedModel.length) {
            LauncherService.executeItem(cachedModel[appListView.currentIndex]);
            closeRequested();
        }
    }

    // ── SUB-COMPONENTS ────────────────────────────────────────────────

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() {
            if (root.isActive) root.performSearch();
        }
    }

    Timer {
        id: searchDebounceTimer
        interval: 100
        repeat: false
        onTriggered: root.performSearch()
    }

    LauncherListView {
        id: appListView
        anchors.fill: parent
        model: root.cachedModel

        onCountChanged: {
            if (LauncherService.lastInputMethod === "keyboard" || currentIndex === -1) {
                if (count > 0 && currentIndex < 0)
                    currentIndex = 0;
                else if (count === 0)
                    currentIndex = -1;
            }
        }

        delegate: LauncherItemDelegate {
            itemIndex: index
            selected: appListView.currentIndex === index

            text: modelData ? modelData.name : ""
            subText: {
                if (!modelData) return "";
                return Preferences.launcher.showAppDescriptions ? (modelData.description || "") : "";
            }

            imageSource: modelData ? LauncherService.resolveIcon(modelData.icon) : ""
            showFallbackIcon: imageSource === ""
            fallbackText: (modelData && modelData.name && modelData.name.length > 0) ? modelData.name.charAt(0).toUpperCase() : "?"

            onClicked: {
                appListView.currentIndex = index;
                root.activateCurrentItem();
            }
        }
    }
}
