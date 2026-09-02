#!/bin/bash
# Clock. The popup lives on a bracket around the item (same pattern as stats),
# because popups attached directly to an item with update_freq get closed by
# the item's own update cycle.
sketchybar --add item clock right \
  --set clock \
    icon="$ICON_CLOCK" \
    icon.color=$ACCENT \
    update_freq=20 \
    script="$PLUGIN_DIR/clock.sh" \
    click_script="$PLUGIN_DIR/popup.sh toggle clock_popup $PLUGIN_DIR/calendar_popup.sh"

sketchybar --add bracket clock_popup clock \
  --set clock_popup \
    background.drawing=off \
    popup.align=right \
    popup.height=18 \
    script="$PLUGIN_DIR/popup.sh" \
  --subscribe clock_popup mouse.exited.global
