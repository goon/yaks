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
 * yield a grey theme. Terminal ANSI is drawn only from the wallpaper's
 * chromatic families (passed in from seed.sh), separated by lightness.
 *
 * Tokens:
 *   surfaces  deep well bg surface raised hair border
 *   chrome    top bottom   (shell capsule gradient; never used by app hooks)
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
var ANSI_L = 0.560;            // base lightness of the ANSI chromatic slots
var ANSI_STEP = 0.110;         // lightness step when slots share a hue
var ANSI_LIFT = 0.140;         // bright-variant lightness lift
var ANSI_DEDUP = 22;           // min hue gap (deg) between ANSI families

function _deltaHue(a, b) {
    return (((b - a + 180) % 360) + 360) % 360 - 180;
}

function build(hueDeg, sat, meanLightness, hue2Deg, sat2, families) {
    hueDeg = _num(hueDeg, 258);
    sat = Color.clamp(_num(sat, 0.35), 0, 1);
    var meanL = Color.clamp(_num(meanLightness, 0.12), 0, 1);

    // Seed -> OKLCH hue + chroma. Achromatic wallpapers carry no chroma.
    var seed = Color.rgbToOklch(Color.hslToRgb(hueDeg / 360, sat, 0.5));
    var H = seed.h;
    var seedC = sat <= 0.04 ? 0 : seed.c;

    var lift = 0.08 * Math.min(meanL, 0.6);
    var textC = Color.clamp(seedC * 0.08, 0, 0.018);

    // Chroma policy. Achromatic wallpapers (seedC 0) stay fully grey.
    var chromatic = seedC > 0;
    var accentC = chromatic ? Color.clamp(seedC * 0.85, 0.075, 0.150) : 0;

    // Content/app surfaces: calm and near-neutral, uniform. Only lightness
    // separates a canvas from a panel, so large app windows aren't a coloured
    // slab and a sidebar never reads more vibrant than the editor beside it.
    var surfaceC = chromatic ? Color.clamp(seedC * 0.18, 0, 0.020) : 0;

    // Shell chrome: the capsule gradient is the shell's only exclusive surface,
    // so it can carry vivid wallpaper tint without touching any app window.
    var chromeC = chromatic ? Color.clamp(seedC * 0.45, 0.032, 0.055) : 0;

    function s(L) { return Color.oklch(L + lift, surfaceC, H); }

    var t = {};
    t.deep    = s(L_DEEP);   // also the terminal's ANSI black
    t.well    = s(L_WELL);
    t.bg      = s(L_BG);
    t.surface = s(L_SURFACE);
    t.raised  = s(L_RAISED);
    t.hair    = s(L_HAIR);
    t.border  = Color.oklch(L_BORDER, surfaceC, H);

    // shell capsule gradient (top lighter -> bottom darker), vivid
    t.top    = Color.oklch(L_RAISED + lift, chromeC, H);
    t.bottom = Color.oklch(L_SURFACE + lift, chromeC, H);

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
    t.error = Color.oklch(L_ERROR, Color.clamp(Math.max(accentC * 1.05, 0.085), 0, 0.150), H_ERROR);

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

    // ANSI: built only from hues the wallpaper actually contains. seed.sh
    // reports the prominent chromatic families; the six chromatic slots are
    // drawn from those families and separated by lightness tiers, so a
    // monochrome wallpaper yields a tonal ramp of its own hue rather than
    // invented greens/purples. Canonical slots are filled in hue order, so the
    // warmest family lands on red and the coolest on blue. Achromatic
    // wallpapers keep the canonical spread at a low chroma.
    var aSat = Color.clamp(accentC * 1.10, 0.06, 0.14);
    function famOK(h, s) { return Color.rgbToOklch(Color.hslToRgb(h / 360, s, 0.5)); }

    var fams = [];
    if (chromatic) {
        var src = families || [];
        for (var fi = 0; fi < src.length; fi++) {
            var ok = famOK(src[fi].h, src[fi].s);
            var dup = false;
            for (var fj = 0; fj < fams.length; fj++)
                if (Math.abs(_deltaHue(fams[fj].h, ok.h)) < ANSI_DEDUP) { dup = true; break; }
            if (!dup && ok.c > 0.012) fams.push({ h: ok.h, c: ok.c });
        }
        if (fams.length === 0) {
            fams.push({ h: H, c: seedC });
            if (h2 >= 0 && s2 > 0.04) {
                var ok2 = famOK(h2, s2);
                if (Math.abs(_deltaHue(H, ok2.h)) >= ANSI_DEDUP) fams.push({ h: ok2.h, c: ok2.c });
            }
        }
    }

    var n = 0.68, b = 0.82;
    t.ansi = [t.deep, null, null, null, null, null, null, t.faint, t.raised,
              null, null, null, null, null, null, t.text];

    if (!chromatic) {
        var ansiH = [29, 96, 145, 195, 264, 328];   // canonical, ascending hue
        var ansiIdx = [1, 3, 2, 6, 4, 5];           // red yellow green cyan blue magenta
        for (var g = 0; g < 6; g++) {
            t.ansi[ansiIdx[g]] = Color.oklch(n, aSat, ansiH[g]);
            t.ansi[ansiIdx[g] + 8] = Color.oklch(b, aSat, ansiH[g]);
        }
    } else {
        // One colour per family per lightness tier; a single-family wallpaper
        // gets a wider ramp so all six slots stay distinct.
        var solo = fams.length === 1;
        var slots = [];
        for (var si = 0; si < 6; si++) {
            var fm = solo ? fams[0] : fams[si % fams.length];
            var L = solo ? (0.46 + si * 0.083) : (ANSI_L + Math.floor(si / fams.length) * ANSI_STEP);
            slots.push({ h: fm.h, c: Color.clamp(fm.c * 0.95, 0.03, aSat), L: L });
        }
        slots.sort(function (x, y) {
            return (((x.h % 360) + 360) % 360) - (((y.h % 360) + 360) % 360);
        });
        var slotIdx = [1, 3, 2, 6, 4, 5];
        for (var k = 0; k < 6; k++) {
            t.ansi[slotIdx[k]] = Color.oklch(slots[k].L, slots[k].c, slots[k].h);
            t.ansi[slotIdx[k] + 8] = Color.oklch(Color.clamp(slots[k].L + ANSI_LIFT, 0, 0.95), slots[k].c, slots[k].h);
        }
    }

    for (var i = 1; i <= 6; i++) {
        t.ansi[i] = Color.ensureContrast(t.ansi[i], t.bg, 3.0);
        t.ansi[i + 8] = Color.ensureContrast(t.ansi[i + 8], t.bg, 3.0);
    }

    return t;
}
