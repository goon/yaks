.pragma library

.import "color.js" as Color

function generate(tokens, ctx) {
    var c = tokens || {};

    var content = `.theme-dark, .theme-light {

    --mat-bg-rgb:             ${Color.rgbString(c.bg)};
    --mat-surface-rgb:        ${Color.rgbString(c.surface)};
    --mat-on-surface-rgb:     ${Color.rgbString(c.text)};
    --mat-primary-rgb:        ${Color.rgbString(c.primary)};
    --mat-on-primary-rgb:     ${Color.rgbString(c.ink)};

    --background-primary:           ${c.bg};
    --background-primary-alt:       ${c.well};
    --background-secondary:         ${c.surface};
    --background-secondary-alt:     ${c.surface};

    --titlebar-background:          ${c.bg};
    --titlebar-background-focused:  ${c.surface};
    --titlebar-text-color:          ${c.text};

    --background-modifier-border:         ${c.border};
    --background-modifier-border-focus:   ${c.primary};
    --background-modifier-border-hover:   ${c.primary};

    --text-normal:      ${c.text};
    --text-muted:       ${c.muted};
    --text-faint:       ${c.faint};
    --text-on-accent:   ${c.ink};
    --text-selection:   rgba(${Color.rgbString(c.primary)}, 0.25);

    --interactive-accent:           ${c.primary};
    --interactive-accent-hover:     ${c.secondary};
    --interactive-accent-rgb:       ${Color.rgbString(c.primary)};
    --text-accent:                  ${c.primary};
    --text-accent-hover:            ${c.secondary};

    --color-accent:     ${c.primary};
    --color-accent-1:   ${c.accentTop};
    --color-accent-2:   ${c.accentBottom};

    --background-modifier-hover:          rgba(var(--mat-on-surface-rgb), 0.06);
    --background-modifier-active-hover:   rgba(var(--mat-primary-rgb), 0.15);
    --background-modifier-success:        ${c.tertiary};
    --background-modifier-error:          ${c.error};
    --background-modifier-error-hover:    ${c.error};

    --color-base-00:    ${c.bg};
    --color-base-05:    ${c.well};
    --color-base-10:    ${c.bg};
    --color-base-20:    ${c.surface};
    --color-base-25:    ${c.surface};
    --color-base-30:    ${c.raised};
    --color-base-35:    ${c.raised};
    --color-base-40:    ${c.border};
    --color-base-50:    ${c.border};
    --color-base-60:    ${c.muted};
    --color-base-70:    ${c.text};
    --color-base-100:   ${c.text};

    --color-red:        ${c.error};
    --color-orange:     ${c.tertiary};
    --color-yellow:     ${c.secondary};
    --color-green:      ${c.tertiary};
    --color-cyan:       ${c.secondary};
    --color-blue:       ${c.primary};
    --color-purple:     ${c.secondary};
    --color-pink:       ${c.tertiary};

    --h1-color:     ${c.primary};
    --h2-color:     ${c.primary};
    --h3-color:     ${c.secondary};
    --h4-color:     ${c.tertiary};
    --h5-color:     ${c.muted};
    --h6-color:     ${c.faint};

    --link-color:           ${c.primary};
    --link-color-hover:     ${c.primary};
    --link-external-color:  ${c.tertiary};
    --link-unresolved-color: ${c.faint};

    --tag-color:            ${c.ink};
    --tag-background:       ${c.primary};
    --tag-border-color:     ${c.primary};
    --tag-color-hover:      ${c.ink};
    --tag-background-hover: ${c.secondary};

    --checkbox-color:           ${c.primary};
    --checkbox-color-hover:     ${c.secondary};
    --checkbox-border-color:    ${c.border};
    --checkbox-marker-color:    ${c.ink};

    --code-background:  ${c.surface};
    --code-normal:      ${c.text};
    --code-comment:     ${c.faint};
    --code-function:    ${c.primary};
    --code-important:   ${c.error};
    --code-keyword:     ${c.secondary};
    --code-operator:    ${c.tertiary};
    --code-property:    ${c.muted};
    --code-punctuation: ${c.border};
    --code-string:      ${c.tertiary};
    --code-tag:         ${c.error};
    --code-value:       ${c.secondary};

    --scrollbar-thumb-bg:           rgba(var(--mat-on-surface-rgb), 0.12);
    --scrollbar-active-thumb-bg:    rgba(var(--mat-on-surface-rgb), 0.25);
    --scrollbar-bg:                 transparent;

    --input-shadow: none;
    --input-shadow-hover: 0 0 0 2px ${c.border};

    --graph-node:           ${c.primary};
    --graph-node-unresolved: ${c.faint};
    --graph-node-focused:   ${c.ink};
    --graph-node-tag:       ${c.secondary};
    --graph-node-attachment: ${c.tertiary};
    --graph-line:           ${c.border};
    --graph-background:     ${c.bg};

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
