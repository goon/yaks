.pragma library

// ── HELPERS ──────────────────────────────────────────────────────────────────

function hslToHex(h, s, l) {
    h = ((h % 1) + 1) % 1; // wrap hue
    s = Math.max(0, Math.min(1, s));
    l = Math.max(0, Math.min(1, l));
    let r, g, b;
    if (s === 0) {
        r = g = b = l;
    } else {
        const hue2rgb = function(p, q, t) {
            if (t < 0) t += 1;
            if (t > 1) t -= 1;
            if (t < 1/6) return p + (q - p) * 6 * t;
            if (t < 1/2) return q;
            if (t < 2/3) return p + (q - p) * (2/3 - t) * 6;
            return p;
        };
        const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
        const p = 2 * l - q;
        r = hue2rgb(p, q, h + 1/3);
        g = hue2rgb(p, q, h);
        b = hue2rgb(p, q, h - 1/3);
    }
    const toHex = x => {
        const hex = Math.round(x * 255).toString(16);
        return hex.length === 1 ? '0' + hex : hex;
    };
    return `#${toHex(r)}${toHex(g)}${toHex(b)}`;
}

function hexToHsl(hex) {
    let result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    if (!result) return { h: 0, s: 0, l: 0 };
    let r = parseInt(result[1], 16) / 255;
    let g = parseInt(result[2], 16) / 255;
    let b = parseInt(result[3], 16) / 255;
    let max = Math.max(r, g, b), min = Math.min(r, g, b);
    let h, s, l = (max + min) / 2;
    if (max === min) {
        h = s = 0;
    } else {
        let d = max - min;
        s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
        switch (max) {
            case r: h = (g - b) / d + (g < b ? 6 : 0); break;
            case g: h = (b - r) / d + 2; break;
            case b: h = (r - g) / d + 4; break;
        }
        h /= 6;
    }
    return { h, s, l };
}

function shiftHue(h, offset) {
    return (((h + offset) % 1.0) + 1.0) % 1.0;
}

function avoidCollision(targetHue, seedHue) {
    let diff = Math.abs(targetHue - seedHue);
    diff = Math.min(diff, 1.0 - diff);
    return diff < 0.06 ? shiftHue(targetHue, 0.08) : targetHue;
}

function buildPalette(name, primaryHex, secondaryHex, bases) {
    bases.name = name;
    bases.base0D = primaryHex;
    bases.base0E = secondaryHex;
    bases.primaryIdx = "base0D";
    bases.secondaryIdx = "base0E";
    return bases;
}

// ── 1. PURE ───────────────────────────────────────────────────────────────────
function generatePure(seedHex, hsl, bgL) {
    bgL = bgL || 0.08;
    const h = hsl.h;
    const bgS = Math.min(hsl.s, 0.06);
    const textS = Math.min(hsl.s, 0.10);
    const secondaryHex = hslToHex(shiftHue(h, 0.08), hsl.s, hsl.l);
    
    // Ensure accents are bright/saturated enough to read against dark backgrounds
    const safeL = Math.max(hsl.l, 0.65);
    const safeS = Math.max(hsl.s, 0.40);
    const avoid = (target) => avoidCollision(target, h);
    
    return buildPalette("Dynamic (Pure)", seedHex, secondaryHex, {
        base00: hslToHex(h, bgS, bgL),
        base01: hslToHex(h, bgS, bgL + 0.04),
        base02: hslToHex(h, bgS, bgL + 0.09),
        base03: hslToHex(h, bgS, bgL + 0.15),
        base04: hslToHex(h, bgS, bgL + 0.22),
        base05: hslToHex(h, textS, 0.85),
        base06: hslToHex(h, textS, 0.92),
        base07: hslToHex(h, textS, 0.98),
        base08: hslToHex(avoid(0.00), safeS, safeL),
        base09: hslToHex(avoid(0.08), safeS, safeL),
        base0A: hslToHex(avoid(0.14), safeS, safeL),
        base0B: hslToHex(avoid(0.33), safeS, safeL),
        base0C: hslToHex(avoid(0.50), safeS, safeL),
        base0F: hslToHex(avoid(0.05), safeS, safeL)
    });
}

