.pragma library

function generate(tokens, ctx) {
    var c = tokens || {};
    var image = (ctx && ctx.wallpaper) ? ctx.wallpaper : "";

    var data = {
        "wallpaper": image,
        "alpha": "100",
        "colors": {
            "color0":  c.surface,
            "color1":  "",
            "color2":  "",
            "color3":  c.primary,
            "color4":  "",
            "color5":  c.secondary,
            "color6":  "",
            "color7":  c.surface_container_highest,
            "color8":  "",
            "color9":  "",
            "color10": c.primary,
            "color11": "",
            "color12": "",
            "color13": c.secondary,
            "color14": "",
            "color15": c.on_background
        }
    };

    var postHook = 'mkdir -p ~/.cache/wal && ln -sf ~/.cache/yaks/themes/pywalfox.json ~/.cache/wal/colors.json && (command -v pywalfox >/dev/null 2>&1 && pywalfox update || true)';

    return {
        files: [
            { path: "~/.cache/yaks/themes/pywalfox.json", content: JSON.stringify(data, null, 2) }
        ],
        postHook: postHook
    };
}
