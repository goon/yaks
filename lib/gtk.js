.pragma library

function _css(tokens) {
    var c = tokens || {};
    var primaryFixedDim = c.primary_fixed_dim;
    var onPrimaryFixed = c.on_primary_fixed;
    var surfaceDim = c.surface_dim;
    var onSurface = c.on_surface;
    var surface = c.surface;

    return `
@define-color accent_color ${primaryFixedDim};
@define-color accent_fg_color ${onPrimaryFixed};
@define-color accent_bg_color ${primaryFixedDim};
@define-color window_bg_color ${surfaceDim};
@define-color window_fg_color ${onSurface};
@define-color headerbar_bg_color ${surfaceDim};
@define-color headerbar_fg_color ${onSurface};
@define-color popover_bg_color ${surfaceDim};
@define-color popover_fg_color ${onSurface};
@define-color view_bg_color ${surface};
@define-color view_fg_color ${onSurface};
@define-color card_bg_color ${surface};
@define-color card_fg_color ${onSurface};
@define-color sidebar_bg_color @window_bg_color;
@define-color sidebar_fg_color @window_fg_color;
@define-color sidebar_border_color @window_bg_color;
@define-color sidebar_backdrop_color @window_bg_color;
`;
}

function _postHook(ctx) {
    var mode = (ctx && ctx.mode) ? ctx.mode : "dark";
    var context = (ctx && ctx.context) ? ctx.context : "manual";
    var colorScheme = (mode === "light") ? "prefer-light" : "prefer-dark";

    var lines = [
        'GTK3_DIR="$HOME/.config/gtk-3.0"',
        'GTK4_DIR="$HOME/.config/gtk-4.0"',
        'mkdir -p "$GTK3_DIR" "$GTK4_DIR"',
        '',
        'safe_write_import() {',
        '    local file="$1"',
        '    local import_line="$2"',
        '    if [ ! -f "$file" ]; then',
        '        echo "$import_line" > "$file"',
        '    elif ! grep -qF "$import_line" "$file"; then',
        '        sed -i "1i\\$import_line" "$file"',
        '    fi',
        '}',
        '',
        "IMPORT_LINE='@import url(\"yaks.css\");'",
        'safe_write_import "$GTK4_DIR/gtk.css" "$IMPORT_LINE"',
        'safe_write_import "$GTK4_DIR/gtk-dark.css" "$IMPORT_LINE"',
        'safe_write_import "$GTK3_DIR/gtk.css" "$IMPORT_LINE"',
        '',
        "dconf write /org/gnome/desktop/interface/color-scheme \"'" + colorScheme + "'\""
    ];

    if (context !== "startup") {
        lines.push('');
        lines.push('dconf write /org/gnome/desktop/a11y/interface/high-contrast true');
        lines.push('sleep 0.1');
        lines.push('dconf write /org/gnome/desktop/a11y/interface/high-contrast false');
    }

    return lines.join('\n');
}

function generate(tokens, ctx) {
    var css = _css(tokens);

    return {
        files: [
            { path: "~/.config/gtk-3.0/yaks.css", content: css },
            { path: "~/.config/gtk-4.0/yaks.css", content: css }
        ],
        postHook: _postHook(ctx)
    };
}
