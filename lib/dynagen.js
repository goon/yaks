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

// Shared palette builder helper
function _meta(name, h, s, l) {
    return {
        name: name,
        primaryIdx: "base0D",
        secondaryIdx: "base0E"
    };
}

// ── 1. PURE ───────────────────────────────────────────────────────────────────
function generatePure(seedHex, bgL) {
    bgL = bgL || 0.08;
    const hsl = hexToHsl(seedHex);
    const h = hsl.h;
    const bgS = Math.min(hsl.s, 0.06);
    const textS = Math.min(hsl.s, 0.10);
    return {
        name: "Dynamic (Pure)",
        base00: hslToHex(h, bgS, bgL),
        base01: hslToHex(h, bgS, bgL + 0.03),
        base02: hslToHex(h, bgS, bgL + 0.07),
        base03: hslToHex(h, bgS, bgL + 0.17),
        base04: hslToHex(h, bgS, bgL + 0.42),
        base05: hslToHex(h, textS, 0.85),
        base06: hslToHex(h, textS, 0.92),
        base07: hslToHex(h, textS, 0.98),
        base08: hslToHex(0.00, hsl.s, hsl.l),
        base09: hslToHex(0.08, hsl.s, hsl.l),
        base0A: hslToHex(0.14, hsl.s, hsl.l),
        base0B: hslToHex(0.33, hsl.s, hsl.l),
        base0C: hslToHex(0.50, hsl.s, hsl.l),
        base0D: seedHex,
        base0E: hslToHex((h + 0.08) % 1.0, hsl.s, hsl.l),
        base0F: hslToHex(0.05, hsl.s, hsl.l),
        primaryIdx: "base0D",
        secondaryIdx: "base0E"
    };
}

// ── 2. TINTED ─────────────────────────────────────────────────────────────────
// Catppuccin Mocha base — seed only drives the primary accent.
// bgL offsets the Mocha background lightness levels from their default (~0.147).
function generateTinted(seedHex, bgL) {
    bgL = bgL || 0.08;
    // Mocha default base00 lightness is ~0.147; shift all levels by delta
    const delta = bgL - 0.08;
    const hsl = hexToHsl(seedHex);
    const h = hsl.h;
    const mH = 0.667; const mS = 0.19; // Mocha hue/sat
    return {
        name: "Dynamic (Tinted)",
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
        base0D: seedHex,
        base0E: hslToHex((h + 0.08) % 1.0, hsl.s, hsl.l),
        base0F: "#F2CDCD",
        primaryIdx: "base0D",
        secondaryIdx: "base0E"
    };
}

// ── 3. MONOCHROME ─────────────────────────────────────────────────────────────
function generateMonochrome(seedHex, bgL) {
    bgL = bgL || 0.08;
    const hsl = hexToHsl(seedHex);
    const h = hsl.h;
    const s = 0.08;
    const as = Math.min(hsl.s + 0.10, 0.60);
    return {
        name: "Dynamic (Monochrome)",
        base00: hslToHex(h, s, bgL),
        base01: hslToHex(h, s, bgL + 0.03),
        base02: hslToHex(h, s, bgL + 0.08),
        base03: hslToHex(h, s, bgL + 0.20),
        base04: hslToHex(h, s, bgL + 0.37),
        base05: hslToHex(h, s, 0.82),
        base06: hslToHex(h, s, 0.90),
        base07: hslToHex(h, s, 0.97),
        base08: hslToHex(h, as, 0.55),
        base09: hslToHex(h, as, 0.60),
        base0A: hslToHex(h, as, 0.65),
        base0B: hslToHex(h, as, 0.70),
        base0C: hslToHex(h, as, 0.75),
        base0D: hslToHex(h, as, 0.80),
        base0E: hslToHex(h, as * 0.8, 0.72),
        base0F: hslToHex(h, as, 0.50),
        primaryIdx: "base0D",
        secondaryIdx: "base0E"
    };
}

// ── 4. EARTHEN ────────────────────────────────────────────────────────────────
// Warm amber/brown backgrounds locked at ~30° regardless of seed.
// Seed only shifts warmth temperature and provides the accent color.
function generateEarthen(seedHex) {
    const hsl = hexToHsl(seedHex);
    // Background hue: seed slightly pulls the warm base between 20°-40°
    const bgH = (0.055 + (hsl.h * 0.03)) % 1.0;
    const bgS = 0.12;
    const accent = hsl.h;
    const as = Math.min(hsl.s, 0.55);
    const al = Math.min(hsl.l, 0.70);
    return {
        name: "Dynamic (Earthen)",
        base00: hslToHex(bgH, bgS, 0.08),
        base01: hslToHex(bgH, bgS, 0.12),
        base02: hslToHex(bgH, bgS, 0.17),
        base03: hslToHex(bgH, bgS, 0.28),
        base04: hslToHex(bgH, bgS * 0.8, 0.48),
        base05: hslToHex(bgH, 0.18, 0.80),
        base06: hslToHex(bgH, 0.14, 0.88),
        base07: hslToHex(bgH, 0.10, 0.95),
        base08: hslToHex(0.02, 0.55, 0.60), // warm red
        base09: hslToHex(0.07, 0.55, 0.62), // amber
        base0A: hslToHex(0.12, 0.50, 0.65), // gold
        base0B: hslToHex(0.28, 0.40, 0.58), // sage green
        base0C: hslToHex(0.47, 0.35, 0.58), // muted teal
        base0D: hslToHex(accent, as, al),    // primary: seed color
        base0E: hslToHex((accent + 0.08) % 1.0, as * 0.85, al * 0.92), // secondary
        base0F: hslToHex(0.05, 0.40, 0.55),
        primaryIdx: "base0D",
        secondaryIdx: "base0E"
    };
}

