#!/bin/bash
source "$CONFIG_DIR/colors.sh"
IDLE="$(top -l 1 -n 0 | awk -F'[ %]+' '/CPU usage/{print $7}')"
USED="$(awk -v i="${IDLE:-100}" 'BEGIN{printf "%d", 100 - i}')"
COLOR=$TEXT
[ "$USED" -ge 60 ] && COLOR=$YELLOW
[ "$USED" -ge 85 ] && COLOR=$RED
sketchybar --set "$NAME" label="${USED}%" label.color=$COLOR
