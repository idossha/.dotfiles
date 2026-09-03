#!/bin/bash
# Shared reader for the Claude Code usage cache, so the bar label and the popup
# can never disagree: both go through claude_read and the same rounding.
#
# The cache is written by agent/claude/statusline-command.sh on every statusline
# render — the only place Claude Code exposes the plan's rate limits.
# overridable so the tests can drive these helpers from a fixture instead of the
# live cache, which a running Claude session rewrites on every statusline render
CLAUDE_CACHE="${CLAUDE_CACHE:-$HOME/.cache/sketchybar/claude_usage.json}"
CLAUDE_STALE_AFTER=$((6 * 3600))   # older than this and the numbers aren't worth trusting

# claude_read -> "<five> <seven> <age-seconds>", or nothing when there is no usable cache.
claude_read() {
  [ -r "$CLAUDE_CACHE" ] || return 1
  local vals
  vals="$(jq -r '[(.five_hour.used_percentage // empty), (.seven_day.used_percentage // empty)]
                 | if length == 2 then map(round) | @tsv else empty end' "$CLAUDE_CACHE" 2>/dev/null)"
  [ -n "$vals" ] || return 1
  printf '%s %s\n' "$vals" "$(( $(date +%s) - $(stat -f %m "$CLAUDE_CACHE") ))"
}

# claude_set_label — refresh the bar item from the cache.
claude_set_label() {
  source "$CONFIG_DIR/colors.sh"
  local five seven age worst color
  if ! read -r five seven age < <(claude_read); then
    sketchybar --set claude icon.color=$MUTED label="—" label.color=$MUTED
    return
  fi
  if [ "$age" -gt "$CLAUDE_STALE_AFTER" ]; then
    sketchybar --set claude icon.color=$MUTED label="$five% $seven%" label.color=$MUTED
    return
  fi
  worst=$five; [ "$seven" -gt "$worst" ] && worst=$seven
  if   [ "$worst" -ge 90 ]; then color=$RED
  elif [ "$worst" -ge 75 ]; then color=$ORANGE
  elif [ "$worst" -ge 50 ]; then color=$YELLOW
  else                           color=$ACCENT
  fi
  sketchybar --set claude icon.color=$color label="$five% $seven%" label.color=$TEXT
}
