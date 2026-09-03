#!/usr/bin/env bash
input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd')
user=$(whoami)
host=$(hostname -s)
dirname=$(basename "$cwd")
git_part=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" -c core.fsmonitor=false branch --show-current 2>/dev/null)
  [ -n "$branch" ] && git_part=" ($branch)"
fi
printf "%s@%s|%s%s" "$user" "$host" "$dirname" "$git_part"

# Publish the plan rate limits for the sketchybar `claude` item. This is the only
# place Claude Code hands them out, so the bar is only as fresh as the last render.
if [ -n "$(printf '%s' "$input" | jq -r '.rate_limits // empty')" ]; then
  cache="$HOME/.cache/sketchybar/claude_usage.json"
  mkdir -p "${cache%/*}"
  printf '%s' "$input" | jq -c '.rate_limits' > "$cache.tmp" && mv "$cache.tmp" "$cache"
  command -v sketchybar >/dev/null 2>&1 && sketchybar --trigger claude_usage >/dev/null 2>&1 &
fi
