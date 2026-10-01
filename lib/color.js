.pragma library

/**
 * Single colour module for the shell: OKLCH palette generation plus the
 * conversion/contrast maths it needs, and the small sRGB/hex helpers the app
 * hooks call (`alpha`/`rgbString`).
 *
 * `build()` turns a wallpaper seed (from lib/seed.sh) into the flat token
 * vocabulary consumed by Globals and the hooks. Generation and gamut mapping
 * run in OKLCH (a perceptually uniform space); contrast uses WCAG relative
 * luminance.
 */

function clamp(x, lo, hi) { return x < lo ? lo : (x > hi ? hi : x); }

function hexToRgb(hex) {
    var h = String(hex || "").replace("#", "");
    if (h.length === 8) h = h.substr(0, 6);   // tolerate #rrggbbaa
    return {
        r: parseInt(h.substr(0, 2), 16) / 255,
        g: parseInt(h.substr(2, 2), 16) / 255,
        b: parseInt(h.substr(4, 2), 16) / 255
    };
}

function rgbToHex(c) {
    function to(x) {
        var v = Math.round(clamp(x, 0, 1) * 255).toString(16);
        return v.length < 2 ? "0" + v : v;
    }
    return "#" + to(c.r) + to(c.g) + to(c.b);
}

// ── OKLab / OKLCH (Björn Ottosson) ────────────────────────────────────

function _srgbToLinear(x) {
    return x <= 0.04045 ? x / 12.92 : Math.pow((x + 0.055) / 1.055, 2.4);
}

function _linearToSrgb(x) {
    return x <= 0.0031308 ? x * 12.92 : 1.055 * Math.pow(x, 1 / 2.4) - 0.055;
}

function rgbToOklch(c) {
    var r = _srgbToLinear(c.r), g = _srgbToLinear(c.g), b = _srgbToLinear(c.b);

    var l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
    var m = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
    var s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);

    var L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s;
    var A = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s;
    var B = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s;

    var C = Math.sqrt(A * A + B * B);
    var H = Math.atan2(B, A) * 180 / Math.PI;
    if (H < 0) H += 360;
    return { l: L, c: C, h: H };
}

function _oklchToRgbRaw(l, c, h) {
    var hr = h * Math.PI / 180;
    var A = c * Math.cos(hr), B = c * Math.sin(hr);

    var l_ = l + 0.3963377774 * A + 0.2158037573 * B;
    var m_ = l - 0.1055613458 * A - 0.0638541728 * B;
    var s_ = l - 0.0894841775 * A - 1.2914855480 * B;

    var l3 = l_ * l_ * l_, m3 = m_ * m_ * m_, s3 = s_ * s_ * s_;

    var r = 4.0767416621 * l3 - 3.3077115913 * m3 + 0.2309699292 * s3;
    var g = -1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3;
    var b = -0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3;

    return { r: _linearToSrgb(r), g: _linearToSrgb(g), b: _linearToSrgb(b) };
}

function _inGamut(c) {
    var e = 0.0005;
    return c.r >= -e && c.r <= 1 + e && c.g >= -e && c.g <= 1 + e && c.b >= -e && c.b <= 1 + e;
}

/** OKLCH → #rrggbb, reducing chroma until the colour fits sRGB. */
function oklch(l, c, h) {
    l = clamp(l, 0, 1);
    if (c < 0) c = 0;
    var rgb = _oklchToRgbRaw(l, c, h);
    var k = 0;
    while (!_inGamut(rgb) && k < 40) {
        c *= 0.95;
        rgb = _oklchToRgbRaw(l, c, h);
        k++;
    }
    return rgbToHex({ r: clamp(rgb.r, 0, 1), g: clamp(rgb.g, 0, 1), b: clamp(rgb.b, 0, 1) });
}

// ── Contrast ──────────────────────────────────────────────────────────

