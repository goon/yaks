import QtQuick
import Quickshell
import qs
pragma Singleton

QtObject {
    id: root

    // Input State Management
    property string lastInputMethod: "keyboard"
    property point originMousePos: Qt.point(-1, -1)
    property bool mouseSelectionEnabled: false
    property point lastMousePos: Qt.point(-1, -1)
    readonly property int moveThreshold: 10

    // Terminal auto-discovery (priority: $TERMINAL > discovered > xterm)
    property var _availableTerminals: ["xterm"]

    Component.onCompleted: {
        var cmd = "for t in kitty alacritty foot wezterm ghostty; do "
                + "command -v $t >/dev/null 2>&1 && echo $t; done";
        ProcessService.run(["sh", "-c", cmd], function(out, code) {
            var found = out.trim().split("\n").filter(function(x) { return x.length > 0; });
            if (found.length > 0) root._availableTerminals = found;
        });
    }

    function resetInputStates() {
        lastInputMethod = "keyboard";
        mouseSelectionEnabled = false;
        originMousePos = Qt.point(-1, -1);
        lastMousePos = Qt.point(-1, -1);
    }

    function handleMouseMove(globalX, globalY) {
        if (originMousePos.x === -1) {
            originMousePos = Qt.point(globalX, globalY);
            lastMousePos = Qt.point(globalX, globalY);
            return false;
        }
        var dx = Math.abs(globalX - lastMousePos.x);
        var dy = Math.abs(globalY - lastMousePos.y);
        // If movement is significant, enable mouse selection
        if (dx > 2 || dy > 2) {
            lastMousePos = Qt.point(globalX, globalY);
            if (!mouseSelectionEnabled) {
                var totalDx = Math.abs(globalX - originMousePos.x);
                var totalDy = Math.abs(globalY - originMousePos.y);
                if (totalDx > moveThreshold || totalDy > moveThreshold) {
                    mouseSelectionEnabled = true;
                    lastInputMethod = "mouse";
                }
            } else {
                lastInputMethod = "mouse";
            }
        }
        return mouseSelectionEnabled && lastInputMethod === "mouse";
    }

    function fuzzyMatch(text, query) {
        if (!query)
            return true;

        text = text.toLowerCase();
        query = query.toLowerCase();
        var idx = 0;
        for (var i = 0; i < text.length && idx < query.length; i++) {
            if (text[i] === query[idx])
                idx++;

        }
        return idx === query.length;
    }



    function getIconFromDesktop(appId) {
        if (!appId) return "";
        var apps = DesktopEntries.applications.values;
        var lowerId = appId.toLowerCase();
        
        for (var i = 0; i < apps.length; i++) {
            var app = apps[i];
            var entryId = (app.id || "").toLowerCase();
            
            if (entryId === lowerId || entryId === lowerId + ".desktop" || 
                (app.name && app.name.toLowerCase() === lowerId) ||
                (app.startupClass && app.startupClass.toLowerCase() === lowerId)) {
                return app.icon;
            }
        }
        return "";
    }

    function resolveIcon(iconName) {
        function getVerifiedPath(name) {
            if (!name)
                return "";

            // Fast path: skip iconPath() call entirely if not in theme
            if (!Quickshell.hasThemeIcon(name))
                return "";

            var path = Quickshell.iconPath(name, true);
            if (!path)
                return "";

            var s = path.toString();
            if (s === "" || s.indexOf("image-missing") !== -1 || s.indexOf("missing") !== -1)
                return "";

            if (s.startsWith("image://") || s.startsWith("file://"))
                return s;

            if (s.startsWith("/"))
                return "file://" + s;

            return s;
        }

        if (!iconName)
            return "";

        // Symbols are handled internally by UI components (e.g. NotificationCard)
        // Returning empty here prevents Quickshell from trying to load them as themed icons
        if (iconName.startsWith("symbol:") || iconName.includes("symbol:"))
            return "";

        // Absolute / protocol paths bypass theme lookup entirely
        if (iconName.startsWith("/") || iconName.startsWith("file://") || iconName.startsWith("image://")) {
            if (iconName.startsWith("/"))
                return "file://" + iconName;
            return iconName;
        }

        // ── DESKTOP ENTRY LOOKUP ──────────────────────────────────────────
        var desktopIcon = getIconFromDesktop(iconName);
        if (desktopIcon) {
            // If the desktop icon is itself a path, return it directly
            if (desktopIcon.startsWith("/") || desktopIcon.startsWith("file://"))
                return desktopIcon.startsWith("/") ? "file://" + desktopIcon : desktopIcon;
            var dp = getVerifiedPath(desktopIcon);
            if (dp) return dp;
        }

        // ── DIRECT THEME HIT ──────────────────────────────────────────────
        var v = getVerifiedPath(iconName);
        if (v) return v;

        // ── FALLBACK VARIATIONS ───────────────────────────────────────────
        var lowerIcon = iconName.toLowerCase();
        var variations = [lowerIcon];

        if (iconName.length > 0) {
            var firstChar = iconName.charAt(0);
            var rest = iconName.slice(1);
            variations.push(firstChar === firstChar.toUpperCase()
                ? firstChar.toLowerCase() + rest
                : firstChar.toUpperCase() + rest);
        }

        // Symbolic / indicator / panel suffixes
        variations.push(lowerIcon + "-symbolic");
        variations.push(iconName + "-symbolic");
        variations.push(lowerIcon + "-indicator");
        variations.push(lowerIcon + "-panel");

        if (iconName.indexOf('.') !== -1)
            variations.push(iconName.split('.').pop());

        for (var i = 0; i < variations.length; i++) {
            var hv = getVerifiedPath(variations[i]);
            if (hv) return hv;
        }
        return "";
    }

    function searchApps(query, applications, maxResults) {
        maxResults = maxResults || 100;
        var queryLower = query.toLowerCase();
        var scored = [];
        // ── APPLICATIONS ──────────────────────────────────────────────────
        for (var i = 0; i < applications.length; i++) {
            var app = applications[i];
            if (app.noDisplay)
                continue;

            var name = (app.name || "").toLowerCase();
            var comment = (app.comment || "").toLowerCase();
            var genericName = (app.genericName || "").toLowerCase();
            if (queryLower === "" || fuzzyMatch(name, queryLower) || fuzzyMatch(comment, queryLower) || fuzzyMatch(genericName, queryLower)) {
                var score = 0;
                if (queryLower !== "") {
                    if (name === queryLower)
                        score += 2000;
                    else if (name.startsWith(queryLower))
                        score += 1000;
                    else if (name.includes(queryLower))
                        score += 500;
                    else
                        score += 100;
                }
                scored.push({
                    "item": {
                        "type": "app",
                        "name": app.name,
                        "description": app.comment || app.genericName || "Application",
                        "icon": app.icon,
                        "category": "Application",
                        "app": app
                    },
                    "score": score
                });
            }
        }
        scored.sort((a, b) => {
            if (b.score !== a.score) {
                return b.score - a.score;
            }
            return (a.item.name || "").localeCompare(b.item.name || "");
        });
        var finalResults = [];
        for (var i = 0; i < Math.min(scored.length, maxResults); i++) {
            finalResults.push(scored[i].item);
        }
        return finalResults;
    }

    function resolveTerminal() {
        var fromEnv = Quickshell.env("TERMINAL");
        if (fromEnv && fromEnv.length > 0) return fromEnv;
        return root._availableTerminals[0];
    }

    function executeItem(item) {
        if (!item || !item.app)
            return;

        if (item.app.runInTerminal)
            ProcessService.runDetached(["sh", "-c", resolveTerminal() + " -e " + item.app.command]);
        else
            item.app.execute();
    }
}
