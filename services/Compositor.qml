import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.services
pragma Singleton

Singleton {
    id: root

    // --- Public State ---
    property var workspaces: []
    property var windows: []
    property var windowByAddress: ({})
    property var specialWorkspaces: []
    property int activeWorkspaceId: -1
    property var activeWindow: ({ "title": "Desktop", "app": "" })


    // --- Workspace Mapping ---
    function _mapWorkspaces() {
        var wsMap = {};
        var maxId = Preferences.workspaceCount;
        var activeId = -1;

        var focusedWs = Hyprland.focusedWorkspace;
        if (focusedWs && focusedWs.id > 0) {
            activeId = focusedWs.id;
            if (activeId > maxId) maxId = activeId;
        }

        var wsList = Hyprland.workspaces.values;
        for (var i = 0; i < wsList.length; i++) {
            var ws = wsList[i];
            if (ws.id < 0) continue;

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

            if (!win.address || win.address === "") continue;

            var addr = win.address;
            if (!addr.startsWith("0x")) addr = "0x" + addr;

            var hyprData = root.windowByAddress[addr] || {};

            var appId = "";
            if (win.wayland && win.wayland.appId) {
                appId = win.wayland.appId;
            } else if (hyprData["class"]) {
                appId = hyprData["class"];
            } else if (win.lastIpcObject && win.lastIpcObject["class"]) {
                appId = win.lastIpcObject["class"];
            }

            var title = win.title || hyprData["title"] || "";
            if (appId === "" && title === "") continue;

            var at = hyprData["at"] || (win.lastIpcObject && win.lastIpcObject["at"]) || [0, 0];
            var size = hyprData["size"] || (win.lastIpcObject && win.lastIpcObject["size"]) || [100, 100];
            var floating = hyprData["floating"] !== undefined ? hyprData["floating"] : !!(win.lastIpcObject && win.lastIpcObject["floating"]);
            var fullscreen = hyprData["fullscreen"] || (win.lastIpcObject && win.lastIpcObject["fullscreen"]) || 0;
            var monitorId = hyprData["monitor"] !== undefined ? hyprData["monitor"] : -1;
            var monitorName = hyprData["monitorname"] || "";
            var workspaceId = hyprData["workspace"] && hyprData["workspace"].id !== undefined ? hyprData["workspace"].id : (win.workspace ? win.workspace.id : -1);

            res.push({
                "id": addr,
                "title": title,
                "appId": appId || title,
                "workspaceId": workspaceId,
                "workspaceIdx": workspaceId,
                "isFocused": win.activated,
                "at": at,
                "size": size,
                "floating": floating,
                "fullscreen": fullscreen,
                "monitor": monitorName,
                "monitorId": monitorId,
                "class": hyprData["class"] || appId
            });
        }

        res.sort((a, b) => {
            if (a.workspaceIdx !== b.workspaceIdx) return a.workspaceIdx - b.workspaceIdx;
            return String(a.id).localeCompare(String(b.id));
        });
        return res;
    }

    function _refreshClients() {
        ProcessService.run(["hyprctl", "clients", "-j"], function(text, exitCode) {
            try {
                var clients = JSON.parse(text);
                var byAddr = {};
                for (var i = 0; i < clients.length; i++) {
                    var c = clients[i];
                    if (c.address) {
                        byAddr[c.address] = c;
                    }
                }
                root.windowByAddress = byAddr;
            } catch (e) {
            }
            root._updateWindows();
        });
    }

    // --- Internal Update Helpers ---
    function _updateWorkspaces() {
        var data = _mapWorkspaces();
        root.workspaces = data.list;
        root.activeWorkspaceId = data.activeId;
        _updateSpecialWorkspaces();
    }

    function _updateSpecialWorkspaces() {
        var names = [];
        var wsList = Hyprland.workspaces.values;
        for (var i = 0; i < wsList.length; i++) {
            var ws = wsList[i];
            if (ws.id < 0 && ws.name) {
                var displayName = ws.name;
                if (displayName.startsWith("special:")) {
                    displayName = displayName.slice(8);
                }
                if (displayName.length > 0 && names.indexOf(displayName) < 0) {
                    names.push(displayName);
                }
            }
        }
        root.specialWorkspaces = names;
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
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            switch (event.type) {
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

                case "openwindow":
                case "closewindow":
                case "movewindow":
                case "movewindowv2":
                case "changefloatingmode":
                case "fullscreen":
                    Hyprland.refreshToplevels();
                    winDebounce.restart();
                    clientsDebounce.restart();
                    wsDebounce.restart();
                    break;

                case "activewindow":
                case "activewindowv2":
                    activeWinDebounce.restart();
                    clientsDebounce.restart();
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
    Timer { id: clientsDebounce; interval: 100; repeat: false; onTriggered: root._refreshClients() }

    // --- Startup ---
    Timer {
        id: startupTimer
        interval: 200
        repeat: true
        property int _tries: 0
        onTriggered: {
            _tries++;
            Hyprland.refreshWorkspaces();
            Hyprland.refreshToplevels();
            root._refreshClients();
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

    // Periodic safety sync
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            root._updateWorkspaces();
            root._updateWindows();
            root._updateSpecialWorkspaces();
            root._refreshClients();
        }
    }

    // --- Public Utilities ---

    function normalizeAddress(raw) {
        if (!raw) return "";
        return raw.startsWith("0x") ? raw : ("0x" + raw);
    }

    property bool usingLua: true

    // --- Public Actions ---

    function _dispatch(cmd) {
        Hyprland.dispatch(cmd);
    }

    function switchToWorkspace(workspaceIdx) {
        if (root.usingLua) {
            _dispatch("hl.dsp.focus({ workspace = " + workspaceIdx.toString() + " })");
        } else {
            _dispatch("workspace " + workspaceIdx.toString());
        }
    }

    function focusWindow(windowId) {
        var addr = windowId.toString();
        if (!addr.startsWith("0x")) addr = "0x" + addr;

        if (root.usingLua) {
            _dispatch("(function() for _, w in ipairs(hl.get_windows()) do if w.address == \"" + addr + "\" then return hl.dsp.focus({ window = w }) end end end)()");
        } else {
            _dispatch("focuswindow address:" + addr);
        }
    }



    Component.onCompleted: {
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
        root._refreshClients();
        root._updateWorkspaces();
        root._updateWindows();
        root._updateActiveWindow();
        startupTimer.start();
    }
}
