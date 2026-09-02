#!/bin/bash
# Wi-Fi. Popup lives on a bracket around the item (see clock.sh for why).
sketchybar --add item wifi right \
  --set wifi \
    icon="$ICON_WIFI" \
    update_freq=15 \
    script="$PLUGIN_DIR/wifi.sh" \
    click_script="$PLUGIN_DIR/popup.sh toggle wifi_popup $PLUGIN_DIR/wifi_popup.sh" \
  --subscribe wifi wifi_change system_woke

sketchybar --add bracket wifi_popup wifi \
  --set wifi_popup \
    background.drawing=off \
    popup.align=right \
    popup.height=20 \
    script="$PLUGIN_DIR/popup.sh" \
  --subscribe wifi_popup mouse.exited.global
