#!/bin/bash
# Shared reader and background refresher for Codex usage.
# quota-axi owns the authenticated API details; this cache keeps the bar fast.
CODEX_CACHE="${CODEX_CACHE:-$HOME/.cache/sketchybar/codex_usage.json}"
CODEX_CACHE_MAX_AGE=$((5 * 60))

codex_windows() {
  [ -r "$CODEX_CACHE" ] || return 1
  jq -r '
    .providers[] | select(.provider == "codex") | .windows[]
    | [.id, .label, (.percentUsed | round), (.resetsAt // "")] | @tsv
  ' "$CODEX_CACHE" 2>/dev/null | grep -q . || return 1
  jq -r '
    .providers[] | select(.provider == "codex") | .windows[]
    | [.id, .label, (.percentUsed | round), (.resetsAt // "")] | @tsv
  ' "$CODEX_CACHE" 2>/dev/null
}

codex_set_label() {
  source "$CONFIG_DIR/colors.sh"
  local windows first second worst=0 id label pct reset color
  if ! windows="$(codex_windows)"; then
    sketchybar --set codex icon.color=$MUTED label="—" label.color=$MUTED
    return
  fi
  while IFS=$'\t' read -r id label pct reset; do
    [ -z "$pct" ] && continue
    [ "$pct" -gt "$worst" ] && worst=$pct
    [ -z "$first" ] && first="$pct"
    [ -z "$second" ] && second="$pct"
  done <<< "$windows"
  if [ -n "$second" ]; then label="$first% $second%"; else label="$first%"; fi

  if [ $(( $(date +%s) - $(stat -f %m "$CODEX_CACHE") )) -gt "$CODEX_CACHE_MAX_AGE" ]; then
    sketchybar --set codex icon.color=$MUTED label="$label" label.color=$MUTED
    return
  fi
  if   [ "$worst" -ge 90 ]; then color=$RED
  elif [ "$worst" -ge 75 ]; then color=$ORANGE
  elif [ "$worst" -ge 50 ]; then color=$YELLOW
  else                           color=$ACCENT
  fi
  sketchybar --set codex icon.color=$color label="$label" label.color=$TEXT
}

codex_refresh() {
  local quota_bin lock tmp
  quota_bin="$(command -v quota-axi 2>/dev/null)" || return 0
  if [ -r "$CODEX_CACHE" ] && [ $(( $(date +%s) - $(stat -f %m "$CODEX_CACHE") )) -lt "$CODEX_CACHE_MAX_AGE" ]; then return 0; fi
  lock="${CODEX_CACHE}.lock"
  if [ -d "$lock" ] && [ $(( $(date +%s) - $(stat -f %m "$lock") )) -gt 600 ]; then
    rmdir "$lock" 2>/dev/null || return 0
  fi
  mkdir "$lock" 2>/dev/null || return 0
  mkdir -p "${CODEX_CACHE%/*}"
  tmp="${CODEX_CACHE}.tmp.$$"
  (
    "$quota_bin" --provider codex --json --no-credential-refresh > "$tmp" 2>/dev/null \
      && jq -e '.providers[] | select(.provider == "codex")' "$tmp" >/dev/null \
      && mv "$tmp" "$CODEX_CACHE"
    rm -f "$tmp"
    rmdir "$lock" 2>/dev/null
    sketchybar --trigger codex_usage >/dev/null 2>&1
  ) &
}
