#!/bin/bash
source "$CONFIG_DIR/colors.sh"
FREE="$(memory_pressure 2>/dev/null | awk -F': ' '/free percentage/{gsub("%","",$2); print $2}')"
USED="$((100 - ${FREE:-0}))"
COLOR=$TEXT
[ "$USED" -ge 75 ] && COLOR=$YELLOW
[ "$USED" -ge 90 ] && COLOR=$RED
sketchybar --set "$NAME" label="${USED}%" label.color=$COLOR
