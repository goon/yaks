pragma Singleton
import QtQuick
import Quickshell
import Quickshell.WindowManager
import Quickshell.Wayland._ToplevelManagement
import qs

Singleton {
    id: root

    // --- Signals (Unified Interface) ---
    signal workspacesUpdated(var workspaces, int activeId)
    signal windowsUpdated(var windows)
    signal focusedWindowUpdated(var window)

    // --- Reactive: Workspaces via ext-workspace ---
    property Connections _wmWatcher: Connections {
        target: WindowManager
        function onWindowsetsChanged() { root._emitWorkspaces(); }
    }

    // --- Reactive: Windows / Focus via ToplevelManager ---
    property Connections _focusWatcher: Connections {
        target: ToplevelManager
        function onActiveToplevelChanged() { root._emitFocusedWindow(); }
    }
    property Connections _windowsWatcher: Connections {
        target: ToplevelManager.toplevels
        function onValuesChanged() { root._emitWindows(); }
    }

    function _emitWorkspaces() {
        var sets = WindowManager.windowsets;
        var activeId = -1;
        var workspaces = [];
        for (var i = 0; i < sets.length; i++) {
            var ws = sets[i];
            var id = i + 1;
            if (ws.active) activeId = id;
            workspaces.push({
                "id": id,
                "idx": id,
                "_native": ws,
                "name": ws.name || id.toString(),
                "isActive": ws.active,
                "isFocused": ws.active,
                "hasWindows": ws.shouldDisplay,
                "isUrgent": ws.urgent,
                "windowTitles": []
            });
        }
        root.workspacesUpdated(workspaces, activeId);
    }

    function _emitWindows() {
        var toplevels = ToplevelManager.toplevels.values;
        var windows = [];
        for (var i = 0; i < toplevels.length; i++) {
            var tl = toplevels[i];
            windows.push({
                "id": tl.appId + "|" + tl.title + "|" + i,
                "title": tl.title || "",
                "appId": tl.appId || "",
                "isFocused": tl.activated,
                "workspaceId": -1,
                "workspaceIdx": -1,
                "colIdx": 0,
                "_native": tl
            });
        }
        root.windowsUpdated(windows);
    }

    function _emitFocusedWindow() {
        var tl = ToplevelManager.activeToplevel;
        if (tl) {
            root.focusedWindowUpdated({
                "id": tl.appId + "|" + tl.title,
                "title": tl.title || "",
                "app": tl.appId || "",
                "_native": tl
            });
        } else {
            root.focusedWindowUpdated(null);
        }
    }

    // --- Public API ---
    function queryWorkspaces(callback) {
        _emitWorkspaces();
        if (callback) {
            var sets = WindowManager.windowsets;
            var activeId = -1;
            var workspaces = [];
            for (var i = 0; i < sets.length; i++) {
                var ws = sets[i];
                var id = i + 1;
                if (ws.active) activeId = id;
                workspaces.push({
                    "id": id, "idx": id, "_native": ws,
                    "name": ws.name || id.toString(),
                    "isActive": ws.active, "isFocused": ws.active,
                    "hasWindows": ws.shouldDisplay, "isUrgent": ws.urgent, "windowTitles": []
                });
            }
            callback(workspaces, activeId);
        }
    }

    function queryWindows(callback) {
        _emitWindows();
        if (callback) {
            var toplevels = ToplevelManager.toplevels.values;
            var windows = [];
            for (var i = 0; i < toplevels.length; i++) {
                var tl = toplevels[i];
                windows.push({
                    "id": tl.appId + "|" + tl.title + "|" + i,
                    "title": tl.title || "", "appId": tl.appId || "",
                    "isFocused": tl.activated,
                    "workspaceId": -1, "workspaceIdx": -1, "colIdx": 0, "_native": tl
                });
            }
            callback(windows);
        }
    }

    function queryFocusedWindow(callback) {
        _emitFocusedWindow();
        if (callback) {
            var tl = ToplevelManager.activeToplevel;
            callback(tl ? { "id": tl.appId + "|" + tl.title, "title": tl.title || "", "app": tl.appId || "" } : null);
        }
    }

    function switchToWorkspace(workspaceIdx) {
        var sets = WindowManager.windowsets;
        var idx = workspaceIdx - 1;
        if (idx >= 0 && idx < sets.length && sets[idx].canActivate) {
            sets[idx].activate();
        }
    }

    function focusWindow(windowId) {
        if (!windowId) return;
        var toplevels = ToplevelManager.toplevels.values;
        for (var i = 0; i < toplevels.length; i++) {
            var tl = toplevels[i];
            var id = tl.appId + "|" + tl.title + "|" + i;
            if (id === windowId) {
                tl.activate();
                return;
            }
        }
    }

    function quit() {
        // Session lifecycle is managed externally in Mango
        console.warn("Mango: quit() is not supported via the native WindowManager API.");
    }

    Component.onCompleted: {
        _emitWorkspaces();
        _emitWindows();
        _emitFocusedWindow();
    }
}
