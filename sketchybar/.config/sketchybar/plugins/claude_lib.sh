#!/bin/bash
# Shared reader for the Claude Code usage cache, so the bar label and the popup
# can never disagree: both go through these helpers and the same rounding.
#
# The cache is written by agent/claude/statusline-command.sh on every statusline
# render — the only place Claude Code exposes the plan's rate limits. Which
# windows appear is Claude Code's call, not ours: today it sends five_hour and
# seven_day, and a per-model weekly (Fable, Opus) shows up here as soon as it
# sends one, without a change to this file.
# overridable so the tests can drive these helpers from a fixture
CLAUDE_CACHE="${CLAUDE_CACHE:-$HOME/.cache/sketchybar/claude_usage.json}"
CLAUDE_STALE_AFTER=$((6 * 3600))   # older than this and the numbers aren't worth trusting

# claude_windows -> one "<key> <percent> <resets_at>" line per reported window,
# session first, then weeklies. Nothing (and non-zero) when there is no usable cache.
claude_windows() {
  [ -r "$CLAUDE_CACHE" ] || return 1
  local out
  out="$(jq -r '
    to_entries
    | map(select(.value.used_percentage != null))
    | sort_by(if .key == "five_hour" then 0 elif .key == "seven_day" then 1 else 2 end)
    | .[] | "\(.key) \(.value.used_percentage | round) \(.value.resets_at // 0)"
  ' "$CLAUDE_CACHE" 2>/dev/null)"
  [ -n "$out" ] || return 1
  printf '%s\n' "$out"
}

# claude_age -> seconds since the cache was written.
claude_age() { echo $(( $(date +%s) - $(stat -f %m "$CLAUDE_CACHE") )); }

# claude_name <key> -> the label to print for a window.
claude_name() {
  case "$1" in
    five_hour)     echo "session" ;;
    seven_day)     echo "weekly" ;;
    seven_day_*)   echo "${1#seven_day_} wk" ;;   # e.g. seven_day_fable -> "fable wk"
    *)             echo "${1//_/ }" ;;
  esac
}

# claude_set_label — refresh the bar item. It shows the session and overall weekly
# numbers, but takes its colour from the worst of every window, so a per-model
# weekly running hot still turns the icon red.
claude_set_label() {
  source "$CONFIG_DIR/colors.sh"
  local windows five seven worst=0 key pct reset color
  if ! windows="$(claude_windows)"; then
    sketchybar --set claude icon.color=$MUTED label="—" label.color=$MUTED
    return
  fi
  while read -r key pct reset; do
    [ "$pct" -gt "$worst" ] && worst=$pct
    case "$key" in five_hour) five=$pct ;; seven_day) seven=$pct ;; esac
  done <<< "$windows"

  if [ -n "$five" ] && [ -n "$seven" ]; then label="$five% $seven%"
  else label="$(printf '%s' "$windows" | awk '{printf "%s%% ", $2}' | sed 's/ $//')"
  fi

  if [ "$(claude_age)" -gt "$CLAUDE_STALE_AFTER" ]; then
    sketchybar --set claude icon.color=$MUTED label="$label" label.color=$MUTED
    return
  fi
  if   [ "$worst" -ge 90 ]; then color=$RED
  elif [ "$worst" -ge 75 ]; then color=$ORANGE
  elif [ "$worst" -ge 50 ]; then color=$YELLOW
  else                           color=$ACCENT
  fi
  sketchybar --set claude icon.color=$color label="$label" label.color=$TEXT
}
