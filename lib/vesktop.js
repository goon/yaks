.pragma library

function generate(colors, opacity, mode, context) {
    const bg4 = colors.base00 || "#000000";
    const bg3 = colors.base01 || bg4;
    const bg2 = colors.base02 || bg3;
    const bg1 = colors.base03 || bg2;
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
  
	/* Status Indicators */
	--online-indicator: ${success};
	--dnd-indicator: ${error};
	--idle-indicator: ${warning};
	--streaming-indicator: ${secondary};

	/* Accent Colors */
	--accent-1: ${primary};     /* links */
	--accent-2: ${secondary};   /* unread/mention elements */
	--accent-3: ${primary};     /* accent buttons */
	--accent-4: ${bg2};         /* accent buttons hover */
	--accent-5: ${accent};      /* accent buttons clicked */
	
	--mention:  ${primary}33;
	--mention-hover: ${primary}4D;

	/* Text Colors */
	--text-0: ${bg4};           /* text on colored elements */
	--text-1: ${text};          /* standard white text */
	--text-2: ${text};          /* headings */
	--text-3: ${muted};         /* normal text */
	--text-4: ${muted};         /* icons/channels */
	--text-5: ${muted};         /* muted timestamps */

	/* Background Colors */
	--bg-1: ${bg1};             /* dark buttons clicked */
	--bg-2: ${bg2};             /* dark buttons */
	--bg-3: ${bg3};             /* spacing/secondary */
	--bg-4: ${bg4};             /* main background */
	
	/* Interactions */
	--hover: ${bg2};            /* channels/buttons hover */
	--active: ${bg1};           /* channels/buttons clicked */
	--message-hover: ${bg3};
}
`;

    return {
        destination: "~/.config/vesktop/themes/qsTheme.css",
        content: content,
        reloadCommand: "true"
    };
}
