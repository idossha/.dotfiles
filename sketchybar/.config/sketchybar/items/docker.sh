#!/bin/bash
# Docker: running container count. Click shows the containers (see clock.sh for
# why the popup lives on a bracket rather than on the item itself).
sketchybar --add item docker right \
  --set docker \
    icon="$ICON_DOCKER" \
    update_freq=15 \
    script="$PLUGIN_DIR/docker.sh" \
    click_script="$PLUGIN_DIR/popup.sh toggle docker_popup $PLUGIN_DIR/docker_popup.sh"

sketchybar --add bracket docker_popup docker \
  --set docker_popup \
    background.drawing=off \
    popup.align=right \
    popup.height=18 \
    script="$PLUGIN_DIR/popup.sh" \
  --subscribe docker_popup mouse.exited.global
