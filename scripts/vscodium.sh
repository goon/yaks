#!/usr/bin/env bash
# scripts/vscodium.sh
# Quickshell Hook: Updates VSCodium theme via Direct Settings Injection
# Args: $1 = theme_id, $2 = absolute_theme_path

THEME_PATH="$2"
THEME_DIR=$(dirname "$THEME_PATH")
TEMPLATE_FILE="$THEME_DIR/vscodium.json"
COLORS_FILE="$THEME_PATH/colors.json"

if [ ! -f "$COLORS_FILE" ] || [ ! -f "$TEMPLATE_FILE" ]; then
    exit 1
fi

SETTINGS_FILE="$HOME/.config/VSCodium/User/settings.json"
if [ ! -f "$SETTINGS_FILE" ] || ! command -v jq >/dev/null 2>&1; then
    exit 1
fi

TMP_THEME="/tmp/vscodium_theme_$$.json"

# Apply colors and generate temporary theme file
awk -v json_file="$COLORS_FILE" '
    BEGIN {
        while ((getline line < json_file) > 0) {
            if (line ~ /": "/) {
                match(line, /"([^"]+)": "([^"]+)"/, arr)
                colors[arr[1]] = arr[2]
            }
        }
        if (colors["primaryIdx"] != "") colors["primary"] = colors[colors["primaryIdx"]]
        if (colors["secondaryIdx"] != "") colors["secondary"] = colors[colors["secondaryIdx"]]
        if (colors["base"] == "") colors["base"] = colors["base00"]
        if (colors["background"] == "") colors["background"] = colors["base00"]
        if (colors["surface"] == "") colors["surface"] = colors["base01"]
        if (colors["surfaceAlt"] == "") colors["surfaceAlt"] = colors["base02"]
        if (colors["text"] == "") colors["text"] = colors["base05"]
        if (colors["textDim"] == "") colors["textDim"] = colors["base04"]
        if (colors["muted"] == "") colors["muted"] = colors["base04"]
        if (colors["accent"] == "") colors["accent"] = colors["base0A"]
        if (colors["error"] == "") colors["error"] = colors["base08"]
        if (colors["warning"] == "") colors["warning"] = colors["base09"]
        if (colors["success"] == "") colors["success"] = colors["base0B"]
    }
    {
        line = $0
        for (key in colors) {
            gsub("{{" key "}}", colors[key], line)
        }
        print line
    }
' "$TEMPLATE_FILE" > "$TMP_THEME"

# Inject into settings.json securely
jq --slurpfile theme "$TMP_THEME" '
  .["workbench.colorCustomizations"] = $theme[0].colors |
  .["editor.tokenColorCustomizations"] = { "textMateRules": $theme[0].tokenColors }
' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"

rm -f "$TMP_THEME"
