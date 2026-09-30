import QtQuick
import Quickshell
import qs.services
pragma Singleton

QtObject {
    id: root

    // ── ROUNDING PRESETS ──────────────────────────────────────────────────
    // Fixed, designed panel radii (not arbitrary). Sub-radii derive from the
    // selected base via geometry.radius / geometry.innerRadius.
    readonly property var _roundingBases: ({ sharp: 8, soft: 16, round: 26 })

    // ── PATHS & EXTERNAL RESOURCES ────────────────────────────────────────
    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string rootDir: homeDir + "/.config/yaks"
    readonly property string assetsDir: rootDir + "/assets"
    readonly property string dataDir: homeDir + "/.local/share/yaks"
    readonly property string cacheDir: homeDir + "/.cache/yaks"

    // Explicit PATH for spawning external tools. The shell may be started from
    // a systemd user service whose PATH lacks the system profiles, so tools
    // that are installed (terminals, theming CLIs) would otherwise be reported
    // missing. Shared by every Process that shells out (Theme, Wallpaper).
    readonly property string toolPath: "/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:/nix/var/nix/profiles/default/bin:$HOME/.local/bin:$PATH"

    // ── COLOURS ───────────────────────────────────────────────────────────
    readonly property QtObject colors: QtObject {
        id: colorsRoot

        // ── RAW PASSTHROUGH (internal) ────────────────────────────────────
        readonly property var _raw: Theme.currentColors || ({})

        // ── ROLE LAYER ────────────────────────────────────────────────────
        // The only colours components consume. Everything derived (state
        // layers, the recessed well, the background gradient's opacity) is
        // resolved here once; call sites never touch raw tokens or do colour
        // math.

        // surfaces
        readonly property color bg:      colorsRoot._raw.bg
        readonly property color surface: colorsRoot._raw.surface
        readonly property color raised:  colorsRoot._raw.raised
        readonly property color well:    colorsRoot._raw.well

        // shell capsule gradient — vivid chrome tokens, shell-only, and the
        // only place the user Opacity setting applies.
        readonly property color top:    root.alpha(colorsRoot._raw.top, root.opacity.background)
        readonly property color bottom: root.alpha(colorsRoot._raw.bottom, root.opacity.background)

        // lines
        readonly property color border: colorsRoot._raw.border
        readonly property color hair:   colorsRoot._raw.hair

        // copy
        readonly property color text:  colorsRoot._raw.text
        readonly property color muted: colorsRoot._raw.muted

        // accents
        readonly property color primary:   colorsRoot._raw.primary
        readonly property color secondary: colorsRoot._raw.secondary

        // states
        readonly property color hover:    root.alpha(colorsRoot._raw.text, 0.08)
        readonly property color tint:     root.alpha(colorsRoot._raw.primary, 0.15)
        readonly property color disabled: root.alpha(colorsRoot._raw.bg, 0.50)
    }

    readonly property QtObject opacity: QtObject {
        readonly property real background: Math.max(0.3, Preferences.globals.backgroundOpacity)
    }

    /*
     * =========================================================================
     *   📐 GEOMETRY (Style Tokens)
     * =========================================================================
     */
    readonly property QtObject geometry: QtObject {
        readonly property int radius: (_roundingBases[Preferences.globals.rounding] || 26) * root.shellScale
        readonly property QtObject spacing: QtObject {
            readonly property int small: 6 * root.shellScale
            readonly property int medium: 8 * root.shellScale
            readonly property int large: 12 * root.shellScale
        }

        readonly property QtObject padding: QtObject {
            readonly property int small: 8 * root.shellScale
            readonly property int medium: 14 * root.shellScale
            readonly property int island: Math.max(22 * root.shellScale, Math.ceil(root.geometry.radius * 0.5))
        }

        readonly property QtObject innerRadius: QtObject {
            readonly property int small: root.geometry.radius === 0 ? 0 : Math.max(4 * root.shellScale, root.geometry.radius - root.geometry.spacing.small)
            readonly property int medium: root.geometry.radius === 0 ? 0 : Math.max(4 * root.shellScale, root.geometry.radius - root.geometry.spacing.medium)
        }

        readonly property QtObject slider: QtObject {
            readonly property int trackHeight: 12 * root.shellScale
            readonly property int handleWidth: 4 * root.shellScale
            readonly property int handleHeight: 20 * root.shellScale
            readonly property int gap: 5 * root.shellScale
        }
    }

    /*
     * =========================================================================
     *   📏 DIMENSIONS (Component Sizing)
     * =========================================================================
     */
    readonly property QtObject
    dimensions: QtObject {
        readonly property int barItemHeight: 32 * root.shellScale
        readonly property int listItemHeight: 44 * root.shellScale
        readonly property int settingsRowHeight: 36 * root.shellScale
        readonly property int iconSmall: 16 * root.shellScale
        readonly property int iconBase: 18 * root.shellScale
        readonly property int iconMedium: 20 * root.shellScale
        readonly property int iconLarge: 32 * root.shellScale
        readonly property int iconExtraLarge: 48 * root.shellScale
        readonly property int launcherItemHeight: 54 * root.shellScale
        readonly property int launcherSearchHeight: 50 * root.shellScale
        readonly property int caretWidth: Math.max(2, Math.round(2 * root.shellScale))
    }

    /*
     * =========================================================================
     *   🔡 TYPOGRAPHY
     * =========================================================================
     */
    readonly property QtObject
    typography: QtObject {
        readonly property string family: Preferences.globals.shellFont
        readonly property string iconFamily: "Lucide"
        readonly property QtObject
        weights: QtObject {
            readonly property int normal: 400
            readonly property int medium: 500
            readonly property int bold: 700
        }

        readonly property QtObject
        size: QtObject {
            readonly property int small: 12 * root.shellScale
            readonly property int base: 14 * root.shellScale
            readonly property int medium: 16 * root.shellScale
            readonly property int large: 18 * root.shellScale
        }

    }

    /*
     * =========================================================================
     *   🎬 MOTION & EFFECTS
     * =========================================================================
     */
    readonly property QtObject
    motion: QtObject {
        // ── DURATIONS (ms) ──────────────────────────────────────────────
        readonly property int hover: 140
        readonly property int standard: 300
        readonly property int morph: 420
        readonly property int heat: 2000

        // ── EASINGS ─────────────────────────────────────────────────────
        readonly property int easeStandard: Easing.OutCubic
        readonly property int easeSpring: Easing.OutBack
        // Easing.BezierSpline curve; Qt expects point groups ending at 1,1.
        readonly property var easeEmphasis: [0.16, 1, 0.3, 1, 1, 1]
    }

    readonly property QtObject
    effects: QtObject {
        readonly property QtObject
        shadow: QtObject {
            readonly property color color: "#000000"
            readonly property int radius: 20
            readonly property int offsetX: 0
            readonly property int offsetY: 0
        }
    }

    function alpha(c, a) {
        if (!c)
            return "transparent";

        var col = (typeof c === "string") ? Qt.color(c) : c;
        return Qt.rgba(col.r, col.g, col.b, a);
    }

    readonly property real shellScale: {
        if (Preferences.globals.scale === 0)
            return 0.9;
        if (Preferences.globals.scale === 1)
            return 1;
        if (Preferences.globals.scale === 2)
            return 1.1;
        return 1;
    }

}
