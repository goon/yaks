.pragma library

/**
 * Shared colour maths for the palette generator and the app hooks.
 *
 * Generation and gamut mapping run in OKLCH (a perceptually uniform space);
 * contrast uses WCAG relative luminance; the hook helpers (`mix`/`alpha`/
 * `rgbString`) operate in sRGB/hex. The generator uses oklch()/ensureContrast()
 * to keep every token perceptually even and legible; the hooks use the helpers
 * so they no longer each carry their own copy of the same conversions.
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

function hslToRgb(h, s, l) {
    h = ((h % 1) + 1) % 1;
    function hue(p, q, t) {
        if (t < 0) t += 1;
        if (t > 1) t -= 1;
        if (t < 1 / 6) return p + (q - p) * 6 * t;
        if (t < 1 / 2) return q;
        if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
        return p;
    }
    if (s === 0) return { r: l, g: l, b: l };
    var q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    var p = 2 * l - q;
    return { r: hue(p, q, h + 1 / 3), g: hue(p, q, h), b: hue(p, q, h - 1 / 3) };
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

// ── Hooks' helpers ────────────────────────────────────────────────────

function mix(a, b, t) {
    var ca = hexToRgb(a), cb = hexToRgb(b);
    return rgbToHex({
        r: ca.r + (cb.r - ca.r) * t,
        g: ca.g + (cb.g - ca.g) * t,
        b: ca.b + (cb.b - ca.b) * t
    });
}

function alpha(hex, a) {
    var v = Math.round(clamp(a, 0, 1) * 255).toString(16);
    return rgbToHex(hexToRgb(hex)) + (v.length < 2 ? "0" + v : v);
}

/** "#rrggbb" -> "r, g, b" (for CSS rgba()). */
function rgbString(hex) {
    var c = hexToRgb(hex);
    return Math.round(c.r * 255) + ", " + Math.round(c.g * 255) + ", " + Math.round(c.b * 255);
}
