#!/bin/bash
# Shared reader for the Claude Code usage cache, so the bar label and the popup
# can never disagree: both go through claude_read and the same rounding.
#
# The cache is written by agent/claude/statusline-command.sh on every statusline
# render — the only place Claude Code exposes the plan's rate limits. It is the
# statusline's `rate_limits` object, in which every window is optional:
#   five_hour   — session limit; not every plan reports it, and it is dropped once reset
#   seven_day   — weekly limit
#   spend_limit — a Claude gateway's spend cap (API/gateway users, no plan windows)
# overridable so the tests can drive these helpers from a fixture instead of the
# live cache, which a running Claude session rewrites on every statusline render
CLAUDE_CACHE="${CLAUDE_CACHE:-$HOME/.cache/sketchybar/claude_usage.json}"
CLAUDE_STALE_AFTER=$((6 * 3600))   # older than this and the numbers aren't worth trusting

# claude_read — set CLAUDE_{FIVE,SEVEN,SPEND} (rounded percent, empty when the window
# is absent), CLAUDE_{FIVE,SEVEN,SPEND}_RESET (epoch), CLAUDE_SPEND_{PERIOD,USED,LIMIT}
# and CLAUDE_AGE (seconds). Windows whose reset time has passed are dropped, as Claude
# Code itself does: the cache can outlive them. Fails when no window is usable.
claude_read() {
  CLAUDE_FIVE= CLAUDE_FIVE_RESET= CLAUDE_SEVEN= CLAUDE_SEVEN_RESET=
  CLAUDE_SPEND= CLAUDE_SPEND_RESET= CLAUDE_SPEND_PERIOD= CLAUDE_SPEND_USED= CLAUDE_SPEND_LIMIT=
  CLAUDE_AGE=
  [ -r "$CLAUDE_CACHE" ] || return 1
  local vals
  # '|' rather than tabs: read collapses consecutive whitespace IFS, losing empty fields
  vals="$(jq -r '
    def win(k): (.[k] // {}) | if (.used_percentage | type) == "number"
                                   and ((.resets_at | type) != "number" or .resets_at > now)
                                then . else {} end;
    def pct: if .used_percentage then .used_percentage | round else "" end;
    win("five_hour") as $f | win("seven_day") as $s | win("spend_limit") as $g
    | [($f|pct), ($f.resets_at // ""), ($s|pct), ($s.resets_at // ""),
       ($g|pct), ($g.resets_at // ""), ($g.period // ""), ($g.used_usd // ""), ($g.limit_usd // "")]
    | map(tostring) | join("|")' "$CLAUDE_CACHE" 2>/dev/null)" || return 1
  IFS='|' read -r CLAUDE_FIVE CLAUDE_FIVE_RESET CLAUDE_SEVEN CLAUDE_SEVEN_RESET \
    CLAUDE_SPEND CLAUDE_SPEND_RESET CLAUDE_SPEND_PERIOD CLAUDE_SPEND_USED CLAUDE_SPEND_LIMIT <<<"$vals"
  [ -n "$CLAUDE_FIVE$CLAUDE_SEVEN$CLAUDE_SPEND" ] || return 1
  CLAUDE_AGE=$(( $(date +%s) - $(stat -f %m "$CLAUDE_CACHE") ))
}

# claude_label — the bar text: "<session>% <weekly>%", with "–" holding the place of a
# window the plan doesn't report so the two numbers never swap meaning. A gateway
# spend limit alone shows as "$<pct>%".
claude_label() {
  if [ -n "$CLAUDE_FIVE$CLAUDE_SEVEN" ]; then
    printf '%s %s' "${CLAUDE_FIVE:+$CLAUDE_FIVE%}" "${CLAUDE_SEVEN:+$CLAUDE_SEVEN%}" \
      | sed -e 's/^ /– /' -e 's/ $/ –/'
  else
    printf '$%s%%' "$CLAUDE_SPEND"
  fi
}

# claude_set_label — refresh the bar item from the cache.
claude_set_label() {
  source "$CONFIG_DIR/colors.sh"
  local worst=0 p color
  if ! claude_read; then
    sketchybar --set claude icon.color=$MUTED label="—" label.color=$MUTED
    return
  fi
  if [ "$CLAUDE_AGE" -gt "$CLAUDE_STALE_AFTER" ]; then
    sketchybar --set claude icon.color=$MUTED label="$(claude_label)" label.color=$MUTED
    return
  fi
  for p in $CLAUDE_FIVE $CLAUDE_SEVEN $CLAUDE_SPEND; do
    [ "$p" -gt "$worst" ] && worst=$p
  done
  if   [ "$worst" -ge 90 ]; then color=$RED
  elif [ "$worst" -ge 75 ]; then color=$ORANGE
  elif [ "$worst" -ge 50 ]; then color=$YELLOW
  else                           color=$ACCENT
  fi
  sketchybar --set claude icon.color=$color label="$(claude_label)" label.color=$TEXT
}

# claude_plan — the account's subscription, e.g. "Ultra · max 20x", "Pro", "API key",
# "Bedrock"; nothing when Claude Code isn't installed or logged in.
# `claude auth status` is the supported source (subscriptionType, auth method); the
# profile Claude Code caches in ~/.claude.json adds the plan's display name and tier
# when present. Both are overridable for the tests.
CLAUDE_BIN="${CLAUDE_BIN:-$(command -v claude || echo "$HOME/.local/bin/claude")}"
CLAUDE_PROFILE="${CLAUDE_PROFILE:-${CLAUDE_CONFIG_DIR:-$HOME}/.claude.json}"
claude_plan() {
  local auth profile='{}'
  auth="$("$CLAUDE_BIN" auth status 2>/dev/null </dev/null)" || return 0
  [ -r "$CLAUDE_PROFILE" ] && profile="$(jq -c '.oauthAccount // {}' "$CLAUDE_PROFILE" 2>/dev/null || echo '{}')"
  jq -r --argjson p "$profile" '
    def cap: (.[:1] | ascii_upcase) + .[1:];
    select(.loggedIn == true)
    | if .authMethod == "claude.ai" or (.subscriptionType // "") != "" then
        (.subscriptionType // "") as $sub
        | (($p.organizationRateLimitTier // $p.userRateLimitTier // "")
           | capture("(?<x>[0-9]+x)$").x // "") as $tier
        | ($p.planDisplayName // ($sub | cap)) as $name
        | [$name,
           ([(if ($sub | ascii_downcase) != ($name | ascii_downcase) then $sub else empty end), $tier]
            | map(select(. != "")) | join(" ") | select(. != ""))]
        | map(select(. != "")) | join(" · ")
      elif (.apiProvider // "firstParty") != "firstParty" then
        {bedrock: "Bedrock", vertex: "Vertex", foundry: "Foundry"}[.apiProvider] // .apiProvider
      else "API key" end' <<<"$auth" 2>/dev/null
}