function lum(hex) {
    var c = hexToRgb(hex);
    return 0.2126 * _srgbToLinear(c.r) + 0.7152 * _srgbToLinear(c.g) + 0.0722 * _srgbToLinear(c.b);
}

function contrast(a, b) {
    var la = lum(a), lb = lum(b);
    var hi = Math.max(la, lb), lo = Math.min(la, lb);
    return (hi + 0.05) / (lo + 0.05);
}

/**
 * Return `fg` adjusted (lightness only, hue+chroma preserved) until it clears
 * `ratio` against `bg`. Moves away from the background's lightness.
 */
function ensureContrast(fg, bg, ratio) {
    if (contrast(fg, bg) >= ratio) return fg;
    var f = rgbToOklch(hexToRgb(fg));
    var dir = rgbToOklch(hexToRgb(bg)).l < 0.5 ? 1 : -1;   // dark bg -> lighten fg
    for (var i = 1; i <= 100; i++) {
        var L = clamp(f.l + dir * i * 0.01, 0, 1);
        var hx = oklch(L, f.c, f.h);
        if (contrast(hx, bg) >= ratio) return hx;
        if (L <= 0 || L >= 1) break;
    }
    return oklch(clamp(f.l + dir, 0, 1), f.c, f.h);
}

// ── Hooks' helpers (the surface the app hooks use) ────────────────────

function alpha(hex, a) {
    var v = Math.round(a * 255).toString(16);
    return rgbToHex(hexToRgb(hex)) + (v.length < 2 ? "0" + v : v);
}

/** "#rrggbb" -> "r, g, b" (for CSS rgba()). */
function rgbString(hex) {
    var c = hexToRgb(hex);
    return Math.round(c.r * 255) + ", " + Math.round(c.g * 255) + ", " + Math.round(c.b * 255);
}

// ── Palette generation ────────────────────────────────────────────────
//
// Turns a seed object (from seedFromHistogram()) into the shell's flat token
// vocabulary, generated in OKLCH so every token is perceptually even across
// hues and every legible pairing is contrast-checked.
//
// Policy: one hue family (the seed) for surfaces, text and accents; chroma is
// calm and gamut-mapped; `meanL` lifts the ladder a touch on brighter
// wallpapers but the shell always stays dark. Achromatic wallpapers (chroma ~ 0)
// yield a grey theme. A `colorfulness` score damps accents on busy wallpapers.
// Terminal ANSI is drawn only from the wallpaper's chromatic families,
// separated by lightness.
//
// Tokens:
//   surfaces  deep well bg surface raised hair border
//   chrome    top bottom outline   (shell-only; never used by app hooks)
//   text      text muted faint
//   accents   primary secondary tertiary error
//   ink       text over an accent
//   ansi      16 terminal colours, indexed (0 black .. 15 bright white)

// Fallback seed (no wallpaper): a soft periwinkle. Same shape as a
// seedFromHistogram() result so build() has a single input vocabulary.
var DEFAULT_SEED = { hue: 258, chroma: 0.10, meanL: 0.12, colorfulness: 0,
                     hue2: -1, chroma2: 0, families: [] };

// ── Seed extraction (from a colour histogram) ─────────────────────────
//
// seed.sh prints ImageMagick histogram lines ("<count>: (...) #rrggbb ...");
// all colour science lives here. Bins are converted to OKLab, weighted by
// pixel count, and binned into 30-degree hue families. The seed carries the
// wallpaper's *real* chroma and lightness — never a chroma reconstructed at a
// synthetic lightness — plus a `colorfulness` score that build() uses to keep
// loud wallpapers from producing a loud theme.

var CHROMA_FLOOR = 0.04;       // below this a bin counts as grey
var L_MIN = 0.05;              // ignore near-black
var L_MAX = 0.92;              // ignore near-white
var FAMILY_SCORE_TAIL = 0.10;  // family counts toward variety above this fraction
var INTENSITY_REF = 0.16;      // OKLCH chroma that reads as "fully vivid"

