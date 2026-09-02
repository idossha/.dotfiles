#!/bin/bash
# Shared popup helpers.
#   popup.sh toggle <item> <fill-script> [args]  -> (re)populate then toggle
#   As an item `script` with SENDER=mouse.exited.global -> hide the popup
if [ "$SENDER" = "mouse.exited.global" ]; then
  sketchybar --set "$NAME" popup.drawing=off
  exit 0
fi
if [ "$1" = "toggle" ]; then
  ITEM="$2"; shift 2
  STATE="$(sketchybar --query "$ITEM" | jq -r '.popup.drawing' 2>/dev/null)"
  if [ "$STATE" = "on" ]; then
    sketchybar --set "$ITEM" popup.drawing=off
  else
    "$@"
    sketchybar --set "$ITEM" popup.drawing=on
  fi
fi
