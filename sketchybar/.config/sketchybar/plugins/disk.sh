#!/bin/bash

# Fetch the disk usage percentage for the root volume
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

# Update SketchyBar label with the disk usage percentage
sketchybar --set $NAME label="SSD:${DISK_USAGE}%"
