.pragma library

.import "color.js" as Color

/**
 * Yaks palette generator.
 *
 * Turns the wallpaper seed (`hue`, `sat`, `mean_l`, from lib/seed.sh) into the
 * shell's flat token vocabulary, generated in OKLCH so every token is
 * perceptually even across hues and every legible pairing is contrast-checked.
 *
 * Policy: one hue family (the seed) for surfaces, text and accents; chroma is
 * calm and gamut-mapped; `mean_l` lifts the ladder a touch on brighter
 * wallpapers but the shell always stays dark. Achromatic wallpapers (sat ~ 0)
 * yield a grey theme. Terminal ANSI keeps its semantic hues, pulled slightly
 * toward the seed.
 *
 * Tokens:
 *   surfaces  deep well bg surface raised hair border
 *   text      text muted faint
 *   accents   primary secondary tertiary error
 *   ink       text over an accent
 *   ansi      16 terminal colours, indexed (0 black .. 15 bright white)
 */

function _num(x, d) { return (typeof x === "number" && !isNaN(x)) ? x : d; }

// --- ladder (OKLCH lightness), calibrated to the pre-OKLCH look ---------
var L_DEEP = 0.208, L_WELL = 0.248, L_BG = 0.259, L_SURFACE = 0.295,
    L_RAISED = 0.336, L_HAIR = 0.371, L_BORDER = 0.452;
var L_TEXT = 0.923, L_MUTED = 0.784, L_FAINT = 0.496;
var L_ACCENT = 0.800, L_ERROR = 0.760;
var H_ERROR = 29;              // warm red
var ACCENT_SPLIT = 30;         // secondary/tertiary hue offset (deg)
var ANSI_PULL = 0.08;          // how far ANSI hues lean toward the seed

function _deltaHue(a, b) {
    return (((b - a + 180) % 360) + 360) % 360 - 180;
}

function _mixHue(a, b, t) {
    return (a + _deltaHue(a, b) * t + 360) % 360;
}

function build(hueDeg, sat, meanLightness, hue2Deg, sat2) {
    hueDeg = _num(hueDeg, 258);
    sat = Color.clamp(_num(sat, 0.35), 0, 1);
    var meanL = Color.clamp(_num(meanLightness, 0.12), 0, 1);

    // Seed -> OKLCH hue + chroma. Achromatic wallpapers carry no chroma.
    var seed = Color.rgbToOklch(Color.hslToRgb(hueDeg / 360, sat, 0.5));
    var H = seed.h;
    var seedC = sat <= 0.04 ? 0 : seed.c;

    var lift = 0.08 * Math.min(meanL, 0.6);
    var textC = Color.clamp(seedC * 0.08, 0, 0.018);
    var accentC = Color.clamp(seedC * 0.45, 0, 0.105);

    // One uniform surface chroma for the whole family: only lightness separates
    // a canvas from a panel, so sidebars never read lighter/vibrant than the
    // editor beside them. Kept low so a full-window background isn't a flat slab.
    var surfaceC = Color.clamp(seedC * 0.15, 0, 0.017);
    function s(L) { return Color.oklch(L + lift, surfaceC, H); }

    var t = {};
    t.deep    = s(L_DEEP);   // also the terminal's ANSI black
    t.well    = s(L_WELL);
    t.bg      = s(L_BG);
    t.surface = s(L_SURFACE);
    t.raised  = s(L_RAISED);
    t.hair    = s(L_HAIR);
    t.border  = Color.oklch(L_BORDER, surfaceC, H);

    t.text  = Color.oklch(L_TEXT, textC, H);
    t.muted = Color.oklch(L_MUTED, textC, H);
    t.faint = Color.oklch(L_FAINT, textC, H);

    t.primary = Color.oklch(L_ACCENT, accentC, H);

    // secondary/tertiary: if the wallpaper has a real second hue use it, with
    // tertiary an analogous step on the far side — a chord anchored on the
    // image's own hues. Otherwise fall back to synthetic ±ACCENT_SPLIT siblings.
    var h2 = _num(hue2Deg, -1), s2 = _num(sat2, 0);
    if (h2 >= 0 && s2 > 0.04) {
        var H2 = Color.rgbToOklch(Color.hslToRgb(h2 / 360, s2, 0.5)).h;
        var side = _deltaHue(H, H2) >= 0 ? -1 : 1;
        t.secondary = Color.oklch(L_ACCENT, accentC * 0.85, H2);
        t.tertiary  = Color.oklch(L_ACCENT + 0.01, accentC * 0.85, H + side * ACCENT_SPLIT);
    } else {
        t.secondary = Color.oklch(L_ACCENT, accentC * 0.85, H + ACCENT_SPLIT);
        t.tertiary  = Color.oklch(L_ACCENT + 0.01, accentC * 0.85, H - ACCENT_SPLIT);
    }
    // error is semantic: keep a little chroma even on a grey wallpaper.
    t.error = Color.oklch(L_ERROR, Color.clamp(Math.max(accentC * 1.05, 0.055), 0, 0.150), H_ERROR);

    // ink: text over an accent, dark enough for every accent.
    t.ink = Color.oklch(0.240, Color.clamp(accentC * 0.4, 0, 0.05), H);
    var accents = [t.primary, t.secondary, t.tertiary, t.error];
    for (var a = 0; a < accents.length; a++)
        t.ink = Color.ensureContrast(t.ink, accents[a], 4.5);

    // copy: legible on both the panel and the window background.
    t.text = Color.ensureContrast(t.text, t.surface, 7.0);
    t.muted = Color.ensureContrast(t.muted, t.surface, 4.5);
    t.faint = Color.ensureContrast(t.faint, t.surface, 3.0);
    t.text = Color.ensureContrast(t.text, t.bg, 7.0);
    t.muted = Color.ensureContrast(t.muted, t.bg, 4.5);
    t.faint = Color.ensureContrast(t.faint, t.bg, 3.0);

    // ANSI: true semantic hues pulled toward the seed, calm chroma, checked.
    // A small floor keeps red/green/blue legible even on a grey wallpaper.
    var aSat = Color.clamp(Math.max(accentC * 1.3, 0.05), 0, 0.15);
    var pull = seedC > 0 ? ANSI_PULL : 0;
    function ansi(h, L) { return Color.oklch(L, aSat, _mixHue(h, H, pull)); }
    var n = 0.68, b = 0.82;
    t.ansi = [
        t.deep,            // 0  black
        ansi(29, n),       // 1  red
        ansi(145, n),      // 2  green
        ansi(96, n),       // 3  yellow
        ansi(264, n),      // 4  blue
        ansi(328, n),      // 5  magenta
        ansi(195, n),      // 6  cyan
        t.faint,           // 7  white
        t.raised,          // 8  bright black
        ansi(29, b),       // 9  bright red
        ansi(145, b),      // 10 bright green
        ansi(96, b),       // 11 bright yellow
        ansi(264, b),      // 12 bright blue
        ansi(328, b),      // 13 bright magenta
        ansi(195, b),      // 14 bright cyan
        t.text             // 15 bright white
    ];
    for (var i = 1; i <= 6; i++) {
        t.ansi[i] = Color.ensureContrast(t.ansi[i], t.bg, 3.0);
        t.ansi[i + 8] = Color.ensureContrast(t.ansi[i + 8], t.bg, 3.0);
    }

    return t;
}
