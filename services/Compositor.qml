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
    property bool dragInProgress: false

    onDragInProgressChanged: {
        if (!dragInProgress) {
            _updateWorkspaces();
            _updateWindows();
            _refreshClients();
        }
    }

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
        if (root.dragInProgress) return;
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
        if (root.dragInProgress) return;
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

    // --- Public Actions ---

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
            _dispatch("(function() for _, w in ipairs(hl.get_windows()) do if w.address == \"" + addr + "\" then return hl.dsp.focus({ window = w }) end end end)()");
        } else {
            _dispatch("focuswindow address:" + addr);
        }
    }

    function moveToWorkspace(windowId, workspaceId) {
        var addr = windowId.toString();
        if (!addr.startsWith("0x")) addr = "0x" + addr;

        // Optimistically update local cache to prevent spring-back
        var oldWsId = -1;
        if (root.windowByAddress[addr]) {
            if (root.windowByAddress[addr]["workspace"]) {
                oldWsId = root.windowByAddress[addr]["workspace"].id;
            } else {
                root.windowByAddress[addr]["workspace"] = {};
            }
            root.windowByAddress[addr]["workspace"].id = workspaceId;
        }

        // Optimistically update workspaces state using a new array assignment so QML detects the changes
        if (oldWsId !== -1 && oldWsId !== workspaceId) {
            var updatedWorkspaces = [];
            for (var i = 0; i < root.workspaces.length; i++) {
                var wsCopy = Object.assign({}, root.workspaces[i]);
                if (wsCopy.id === oldWsId) {
                    var wsWindowsCount = 0;
                    for (var j = 0; j < root.windows.length; j++) {
                        if (root.windows[j].workspaceId === oldWsId && root.windows[j].id !== addr) {
                            wsWindowsCount++;
                        }
                    }
                    wsCopy.hasWindows = wsWindowsCount > 0;
                }
                if (wsCopy.id === workspaceId) {
                    wsCopy.hasWindows = true;
                }
                updatedWorkspaces.push(wsCopy);
            }
            root.workspaces = updatedWorkspaces;
        }

        // Optimistically update the window geometry (at/size) for layout changes
        var oldWsWindows = [];
        var targetWsWindows = [];
        for (var addrKey in root.windowByAddress) {
            var cachedWin = root.windowByAddress[addrKey];
            if (!cachedWin || !cachedWin.workspace) continue;
            
            var wsId = cachedWin.workspace.id;
            if (addrKey === addr) {
                wsId = workspaceId;
            }
            
            if (wsId === oldWsId) {
                oldWsWindows.push(cachedWin);
            } else if (wsId === workspaceId) {
                targetWsWindows.push(cachedWin);
            }
        }

        var getMonitorInfo = function(wsId) {
            var targetMonitor = null;
            var wsList = Hyprland.workspaces.values;
            for (var i = 0; i < wsList.length; i++) {
                if (wsList[i].id === wsId) {
                    targetMonitor = wsList[i].monitor;
                    break;
                }
            }
            if (!targetMonitor) targetMonitor = Hyprland.focusedMonitor;
            if (!targetMonitor) return null;
            
            var scale = targetMonitor.scale || 1.0;
            var rLeft = targetMonitor.reserved ? targetMonitor.reserved.left : 0;
            var rRight = targetMonitor.reserved ? targetMonitor.reserved.right : 0;
            var rTop = targetMonitor.reserved ? targetMonitor.reserved.top : 0;
            var rBottom = targetMonitor.reserved ? targetMonitor.reserved.bottom : 0;
            return {
                x: targetMonitor.x,
                y: targetMonitor.y,
                width: (targetMonitor.width / scale) - rLeft - rRight,
                height: (targetMonitor.height / scale) - rTop - rBottom,
                rLeft: rLeft,
                rTop: rTop
            };
        };

        if (oldWsId !== -1) {
            var mInfo = getMonitorInfo(oldWsId);
            if (mInfo) {
                if (oldWsWindows.length === 1) {
                    oldWsWindows[0].at = [mInfo.x + mInfo.rLeft, mInfo.y + mInfo.rTop];
                    oldWsWindows[0].size = [mInfo.width, mInfo.height];
                } else if (oldWsWindows.length === 2) {
                    oldWsWindows[0].at = [mInfo.x + mInfo.rLeft, mInfo.y + mInfo.rTop];
                    oldWsWindows[0].size = [mInfo.width * 0.5, mInfo.height];
                    oldWsWindows[1].at = [mInfo.x + mInfo.rLeft + mInfo.width * 0.5, mInfo.y + mInfo.rTop];
                    oldWsWindows[1].size = [mInfo.width * 0.5, mInfo.height];
                }
            }
        }

        var mInfoT = getMonitorInfo(workspaceId);
        if (mInfoT) {
            if (targetWsWindows.length === 1) {
                targetWsWindows[0].at = [mInfoT.x + mInfoT.rLeft, mInfoT.y + mInfoT.rTop];
                targetWsWindows[0].size = [mInfoT.width, mInfoT.height];
            } else if (targetWsWindows.length === 2) {
                targetWsWindows[0].at = [mInfoT.x + mInfoT.rLeft, mInfoT.y + mInfoT.rTop];
                targetWsWindows[0].size = [mInfoT.width * 0.5, mInfoT.height];
                targetWsWindows[1].at = [mInfoT.x + mInfoT.rLeft + mInfoT.width * 0.5, mInfoT.y + mInfoT.rTop];
                targetWsWindows[1].size = [mInfoT.width * 0.5, mInfoT.height];
            }
        }

        if (Hyprland.usingLua) {
            _dispatch("hl.dsp.window.move({ workspace = " + workspaceId.toString() + ", follow = false, window = \"address:" + addr + "\" })");
        } else {
            _dispatch("movetoworkspacesilent " + workspaceId.toString() + ",address:" + addr);
        }

        root._updateWindows();
        wsDebounce.restart();
        clientsDebounce.restart();
    }

    function swapWindows(windowIdA, windowIdB) {
        var addrA = windowIdA.toString();
        if (!addrA.startsWith("0x")) addrA = "0x" + addrA;
        var addrB = windowIdB.toString();
        if (!addrB.startsWith("0x")) addrB = "0x" + addrB;

        // Optimistically swap coordinates, sizes and states in local cache to prevent spring-back/delays
        if (root.windowByAddress[addrA] && root.windowByAddress[addrB]) {
            var tempAt = root.windowByAddress[addrA]["at"];
            root.windowByAddress[addrA]["at"] = root.windowByAddress[addrB]["at"];
            root.windowByAddress[addrB]["at"] = tempAt;

            var tempSize = root.windowByAddress[addrA]["size"];
            root.windowByAddress[addrA]["size"] = root.windowByAddress[addrB]["size"];
            root.windowByAddress[addrB]["size"] = tempSize;

            var tempFloating = root.windowByAddress[addrA]["floating"];
            root.windowByAddress[addrA]["floating"] = root.windowByAddress[addrB]["floating"];
            root.windowByAddress[addrB]["floating"] = tempFloating;

            var tempFullscreen = root.windowByAddress[addrA]["fullscreen"];
            root.windowByAddress[addrA]["fullscreen"] = root.windowByAddress[addrB]["fullscreen"];
            root.windowByAddress[addrB]["fullscreen"] = tempFullscreen;
        }

        if (Hyprland.usingLua) {
            // Self-invoking Lua function executes focus and swap atomically within the same evaluation, restoring original focus
            _dispatch("(function() " +
                      "  local active = hl.get_active_window(); " +
                      "  for _, w in ipairs(hl.get_windows()) do " +
                      "    if w.address == \"" + addrA + "\" then " +
                      "      hl.dispatch(hl.dsp.focus({ window = w })); " +
                      "      hl.dispatch(hl.dsp.window.swap({ target = \"address:" + addrB + "\" })); " +
                      "      if active then hl.dispatch(hl.dsp.focus({ window = active })); end " +
                      "      return; " +
                      "    end " +
                      "  end " +
                      "end)()");
        } else {
            // Non-Lua fallback using hyprctl --batch, restoring original focus
            var activeAddr = Hyprland.activeToplevel ? Hyprland.activeToplevel.address : "";
            if (activeAddr) {
                if (!activeAddr.startsWith("0x")) activeAddr = "0x" + activeAddr;
                ProcessService.run([
                    "hyprctl",
                    "--batch",
                    "dispatch focuswindow address:" + addrA + " ; dispatch swapwindow address:" + addrB + " ; dispatch focuswindow address:" + activeAddr
                ]);
            } else {
                ProcessService.run([
                    "hyprctl",
                    "--batch",
                    "dispatch focuswindow address:" + addrA + " ; dispatch swapwindow address:" + addrB
                ]);
            }
        }

        root._updateWindows();
        clientsDebounce.restart();
    }

    function closeWindow(windowId) {
        var addr = windowId.toString();
        if (!addr.startsWith("0x")) addr = "0x" + addr;

        if (Hyprland.usingLua) {
            _dispatch("hl.dsp.window.close('address:" + addr + "')");
        } else {
            _dispatch("closewindow address:" + addr);
        }
    }

    function toggleSpecialWorkspace(name) {
        if (Hyprland.usingLua) {
            _dispatch("hl.dsp.workspace.toggle_special('" + name + "')");
        } else {
            _dispatch("togglespecialworkspace " + name);
        }
    }

    function quit() {
        _dispatch("exit");
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
