#!/bin/bash
# Amphetamine keep-awake session indicator; click toggles a session
sketchybar --add item amphetamine right \
  --set amphetamine \
    icon="$ICON_COFFEE" \
    label.drawing=off \
    update_freq=10 \
    script="$PLUGIN_DIR/amphetamine.sh" \
    click_script="$PLUGIN_DIR/amphetamine.sh toggle" \
  --subscribe amphetamine system_woke
