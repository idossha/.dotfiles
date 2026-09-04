#!/bin/bash
# Codex plan usage from quota-axi. Click for the session and weekly windows.
sketchybar --add event codex_usage

sketchybar --add item codex right \
  --set codex \
    icon="$ICON_CODEX" \
    update_freq=60 \
    script="$PLUGIN_DIR/codex_usage.sh" \
    click_script="$PLUGIN_DIR/popup.sh toggle codex_popup $PLUGIN_DIR/codex_popup.sh" \
  --subscribe codex codex_usage

sketchybar --add bracket codex_popup codex \
  --set codex_popup \
    popup.align=right \
    popup.height=18 \
    script="$PLUGIN_DIR/popup.sh" \
  --subscribe codex_popup mouse.exited.global