// ── 2. TINTED ─────────────────────────────────────────────────────────────────
// Catppuccin Mocha base — seed only drives the primary accent.
// bgL offsets the Mocha background lightness levels from their default (~0.147).
function generateTinted(seedHex, hsl, bgL) {
    bgL = bgL || 0.08;
    // Mocha default base00 lightness is ~0.147; shift all levels by delta
    const delta = bgL - 0.08;
    const h = hsl.h;
    const mH = 0.667; const mS = 0.19; // Mocha hue/sat
    const secondaryHex = hslToHex(shiftHue(h, 0.08), hsl.s, hsl.l);

    return buildPalette("Dynamic (Tinted)", seedHex, secondaryHex, {
        base00: hslToHex(mH, mS, Math.max(0.04, 0.147 + delta)),
        base01: hslToHex(mH, mS, Math.max(0.03, 0.118 + delta)),
        base02: hslToHex(mH, mS * 0.9, Math.max(0.05, 0.196 + delta)),
        base03: hslToHex(mH, mS * 0.75, Math.max(0.10, 0.277 + delta)),
        base04: hslToHex(mH, mS * 0.65, Math.max(0.18, 0.353 + delta)),
        base05: "#CDD6F4",
        base06: "#F5E0DC",
        base07: "#B4BEFE",
        base08: "#F38BA8",
        base09: "#FAB387",
        base0A: "#F9E2AF",
        base0B: "#A6E3A1",
        base0C: "#94E2D5",
        base0F: "#F2CDCD"
    });
}

// ── 3. MONOCHROME ─────────────────────────────────────────────────────────────
function generateMonochrome(seedHex, hsl, bgL) {
    bgL = bgL || 0.08;
    const h = hsl.h;
    const s = 0.08;
    const as = Math.min(hsl.s + 0.10, 0.60);
    const secondaryHex = hslToHex(h, as * 0.8, 0.72);

    return buildPalette("Dynamic (Monochrome)", seedHex, secondaryHex, {
        base00: hslToHex(h, s, bgL),
        base01: hslToHex(h, s, bgL + 0.04),
        base02: hslToHex(h, s, bgL + 0.09),
        base03: hslToHex(h, s, bgL + 0.15),
        base04: hslToHex(h, s, bgL + 0.22),
        base05: hslToHex(h, s, 0.82),
        base06: hslToHex(h, s, 0.90),
        base07: hslToHex(h, s, 0.97),
        base08: hslToHex(h, as, 0.55),
        base09: hslToHex(h, as, 0.60),
        base0A: hslToHex(h, as, 0.65),
        base0B: hslToHex(h, as, 0.70),
        base0C: hslToHex(h, as, 0.75),
        base0F: hslToHex(h, as, 0.50)
    });
}


// ── 4. PASTEL ─────────────────────────────────────────────────────────────────
// Dark backgrounds + all accent colors forced to high lightness, soft saturation.
// Think Rosé Pine or cotton-candy Catppuccin — delicate and airy.
function generatePastel(seedHex, hsl, bgL) {
    bgL = bgL || 0.09;
    const h = hsl.h;
    const bgS = Math.min(hsl.s, 0.10);
    // Force all accents to soft pastels: moderate sat, high lightness
    const aS = 0.40;
    const aL = 0.82;
    const primaryHex = hslToHex(h, aS, aL);
    const secondaryHex = hslToHex(shiftHue(h, 0.08), aS, aL - 0.04);
    const avoid = (target) => avoidCollision(target, h);

    return buildPalette("Dynamic (Pastel)", primaryHex, secondaryHex, {
        base00: hslToHex(h, bgS, bgL),
        base01: hslToHex(h, bgS, bgL + 0.04),
        base02: hslToHex(h, bgS, bgL + 0.09),
        base03: hslToHex(h, bgS, bgL + 0.15),
        base04: hslToHex(h, bgS, bgL + 0.22),
        base05: hslToHex(h, 0.22, 0.87),
        base06: hslToHex(h, 0.16, 0.92),
        base07: hslToHex(h, 0.10, 0.97),
        base08: hslToHex(avoid(0.00), aS, aL),
        base09: hslToHex(avoid(0.08), aS, aL),
        base0A: hslToHex(avoid(0.14), aS, aL),
        base0B: hslToHex(avoid(0.38), aS - 0.05, aL - 0.02),
        base0C: hslToHex(avoid(0.52), aS - 0.05, aL - 0.02),
        base0F: hslToHex(avoid(0.92), aS, aL)
    });
}

