#!/bin/bash
# Amphetamine session indicator. `toggle` starts/ends a session.
source "$CONFIG_DIR/colors.sh"

if ! pgrep -qx Amphetamine; then
  [ "$1" = "toggle" ] && open -a Amphetamine
  sketchybar --set "$NAME" icon.color=$MUTED
  exit 0
fi

ACTIVE="$(osascript -e 'tell application "Amphetamine" to session is active' 2>/dev/null)"

if [ "$1" = "toggle" ]; then
  if [ "$ACTIVE" = "true" ]; then
    osascript -e 'tell application "Amphetamine" to end session' >/dev/null 2>&1
    ACTIVE=false
  else
    osascript -e 'tell application "Amphetamine" to start new session' >/dev/null 2>&1
    ACTIVE=true
  fi
fi

if [ "$ACTIVE" = "true" ]; then
  sketchybar --set "$NAME" icon.color=$ORANGE
else
  sketchybar --set "$NAME" icon.color=$TEXT_DIM
fi
