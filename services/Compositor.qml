import QtQuick
import Quickshell
import Quickshell.Hyprland
pragma Singleton

Singleton {
    id: root

    // --- Public State ---
    property var workspaces: []
    property var windows: []
    property int activeWorkspaceId: -1
    property var activeWindow: ({ "title": "Desktop", "app": "" })

    // --- Workspace Mapping ---
    function _mapWorkspaces() {
        var wsMap = {};
        var maxId = 5;
        var activeId = -1;

        var focusedWs = Hyprland.focusedWorkspace;
        if (focusedWs && focusedWs.id > 0) {
            activeId = focusedWs.id;
            if (activeId > maxId) maxId = activeId;
        }

        var wsList = Hyprland.workspaces.values;
        for (var i = 0; i < wsList.length; i++) {
            var ws = wsList[i];
            if (ws.id < 0) continue; // skip named/special

            if (activeId === -1 && ws.focused) activeId = ws.id;

            wsMap[ws.id] = {
                "id": ws.id,
                "idx": ws.id,
                "name": ws.name || ws.id.toString(),
                "isActive": ws.active,
                "isFocused": ws.focused,
                "hasWindows": ws.toplevels.values.length > 0,
                "monitor": ws.monitor ? ws.monitor.name : ""
            };
            if (ws.id > maxId) maxId = ws.id;
        }

        var res = [];
        for (var id = 1; id <= maxId; id++) {
            if (wsMap[id]) {
                res.push(wsMap[id]);
            } else {
                res.push({
                    "id": id, "idx": id,
                    "name": id.toString(),
                    "isActive": false, "isFocused": false,
                    "hasWindows": false, "monitor": ""
                });
            }
        }
        return { list: res, activeId: activeId };
    }

    // --- Window Mapping ---
    function _mapWindows() {
        var res = [];
        var tlList = Hyprland.toplevels.values;

        for (var i = 0; i < tlList.length; i++) {
            var win = tlList[i];

            // Skip toplevels with no address yet — not ready
            if (!win.address || win.address === "") continue;

            // Prefer wayland appId, fall back to IPC class
            var appId = "";
            if (win.wayland && win.wayland.appId) {
                appId = win.wayland.appId;
            } else if (win.lastIpcObject && win.lastIpcObject["class"]) {
                appId = win.lastIpcObject["class"];
            }

            // Use title as last-resort identifier — never skip a window entirely
            var title = win.title || "";
            if (appId === "" && title === "") continue;

            res.push({
                "id": win.address,
                "title": title,
                "appId": appId || title,
                "workspaceId": win.workspace ? win.workspace.id : -1,
                "workspaceIdx": win.workspace ? win.workspace.id : -1,
                "isFocused": win.activated
            });
        }

        // Sort by workspace index for a deterministic Dock order
        res.sort((a, b) => {
            if (a.workspaceIdx !== b.workspaceIdx) return a.workspaceIdx - b.workspaceIdx;
            return String(a.id).localeCompare(String(b.id));
        });
        return res;
    }

    // --- Internal Update Helpers ---
    function _updateWorkspaces() {
        var data = _mapWorkspaces();
        root.workspaces = data.list;
        root.activeWorkspaceId = data.activeId;
    }

    function _updateWindows() {
        root.windows = _mapWindows();
    }

    function _updateActiveWindow() {
        var win = Hyprland.activeToplevel;
        if (win) {
            var app = "";
            if (win.wayland && win.wayland.appId) app = win.wayland.appId;
            else if (win.lastIpcObject && win.lastIpcObject["class"]) app = win.lastIpcObject["class"];
            root.activeWindow = { "title": win.title || "Desktop", "app": app };
        } else {
            root.activeWindow = { "title": "Desktop", "app": "" };
        }
    }

    // --- Event-Driven Updates via rawEvent ---
    // This is the reliable mechanism — ObjectModel doesn't have usable change signals.
    Connections {
        target: Compositor
        function onRawEvent(event) {
            switch (event.type) {
                // Workspace events
                case "workspace":
                case "workspacev2":
                case "focusedmon":
                case "createworkspace":
                case "createworkspacev2":
                case "destroyworkspace":
                case "destroyworkspacev2":
                case "moveworkspace":
                case "moveworkspacev2":
                case "renameworkspace":
                case "activespecial":
                    Hyprland.refreshWorkspaces();
                    wsDebounce.restart();
                    break;

                // Window events
                case "openwindow":
                case "closewindow":
                case "movewindow":
                case "movewindowv2":
                case "changefloatingmode":
                case "fullscreen":
                    Hyprland.refreshToplevels();
                    winDebounce.restart();
                    break;

                // Active window events
                case "activewindow":
                case "activewindowv2":
                    activeWinDebounce.restart();
                    break;

                default:
                    break;
            }
        }

        function onFocusedWorkspaceChanged() {
            wsDebounce.restart();
        }

        function onActiveToplevelChanged() {
            _updateActiveWindow();
            winDebounce.restart();
        }
    }

    Timer { id: wsDebounce;      interval: 50;  repeat: false; onTriggered: root._updateWorkspaces() }
    Timer { id: winDebounce;     interval: 50;  repeat: false; onTriggered: root._updateWindows() }
    Timer { id: activeWinDebounce; interval: 50; repeat: false; onTriggered: root._updateActiveWindow() }

    // --- Startup: retry until Hyprland reports live data ---
    Timer {
        id: startupTimer
        interval: 200
        repeat: true
        property int _tries: 0
        onTriggered: {
            _tries++;
            Hyprland.refreshWorkspaces();
            Hyprland.refreshToplevels();
            root._updateWorkspaces();
            root._updateWindows();
            root._updateActiveWindow();

            var fw = Hyprland.focusedWorkspace;
            if ((fw && fw.id > 0) || _tries >= 15) {
                stop();
                _tries = 0;
            }
        }
    }

    // Periodic safety sync — catches edge cases the event socket might miss
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            root._updateWorkspaces();
            root._updateWindows();
        }
    }

    // --- Public Actions ---

    // Dispatch helper — handles Lua vs non-Lua syntax automatically
    function _dispatch(cmd) {
        Hyprland.dispatch(cmd);
    }

    function switchToWorkspace(workspaceIdx) {
        if (Hyprland.usingLua) {
            _dispatch("hl.dsp.focus({ workspace = " + workspaceIdx.toString() + " })");
        } else {
            _dispatch("workspace " + workspaceIdx.toString());
        }
    }

    function focusWindow(windowId) {
        var addr = windowId.toString();
        if (!addr.startsWith("0x")) addr = "0x" + addr;
        
        if (Hyprland.usingLua) {
            _dispatch("hl.dsp.focus({ window = \"address:" + addr + "\" })");
        } else {
            _dispatch("focuswindow address:" + addr);
        }
    }

    function quit() {
        _dispatch("exit");
    }

    Component.onCompleted: {
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
        _updateWorkspaces();
        _updateWindows();
        _updateActiveWindow();
        startupTimer.start();
    }
}
