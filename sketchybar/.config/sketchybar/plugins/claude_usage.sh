#!/bin/bash
# Reads the rate limits the Claude Code statusline caches (see
# ~/.dotfiles/agent/claude/statusline-command.sh). No session running -> stale data.
source "$CONFIG_DIR/colors.sh"

CACHE="$HOME/.cache/sketchybar/claude_usage.json"
STALE_AFTER=$((6 * 3600))   # older than this and the numbers are not worth trusting

if [ ! -r "$CACHE" ]; then
  sketchybar --set "$NAME" icon.color=$MUTED label="—" label.color=$MUTED
  exit 0
fi

read -r FIVE SEVEN < <(jq -r '[(.five_hour.used_percentage // 0), (.seven_day.used_percentage // 0)] | map(round) | @tsv' "$CACHE" 2>/dev/null)
[ -z "$FIVE" ] && { sketchybar --set "$NAME" icon.color=$MUTED label="—" label.color=$MUTED; exit 0; }

AGE=$(( $(date +%s) - $(stat -f %m "$CACHE") ))
if [ "$AGE" -gt "$STALE_AFTER" ]; then
  sketchybar --set "$NAME" icon.color=$MUTED label="$FIVE% $SEVEN%" label.color=$MUTED
  exit 0
fi

WORST=$FIVE
[ "$SEVEN" -gt "$WORST" ] && WORST=$SEVEN
if   [ "$WORST" -ge 90 ]; then COLOR=$RED
elif [ "$WORST" -ge 75 ]; then COLOR=$ORANGE
elif [ "$WORST" -ge 50 ]; then COLOR=$YELLOW
else                           COLOR=$ACCENT
fi

sketchybar --set "$NAME" icon.color=$COLOR label="$FIVE% $SEVEN%" label.color=$TEXT
