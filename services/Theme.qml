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
pragma Singleton

Item {
    id: root

    property bool ready: false

    property var currentColors: root._fallbackColors

    readonly property string defaultSeedColor: "#9d99e5"
    readonly property string configPath: Globals.cacheDir + "/matugen/config.toml"
    readonly property string colorsPath: Globals.cacheDir + "/current_theme/colors.json"

    readonly property var _fallbackColors: ({
        "primary": "#adc6ff",
        "on_primary": "#002e69",
        "primary_container": "#004494",
        "on_primary_container": "#d8e2ff",
        "primary_fixed": "#d8e2ff",
        "primary_fixed_dim": "#adc6ff",
        "on_primary_fixed": "#001a41",
        "on_primary_fixed_variant": "#004494",
        "secondary": "#bbc6e4",
        "on_secondary": "#253048",
        "secondary_container": "#3b475f",
        "on_secondary_container": "#d8e2ff",
        "secondary_fixed": "#d8e2ff",
        "secondary_fixed_dim": "#bbc6e4",
        "on_secondary_fixed": "#0f1b32",
        "on_secondary_fixed_variant": "#3b475f",
        "tertiary": "#e5b8e8",
        "on_tertiary": "#44244a",
        "tertiary_container": "#5d3a62",
        "on_tertiary_container": "#fed6ff",
        "tertiary_fixed": "#fed6ff",
        "tertiary_fixed_dim": "#e5b8e8",
        "on_tertiary_fixed": "#2d0e34",
        "on_tertiary_fixed_variant": "#5d3a62",
        "error": "#ffb4ab",
        "on_error": "#690005",
        "error_container": "#93000a",
        "on_error_container": "#ffb4ab",
        "background": "#1b1b1f",
        "on_background": "#e3e2e6",
        "surface": "#1b1b1f",
        "on_surface": "#e3e2e6",
        "surface_variant": "#44474f",
        "on_surface_variant": "#c4c6d0",
        "surface_dim": "#1b1b1f",
        "surface_bright": "#39393d",
        "surface_container_lowest": "#161618",
        "surface_container_low": "#232326",
        "surface_container": "#27272b",
        "surface_container_high": "#313135",
        "surface_container_highest": "#3c3c40",
        "surface_tint": "#adc6ff",
        "outline": "#8e9099",
        "outline_variant": "#44474f",
        "shadow": "#000000",
        "scrim": "#000000",
        "inverse_surface": "#e3e2e6",
        "inverse_on_surface": "#303033",
        "inverse_primary": "#005ac1",
        "source_color": "#4285f4"
    })

    readonly property int debounceInterval: 300

    // ── THEME APPLICATION ─────────────────────────────────────────────

    function requestApply(context) {
        if (!Preferences.loaded) return;
        executionTimer.pendingContext = context || "manual";
        executionTimer.restart();
    }

    function apply() {
        var scheme = Preferences.globals.schemeType || "scheme-tonal-spot";
        var wp = Wallpaper.currentWallpaper;
        var sourceArgs = (wp && wp !== "")
            ? ["image", wp]
            : ["color", "hex", root.defaultSeedColor];

        var cfg = '[config]\n'
            + 'version_check = false\n'
            + 'caching = false\n'
            + 'fallback_color = "' + root.defaultSeedColor + '"\n'
            + 'prefer = "closest-to-fallback"\n'
            + '[templates]\n';

        var writeCmd = 'mkdir -p "$(dirname "$1")" && printf "%s" "$2" > "$1"';
        ProcessService.run(["sh", "-c", writeCmd, "--", root.configPath, cfg], function() {
            // matugen may live outside the systemd user service PATH, so set it explicitly.
            var script = 'export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:/nix/var/nix/profiles/default/bin:$HOME/.local/bin:$PATH"; exec "$@"';
            var args = ["sh", "-c", script, "--", "matugen", "-c", root.configPath]
                .concat(sourceArgs)
                .concat(["-m", "dark", "-t", scheme, "--json", "hex", "--include-image-in-json=false"]);

            ProcessService.run(args, function(output, exitCode) {
                if (exitCode !== 0 || !output || output.trim() === "") {
                    console.warn("[Theme] matugen failed (exit " + exitCode + ")");
                    return;
                }
                try {
                    root._ingest(JSON.parse(output));
                } catch (e) {
                    console.warn("[Theme] Failed to parse matugen output:", e.message);
                }
            });
        });
    }

    function _token(map, name, mode) {
        if (!map || map[name] === undefined) return undefined;
        if (typeof map[name] === "string") return map[name];
        var entry = map[name][mode] !== undefined ? map[name][mode] : map[name]["default"];
        if (entry === undefined) return undefined;
        return (typeof entry === "string") ? entry : entry.color;
    }

    function _ingest(data) {
        var mode = "dark";
        var colors = Object.assign({}, root._fallbackColors);
        var source = data.colors || {};
        for (var name in source) {
            var val = root._token(source, name, mode);
            if (val) colors[name] = val;
        }

        root.currentColors = colors;
        root.ready = true;

        // Persist a flat copy for debugging.
        var jsonStr = JSON.stringify({ md3: colors }, null, 2);
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
            ProcessService.run(["sh", "-c", app.binary + " > /dev/null 2>&1"], function(out, exitCode) {
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

    Connections {
        target: Preferences.globals
        function onSchemeTypeChanged() {
            root.requestApply("scheme");
        }
    }

    Component.onCompleted: {
        checkInstalledApps();
        updateFontFamilies();
        root.runStartup();
    }
}
