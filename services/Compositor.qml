import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs
pragma Singleton

Singleton {
    id: root

    // ── PUBLIC STATE ───────────────────────────────────────────────────
    property var workspaces: []
    property var windowByAddress: ({})
    property int activeWorkspaceId: -1


    // ── WORKSPACE MAPPING ─────────────────────────────────────────────
    function _mapWorkspaces() {
        var wsMap = {};
        var maxId = Preferences.bar.workspaceCount;
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
                "name": ws.name || ws.id.toString(),
                "isActive": ws.active,
                "isFocused": ws.focused,
                "hasWindows": ws.toplevels.values.length > 0
            };
            if (ws.id > maxId) maxId = ws.id;
        }

        var res = [];
        for (var id = 1; id <= maxId; id++) {
            if (wsMap[id]) {
                res.push(wsMap[id]);
            } else {
                res.push({
                    "id": id,
                    "name": id.toString(),
                    "isActive": false, "isFocused": false,
                    "hasWindows": false
                });
            }
        }
        return { list: res, activeId: activeId };
    }

    function _refreshClients() {
        Runner.run(["hyprctl", "clients", "-j"], function(text, exitCode) {
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
        });
    }

    // ── INTERNAL UPDATE HELPERS ───────────────────────────────────────
    function _updateWorkspaces() {
        var data = _mapWorkspaces();
        root.workspaces = data.list;
        root.activeWorkspaceId = data.activeId;
    }

    // ── EVENT-DRIVEN UPDATES ──────────────────────────────────────────
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
                    root._refreshClients();
                    wsDebounce.restart();
                    break;

                case "closewindow":
                case "movewindow":
                case "movewindowv2":
                case "changefloatingmode":
                case "fullscreen":
                    clientsDebounce.restart();
                    wsDebounce.restart();
                    break;

                case "activewindow":
                case "activewindowv2":
                    clientsDebounce.restart();
                    break;

                default:
                    break;
            }
        }

        function onFocusedWorkspaceChanged() {
            wsDebounce.restart();
        }
    }

    Connections {
        target: Preferences.bar
        function onWorkspaceCountChanged() { root._updateWorkspaces(); }
    }

    Timer { id: wsDebounce;      interval: 50;  repeat: false; onTriggered: root._updateWorkspaces() }
    Timer { id: clientsDebounce; interval: 100; repeat: false; onTriggered: root._refreshClients() }

    // ── STARTUP ────────────────────────────────────────────────────────
    Timer {
        id: startupTimer
        interval: 200
        repeat: true
        property int _tries: 0
        onTriggered: {
            _tries++;
            Hyprland.refreshWorkspaces();
            root._refreshClients();
            root._updateWorkspaces();

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
            root._refreshClients();
        }
    }

    // ── PUBLIC UTILITIES ──────────────────────────────────────────────

    // ── PUBLIC ACTIONS ────────────────────────────────────────────────

    function _dispatch(cmd) {
        Hyprland.dispatch(cmd);
    }

    function switchToWorkspace(workspaceIdx) {
        _dispatch("hl.dsp.focus({ workspace = " + workspaceIdx.toString() + " })");
    }

    Component.onCompleted: {
        Hyprland.refreshWorkspaces();
        root._refreshClients();
        root._updateWorkspaces();
        startupTimer.start();
    }
}
