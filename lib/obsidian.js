.pragma library

function _rgb(hex) {
    if (!hex || hex.charAt(0) !== "#") return "0, 0, 0";
    var h = hex.substring(1);
    if (h.length === 8) h = h.substring(0, 6);
    return parseInt(h.substring(0, 2), 16) + ", " + parseInt(h.substring(2, 4), 16) + ", " + parseInt(h.substring(4, 6), 16);
}

function generate(tokens, ctx) {
    var c = tokens || {};

    var content = `.theme-dark, .theme-light {

    --mat-bg-rgb:             ${_rgb(c.background)};
    --mat-surface-rgb:        ${_rgb(c.surface)};
    --mat-on-surface-rgb:     ${_rgb(c.on_surface)};
    --mat-primary-rgb:        ${_rgb(c.primary)};
    --mat-on-primary-rgb:     ${_rgb(c.on_primary)};

    --background-primary:           ${c.background};
    --background-primary-alt:       ${c.surface_dim};
    --background-secondary:         ${c.surface_container_low};
    --background-secondary-alt:     ${c.surface_container};

    --titlebar-background:          ${c.surface_dim};
    --titlebar-background-focused:  ${c.surface_container_low};
    --titlebar-text-color:          ${c.on_surface};

    --background-modifier-border:         ${c.outline_variant};
    --background-modifier-border-focus:   ${c.outline};
    --background-modifier-border-hover:   ${c.outline};

    --text-normal:      ${c.on_surface};
    --text-muted:       ${c.on_surface_variant};
    --text-faint:       ${c.outline};
    --text-on-accent:   ${c.on_primary};
    --text-selection:   rgba(${_rgb(c.primary)}, 0.25);

    --interactive-accent:           ${c.primary};
    --interactive-accent-hover:     ${c.primary_container};
    --interactive-accent-rgb:       ${_rgb(c.primary)};
    --text-accent:                  ${c.primary};
    --text-accent-hover:            ${c.primary_container};

    --background-modifier-hover:          rgba(var(--mat-on-surface-rgb), 0.06);
    --background-modifier-active-hover:   rgba(var(--mat-primary-rgb), 0.15);
    --background-modifier-success:        ${c.tertiary_container};
    --background-modifier-error:          ${c.error_container};
    --background-modifier-error-hover:    ${c.error};

    --color-base-00:    ${c.background};
    --color-base-05:    ${c.surface_dim};
    --color-base-10:    ${c.surface_container_lowest};
    --color-base-20:    ${c.surface_container_low};
    --color-base-25:    ${c.surface_container};
    --color-base-30:    ${c.surface_container_high};
    --color-base-35:    ${c.surface_container_highest};
    --color-base-40:    ${c.outline_variant};
    --color-base-50:    ${c.outline};
    --color-base-60:    ${c.on_surface_variant};
    --color-base-70:    ${c.on_surface};
    --color-base-100:   ${c.inverse_surface};

    --color-red:        ${c.error};
    --color-orange:     ${c.tertiary};
    --color-yellow:     ${c.secondary};
    --color-green:      ${c.tertiary_container};
    --color-cyan:       ${c.secondary_container};
    --color-blue:       ${c.primary};
    --color-purple:     ${c.secondary};
    --color-pink:       ${c.tertiary};

    --h1-color:     ${c.primary};
    --h2-color:     ${c.primary};
    --h3-color:     ${c.secondary};
    --h4-color:     ${c.tertiary};
    --h5-color:     ${c.on_surface_variant};
    --h6-color:     ${c.outline};

    --link-color:           ${c.primary};
    --link-color-hover:     ${c.on_primary_container};
    --link-external-color:  ${c.tertiary};
    --link-unresolved-color: ${c.outline};

    --tag-color:            ${c.on_primary_container};
    --tag-background:       ${c.primary_container};
    --tag-border-color:     ${c.primary};
    --tag-color-hover:      ${c.on_primary};
    --tag-background-hover: ${c.primary};

    --checkbox-color:           ${c.primary};
    --checkbox-color-hover:     ${c.primary_container};
    --checkbox-border-color:    ${c.outline};
    --checkbox-marker-color:    ${c.on_primary};

    --code-background:  ${c.surface_container_low};
    --code-normal:      ${c.on_surface};
    --code-comment:     ${c.outline};
    --code-function:    ${c.primary};
    --code-important:   ${c.error};
    --code-keyword:     ${c.secondary};
    --code-operator:    ${c.tertiary};
    --code-property:    ${c.on_surface_variant};
    --code-punctuation: ${c.outline_variant};
    --code-string:      ${c.tertiary};
    --code-tag:         ${c.error};
    --code-value:       ${c.secondary};

    --scrollbar-thumb-bg:           rgba(var(--mat-on-surface-rgb), 0.12);
    --scrollbar-active-thumb-bg:    rgba(var(--mat-on-surface-rgb), 0.25);
    --scrollbar-bg:                 transparent;

    --input-shadow: none;
    --input-shadow-hover: 0 0 0 2px ${c.outline};

    --graph-node:           ${c.primary};
    --graph-node-unresolved: ${c.outline};
    --graph-node-focused:   ${c.on_primary_container};
    --graph-node-tag:       ${c.secondary};
    --graph-node-attachment: ${c.tertiary};
    --graph-line:           ${c.outline_variant};
    --graph-background:     ${c.background};

}

.cm-active {
    background-color: rgba(var(--mat-on-surface-rgb), 0.03) !important;
}

.workspace-split.mod-left-split,
.workspace-split.mod-right-split {
    background-color: var(--background-secondary);
    --background-primary: var(--background-secondary);
    --background-primary-alt: var(--background-secondary);
}

.nav-header,
.workspace-leaf-header,
.workspace-tab-header-container,
.workspace-tab-header-inner {
    background-color: transparent !important;
    border: none !important;
    box-shadow: none !important;
}

.nav-header::after,
.workspace-leaf-header::after,
.workspace-tab-header-container::after,
.workspace-tab-header-inner::after {
    display: none !important;
}

.workspace-leaf-content,
.view-content,
.view-header {
    border: none !important;
    box-shadow: none !important;
}

.workspace-leaf-resize-handle {
    border: none !important;
    background-color: transparent !important;
}

.workspace-tab-header-container::before,
.workspace-tab-header-container::after {
    border-bottom: none !important;
    box-shadow: none !important;
}
`;

    var postHook = `
OBSIDIAN_CONFIG="$HOME/.config/obsidian/obsidian.json"
[ -f "$OBSIDIAN_CONFIG" ] || exit 0
VAULTS=$(jq -r '.vaults[]?.path // empty' "$OBSIDIAN_CONFIG" 2>/dev/null)
for vault in $VAULTS; do
    [ -d "$vault" ] || continue
    SNIPPET_DIR="$vault/.obsidian/snippets"
    mkdir -p "$SNIPPET_DIR"
    cp ~/.cache/yaks/themes/obsidian.css "$SNIPPET_DIR/yaks.css"
    APP_JSON="$vault/.obsidian/appearance.json"
    if [ -f "$APP_JSON" ]; then
        jq '.enabledCssSnippets = ((.enabledCssSnippets // []) + ["yaks"] | unique)' "$APP_JSON" > "$APP_JSON.tmp" 2>/dev/null && mv "$APP_JSON.tmp" "$APP_JSON"
    else
        printf '%s' '{"enabledCssSnippets": ["yaks"]}' > "$APP_JSON"
    fi
done
`;

    return {
        files: [
            { path: "~/.cache/yaks/themes/obsidian.css", content: content }
        ],
        postHook: postHook
    };
}
