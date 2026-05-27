import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs

LauncherTab {
    id: root

    // --- Tab Configuration ---
    property bool includeWindows: false
    
    // Alias for the list view so the parent (Launcher.qml) can control it
    listView: appListView

    // --- Internal Properties ---
    property var cachedModel: []
    property string _lastQuery: ""
    property string specialMode: ""
    property string specialModeText: ""

    // --- Search Handling ---
    
    onSearchTextChanged: {
        searchDebounceTimer.restart();
    }

    // Called by the base class when this tab becomes active
    function onActivated() {
        if (root.searchText.trim() === "")
            appListView.currentIndex = 0;

        performSearch();
        
        if (appListView.count > 0 && appListView.currentIndex === -1)
             appListView.currentIndex = 0;
    }

    // Override the base performSearch
    function performSearch() {
        var rawQuery = root.searchText;
        var globalPrefix = Preferences.launcherGlobalPrefix || ">";
        if (rawQuery.startsWith(globalPrefix) && LauncherService.activeUtilityMode === "") {
            var rest = rawQuery.substring(globalPrefix.length);
            var spaceIdx = rest.indexOf(" ");
            if (spaceIdx !== -1) {
                var trigger = rest.substring(0, spaceIdx).trim();
                var remaining = rest.substring(spaceIdx + 1);
                
                var modeToEnter = "";
                if (trigger === "s" || trigger === "web") modeToEnter = "web";
                else if (trigger === "c" || trigger === "calc" || trigger === "calculator") modeToEnter = "calculator";
                else if (trigger === "" || trigger === "cmd" || trigger === "command") modeToEnter = "command";
                else if (trigger === "w" || trigger === "wallpaper") {
                    root.tabRedirectRequested(2);
                    return;
                }
                else {
                    if (Preferences.launcherBangs) {
                        for (var i = 0; i < Preferences.launcherBangs.length; i++) {
                            if (Preferences.launcherBangs[i].trigger === trigger) {
                                modeToEnter = "bang-" + trigger;
                                break;
                            }
                        }
                    }
                }
                
                if (modeToEnter !== "") {
                    LauncherService.activeUtilityMode = modeToEnter;
                    root.searchTextUpdateRequested(remaining);
                    return;
                }
            }
        }

        var query = root.searchText.trim();
        var queryChanged = query !== _lastQuery;
        _lastQuery = query;

        specialMode = "";
        specialModeText = "";

        // Check for shortcut mode
        var shortcutResults = LauncherService.getShortcutResults(query);
        if (shortcutResults !== null) {
            finalizeModel(null, shortcutResults, queryChanged);
            return;
        }

        // Otherwise, regular application & calculator search
        var calcResult = LauncherService.evaluateCalculator(query);
        var appResults = [];

        if (root.includeWindows) {
            Compositor.queryWorkspaces((workspaces) => {
                appResults = LauncherService.searchApps(query, DesktopEntries.applications.values, workspaces, Config.launcherMaxResults || 100);
                finalizeModel(calcResult, appResults, queryChanged);
            });
        } else {
            appResults = LauncherService.searchApps(query, DesktopEntries.applications.values, null, Config.launcherMaxResults || 100);
            finalizeModel(calcResult, appResults, queryChanged);
        }
    }

    function finalizeModel(calcResult, appResults, queryChanged) {
        var newModel = [];
        if (calcResult !== null) {
            newModel.push({
                "type": "calculation",
                "name": calcResult.toString(),
                "description": "Result - Copy to clipboard",
                "icon": "calculate"
            });
        }
        
        for (var i = 0; i < appResults.length; i++) {
            newModel.push(appResults[i]);
        }
        
        cachedModel = newModel;
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

    // Override base activateCurrentItem
    function activateCurrentItem() {
        searchDebounceTimer.stop();
        performSearch(); // Ensure state is fresh

        if (appListView.currentIndex < 0 && cachedModel.length > 0)
            appListView.currentIndex = 0;

        if (appListView.currentIndex >= 0 && cachedModel && appListView.currentIndex < cachedModel.length) {
            var item = cachedModel[appListView.currentIndex];
            if (item.type === "shortcut-option") {
                if (item.mode === "wallpaper") {
                    root.tabRedirectRequested(2);
                } else {
                    LauncherService.activeUtilityMode = item.mode;
                    root.searchTextUpdateRequested("");
                }
            } else {
                LauncherService.executeItem(item);
                root.closeRequested();
            }
        }
    }

    // --- Sub-Components ---

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() {
            if (root.isActive) performSearch();
        }
    }

    Connections {
        target: LauncherService
        function onActiveUtilityModeChanged() {
            performSearch();
        }
    }

    Timer {
        id: searchDebounceTimer
        interval: 100
        repeat: false
        onTriggered: performSearch()
    }

    LauncherListView {
        id: appListView
        anchors.fill: parent
        model: cachedModel
        
        // Handle special modes logic for selection
        onCountChanged: {
             if (LauncherService.lastInputMethod === "keyboard" || currentIndex === -1) {
                if (count > 0 && currentIndex < 0 && specialMode === "")
                    currentIndex = 0;
                else if (count === 0)
                    currentIndex = -1;
            }
        }

        delegate: LauncherItemDelegate {
            itemIndex: index
            selected: appListView.currentIndex === index
            
            // App Logic
            text: modelData ? modelData.name : ""
            subText: {
                if (!modelData) return "";
                if (modelData.type === "calculation" || 
                    modelData.type === "calculation-hint" ||
                    modelData.type === "workspace" || 
                    modelData.type === "web" ||
                    modelData.type === "web-hint" ||
                    modelData.type === "command" ||
                    modelData.type === "command-hint" ||
                    modelData.type === "shortcut-option") {
                    return modelData.description || "";
                }
                return Preferences.launcherShowAppDescriptions ? (modelData.description || "") : "";
            }
            
            property bool isGlyphIcon: (modelData && (
                modelData.type === "workspace" || 
                modelData.type === "calculation" || 
                modelData.type === "calculation-hint" ||
                modelData.type === "shortcut-option" ||
                modelData.type === "command" ||
                modelData.type === "command-hint" ||
                modelData.type === "web" ||
                modelData.type === "web-hint"
            ))
            
            iconSource: isGlyphIcon ? (modelData.icon || "extension") : ""
            imageSource: (!isGlyphIcon && modelData) ? LauncherService.resolveIcon(modelData.icon) : ""
            
            showFallbackIcon: (imageSource === "") && !isGlyphIcon
            boxedIcon: isGlyphIcon
            fallbackText: (modelData && modelData.name && modelData.name.length > 0) ? modelData.name.charAt(0).toUpperCase() : "?"
            
            onClicked: {
                appListView.currentIndex = index;
                if (modelData && modelData.type === "shortcut-option") {
                    LauncherService.activeUtilityMode = modelData.mode;
                    root.searchTextUpdateRequested("");
                } else {
                    root.activateCurrentItem();
                }
            }
        }

    }
}
