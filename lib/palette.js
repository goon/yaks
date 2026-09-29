.pragma library

/**
 * Yaks palette generator.
 *
 * Turns the wallpaper seed colour (produced by lib/seed.sh) into the shell's
 * flat token vocabulary. Deliberately not Material: there is no HCT, no
 * on_/container/fixed/dim roles and no scheme type. The palette is one hue
 * family (the seed) plus the text/border tiers, and the terminal ANSI wheel
 * keeps its true semantic hues tuned to the seed so terminals still read
 * red/green/blue correctly. "on" colours are folded into `ink`; any softer
 * tint is expressed as alpha at the call site.
 *
 * Tokens:
 *   surfaces  deep bg surface raised       (lightness ladder, seed hue, low chroma)
 *   borders   border hair
 *   text      bright text muted subtle dim faint
 *   accents   primary secondary tertiary error
 *   ink       text over an accent
 *   ansi      16 terminal colours, indexed (0 black .. 15 bright white)
 */

function _clamp(x, lo, hi) { return x < lo ? lo : (x > hi ? hi : x); }

function _hexToRgb(hex) {
    var h = String(hex || "").replace("#", "");
    return {
        r: parseInt(h.substr(0, 2), 16) / 255,
        g: parseInt(h.substr(2, 2), 16) / 255,
        b: parseInt(h.substr(4, 2), 16) / 255
    };
}

function _rgbToHsl(c) {
    var max = Math.max(c.r, c.g, c.b), min = Math.min(c.r, c.g, c.b);
    var l = (max + min) / 2, h = 0, s = 0, d = max - min;
    if (d !== 0) {
        s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
        if (max === c.r) h = (c.g - c.b) / d + (c.g < c.b ? 6 : 0);
        else if (max === c.g) h = (c.b - c.r) / d + 2;
        else h = (c.r - c.g) / d + 4;
        h /= 6;
    }
    return { h: h, s: s, l: l };
}

// Shortest-path hue interpolation: blend `a` toward `b` by t (0..1). Used to
// pull the semantic ANSI hues toward the wallpaper without losing their identity.
function _mixHue(a, b, t) {
    var d = (((b - a + 0.5) % 1) + 1) % 1 - 0.5;
    return (((a + d * t) % 1) + 1) % 1;
}

function _hslToHex(h, s, l) {
    h = ((h % 1) + 1) % 1;
    s = _clamp(s, 0, 1);
    l = _clamp(l, 0, 1);

    function hue(p, q, t) {
        if (t < 0) t += 1;
        if (t > 1) t -= 1;
        if (t < 1 / 6) return p + (q - p) * 6 * t;
        if (t < 1 / 2) return q;
        if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
        return p;
    }

    var r, g, b;
    if (s === 0) {
        r = g = b = l;
    } else {
        var q = l < 0.5 ? l * (1 + s) : l + s - l * s;
        var p = 2 * l - q;
        r = hue(p, q, h + 1 / 3);
        g = hue(p, q, h);
        b = hue(p, q, h - 1 / 3);
    }

    function to(x) {
        var v = Math.round(_clamp(x, 0, 1) * 255).toString(16);
        return v.length < 2 ? "0" + v : v;
    }
    return "#" + to(r) + to(g) + to(b);
}

/**
 * Build the token map. Chroma is fixed policy (Uki's clamps) and the tone is
 * wallpaper-driven: `meanLightness` (the image's mean HSL lightness, from
 * lib/seed.sh) lifts the surface ladder a little on brighter wallpapers. The
 * lift is small and capped so the shell always stays a dark theme — no
 * blue-tinted-white panels — and the text tiers stay light regardless.
 */
