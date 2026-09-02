#!/bin/bash
# Docker Desktop: running container count. Click opens/starts Docker Desktop.
source "$CONFIG_DIR/colors.sh"

if [ "$1" = "click" ]; then
  open -a Docker
  exit 0
fi

DOCKER_BIN="$(command -v docker || echo /usr/local/bin/docker)"

if ! pgrep -qx "Docker Desktop" && ! pgrep -qf "com.docker.backend"; then
  sketchybar --set "$NAME" icon.color=$MUTED label="" label.drawing=off
  exit 0
fi

COUNT="$("$DOCKER_BIN" ps -q 2>/dev/null | wc -l | tr -d ' ')"
if [ -z "$COUNT" ] || ! "$DOCKER_BIN" info >/dev/null 2>&1; then
  sketchybar --set "$NAME" icon.color=$YELLOW label="…" label.drawing=on
  exit 0
fi

if [ "$COUNT" -gt 0 ]; then
  sketchybar --set "$NAME" icon.color=$ACCENT label="$COUNT" label.drawing=on
else
  sketchybar --set "$NAME" icon.color=$TEXT_DIM label="0" label.drawing=on
fi
