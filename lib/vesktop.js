.pragma library

function generate(colors, opacity, mode, context) {
    const base = colors.base00 || "#000000";
    const background = colors.base00 || "#000000";
    const surface = colors.base01 || base;
    const text = colors.base05 || "#ffffff";
    const muted = colors.base04 || "#6a6a7a";
    const primary = colors[colors.primaryIdx] || colors.base0D;
    const secondary = colors[colors.secondaryIdx] || colors.base0E;
    const accent = colors.base0A || primary;
    const success = colors.base0B || "#00ff00";
    const error = colors.base08 || "#ff0000";
    const warning = colors.base09 || "#ffff00";

    const font = context && context.font ? context.font : "Outfit";
    const themeName = context && context.name ? context.name : "Dynamic";

    const content = `@import url('https://refact0r.github.io/midnight-discord/build/midnight.css');

body {
\t--font: '${font}';
\t--code-font: '${font}';
  --small-user-panel: on;
}

:root {
\t/* Font */
\t--font: '${font}';
\t--code-font: '${font}';
\t--corner-text: '${themeName}';
  
\t/* Status Indicators */
\t--online-indicator: ${success};
\t--dnd-indicator: ${error};
\t--idle-indicator: ${warning};
\t--streaming-indicator: ${secondary};

\t/* Accent Colors */
\t--accent-1: ${primary};     /* links */
\t--accent-2: ${secondary};   /* unread/mention elements */
\t--accent-3: ${primary};     /* accent buttons */
\t--accent-4: ${surface};     /* accent buttons hover */
\t--accent-5: ${accent};      /* accent buttons clicked */
\t
\t--mention:  ${surface};
\t--mention-hover: ${background};

\t/* Text Colors */
\t--text-0: ${base};          /* text on colored elements */
\t--text-1: ${text};          /* standard white text */
\t--text-2: ${text};          /* headings */
\t--text-3: ${muted};         /* normal text */
\t--text-4: ${muted};         /* icons/channels */
\t--text-5: ${muted};         /* muted timestamps */

\t/* Background Colors */
\t--bg-1: ${surface};         /* dark buttons clicked */
\t--bg-2: ${background};      /* dark buttons */
\t--bg-3: ${background};      /* spacing/secondary */
\t--bg-4: ${surface};            /* main background */
\t
\t/* Interactions */
\t--hover: ${surface};        /* channels/buttons hover */
\t--active: ${surface};       /* channels/buttons clicked */
\t--message-hover: ${background};
}
`;

    return {
        destination: "~/.config/vesktop/themes/qsTheme.css",
        content: content,
        reloadCommand: "true"
    };
}
