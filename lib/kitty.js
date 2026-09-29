.pragma library

function generate(tokens, ctx) {
    var c = tokens || {};
    var a = c.ansi || [];

    var content = `# --- Main Colors ---
background            ${c.bg}
foreground            ${c.text}
cursor                ${c.text}
cursor_text_color     ${c.bg}

selection_background  ${c.raised}
selection_foreground  ${c.text}

url_color             ${c.tertiary}

# --- ANSI Colors ---
color0                ${a[0]}
color1                ${a[1]}
color2                ${a[2]}
color3                ${a[3]}
color4                ${a[4]}
color5                ${a[5]}
color6                ${a[6]}
color7                ${a[7]}
color8                ${a[8]}
color9                ${a[9]}
color10               ${a[10]}
color11               ${a[11]}
color12               ${a[12]}
color13               ${a[13]}
color14               ${a[14]}
color15               ${a[15]}

# --- Starship Prompt Bubbles ---
color255              ${c.primary}
color254              ${c.primary}
color253              ${c.secondary}
color252              ${c.secondary}
color251              ${c.tertiary}
color250              ${c.tertiary}
color249              ${c.error}
color248              ${c.error}

color232              ${c.ink}
color233              ${c.ink}
color234              ${c.text}
color235              ${c.text}
color236              ${c.muted}
color237              ${c.muted}
color238              ${c.error}
color239              ${c.error}
color240              ${c.ink}

# Matched with unthemed light/dark
color243              ${c.primary}
color244              ${c.error}
color245              ${c.border}

# --- UI Elements ---
active_tab_foreground   ${c.ink}
active_tab_background   ${c.primary}
inactive_tab_foreground ${c.muted}
inactive_tab_background ${c.surface}

active_border_color     ${c.primary}
inactive_border_color   ${c.border}

# --- Marks ---
mark1_foreground        ${c.ink}
mark1_background        ${c.primary}
mark2_foreground        ${c.ink}
mark2_background        ${c.secondary}
mark3_foreground        ${c.ink}
mark3_background        ${c.tertiary}
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
