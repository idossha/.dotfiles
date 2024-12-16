
#!/bin/bash

DOCKER_CMD="/usr/local/bin/docker" # Adjust path if necessary

# Log debug info
echo "Script started at $(date)" > /tmp/sketchybar_debug.log
echo "Docker command: $DOCKER_CMD" >> /tmp/sketchybar_debug.log

# Ensure Docker CLI is available
if ! command -v $DOCKER_CMD >/dev/null; then
  echo "Docker CLI not found" >> /tmp/sketchybar_debug.log
  sketchybar -m --set docker.status label="Docker [Not Installed]"
  exit 1
fi

# Count running containers
RUNNING_CONTAINERS=$($DOCKER_CMD ps --quiet | wc -l | tr -d ' ')
echo "Running containers: $RUNNING_CONTAINERS" >> /tmp/sketchybar_debug.log

# Update SketchyBar label
sketchybar -m --set docker.status label="Docker [$RUNNING_CONTAINERS]"

# Toggle the list of running containers in a popup
toggle_containers() {
  echo "Toggling popup" >> /tmp/sketchybar_debug.log

  # Remove all existing popup items
  args=(--remove '/docker.container\.*/' --set docker.status popup.drawing=toggle)

  # Get the names of running containers
  counter=0
  while IFS= read -r container; do
    args+=(--add item docker.container.$counter popup.docker.status
      --set docker.container.$counter label="$container"
      click_script="sketchybar --set docker.status popup.drawing=off")
    counter=$((counter + 1))
  done <<<"$($DOCKER_CMD ps --format '{{.Names}}')"

  # If no containers are running, show a placeholder
  if [ $counter -eq 0 ]; then
    args+=(--add item docker.container.0 popup.docker.status
      --set docker.container.0 label="No containers running"
      click_script="sketchybar --set docker.status popup.drawing=off")
  fi

  # Apply the updates
  sketchybar -m "${args[@]}" >/dev/null
}

# Handle button clicks
if [ "$BUTTON" = "left" ]; then
  toggle_containers
fi
