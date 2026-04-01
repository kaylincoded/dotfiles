#!/bin/bash
# Toggle calcure floating terminal

CALCURE_ADDR=$(hyprctl clients -j | jq -r '.[] | select(.title == "calcure") | .address' | head -1)

if [[ -n "$CALCURE_ADDR" ]]; then
    hyprctl dispatch closewindow "address:$CALCURE_ADDR"
else
    ghostty --title=calcure -e calcure &
fi
