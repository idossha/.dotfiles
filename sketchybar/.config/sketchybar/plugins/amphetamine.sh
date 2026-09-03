#!/bin/bash
# Amphetamine session indicator (read-only).
source "$CONFIG_DIR/colors.sh"

if ! pgrep -qx Amphetamine; then
  sketchybar --set "$NAME" icon.color=$MUTED
  exit 0
fi

ACTIVE="$(osascript -e 'tell application "Amphetamine" to session is active' 2>/dev/null)"


if [ "$ACTIVE" = "true" ]; then
  sketchybar --set "$NAME" icon.color=$ORANGE
else
  sketchybar --set "$NAME" icon.color=$TEXT_DIM
fi
