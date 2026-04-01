#!/bin/bash
# Toggle album art popup window

ART_FILE="/tmp/waybar-album-art.png"
APP_ID="album-art-popup"

# If popup is already open, close it
if hyprctl clients -j | jq -e '.[] | select(.class == "'"$APP_ID"'")' >/dev/null 2>&1; then
    hyprctl dispatch closewindow "class:$APP_ID"
    exit 0
fi

# Get current album art
ART_URL=$(playerctl metadata mpris:artUrl 2>/dev/null)
[[ -z "$ART_URL" ]] && exit 0

if [[ "$ART_URL" == file://* ]]; then
    cp "${ART_URL#file://}" "${ART_FILE}.tmp" 2>/dev/null && mv "${ART_FILE}.tmp" "$ART_FILE"
elif [[ "$ART_URL" == http* ]]; then
    curl -s -o "${ART_FILE}.tmp" "$ART_URL" 2>/dev/null && mv "${ART_FILE}.tmp" "$ART_FILE"
fi

[[ ! -f "$ART_FILE" ]] && exit 0

# Get bar geometry
BAR_H=$(hyprctl layers -j | jq '.. | objects | select(.namespace? == "waybar") | .h' 2>/dev/null)
BAR_H=${BAR_H:-50}

# Music module is ~350px wide (title-width 25 + artist-width 15 + icons/padding)
WIDTH=350
MARGIN=6
X_POS=$((2560 - WIDTH - MARGIN))
Y_POS=$((BAR_H + 4))

hyprctl dispatch exec "[float;pin;nofocus;move $X_POS $Y_POS;size $WIDTH $WIDTH;rounding 18;animation none;decorate false] imv -i $APP_ID -W $WIDTH -H $WIDTH $ART_FILE"