/** Parse ImageMagick histogram lines into `[{ count, rgb }]`. */
function parseHistogram(text) {
    var bins = [];
    if (!text) return bins;
    var lines = String(text).split("\n");
    var re = /^\s*(\d+):.*#([0-9A-Fa-f]{6})/;
    for (var i = 0; i < lines.length; i++) {
        var m = re.exec(lines[i]);
        if (!m) continue;
        var count = parseInt(m[1], 10);
        if (!(count > 0)) continue;
        bins.push({ count: count, rgb: hexToRgb("#" + m[2]) });
    }
    return bins;
}

/** Whole-image mean OKLab lightness (includes grey pixels, so it drives tone). */
function _meanLightness(bins, total) {
    if (!(total > 0)) return DEFAULT_SEED.meanL;
    var acc = 0;
    for (var i = 0; i < bins.length; i++)
        acc += bins[i].count * rgbToOklch(bins[i].rgb).l;
    return acc / total;
}

/**
 * Turn histogram text into the seed object consumed by build():
 * `{ hue, chroma, meanL, colorfulness, hue2, chroma2, families:[{h,c}] }`.
 * Achromatic wallpapers yield all-zero chroma (a grey theme).
 */
function seedFromHistogram(text) {
    var bins = parseHistogram(text);
    var total = 0;
    for (var i = 0; i < bins.length; i++) total += bins[i].count;

    var chromaticCount = 0, chromaSum = 0;
    var fams = {};   // family index -> { count, h, c, score }
    for (var j = 0; j < bins.length; j++) {
        var b = bins[j];
        var ok = rgbToOklch(b.rgb);
        if (ok.c < CHROMA_FLOOR || ok.l < L_MIN || ok.l > L_MAX) continue;
        chromaticCount += b.count;
        chromaSum += b.count * ok.c;
        var fi = Math.floor(ok.h / 30) % 12;
        var f = fams[fi] || (fams[fi] = { count: 0, h: 0, c: 0, score: 0, cs: [] });
        f.count += b.count;
        f.h += b.count * ok.h;
        f.c += b.count * ok.c;
        f.score += b.count * ok.c;
        f.cs.push(ok.c);
    }

    var meanL = _meanLightness(bins, total);
    if (total <= 0 || chromaticCount <= 0) {
        return { hue: 0, chroma: 0, meanL: meanL, colorfulness: 0,
                 hue2: -1, chroma2: 0, families: [] };
    }

    // Materialise families with count-weighted (not max/outlier) stats. Chroma
    // also takes the vivid tail (p75 x 0.85) when that beats the mean: an
    // average sits well below the colours the wallpaper actually shows, and a
    // seed built from it mutes every downstream surface.
    var list = [];
    for (var key in fams) {
        var g = fams[key];
        var cs = g.cs.slice().sort(function (a, b) { return a - b; });
        var p75 = cs[Math.min(cs.length - 1, Math.floor(0.75 * cs.length))] || 0;
        list.push({ h: g.h / g.count, c: Math.max(g.c / g.count, p75 * 0.85),
                    score: g.score });
    }
    list.sort(function (a, b) { return b.score - a.score; });

    var best = list[0];
    var maxScore = best.score;
    var primaryH = ((best.h % 360) + 360) % 360;

    // Second chromatic family only when substantial and far enough, as before.
    var hue2 = -1, chroma2 = 0;
    if (list.length > 1 && list[1].score >= 0.35 * maxScore
            && Math.abs(_deltaHue(primaryH, list[1].h)) >= 40) {
        hue2 = ((list[1].h % 360) + 360) % 360;
        chroma2 = list[1].c;
    }

    // Colorfulness: how much of the image is colour, how vivid, how varied.
    var coverage = chromaticCount / total;
    var intensity = clamp((chromaSum / chromaticCount) / INTENSITY_REF, 0, 1);
    var families = 0;
    for (var q = 0; q < list.length; q++)
        if (list[q].score >= FAMILY_SCORE_TAIL * maxScore) families++;
    var variety = clamp((families - 1) / 3, 0, 1);
    var colorfulness = clamp(0.50 * coverage + 0.35 * intensity + 0.15 * variety, 0, 1);

    // ANSI families, already OKLCH {h, c}, de-duplicated by hue.
    var ansiFams = [];
    for (var r = 0; r < list.length; r++) {
        if (list[r].c <= 0.012) continue;
        var dup = false;
        for (var s = 0; s < ansiFams.length; s++)
            if (Math.abs(_deltaHue(ansiFams[s].h, list[r].h)) < ANSI_DEDUP) { dup = true; break; }
        if (!dup)
            ansiFams.push({ h: ((list[r].h % 360) + 360) % 360, c: list[r].c });
    }

    return { hue: primaryH, chroma: best.c, meanL: meanL, colorfulness: colorfulness,
             hue2: hue2, chroma2: chroma2, families: ansiFams };
}

