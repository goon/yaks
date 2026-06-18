#!/usr/bin/env bash
# scripts/qt.sh

THEME_ID="$1"
THEME_PATH="$2"
CONTEXT="$3"
OPACITY="${4:-1.0}"
MODE="${5:-dark}"
COLORS_JSON="$THEME_PATH/colors.json"

if [ ! -f "$COLORS_JSON" ]; then
    echo "Colors file not found: $COLORS_JSON"
    exit 1
fi

get_color_raw() {
    grep "\"$1\":" "$COLORS_JSON" | sed -E 's/.*:[[:space:]]*"([^"]*)".*/\1/' | head -n 1
}

get_color() {
    local key="$1"
    case "$key" in
        "background"|"base") key="base00" ;;
        "surface"|"surfaceAlt") key="base01" ;;
        "selection"|"active") key="base02" ;;
        "border"|"divider") key="base03" ;;
        "textDim"|"muted") key="base04" ;;
        "text") key="base05" ;;
        "error") key="base08" ;;
        "warning") key="base09" ;;
        "accent") key="base0A" ;;
        "success") key="base0B" ;;
        "info") key="base0C" ;;
        "primary") key="primaryIdx" ;;
        "secondary") key="secondaryIdx" ;;
    esac
    
    local val=$(get_color_raw "$key")
    if [[ "$val" == base* ]]; then
        get_color_raw "$val"
    else
        echo "$val"
    fi
}

BG=$(get_color "background")
SURFACE=$(get_color "surface")
SELECTION=$(get_color "selection")
TEXT=$(get_color "text")
PRIMARY=$(get_color "primary")
ACCENT=$(get_color "accent")

# Fallbacks if colors are missing
[ -z "$BG" ] && BG=$(get_color "base")
[ -z "$ACCENT" ] && ACCENT="$PRIMARY"
[ -z "$TEXT" ] && TEXT="#dfdfdf"
[ -z "$SURFACE" ] && SURFACE="#2e2e2e"
[ -z "$SELECTION" ] && SELECTION="$SURFACE"

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
TEMPLATE_DIR="$SCRIPT_DIR/../assets/themes"

apply_kvconfig_template() {
    local template_file="$1"
    local output_file="$2"
    
    if [ ! -f "$template_file" ]; then
        echo "Template not found: $template_file"
        return 1
    fi
    
    local content=$(cat "$template_file")
    
    # Replace placeholders using bash string replacement
    content="${content//\{\{ACCENT\}\}/$ACCENT}"
    content="${content//\{\{BG\}\}/$BG}"
    content="${content//\{\{SURFACE\}\}/$SURFACE}"
    content="${content//\{\{TEXT\}\}/$TEXT}"
    
    echo "$content" > "$output_file"
    chmod 644 "$output_file"
}

apply_svg_template() {
    local template_file="$1"
    local output_file="$2"
    
    if [ ! -f "$template_file" ]; then
        echo "Template not found: $template_file"
        return 1
    fi
    
    local content=$(cat "$template_file")
    
    # Replace the hardcoded colors in the SVG using bash string replacement
    # Accent colors
    content="${content//\#3584e4/$ACCENT}"
    content="${content//\#3584E4/$ACCENT}"
    content="${content//\#4990e7/$ACCENT}"
    content="${content//\#4990E7/$ACCENT}"
    content="${content//\#587392/$ACCENT}"
    content="${content//\#587392/$ACCENT}"
    content="${content//\#4285f4/$ACCENT}"
    content="${content//\#4285F4/$ACCENT}"
    content="${content//\#3daee9/$ACCENT}"
    content="${content//\#3DAEE9/$ACCENT}"
    content="${content//\#6e6e6e/$ACCENT}"
    content="${content//\#6E6E6E/$ACCENT}"
    
    # Background and panel surface colors
    content="${content//\#1d1d20/$BG}"
    content="${content//\#1D1D20/$BG}"
    content="${content//\#2e2e32/$SURFACE}"
    content="${content//\#2E2E32/$SURFACE}"
    content="${content//\#2c2c2c/$BG}"
    content="${content//\#2C2C2C/$BG}"
    content="${content//\#222226/$BG}"
    content="${content//\#222226/$BG}"
    content="${content//\#444444/$SURFACE}"
    content="${content//\#414141/$SURFACE}"
    content="${content//\#4f4f4f/$SURFACE}"
    content="${content//\#4F4F4F/$SURFACE}"
    content="${content//\#4b4b4b/$SELECTION}"
    content="${content//\#4B4B4B/$SELECTION}"
    content="${content//\#3d3d3d/$SELECTION}"
    content="${content//\#3D3D3D/$SELECTION}"
    content="${content//\#616161/$SELECTION}"
    
    # Text colors
    content="${content//\#dfdfdf/$TEXT}"
    content="${content//\#DFDFDF/$TEXT}"
    
    echo "$content" > "$output_file"
    chmod 644 "$output_file"
}

# --- Apply theme to ~/.config/Kvantum/quickshell/ ---
KV_DIR="$HOME/.config/Kvantum/quickshell"
mkdir -p "$KV_DIR"

apply_kvconfig_template "$TEMPLATE_DIR/quickshell.kvconfig" "$KV_DIR/quickshell.kvconfig"
apply_svg_template "$TEMPLATE_DIR/quickshell.svg" "$KV_DIR/quickshell.svg"

# --- Apply theme to qt5ct/qt6ct colors ---
MUTED=$(get_color "muted")
[ -z "$MUTED" ] && MUTED="#777777"

apply_qtct_scheme() {
    local base_dir="$1"
    local colors_dir="$base_dir/colors"
    mkdir -p "$colors_dir"
    
    local scheme_file="$colors_dir/quickshell.conf"
    
    local active="$TEXT, $SURFACE, $SURFACE, $SURFACE, $BG, $BG, $TEXT, $ACCENT, $TEXT, $BG, $BG, $BG, $ACCENT, $BG, $ACCENT, $ACCENT, $SURFACE, $BG, $SURFACE, $TEXT"
    local inactive="$active"
    local disabled="$MUTED, $SURFACE, $SURFACE, $SURFACE, $BG, $BG, $MUTED, $SURFACE, $MUTED, $BG, $BG, $BG, $SURFACE, $TEXT, $SURFACE, $SURFACE, $SURFACE, $BG, $MUTED, $MUTED"
    
    cat <<EOF > "$scheme_file"
[ColorScheme]
active_colors=$active
inactive_colors=$inactive
disabled_colors=$disabled
EOF
    chmod 644 "$scheme_file"
}

apply_qtct_scheme "$HOME/.config/qt5ct"
apply_qtct_scheme "$HOME/.config/qt6ct"

echo "Qt Theme sync completed for $THEME_ID (Mode: $MODE)"
