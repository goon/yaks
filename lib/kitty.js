.pragma library

function generate(tokens, ctx) {
    var c = tokens || {};

    var content = `# --- Main Colors ---
background            ${c.surface}
foreground            ${c.on_surface}
cursor                ${c.on_surface}
cursor_text_color     ${c.surface}

selection_background  ${c.secondary_container}
selection_foreground  ${c.on_secondary_container}

url_color             ${c.tertiary}

# --- ANSI Colors ---
color0                ${c.surface}
color1                ${c.error}
color2                ${c.tertiary}
color3                ${c.secondary}
color4                ${c.primary}
color5                ${c.tertiary_fixed_dim}
color6                ${c.secondary_fixed_dim}
color7                ${c.on_surface}

color8                ${c.surface_variant}
color9                ${c.error_container}
color10               ${c.tertiary_container}
color11               ${c.secondary_container}
color12               ${c.primary_container}
color13               ${c.on_secondary_fixed_variant}
color14               ${c.on_tertiary_fixed_variant}
color15               ${c.on_surface_variant}

# --- Starship Prompt Bubbles ---
color255              ${c.primary_container}
color254              ${c.primary}
color253              ${c.secondary_container}
color252              ${c.secondary}
color251              ${c.tertiary_container}
color250              ${c.tertiary}
color249              ${c.error_container}
color248              ${c.error}

color232              ${c.on_primary_container}
color233              ${c.on_primary}
color234              ${c.on_secondary_container}
color235              ${c.on_secondary}
color236              ${c.on_tertiary_container}
color237              ${c.on_tertiary}
color238              ${c.on_error_container}
color239              ${c.on_error}
color240              ${c.on_primary_container}

# Matched with unthemed light/dark
color243              ${c.primary}
color244              ${c.error}
color245              ${c.outline_variant}

# --- UI Elements ---
active_tab_foreground   ${c.on_primary}
active_tab_background   ${c.primary}
inactive_tab_foreground ${c.on_primary_container}
inactive_tab_background ${c.primary_container}

active_border_color     ${c.primary}
inactive_border_color   ${c.outline}

# --- Marks ---
mark1_foreground        ${c.on_primary_fixed}
mark1_background        ${c.primary_fixed}
mark2_foreground        ${c.on_secondary_fixed}
mark2_background        ${c.secondary_fixed}
mark3_foreground        ${c.on_tertiary_fixed}
mark3_background        ${c.tertiary_fixed}
`;

    var postHook = `
SOCKETS=""
[ -S "/tmp/kitty" ] && SOCKETS="/tmp/kitty"
DYNAMIC=$(find /tmp -maxdepth 1 -name "kitty-*" -type s 2>/dev/null || true)
SOCKETS="$SOCKETS $DYNAMIC"
if [ -n "$SOCKETS" ]; then
    for socket in $SOCKETS; do
        kitty @ --to "unix:$socket" set-colors -a ~/.cache/yaks/themes/kitty.conf >/dev/null 2>&1 || true
    done
    (pkill -USR1 kitty || true) &
fi
`;

    return {
        files: [
            { path: "~/.cache/yaks/themes/kitty.conf", content: content }
        ],
        postHook: postHook
    };
}
