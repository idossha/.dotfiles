#!/bin/bash
sketchybar --add item docker right \
  --set docker \
    icon="$ICON_DOCKER" \
    update_freq=15 \
    script="$PLUGIN_DIR/docker.sh"
