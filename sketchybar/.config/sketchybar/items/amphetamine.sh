#!/bin/bash
# Amphetamine keep-awake session indicator (display only)
sketchybar --add item amphetamine right \
  --set amphetamine \
    icon="$ICON_COFFEE" \
    label.drawing=off \
    update_freq=10 \
    script="$PLUGIN_DIR/amphetamine.sh" \
  --subscribe amphetamine system_woke
