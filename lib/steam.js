.pragma library

function generate(colors, opacity, mode, context) {
    const surface = colors.base01 || colors.base00 || "#000000";
    const surfaceAlt = colors.base02 || surface;
    const muted = colors.base04 || "#6a6a7a";
    const primary = colors[colors.primaryIdx] || colors.base0D;
    const secondary = colors[colors.secondaryIdx] || colors.base0E;
    const accent = colors.base0A || primary;
    const success = colors.base0B || "#00ff00";

    const content = `/*
 * Quickshell Steam Tokens Template
 * Designed for use with Millenium (https://millenium.sh/)
 */

:root {
    /* NEVKO-UI Specific Variables */
    --custom-accent: ${primary} !important;
    --green-color: ${success} !important;
    --idle-status: ${secondary} !important;
    --ingame-status: ${success} !important;
    --ingameidle-status: ${success} !important;
    --main-background: ${surface} !important;
    --offline-status: ${muted} !important;
    --online-status: ${primary} !important;
    --purple-color: ${accent} !important;
    
    /* Fallback/Additional Tweaks for UI blending */
    --SystemAccent: ${primary} !important;
    --SystemAccentLight: ${primary} !important;
    --SystemAccentDark: ${secondary} !important;
    --Focus-Color: ${primary} !important;
    --Hover-Color: ${surfaceAlt} !important;
    
    /* Typical Steam variable fallbacks just in case */
    --ClientBG: ${surface} !important;
}

/* Force body background to match in case NEVKO misses edge cases */
html, body {
    background-color: var(--main-background) !important;
}
`;

    const customCommand = `
QUICK_CSS_PATH="$HOME/.config/millennium/quick.css"
if [ -d "$(dirname "$QUICK_CSS_PATH")" ]; then
    printf '%s' "$1" > "$QUICK_CSS_PATH"
fi
`;

    return {
        customCommand: customCommand,
        content: content
    };
}
