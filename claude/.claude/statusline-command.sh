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
