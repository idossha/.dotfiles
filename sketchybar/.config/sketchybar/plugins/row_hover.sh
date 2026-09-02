#!/bin/bash
source "$CONFIG_DIR/colors.sh"
case "$SENDER" in
  mouse.entered) sketchybar --set "$NAME" background.drawing=on background.color=$MUTED ;;
  mouse.exited)  sketchybar --set "$NAME" background.drawing=off ;;
esac
