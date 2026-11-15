.pragma library

.import "color.js" as Color

function generate(tokens, ctx) {
    var c = tokens || {};
    var an = c.ansi || [];

    // OpenChamber derives hover, active, selection, focus, diff backgrounds and
    // the syntax aliases from the authored set, so only the roles that must
    // match the shell are written here.
    var theme = {
        "metadata": {
            "id": "yaks-dark",
            "name": "Yaks",
            "variant": "dark"
        },
        "colors": {
            "primary": { "base": c.primary },
            "surface": {
                "background": c.bg,
                "foreground": c.text,
                "muted": c.well,
                "mutedForeground": c.muted,
                "elevated": c.surface,
                "subtle": c.raised
            },
            "interactive": { "border": c.border },
            "status": {
                "error": c.error,
                "warning": an[3],
                "success": an[2],
                "info": an[4]
            },
            "chat": {
                "userMessageBackground": Color.alpha(c.primary, 0.08)
            },
            "markdown": {
                "inlineCode": c.tertiary,
                "inlineCodeBackground": c.raised
            },
            "syntax": {
                "base": {
                    "background": c.well,
                    "comment": c.muted,
                    "keyword": c.secondary,
                    "string": c.tertiary,
                    "number": c.tertiary,
                    "function": c.primary,
                    "variable": c.text,
                    "type": c.primary,
                    "operator": c.muted
                }
            }
        }
    };

    // The OpenChamber server polls themes/ and broadcasts a change, so the
    // rewrite applies live in every window; there is no postHook.
    return {
        files: [
            { path: "~/.config/openchamber/themes/yaks-dark.json", content: JSON.stringify(theme, null, 4) }
        ],
        postHook: ""
    };
}