// --- ladder (OKLCH lightness), calibrated to the pre-OKLCH look ---------
var L_DEEP = 0.158, L_WELL = 0.198, L_BG = 0.209, L_SURFACE = 0.245,
    L_RAISED = 0.286, L_HAIR = 0.321, L_BORDER = 0.402;
var L_OUTLINE = 0.380;         // island capsule outline: lighter than `top`
var L_TEXT = 0.923, L_MUTED = 0.784, L_FAINT = 0.496;
var L_ACCENT = 0.730, L_ERROR = 0.760;
var H_ERROR = 29;              // warm red
var ACCENT_SPLIT = 22;         // secondary/tertiary hue offset (deg)
var ANSI_L = 0.560;            // base lightness of the ANSI chromatic slots
var ANSI_STEP = 0.110;         // lightness step when slots share a hue
var ANSI_LIFT = 0.140;         // bright-variant lightness lift
var ANSI_DEDUP = 22;           // min hue gap (deg) between ANSI families

function _num(x, d) { return (typeof x === "number" && !isNaN(x)) ? x : d; }

function _deltaHue(a, b) {
    return (((b - a + 180) % 360) + 360) % 360 - 180;
}

function build(seed) {
    seed = seed || DEFAULT_SEED;
    var hueDeg = _num(seed.hue, DEFAULT_SEED.hue);
    var seedChroma = _num(seed.chroma, DEFAULT_SEED.chroma);
    var meanL = clamp(_num(seed.meanL, DEFAULT_SEED.meanL), 0, 1);
    var colorfulness = clamp(_num(seed.colorfulness, 0), 0, 1);

    // Seed hue and chroma are already OKLCH (from seedFromHistogram), so no
    // reconstruction at a synthetic lightness is needed. Achromatic
    // wallpapers (chroma ~ 0) stay fully grey.
    var H = ((hueDeg % 360) + 360) % 360;
    var seedC = seedChroma <= 0.02 ? 0 : seedChroma;

    var lift = 0.08 * Math.min(meanL, 0.6);
    var textC = clamp(seedC * 0.16, 0, 0.027);

    // Chroma policy. `k` is adaptive restraint: the more colourful the
    // wallpaper, the calmer the accents, so a busy image never produces a loud
    // theme. Achromatic wallpapers (seedC 0) stay fully grey. The floors keep a
    // faint tint visible on muted wallpapers but are bounded by the seed's own
    // chroma, so an accent can never be more saturated than the image it came
    // from.
    var chromatic = seedC > 0;
    var k = 1 - 0.18 * colorfulness;
    var accentC = chromatic ? clamp(seedC * 0.95 * k, Math.min(0.095, seedC), 0.16) : 0;

    // One chroma knob for every background tier, capsule included. Still one
    // hue family, but visibly tinted — a flat near-grey reads as washed out.
    // Only lightness separates a canvas from a panel, so large app windows
    // aren't a coloured slab and a sidebar never reads more vibrant than the
    // editor beside it. No absolute floor: pure seedC scaling is what keeps the
    // theme honest, and a wallpaper that wants a dull surface gets one.
    var surfaceC = chromatic ? clamp(seedC * 0.42, 0, 0.056) : 0;

    // Chroma ramps up the surface ladder rather than staying flat: a lighter
    // step sits further from neutral in OKLCH, so holding one chroma across
    // deep→border makes the raised end read muddy next to the deep end.
    function s(L, m) { return oklch(L + lift, surfaceC * (m || 1), H); }

    var t = {};
    t.deep    = s(L_DEEP, 0.75);   // also the terminal's ANSI black
    t.well    = s(L_WELL, 0.88);
    t.bg      = s(L_BG, 1.00);
    t.surface = s(L_SURFACE, 1.02);
    t.raised  = s(L_RAISED, 1.08);
    t.hair    = s(L_HAIR, 1.14);
    t.border  = oklch(L_BORDER + lift, surfaceC * 1.28, H);

    // shell capsule gradient (top lighter -> bottom darker). Shares the surface
    // chroma, so the bar sits in the same colour family as the panels it holds
    // instead of shouting over them. The island outline is the same hue, just
    // lighter than the gradient's top.
    t.top    = oklch(L_RAISED + lift, surfaceC, H);
    t.bottom = oklch(L_SURFACE + lift, surfaceC, H);
    t.outline = oklch(L_OUTLINE + lift, surfaceC, H);

    t.text  = oklch(L_TEXT, textC, H);
    t.muted = oklch(L_MUTED, textC, H);
    t.faint = oklch(L_FAINT, textC, H);

    t.primary = oklch(L_ACCENT, accentC, H);

    // The accent's own gradient pair: same hue and chroma as `primary`, stepped
    // in lightness, so a filled control can carry the capsule's top-lit bevel
    // without inventing a second hue.
    t.accentTop    = oklch(L_ACCENT + 0.075, accentC, H);
    t.accentBottom = oklch(L_ACCENT - 0.075, accentC, H);

    // secondary/tertiary: if the wallpaper has a real second hue use it, with
    // tertiary an analogous step on the far side — a chord anchored on the
    // image's own hues. Otherwise fall back to synthetic ±ACCENT_SPLIT siblings.
    var h2 = _num(seed.hue2, -1), c2 = _num(seed.chroma2, 0);
    if (h2 >= 0 && c2 > 0.02) {
        var H2 = ((h2 % 360) + 360) % 360;
        var side = _deltaHue(H, H2) >= 0 ? -1 : 1;
        t.secondary = oklch(L_ACCENT, accentC * 0.62, H2);
        t.tertiary  = oklch(L_ACCENT + 0.01, accentC * 0.62, H + side * ACCENT_SPLIT);
    } else {
        t.secondary = oklch(L_ACCENT, accentC * 0.62, H + ACCENT_SPLIT);
        t.tertiary  = oklch(L_ACCENT + 0.01, accentC * 0.62, H - ACCENT_SPLIT);
    }
    // error is semantic: keep a little chroma even on a grey wallpaper.
    t.error = oklch(L_ERROR, clamp(Math.max(accentC * 1.05, 0.085), 0, 0.150), H_ERROR);

    // ink: text over an accent, dark enough for every accent.
    t.ink = oklch(0.240, clamp(accentC * 0.4, 0, 0.05), H);
    var accents = [t.primary, t.secondary, t.tertiary, t.error,
                   t.accentTop, t.accentBottom];
    for (var a = 0; a < accents.length; a++)
        t.ink = ensureContrast(t.ink, accents[a], 4.5);

    // copy: legible on both the panel and the window background.
    t.text = ensureContrast(t.text, t.surface, 7.0);
    t.muted = ensureContrast(t.muted, t.surface, 4.5);
    t.faint = ensureContrast(t.faint, t.surface, 3.0);
    t.text = ensureContrast(t.text, t.bg, 7.0);
    t.muted = ensureContrast(t.muted, t.bg, 4.5);
    t.faint = ensureContrast(t.faint, t.bg, 3.0);

    // ANSI: built only from hues the wallpaper actually contains. The seed
    // reports the prominent chromatic families (already OKLCH); the six
    // chromatic slots are drawn from those families and separated by lightness
    // tiers, so a monochrome wallpaper yields a tonal ramp of its own hue rather
    // than invented greens/purples. Canonical slots are filled in hue order, so
    // the warmest family lands on red and the coolest on blue. Achromatic
    // wallpapers keep the canonical spread at a low chroma.
    var aSat = clamp(accentC * 1.10 * k, Math.min(0.05, seedC), 0.12);

    var fams = [];
    if (chromatic) {
        // seed.families arrives already hue-de-duplicated by seedFromHistogram(),
        // so this only copies it (never push into the seed's own array).
        fams = (seed.families || []).slice();
        if (fams.length === 0) {
            fams.push({ h: H, c: seedC });
            if (h2 >= 0 && c2 > 0.02 && Math.abs(_deltaHue(H, h2)) >= ANSI_DEDUP)
                fams.push({ h: ((h2 % 360) + 360) % 360, c: c2 });
        }
        // A colourful wallpaper gets fewer ANSI families: a busy image should
        // not also produce a rainbow terminal.
        var maxFam = colorfulness > 0.55 ? 3 : (colorfulness > 0.30 ? 4 : 6);
        if (fams.length > maxFam) fams = fams.slice(0, maxFam);
    }

    // Neutral slots: 0 black = deepest surface, 8 bright-black = raised,
    // 7 white = light-grey muted, 15 bright-white = text.
    var n = 0.68, b = 0.82;
    t.ansi = [t.deep, null, null, null, null, null, null, t.muted, t.raised,
              null, null, null, null, null, null, t.text];

    if (!chromatic) {
        var ansiH = [29, 96, 145, 195, 264, 328];   // canonical, ascending hue
        var ansiIdx = [1, 3, 2, 6, 4, 5];           // red yellow green cyan blue magenta
        for (var g = 0; g < 6; g++) {
            t.ansi[ansiIdx[g]] = oklch(n, aSat, ansiH[g]);
            t.ansi[ansiIdx[g] + 8] = oklch(b, aSat, ansiH[g]);
        }
    } else {
        // One colour per family per lightness tier; a single-family wallpaper
        // gets a wider ramp so all six slots stay distinct.
        var solo = fams.length === 1;
        var slots = [];
        for (var si = 0; si < 6; si++) {
            var fm = solo ? fams[0] : fams[si % fams.length];
            var L = solo ? (0.46 + si * 0.083) : (ANSI_L + Math.floor(si / fams.length) * ANSI_STEP);
            slots.push({ h: fm.h, c: clamp(fm.c * 0.95, 0.03, aSat), L: L });
        }
        slots.sort(function (x, y) { return x.h - y.h; });
        var slotIdx = [1, 3, 2, 6, 4, 5];
        for (var ci = 0; ci < 6; ci++) {
            t.ansi[slotIdx[ci]] = oklch(slots[ci].L, slots[ci].c, slots[ci].h);
            t.ansi[slotIdx[ci] + 8] = oklch(clamp(slots[ci].L + ANSI_LIFT, 0, 0.95), slots[ci].c, slots[ci].h);
        }
    }

    for (var i = 1; i <= 6; i++) {
        t.ansi[i] = ensureContrast(t.ansi[i], t.bg, 4.5);
        t.ansi[i + 8] = ensureContrast(t.ansi[i + 8], t.bg, 4.5);
    }

    return t;
}
