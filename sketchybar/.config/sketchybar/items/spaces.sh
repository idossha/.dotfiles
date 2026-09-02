#!/bin/bash
# AeroSpace workspaces. One item per workspace; focused one is highlighted,
# empty ones are dimmed. Click to switch.

sketchybar --add event aerospace_workspace_change

for sid in $(aerospace list-workspaces --all); do
  sketchybar --add item "space.$sid" left \
    --set "space.$sid" \
      icon="$sid" \
      icon.font="$FONT:Bold:13.0" \
      icon.padding_left=8 \
      icon.padding_right=8 \
      icon.color=$TEXT_DIM \
      label.drawing=off \
      padding_left=1 \
      padding_right=1 \
      background.color=$ITEM_BG \
      background.corner_radius=6 \
      background.height=22 \
      background.drawing=off \
      click_script="aerospace workspace $sid" \
      script="$PLUGIN_DIR/spaces.sh $sid" \
    --subscribe "space.$sid" aerospace_workspace_change front_app_switched space_windows_change
done
