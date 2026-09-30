.pragma library

.import "gtk.js" as Gtk
.import "kitty.js" as Kitty
.import "nvim.js" as Nvim
.import "obsidian.js" as Obsidian
.import "discord.js" as Discord
.import "firefox.js" as Firefox
.import "steam.js" as Steam
.import "zed.js" as Zed

/**
 * Single registry of the app theme hooks.
 *
 * Each entry is `{ id, name, binary, hook }`:
 *   id      preference key in Preferences.applications.themedApps
 *   name    display name in Settings > Applications
 *   binary  shell probe that returns 0 when the app is installed
 *   hook    `(tokens, ctx) -> { files, postHook }`, wrapped so callers do not
 *           depend on `.import` namespaces as values.
 *
 * Adding an app is now two edits: the hook file in lib/ and one entry here.
 * `defaultThemedApps()` seeds Preferences from the same list, so no separate
 * preference default has to be maintained.
 */

function _hook(mod) {
    return function (tokens, ctx) { return mod.generate(tokens, ctx); };
}

var applications = [
    { "id": "gtk",      "name": "GTK",                "binary": "command -v gsettings",                                      "hook": _hook(Gtk) },
    { "id": "kitty",    "name": "Kitty",              "binary": "command -v kitty",                                          "hook": _hook(Kitty) },
    { "id": "nvim",     "name": "Neovim",             "binary": "command -v nvim",                                           "hook": _hook(Nvim) },
    { "id": "obsidian", "name": "Obsidian",           "binary": "command -v obsidian || flatpak info md.obsidian.Obsidian",  "hook": _hook(Obsidian) },
    { "id": "discord",  "name": "Discord",            "binary": "command -v vesktop || flatpak info dev.vencord.Vesktop",   "hook": _hook(Discord) },
    { "id": "firefox",  "name": "Firefox",            "binary": "command -v pywalfox",                                       "hook": _hook(Firefox) },
    { "id": "steam",    "name": "Steam / Millennium", "binary": "command -v steam && test -d ~/.config/millennium",         "hook": _hook(Steam) },
    { "id": "zed",      "name": "Zed",                "binary": "command -v zeditor || command -v zed",                      "hook": _hook(Zed) }
];

/** `{ <id>: false }` for every registered app; the Preferences default. */
function defaultThemedApps() {
    var map = {};
    for (var i = 0; i < applications.length; i++)
        map[applications[i].id] = false;
    return map;
}
