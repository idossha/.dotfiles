#!/bin/bash
# System stats: cpu, memory, battery in one bracket. Click any for a details popup.
TOGGLE="$PLUGIN_DIR/popup.sh toggle stats $PLUGIN_DIR/stats_popup.sh"

sketchybar --add item battery right \
  --set battery \
    icon="$ICON_BATTERY_100" \
    update_freq=60 \
    script="$PLUGIN_DIR/battery.sh" \
    click_script="$TOGGLE" \
  --subscribe battery power_source_change system_woke

sketchybar --add item memory right \
  --set memory \
    icon="$ICON_MEM" \
    update_freq=10 \
    script="$PLUGIN_DIR/memory.sh" \
    click_script="$TOGGLE"

sketchybar --add item cpu right \
  --set cpu \
    icon="$ICON_CPU" \
    update_freq=5 \
    script="$PLUGIN_DIR/cpu.sh" \
    click_script="$TOGGLE"

sketchybar --add bracket stats cpu memory battery \
  --set stats \
    background.color=$ITEM_BG \
    background.corner_radius=8 \
    background.height=26 \
    background.drawing=on \
    popup.align=right \
    popup.height=18 \
    script="$PLUGIN_DIR/popup.sh" \
  --subscribe stats mouse.exited.global
