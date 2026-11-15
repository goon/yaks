.pragma library

.import "gtk.js" as Gtk
.import "kitty.js" as Kitty
.import "nvim.js" as Nvim
.import "obsidian.js" as Obsidian
.import "discord.js" as Discord
.import "firefox.js" as Firefox
.import "steam.js" as Steam
.import "zed.js" as Zed
.import "openchamber.js" as OpenChamber

/**
 * Single registry of the app theme hooks.
 *
 * Each entry is `{ id, binary, hook }`:
 *   id      key used by installedApps
 *   binary  shell probe that returns 0 when the app is installed
 *   hook    `(tokens, ctx) -> { files, postHook }`
 *
 * Adding an app is two edits: the hook file in lib/ and one entry here.
 */

// Wrapped so the registry holds a plain function, not an import namespace.
function _hook(mod) {
    return function (tokens, ctx) { return mod.generate(tokens, ctx); };
}

var applications = [
    { "id": "gtk",      "binary": "command -v gsettings",                                     "hook": _hook(Gtk) },
    { "id": "kitty",    "binary": "command -v kitty",                                         "hook": _hook(Kitty) },
    { "id": "nvim",     "binary": "command -v nvim",                                          "hook": _hook(Nvim) },
    { "id": "obsidian", "binary": "command -v obsidian || flatpak info md.obsidian.Obsidian",  "hook": _hook(Obsidian) },
    { "id": "discord",  "binary": "command -v vesktop || flatpak info dev.vencord.Vesktop",   "hook": _hook(Discord) },
    { "id": "firefox",  "binary": "command -v pywalfox",                                      "hook": _hook(Firefox) },
    { "id": "steam",    "binary": "command -v steam && test -d ~/.config/millennium",         "hook": _hook(Steam) },
    { "id": "zed",      "binary": "command -v zeditor || command -v zed",                     "hook": _hook(Zed) },
    { "id": "openchamber", "binary": "command -v openchamber",                                "hook": _hook(OpenChamber) }
];
