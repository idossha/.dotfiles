#!/bin/bash
case "$1" in
  lock)     osascript -e 'tell application "System Events" to keystroke "q" using {command down, control down}' ;;
  restart)  osascript -e 'tell application "System Events" to restart' ;;
  shutdown) osascript -e 'tell application "System Events" to shut down' ;;
  logout)   osascript -e 'tell application "System Events" to log out' ;;
esac
