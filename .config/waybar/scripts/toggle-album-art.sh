#!/bin/bash
# Toggle album art popup window, sized and centered to the music module

ART_FILE="/tmp/waybar-album-art.png"
APP_ID="album-art-popup"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# If popup is already open, close it
if hyprctl clients -j | jq -e '.[] | select(.class == "'"$APP_ID"'")' >/dev/null 2>&1; then
    hyprctl dispatch closewindow "class:$APP_ID"
    exit 0
elif pgrep -f "album-art-popup.py" >/dev/null 2>&1; then
    pkill -f "album-art-popup.py"
    exit 0
fi

[[ ! -f "$ART_FILE" ]] && exit 0

# Get music module geometry via AT-SPI
read -r MOD_X MOD_Y MOD_W MOD_H < <(python3 "$SCRIPT_DIR/get-music-module-geometry.py" 2>/dev/null)

if [[ -z "$MOD_W" ]]; then
    # Fallback: cursor-centered, 350px
    MOD_W=350
    MOD_X=$(( $(hyprctl cursorpos -j | jq '.x' 2>/dev/null) - MOD_W / 2 ))
    MOD_Y=0
    MOD_H=50
fi

SIZE=$MOD_W
X_POS=$MOD_X
Y_POS=$((MOD_Y + MOD_H + 4))

# Clamp X to screen bounds
[[ $X_POS -lt 0 ]] && X_POS=0

hyprctl dispatch exec "[float;pin;nofocus;move $X_POS $Y_POS;size $SIZE $SIZE;rounding 18] python3 $SCRIPT_DIR/album-art-popup.py $SIZE"