function build(seedHex, meanLightness) {
    var seed = _rgbToHsl(_hexToRgb(seedHex));
    var hue = seed.h;
    var meanL = (typeof meanLightness === "number" && !isNaN(meanLightness))
        ? _clamp(meanLightness, 0, 1) : 0.12;

    // Tone lift: 0 for a dark wallpaper, up to +0.048 at mean_l >= 0.6. Even at
    // full lift the ladder tops out around L 0.23 (raised), still firmly dark.
    var lift = 0.08 * Math.min(meanL, 0.6);
    var liftT = lift / 0.048;   // 0..1, for easing the chroma down with the lift

    // Uki's dark clamps: surfaces sit in the ~0.30 range but on a lifted
    // lightness ladder, so the tint reads as a calm dark surface rather than a
    // coloured slab. Accents carry the stronger hue. As surfaces lift, back the
    // surface chroma off a little so brighter panels don't look milky.
    var surfaceSat = _clamp(seed.s, 0.26, 0.34) * (1 - 0.35 * liftT);
    var accentSat = _clamp(seed.s, 0.40, 0.80);
    var textSat = _clamp(seed.s * 0.3, 0.02, 0.08);

    var t = {};

    // Surfaces — one hue, a dark lightness ladder whose tone follows the
    // wallpaper (border is left fixed so the outline stays consistent).
    t.deep    = _hslToHex(hue, surfaceSat, 0.065 + lift);
    t.bg      = _hslToHex(hue, surfaceSat, 0.110 + lift);
    t.surface = _hslToHex(hue, surfaceSat, 0.145 + lift);
    t.raised  = _hslToHex(hue, surfaceSat, 0.185 + lift);
    t.hair    = _hslToHex(hue, surfaceSat, 0.220 + lift);
    t.border  = _hslToHex(hue, surfaceSat, 0.350);

    // Text tiers.
    t.bright = _hslToHex(hue, textSat, 0.97);
    t.text   = _hslToHex(hue, textSat, 0.90);
    t.muted  = _hslToHex(hue, textSat, 0.72);
    t.subtle = _hslToHex(hue, textSat, 0.62);
    t.dim    = _hslToHex(hue, textSat, 0.48);
    t.faint  = _hslToHex(hue, textSat, 0.38);

    // Accents — seed hue for primary; the other two sit either side of it so
    // editors get a little differentiation without leaving the family.
    t.primary   = _hslToHex(hue, accentSat, 0.72);
    t.secondary = _hslToHex(hue + 0.08, accentSat * 0.85, 0.72);
    t.tertiary  = _hslToHex(hue - 0.08, accentSat * 0.85, 0.75);
    t.error     = _hslToHex(0.0, accentSat, 0.72);

    // Text over an accent (accents share a lightness, so one value covers all).
    t.ink = _hslToHex(hue, _clamp(accentSat * 0.4, 0.05, 0.35), 0.12);

    // Terminal ANSI: true semantic hues at a lightness matched to the theme,
    // with the four neutral slots taken from the ramp so terminals sit with
    // the shell rather than against it.
    var aSat = _clamp(seed.s, 0.35, 0.65);
    // Pull each semantic hue a quarter of the way toward the wallpaper, so the
    // terminal content tracks the seed while red stays red and blue stays blue.
    var tune = 0.25;
    function ansi(h, l) { return _hslToHex(_mixHue(h, hue, tune), aSat, l); }
    t.ansi = [
        t.deep,               // 0  black
        ansi(0.00, 0.62),     // 1  red
        ansi(0.33, 0.62),     // 2  green
        ansi(0.14, 0.62),     // 3  yellow
        ansi(0.60, 0.66),     // 4  blue
        ansi(0.83, 0.66),     // 5  magenta
        ansi(0.50, 0.66),     // 6  cyan
        t.faint,              // 7  white
        t.raised,             // 8  bright black
        ansi(0.00, 0.78),     // 9  bright red
        ansi(0.33, 0.78),     // 10 bright green
        ansi(0.14, 0.78),     // 11 bright yellow
        ansi(0.60, 0.80),     // 12 bright blue
        ansi(0.83, 0.80),     // 13 bright magenta
        ansi(0.50, 0.80),     // 14 bright cyan
        t.bright              // 15 bright white
    ];

    return t;
}