// ── 5. COMPLEMENTARY ─────────────────────────────────────────────────────────
// Seed drives primary; exact opposite hue (+180°) drives secondary.
// Backgrounds are neutral dark. Creates maximum visual tension between P/S.
function generateComplementary(seedHex) {
    const hsl = hexToHsl(seedHex);
    const h = hsl.h;
    const compH = (h + 0.50) % 1.0;
    const bgS = Math.min(hsl.s, 0.06);
    const textS = Math.min(hsl.s, 0.08);
    return {
        name: "Dynamic (Complementary)",
        base00: hslToHex(h, bgS, 0.08),
        base01: hslToHex(h, bgS, 0.11),
        base02: hslToHex(h, bgS, 0.16),
        base03: hslToHex(h, bgS, 0.26),
        base04: hslToHex(h, bgS, 0.48),
        base05: hslToHex(h, textS, 0.84),
        base06: hslToHex(h, textS, 0.91),
        base07: hslToHex(h, textS, 0.97),
        base08: hslToHex(0.00, hsl.s, hsl.l),
        base09: hslToHex(0.08, hsl.s, hsl.l),
        base0A: hslToHex(0.14, hsl.s, hsl.l),
        base0B: hslToHex(0.33, hsl.s, hsl.l),
        base0C: hslToHex(0.50, hsl.s, hsl.l),
        base0D: seedHex,
        base0E: hslToHex(compH, hsl.s, hsl.l), // opposite hue — maximum contrast
        base0F: hslToHex(0.05, hsl.s, hsl.l),
        primaryIdx: "base0D",
        secondaryIdx: "base0E"
    };
}

// ── 6. PASTEL ─────────────────────────────────────────────────────────────────
// Dark backgrounds + all accent colors forced to high lightness, soft saturation.
// Think Rosé Pine or cotton-candy Catppuccin — delicate and airy.
function generatePastel(seedHex, bgL) {
    bgL = bgL || 0.09;
    const hsl = hexToHsl(seedHex);
    const h = hsl.h;
    const bgS = Math.min(hsl.s, 0.10);
    // Force all accents to soft pastels: moderate sat, high lightness
    const aS = 0.40;
    const aL = 0.82;
    return {
        name: "Dynamic (Pastel)",
        base00: hslToHex(h, bgS, bgL),
        base01: hslToHex(h, bgS, bgL + 0.04),
        base02: hslToHex(h, bgS, bgL + 0.09),
        base03: hslToHex(h, bgS, bgL + 0.21),
        base04: hslToHex(h, bgS, bgL + 0.43),
        base05: hslToHex(h, 0.22, 0.87),
        base06: hslToHex(h, 0.16, 0.92),
        base07: hslToHex(h, 0.10, 0.97),
        base08: hslToHex(0.00, aS, aL),   // soft pink/red
        base09: hslToHex(0.08, aS, aL),   // soft peach
        base0A: hslToHex(0.14, aS, aL),   // soft yellow
        base0B: hslToHex(0.38, aS - 0.05, aL - 0.02), // soft green
        base0C: hslToHex(0.52, aS - 0.05, aL - 0.02), // soft cyan
        base0D: hslToHex(h, aS, aL),      // primary: seed pastel
        base0E: hslToHex((h + 0.08) % 1.0, aS, aL - 0.04), // secondary: gentle shift
        base0F: hslToHex(0.92, aS, aL),   // soft rose
        primaryIdx: "base0D",
        secondaryIdx: "base0E"
    };
}

