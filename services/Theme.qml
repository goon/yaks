import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services

import "../lib/gtk.js" as GtkHook
import "../lib/firefox.js" as FirefoxHook
import "../lib/kitty.js" as KittyHook
import "../lib/obsidian.js" as ObsidianHook
import "../lib/steam.js" as SteamHook
import "../lib/discord.js" as DiscordHook
import "../lib/nvim.js" as NvimHook
import "../lib/zed.js" as ZedHook
import "../lib/palette.js" as Palette
pragma Singleton

Item {
    id: root

    /**
     * The generated palette: flat single-word tokens (deep/well/bg/surface/
     * raised/hair/border, text/muted/faint, primary/secondary/tertiary/error,
     * ink) plus an `ansi` array of 16 terminal colours. Built by lib/palette.js
     * in OKLCH from the wallpaper seed; consumed by Globals.colors (the shell)
     * and the app hooks.
     */
    property var currentColors: Palette.build(root.defaultHue, root.defaultSat, root.defaultMeanL, -1, 0)

    // Fallback seed (no wallpaper): a soft periwinkle.
    readonly property real defaultHue: 258
    readonly property real defaultSat: 0.35
    readonly property real defaultMeanL: 0.12
    readonly property string colorsPath: Globals.cacheDir + "/current_theme/colors.json"
    readonly property string seedScript: Globals.rootDir + "/lib/seed.sh"

    readonly property int debounceInterval: 300

    // Explicit PATH for spawning external tools. The shell may be started from
    // a systemd user service whose PATH lacks the system profiles, so tools that
    // are installed (terminals, theming CLIs) would otherwise be reported
    // missing. Shared by every Probe/Process that shells out.
    readonly property string toolPath: "/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:/nix/var/nix/profiles/default/bin:$HOME/.local/bin:$PATH"

    // ── THEME APPLICATION ─────────────────────────────────────────────

    function requestApply(context) {
        if (!Preferences.loaded) return;
        executionTimer.pendingContext = context || "manual";
        executionTimer.restart();
    }

    function apply() {
        var wp = Wallpaper.currentWallpaper;

        if (!wp || wp === "") {
            root._ingest(root.defaultHue, root.defaultSat, root.defaultMeanL, -1, 0);
            return;
        }

        // lib/seed.sh returns "<hue> <sat> <mean_l> <hue2> <sat2>": the
        // wallpaper's most visible chromatic hue, its raw saturation, the
        // image's mean lightness, and its second chromatic hue (-1 = none).
        // Achromatic images emit "0 0 <mean_l> -1 0" for a grey theme.
        var cmd = ["sh", "-c",
            'export PATH="' + root.toolPath + '"; exec sh "$1" "$2"',
            "--", root.seedScript, wp];
        ProcessService.run(cmd, function(output, exitCode) {
            var parts = (exitCode === 0 && output) ? output.trim().split(/\s+/) : [];
            var hue = parseFloat(parts[0]);
            var sat = parseFloat(parts[1]);
            var meanL = parseFloat(parts[2]);
            var hue2 = parseFloat(parts[3]);
            var sat2 = parseFloat(parts[4]);
            if (isNaN(hue) || isNaN(sat) || isNaN(meanL)) {
                hue = root.defaultHue;
                sat = root.defaultSat;
                meanL = root.defaultMeanL;
            }
            if (isNaN(hue2)) hue2 = -1;
            if (isNaN(sat2)) sat2 = 0;
            root._ingest(hue, sat, meanL, hue2, sat2);
        });
    }

    function _ingest(hue, sat, meanL, hue2, sat2) {
        var colors = Palette.build(hue, sat, meanL, hue2, sat2);
        root.currentColors = colors;

        // Persist a flat copy for debugging.
        var jsonStr = JSON.stringify(colors, null, 2);
        var tmp = root.colorsPath + ".tmp";
        ProcessService.runDetached(["sh", "-c",
            'mkdir -p "$(dirname "$3")" && printf "%s" "$1" > "$2" && mv "$2" "$3"',
            "--", jsonStr, tmp, root.colorsPath]);

        root.runHooks(executionTimer.pendingContext);
    }

    // ── APPLICATION HOOKS ─────────────────────────────────────────────

    readonly property var _hooks: ({
        "gtk": GtkHook,
        "firefox": FirefoxHook,
        "kitty": KittyHook,
        "obsidian": ObsidianHook,
        "steam": SteamHook,
        "discord": DiscordHook,
        "nvim": NvimHook,
        "zed": ZedHook
    })

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

            var hook = root._hooks[app.id];
            if (!hook || typeof hook.generate !== "function") continue;

            var result = hook.generate(root.currentColors, ctx);
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

    // ── APPLICATIONS (metadata retained for Phase 2) ──────────────────

    readonly property var applications: [
        { "id": "gtk", "name": "GTK", "binary": "command -v gsettings" },
        { "id": "kitty", "name": "Kitty", "binary": "command -v kitty" },
        { "id": "nvim", "name": "Neovim", "binary": "command -v nvim" },
        { "id": "obsidian", "name": "Obsidian", "binary": "command -v obsidian || flatpak info md.obsidian.Obsidian" },
        { "id": "discord", "name": "Discord", "binary": "command -v vesktop || flatpak info dev.vencord.Vesktop" },
        { "id": "firefox", "name": "Firefox", "binary": "command -v pywalfox" },
        { "id": "steam", "name": "Steam / Millennium", "binary": "command -v steam && test -d ~/.config/millennium" },
        { "id": "zed", "name": "Zed", "binary": "command -v zeditor || command -v zed" }
    ]

    property var installedApps: ({})

    function checkInstalledApps() {
        let newInstalled = {};
        let apps = root.applications;
        let completed = 0;
        apps.forEach(app => {
            // Run the probe with the same explicit PATH as tool invocations, so
            // a tool that is installed but outside the service PATH is not
            // wrongly reported missing.
            var script = 'export PATH="' + root.toolPath + '"; ' + app.binary + ' > /dev/null 2>&1';
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
