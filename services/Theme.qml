import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services
pragma Singleton

Item {
    id: root

    property bool ready: false

    // Flat raw Material 3 tokens, straight from Matugen. No semantic remapping.
    property var currentColors: root._fallbackColors

    // Raw base16 scheme emitted alongside the md3 tokens (retained for Phase 2).
    property var base16: ({})

    readonly property string defaultSeedColor: "#9d99e5"
    readonly property string configPath: Globals.cacheDir + "/matugen/config.toml"
    readonly property string colorsPath: Globals.cacheDir + "/current_theme/colors.json"

    // Material 3 dark baseline, used only until the first Matugen run completes.
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

        // Minimal isolated config: no templates, no wallpaper daemon, no caching.
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

    // Matugen nests tokens as { <name>: { <mode>: { color: "#rrggbb" } } },
    // but also supports a flat string shape, so tolerate both.
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

        var b16 = {};
        var base = data.base16 || {};
        for (var bname in base) {
            var bval = root._token(base, bname, mode);
            if (bval) b16[bname] = bval;
        }

        root.currentColors = colors;
        root.base16 = b16;
        root.ready = true;

        // Persist a flat copy for debugging and future app hooks.
        var jsonStr = JSON.stringify({ md3: colors, base16: b16 }, null, 2);
        var tmp = root.colorsPath + ".tmp";
        ProcessService.runDetached(["sh", "-c",
            'mkdir -p "$(dirname "$3")" && printf "%s" "$1" > "$2" && mv "$2" "$3"',
            "--", jsonStr, tmp, root.colorsPath]);
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
        { "id": "vesktop", "name": "Vesktop", "binary": "command -v vesktop || flatpak info dev.vencord.Vesktop" },
        { "id": "firefox", "name": "Firefox", "binary": "command -v pywalfox" },
        { "id": "steam", "name": "Steam / Millennium", "binary": "command -v steam && test -d ~/.config/millennium" }
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

    // ── SYSTEM THEME SCANNING ─────────────────────────────────────────

    property string gtkTheme: ""
    property string iconTheme: ""
    property string fontName: ""
    property string colorScheme: ""
    property var availableGtkThemes: []
    property var availableIconThemes: []
    property string cursorTheme: ""
    property int cursorSize: 24
    property var availableCursorThemes: []

    function refreshThemeService() {
        ProcessService.run(["gsettings", "get", "org.gnome.desktop.interface", "gtk-theme"], function(out) {
            root.gtkTheme = out.trim().replace(/'/g, "");
        });
        ProcessService.run(["gsettings", "get", "org.gnome.desktop.interface", "icon-theme"], function(out) {
            root.iconTheme = out.trim().replace(/'/g, "");
        });
        ProcessService.run(["gsettings", "get", "org.gnome.desktop.interface", "cursor-theme"], function(out) {
            root.cursorTheme = out.trim().replace(/'/g, "");
        });
        ProcessService.run(["gsettings", "get", "org.gnome.desktop.interface", "cursor-size"], function(out) {
            var val = parseInt(out.trim());
            root.cursorSize = isNaN(val) ? 24 : val;
        });
        ProcessService.run(["gsettings", "get", "org.gnome.desktop.interface", "font-name"], function(out) {
            root.fontName = out.trim().replace(/'/g, "");
        });
        ProcessService.run(["gsettings", "get", "org.gnome.desktop.interface", "color-scheme"], function(out) {
            root.colorScheme = out.trim().replace(/'/g, "");
        });
    }

    function scanThemeServices() {
        const agnosticCmd = `
            echo "$XDG_DATA_DIRS:/usr/local/share:/usr/share" | tr ':' '\\n' | while read -r dir; do
                [ -d "$dir/themes" ] && find -L "$dir/themes" -mindepth 1 -maxdepth 1 -type d -printf '%f\\n' 2>/dev/null
                [ "$dir" = "$HOME/.themes" ] && find -L "$dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\\n' 2>/dev/null
            done | sort | uniq
        `;
        ProcessService.run(["sh", "-c", agnosticCmd], function(out) {
            root.availableGtkThemes = out.split('\n').filter(l => l.length > 0 && l !== "themes" && l[0] !== '.');
        });

        const agnosticIconsCmd = `
            echo "$XDG_DATA_DIRS:/usr/local/share:/usr/share" | tr ':' '\\n' | while read -r dir; do
                SDIR="$dir"
                [ -d "$dir/icons" ] && SDIR="$dir/icons"
                [ -d "$SDIR" ] && for d in "$SDIR"/*; do
                    [ -d "$d" ] && [ -f "$d/index.theme" ] && [ ! -d "$d/cursors" ] && [ ! -f "$d/cursor.theme" ] && basename "$d"
                done
            done 2>/dev/null | sort | uniq
        `;
        ProcessService.run(["sh", "-c", agnosticIconsCmd], function(out) {
            root.availableIconThemes = out.split('\n').filter(l => l.length > 0 && l !== "icons" && l[0] !== '.');
        });

        scanCursorThemes();
    }

    function scanCursorThemes() {
        const agnosticCursorsCmd = `
            echo "$XDG_DATA_DIRS:/usr/local/share:/usr/share" | tr ':' '\\n' | while read -r dir; do
                SDIR="$dir"
                [ -d "$dir/icons" ] && SDIR="$dir/icons"
                [ -d "$SDIR" ] && for d in "$SDIR"/*; do
                    [ -d "$d" ] && { [ -d "$d/cursors" ] || [ -f "$d/cursor.theme" ]; } && basename "$d"
                done
            done 2>/dev/null | sort | uniq
        `;
        ProcessService.run(["sh", "-c", agnosticCursorsCmd], function(out) {
            root.availableCursorThemes = out.split('\n').filter(l => l.length > 0);
        });
    }

    function toggleColorScheme() {
        var newScheme = (root.colorScheme === 'prefer-dark') ? 'default' : 'prefer-dark';
        ProcessService.run(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", newScheme], function() {
            refreshThemeService();
        });
    }

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
        refreshThemeService();
        scanThemeServices();
        checkInstalledApps();
        updateFontFamilies();
        root.runStartup();
    }
}