// ── 7. NOCTILUCENT ────────────────────────────────────────────────────────────
// Near-black, near-zero saturation void + ONE vivid glowing accent.
// Think Tokyo Night or deep space: darkness and a single bright focal point.
function generateNoctilucent(seedHex) {
    const hsl = hexToHsl(seedHex);
    const h = hsl.h;
    const accentS = Math.max(hsl.s, 0.70); // ensure accent is vivid
    const accentL = Math.min(Math.max(hsl.l, 0.55), 0.72);
    return {
        name: "Dynamic (Noctilucent)",
        base00: hslToHex(h, 0.02, 0.05),
        base01: hslToHex(h, 0.02, 0.08),
        base02: hslToHex(h, 0.03, 0.12),
        base03: hslToHex(h, 0.03, 0.22),
        base04: hslToHex(h, 0.04, 0.40),
        base05: hslToHex(h, 0.05, 0.78),
        base06: hslToHex(h, 0.04, 0.88),
        base07: hslToHex(h, 0.02, 0.96),
        base08: hslToHex(0.00, 0.75, 0.62), // vivid red
        base09: hslToHex(0.07, 0.75, 0.64), // vivid orange
        base0A: hslToHex(0.14, 0.72, 0.66), // vivid yellow
        base0B: hslToHex(0.36, 0.68, 0.58), // vivid green
        base0C: hslToHex(0.52, 0.68, 0.60), // vivid cyan
        base0D: hslToHex(h, accentS, accentL), // THE glow — your seed, vivid
        base0E: hslToHex((h + 0.07) % 1.0, accentS * 0.85, accentL * 0.90),
        base0F: hslToHex(0.92, 0.70, 0.62),
        primaryIdx: "base0D",
        secondaryIdx: "base0E"
    };
}

// ── 8. ANALOGOUS ─────────────────────────────────────────────────────────────
// Three adjacent hues (30° apart) drive primary, secondary, accent.
// Feels the most "hand-designed" — rich, flowing, harmonious.
function generateAnalogous(seedHex) {
    const hsl = hexToHsl(seedHex);
    const h = hsl.h;
    const hPrev = (h - 0.083 + 1) % 1.0; // -30°
    const hNext = (h + 0.083) % 1.0;      // +30°
    const bgS = Math.min(hsl.s, 0.06);
    const textS = Math.min(hsl.s, 0.09);
    return {
        name: "Dynamic (Analogous)",
        base00: hslToHex(h, bgS, 0.08),
        base01: hslToHex(h, bgS, 0.11),
        base02: hslToHex(h, bgS, 0.16),
        base03: hslToHex(h, bgS, 0.26),
        base04: hslToHex(h, bgS, 0.48),
        base05: hslToHex(h, textS, 0.84),
        base06: hslToHex(h, textS, 0.91),
        base07: hslToHex(h, textS, 0.97),
        base08: hslToHex(0.00, hsl.s, hsl.l),
        base09: hslToHex(0.08, hsl.s, hsl.l),
        base0A: hslToHex(hPrev, hsl.s, hsl.l), // -30° accent (yellow/gold side)
        base0B: hslToHex(0.33, hsl.s, hsl.l),
        base0C: hslToHex(hNext, hsl.s * 0.9, hsl.l), // +30° cyan/info
        base0D: seedHex,                              // primary: seed
        base0E: hslToHex(hNext, hsl.s, hsl.l),       // secondary: +30° — close but different
        base0F: hslToHex(hPrev, hsl.s * 0.8, hsl.l * 0.85),
        primaryIdx: "base0D",
        secondaryIdx: "base0E"
    };
}

// ── 9. VINTAGE ────────────────────────────────────────────────────────────────
// Warm amber/sepia backgrounds, all accents intentionally desaturated.
// Seed shifts warmth temperature (cool → dark slate, warm → rich mahogany).
function generateVintage(seedHex) {
    const hsl = hexToHsl(seedHex);
    // Blend seed hue toward warm amber (0.083 = 30°)
    const warmness = Math.sin(hsl.h * Math.PI); // peaks at hue 0.5 (cyan)
    const bgH = 0.055 + (hsl.h - 0.055) * 0.12; // heavily biased to ~20-25°
    const bgS = 0.10 + warmness * 0.04;
    // All accents desaturated to feel aged and organic
    const aS = Math.min(hsl.s * 0.45, 0.35);
    const aL = hsl.l * 0.90;
    return {
        name: "Dynamic (Vintage)",
        base00: hslToHex(bgH, bgS, 0.08),
        base01: hslToHex(bgH, bgS, 0.12),
        base02: hslToHex(bgH, bgS, 0.17),
        base03: hslToHex(bgH, bgS * 0.8, 0.28),
        base04: hslToHex(bgH, bgS * 0.7, 0.46),
        base05: hslToHex(bgH, 0.15, 0.78),
        base06: hslToHex(bgH, 0.10, 0.86),
        base07: hslToHex(bgH, 0.06, 0.94),
        base08: hslToHex(0.02, 0.42, 0.55), // faded red
        base09: hslToHex(0.07, 0.42, 0.57), // faded amber
        base0A: hslToHex(0.12, 0.38, 0.58), // faded gold
        base0B: hslToHex(0.27, 0.32, 0.52), // faded sage
        base0C: hslToHex(0.46, 0.30, 0.52), // faded teal
        base0D: hslToHex(hsl.h, aS, aL),    // primary: muted seed
        base0E: hslToHex((hsl.h + 0.08) % 1.0, aS * 0.85, aL * 0.92),
        base0F: hslToHex(0.05, 0.35, 0.48),
        primaryIdx: "base0D",
        secondaryIdx: "base0E"
    };
}
