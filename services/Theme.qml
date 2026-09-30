import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services

import "../lib/color.js" as Color
import "../lib/apps.js" as Apps
pragma Singleton

Item {
    id: root

    /**
     * The generated palette: flat single-word tokens (deep/well/bg/surface/
     * raised/hair/border, text/muted/faint, primary/secondary/tertiary/error,
     * ink) plus an `ansi` array of 16 terminal colours. Built by lib/color.js
     * in OKLCH from the wallpaper seed; consumed by Globals.colors (the shell)
     * and the app hooks.
     */
    property var currentColors: Color.build(Color.DEFAULT_SEED)

    // Fallback seed (no wallpaper) lives with the generator: Color.DEFAULT_SEED.
    readonly property string seedScript: Globals.rootDir + "/lib/seed.sh"

    readonly property int debounceInterval: 300

    // ── THEME APPLICATION ─────────────────────────────────────────────

    function requestApply(context) {
        if (!Preferences.loaded) return;
        executionTimer.pendingContext = context || "manual";
        executionTimer.restart();
    }

    function apply() {
        var wp = Wallpaper.currentWallpaper;

        if (!wp || wp === "") {
            root._ingest(Color.DEFAULT_SEED);
            return;
        }

        // lib/seed.sh prints the wallpaper's ImageMagick colour histogram
        // ("<count>: (...) #rrggbb ..."); all colour science — OKLab
        // clustering, hue families, mean lightness and the colorfulness score —
        // happens in lib/color.js. On any failure, fall back to the default.
        var cmd = ["sh", "-c",
            'export PATH="' + Globals.toolPath + '"; exec sh "$1" "$2"',
            "--", root.seedScript, wp];
        ProcessService.run(cmd, function(output, exitCode) {
            var seed = (exitCode === 0 && output)
                ? Color.seedFromHistogram(output)
                : Color.DEFAULT_SEED;
            if (!seed || !seed.families)
                seed = Color.DEFAULT_SEED;
            root._ingest(seed);
        });
    }

    function _ingest(seed) {
        var s = seed || Color.DEFAULT_SEED;
        console.log("[Theme] seed h=" + Math.round(s.hue) + " c=" + (s.chroma || 0).toFixed(3)
            + " meanL=" + (s.meanL || 0).toFixed(3) + " colorful=" + (s.colorfulness || 0).toFixed(3));
        root.currentColors = Color.build(s);
        root.runHooks(executionTimer.pendingContext);
    }

    // ── APPLICATION HOOKS ─────────────────────────────────────────────

    function runHooks(context) {
        if (!Preferences.loaded) return;

        var ctx = {
            "mode": "dark",
            "context": context || "manual",
            "font": Preferences.globals.shellFont,
            "wallpaper": Wallpaper.currentWallpaper
        };

        for (var i = 0; i < root.applications.length; i++) {
            var app = root.applications[i];
            if (Preferences.applications.themedApps[app.id] !== true) continue;

            var hook = app.hook;
            if (typeof hook !== "function") continue;

            var result = hook(root.currentColors, ctx);
            if (!result) continue;

            root._writeHookFiles(result.files);
            if (result.postHook)
                ProcessService.runDetached(["sh", "-c", result.postHook]);
        }
    }

    function _writeHookFiles(files) {
        if (!files) return;
        for (var i = 0; i < files.length; i++) {
            var f = files[i];
            if (!f || !f.path) continue;
            ProcessService.runDetached(["sh", "-c",
                'p="$1"; p="${p/#\\~/$HOME}"; mkdir -p "$(dirname "$p")" && printf "%s" "$2" > "$p"',
                "--", f.path, f.content || ""]);
        }
    }

    // ── STARTUP ───────────────────────────────────────────────────────

    property bool _started: false
    function runStartup() {
        if (_started || !Preferences.loaded) return;
        _started = true;
        root.requestApply("startup");
    }

    // ── APPLICATIONS ──────────────────────────────────────────────────
    // Single registry in lib/apps.js (id / name / binary / hook).

    readonly property var applications: Apps.applications

    property var installedApps: ({})

    function checkInstalledApps() {
        let newInstalled = {};
        let apps = root.applications;
        let completed = 0;
        apps.forEach(app => {
            // Run the probe with the same explicit PATH as tool invocations, so
            // a tool that is installed but outside the service PATH is not
            // wrongly reported missing.
            var script = 'export PATH="' + Globals.toolPath + '"; ' + app.binary + ' > /dev/null 2>&1';
            ProcessService.run(["sh", "-c", script], function(out, exitCode) {
                newInstalled[app.id] = (exitCode === 0);
                completed++;
                if (completed === apps.length) root.installedApps = newInstalled;
            });
        });
    }

    // ── SYSTEM FONTS ──────────────────────────────────────────────────

    property var allFontFamilies: []
    function updateFontFamilies() {
        const blacklist = /(mtx|math|private|opensymbol|stix|tex|pfont|noto sans .* [0-9])/i;
        root.allFontFamilies = Qt.fontFamilies().filter(font => !blacklist.test(font));
    }

    property Timer executionTimer: Timer {
        interval: root.debounceInterval
        repeat: false
        property string pendingContext: "manual"
        onTriggered: root.apply()
    }

    // ── CONNECTIONS ───────────────────────────────────────────────────

    Connections {
        target: Preferences
        function onLoadedChanged() {
            if (Preferences.loaded) root.runStartup();
        }
    }

    Connections {
        target: Wallpaper
        function onCurrentWallpaperChanged() {
            root.requestApply("wallpaper");
        }
    }

    Component.onCompleted: {
        checkInstalledApps();
        updateFontFamilies();
        root.runStartup();
    }
}
