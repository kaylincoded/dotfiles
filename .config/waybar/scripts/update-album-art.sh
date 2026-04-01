#!/bin/bash
# Keeps /tmp/waybar-album-art.png updated with current track's album art
# Uses playerctl --follow for instant updates on track change

ART_FILE="/tmp/waybar-album-art.png"

playerctl metadata --follow --format '{{mpris:artUrl}}' 2>/dev/null | while IFS= read -r ART_URL; do
    if [[ -z "$ART_URL" ]]; then
        rm -f "$ART_FILE"
    elif [[ "$ART_URL" == file://* ]]; then
        cp "${ART_URL#file://}" "${ART_FILE}.tmp" 2>/dev/null && mv "${ART_FILE}.tmp" "$ART_FILE"
    elif [[ "$ART_URL" == http* ]]; then
        curl -s -o "${ART_FILE}.tmp" "$ART_URL" 2>/dev/null && mv "${ART_FILE}.tmp" "$ART_FILE"
    fi
done
