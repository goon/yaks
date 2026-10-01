import QtQuick
import Quickshell
import qs.services
pragma Singleton

QtObject {
    id: root

    // ── PATHS & EXTERNAL RESOURCES ────────────────────────────────────────
    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string rootDir: homeDir + "/.config/yaks"
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
        readonly property color deep:    colorsRoot._raw.deep
        readonly property color bg:      colorsRoot._raw.bg
        readonly property color surface: colorsRoot._raw.surface
        readonly property color raised:  colorsRoot._raw.raised
        readonly property color well:    colorsRoot._raw.well

        // shell capsule gradient — vivid chrome tokens, shell-only, and the
        // only place the user Opacity setting applies.
        readonly property color top:    root.alpha(colorsRoot._raw.top, root.opacity.background)
        readonly property color bottom: root.alpha(colorsRoot._raw.bottom, root.opacity.background)
        // capsule outline: a lighter tint of the capsule background, shell-only.
        readonly property color outline: colorsRoot._raw.outline

        // lines
        readonly property color border: colorsRoot._raw.border
        readonly property color hair:   colorsRoot._raw.hair

        // copy
        readonly property color text:  colorsRoot._raw.text
        readonly property color muted: colorsRoot._raw.muted
        readonly property color faint: colorsRoot._raw.faint

        // accents
        readonly property color primary:   colorsRoot._raw.primary
        readonly property color secondary: colorsRoot._raw.secondary
        // `primary` stepped in lightness, for the capsule's top-lit bevel on a
        // filled control (slider tracks, the workspace pill). Same hue/chroma.
        readonly property color accentTop:    colorsRoot._raw.accentTop
        readonly property color accentBottom: colorsRoot._raw.accentBottom
        // Text drawn on top of an accent. The palette contrast-enforces this
        // against every accent, so never substitute bg or text for it.
        readonly property color ink:      colorsRoot._raw.ink

        // states
        readonly property color hover:    root.alpha(colorsRoot._raw.text, 0.055)
        readonly property color tint:     root.alpha(colorsRoot._raw.primary, 0.15)
        readonly property color disabled: root.alpha(colorsRoot._raw.bg, 0.50)
    }

    readonly property QtObject opacity: QtObject {
        readonly property real background: Math.max(0.3, Preferences.globals.backgroundOpacity)
    }

    // ── GEOMETRY TOKENS ──────────────────────────────────────────────────

    readonly property QtObject geometry: QtObject {
        readonly property QtObject rounding: QtObject {
            readonly property int sharp: 8
            readonly property int soft: 16
            readonly property int round: 26
        }

        readonly property int radius: (rounding[Preferences.globals.rounding] || rounding.round) * root.shellScale

        readonly property QtObject spacing: QtObject {
            readonly property int xs: 4 * root.shellScale
            readonly property int sm: 8 * root.shellScale
            readonly property int md: 12 * root.shellScale
            readonly property int lg: 18 * root.shellScale
            readonly property int xl: 22 * root.shellScale
        }

        readonly property QtObject borderWidth: QtObject {
            readonly property int hair: 1 * root.shellScale
            readonly property int thick: 2 * root.shellScale
        }
    }

    // The radius of a control nested one step inside another. Takes the gap
    // between the two rather than the gap itself, so it tracks the scale.
    function innerRadius(step) {
        return root.geometry.radius === 0
            ? 0 : Math.max(4 * root.shellScale, root.geometry.radius - step);
    }

    // ── DIMENSIONS ──────────────────────────────────────────────────────
    readonly property QtObject
    dimensions: QtObject {
        readonly property int thumbnail: 30 * root.shellScale
        readonly property int controlHeightSmall: 28 * root.shellScale
    }

    // ── TYPOGRAPHY ──────────────────────────────────────────────────────
    readonly property QtObject
    typography: QtObject {
        readonly property string family: Preferences.globals.shellFont
        readonly property string iconFamily: "Lucide"

        readonly property QtObject
        weight: QtObject {
            readonly property int normal: 500
            readonly property int demi: 600
            readonly property int bold: 700
        }

        readonly property QtObject
        size: QtObject {
            readonly property int xs: 10 * root.shellScale
            readonly property int sm: 12 * root.shellScale
            readonly property int md: 14 * root.shellScale
            readonly property int lg: 16 * root.shellScale
            readonly property int xl: 22 * root.shellScale
        }

        readonly property QtObject
        icon: QtObject {
            readonly property int sm: 16 * root.shellScale
            readonly property int md: 18 * root.shellScale
            readonly property int lg: 20 * root.shellScale
        }
    }

    // ── MOTION ──────────────────────────────────────────────────────────
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
            readonly property int radius: 20 * root.shellScale
            readonly property real opacity: 0.4
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
