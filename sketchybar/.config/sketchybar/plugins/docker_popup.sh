#!/bin/bash
# Docker popup (display only): the running containers, one block each —
# name, image, status, published ports.
#
# `docker ps` talks to the daemon over a socket and hangs for a long time when
# the VM is starting, so every call is bounded by a timeout and the popup falls
# back to a one-line note instead of freezing the bar.
DOCKER_BIN="$(command -v docker || echo /usr/local/bin/docker)"
FONT="Hack Nerd Font Mono:Regular:12.0"
TIMEOUT=5

# run_docker <args...> — like `docker`, but gives up after $TIMEOUT seconds.
run_docker() {
  "$DOCKER_BIN" "$@" &
  local pid=$!  waited=0
  while kill -0 "$pid" 2>/dev/null; do
    [ "$waited" -ge "$((TIMEOUT * 10))" ] && { kill -9 "$pid" 2>/dev/null; wait "$pid" 2>/dev/null; return 124; }
    waited=$((waited + 1))
    perl -e 'select undef, undef, undef, 0.1' 2>/dev/null || sleep 1
  done
  wait "$pid"
}

trunc() { [ "${#1}" -le "$2" ] && printf '%s' "$1" || printf '%s…' "${1:0:$(( $2 - 1 ))}"; }

rows() {
  if ! pgrep -qx "Docker Desktop" && ! pgrep -qf "com.docker.backend"; then
    echo "*Docker"
    echo "#not running"
    return
  fi

  local ps rc
  ps="$(run_docker ps --format '{{.Names}}|{{.Image}}|{{.Status}}|{{.Ports}}' 2>/dev/null)"; rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "*Docker"
    [ "$rc" -eq 124 ] && echo "#daemon not responding" || echo "#daemon still starting…"
    return
  fi

  local count
  count="$(printf '%s' "$ps" | grep -c .)"
  if [ "$count" -eq 0 ]; then
    echo "*Docker"
    echo "#no running containers"
    return
  fi
  echo "*Docker · $count running"

  local name image status ports mark
  while IFS='|' read -r name image status ports; do
    [ -z "$name" ] && continue
    # "Up ..." is healthy; "Restarting"/"Paused" and anything else is not
    case "$status" in Up*) mark="+● " ;; *) mark="!● " ;; esac
    printf '%s%s\n' "$mark" "$(trunc "$name" 34)"
    printf '#    %s\n' "$(trunc "$image" 34)"
    printf '#    %s\n' "$status"
    # one row per published port, trimmed of the 0.0.0.0/:: duplicates docker prints
    if [ -n "$ports" ]; then
      printf '%s' "$ports" | tr ',' '\n' | sed 's/^ *//' | grep -v '^\[::\]' | while IFS= read -r p; do
        [ -n "$p" ] && printf '#    %s\n' "$p"
      done
    fi
  done <<< "$ps"
}

rows | "$CONFIG_DIR/plugins/popup_rows.sh" docker_popup docker.row "$FONT"
