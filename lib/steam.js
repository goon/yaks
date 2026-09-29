.pragma library

function generate(tokens, ctx) {
    var c = tokens || {};

    var content = `
:root {
    --custom-accent: ${c.primary} !important;
    --green-color: ${c.tertiary} !important;
    --idle-status: ${c.secondary} !important;
    --ingame-status: ${c.tertiary} !important;
    --ingameidle-status: ${c.tertiary} !important;
    --main-background: ${c.bg} !important;
    --offline-status: ${c.muted} !important;
    --online-status: ${c.primary} !important;
    --purple-color: ${c.tertiary} !important;

    --SystemAccent: ${c.primary} !important;
    --SystemAccentLight: ${c.primary} !important;
    --SystemAccentDark: ${c.secondary} !important;
    --Focus-Color: ${c.primary} !important;
    --Hover-Color: ${c.raised} !important;

    --ClientBG: ${c.bg} !important;
}

html, body {
    background-color: var(--main-background) !important;
}
`;

    var postHook = `
if [ -d "$HOME/.config/millennium" ]; then
    cp ~/.cache/yaks/themes/steam.css "$HOME/.config/millennium/quick.css"
fi
`;

    return {
        files: [
            { path: "~/.cache/yaks/themes/steam.css", content: content }
        ],
        postHook: postHook
    };
}
