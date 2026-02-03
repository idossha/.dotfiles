#!/bin/bash

MOUNTPOINT="$HOME/homelab"
REMOTE="raspberrypi:/media/idohaber/storage"
LOG="$HOME/.sshfs-watchdog.log"

# Check if mount exists
if mount | grep -q "$MOUNTPOINT"; then
  # Try accessing it (this triggers "Device not configured" if broken)
  ls "$MOUNTPOINT" >/dev/null 2>&1

  if [ $? -ne 0 ]; then
    echo "$(date): Mount broken, remounting" >> "$LOG"
    diskutil unmount force "$MOUNTPOINT" >> "$LOG" 2>&1
    sshfs "$REMOTE" "$MOUNTPOINT" -o reconnect >> "$LOG" 2>&1
  fi
else
  echo "$(date): Mount missing, mounting" >> "$LOG"
  sshfs "$REMOTE" "$MOUNTPOINT" -o reconnect >> "$LOG" 2>&1
fi

