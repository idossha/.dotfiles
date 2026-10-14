#!/bin/bash
# $1 = workspace id. Focused workspace is red, workspaces visible on other
# monitors are blue, empty ones are dimmed.
source "$CONFIG_DIR/colors.sh"

SID="$1"
FOCUSED="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}"

if [ "$SID" = "$FOCUSED" ]; then
  sketchybar --set "$NAME" background.drawing=on background.color=$RED icon.color=$BAR_COLOR
  exit 0
fi

if aerospace list-workspaces --monitor all --visible 2>/dev/null | grep -qx "$SID"; then
  sketchybar --set "$NAME" background.drawing=on background.color=$ACCENT icon.color=$BAR_COLOR
  exit 0
fi

if [ "$(aerospace list-windows --workspace "$SID" --count 2>/dev/null)" -gt 0 ] 2>/dev/null; then
  sketchybar --set "$NAME" background.drawing=off icon.color=$TEXT
else
  sketchybar --set "$NAME" background.drawing=off icon.color=$MUTED
fi
