#!/usr/bin/env bash

# install-agent-tools.sh
#
# Opt-in installer for the machine-level tooling that the canonical config in
# agent/ assumes is present. It is NEVER run by sync-agent-config.sh: the sync
# script only creates symlinks and must stay offline and instant. This one
# reaches the network and installs software, so it is always run by hand.
#
# Default run (idempotent, safe to repeat):
#   1. Pi packages  - `pi install` for every package pinned in
#      agent/pi/settings.json. Pi 0.73 does not auto-install packages listed in
#      global settings at startup (that arrived in 0.82), so a fresh machine
#      needs this. Already-installed pins are skipped.
#   2. herdr integrations - `herdr integration install` for pi, claude and
#      codex, skipping the ones `herdr integration status` reports installed.
#
# Optional:
#   --tools                 Also install the adopted external CLIs:
#                           gnhf, lavish-axi, gh-axi, acpx, backpass (npm -g)
#                           and no-mistakes (curl | sh, asks first).
#   --refresh-herdr-skill   Only regenerate agent/skills/herdr/SKILL.md from
#                           `herdr --skill`. That skill is vendored from the
#                           installed binary: tracked in git, but regenerated
#                           rather than hand-edited. Runs alone and exits.
#   --help                  Show usage.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PI_SETTINGS="$AGENT_DIR/pi/settings.json"
HERDR_SKILL_DIR="$AGENT_DIR/skills/herdr"

NPM_TOOLS=(gnhf lavish-axi gh-axi acpx backpass)
NO_MISTAKES_URL="https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.sh"

WITH_TOOLS=0
REFRESH_HERDR_SKILL=0

DONE_LINES=()
SKIPPED_LINES=()

did() { DONE_LINES+=("$1"); echo "  [do]   $1"; }
skipped() { SKIPPED_LINES+=("$1"); echo "  [skip] $1"; }

usage() {
  sed -n '3,27p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      --tools) WITH_TOOLS=1 ;;
      --refresh-herdr-skill) REFRESH_HERDR_SKILL=1 ;;
      *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
  done
}

# --- Pi packages -------------------------------------------------------------

pinned_packages() {
  python3 - "$PI_SETTINGS" <<'PY'
import json
import sys

with open(sys.argv[1]) as fh:
    settings = json.load(fh)

for entry in settings.get("packages", []):
    source = entry if isinstance(entry, str) else entry.get("source", "")
    if source.startswith("npm:"):
        print(source)
PY
}

npm_global_version() {
  local pkg="$1" root
  root="$(npm root -g 2>/dev/null || true)"
  [ -n "$root" ] && [ -f "$root/$pkg/package.json" ] || return 1
  python3 - "$root/$pkg/package.json" <<'PY'
import json
import sys

with open(sys.argv[1]) as fh:
    print(json.load(fh).get("version", ""))
PY
}

install_pi_packages() {
  echo "Pi packages (pinned in ${PI_SETTINGS#"$AGENT_DIR"/}):"

  if ! command -v pi >/dev/null 2>&1; then
    skipped "all Pi packages: 'pi' is not on PATH"
    return 0
  fi
  if [ ! -f "$PI_SETTINGS" ]; then
    skipped "all Pi packages: $PI_SETTINGS is missing"
    return 0
  fi

  local listed
  listed="$(pi list 2>/dev/null || true)"

  local source name version installed
  while IFS= read -r source; do
    [ -n "$source" ] || continue
    # npm:<name>@<version>, where <name> may be @scope/pkg
    name="${source#npm:}"
    version="${name##*@}"
    name="${name%@*}"

    # `pi list` prints packages configured in settings.json, which this file
    # always is; the pin only counts as installed when the global npm copy is
    # actually there at the pinned version.
    installed="$(npm_global_version "$name" || true)"
    if [ "$installed" = "$version" ] && printf '%s\n' "$listed" | grep -qF "$source"; then
      skipped "$source (already installed)"
      continue
    fi

    if pi install "$source"; then
      did "$source${installed:+ (was $installed)}"
    else
      echo "  [fail] $source" >&2
      return 1
    fi
  done < <(pinned_packages)
}

# --- herdr integrations ------------------------------------------------------

install_herdr_integrations() {
  echo "herdr integrations:"

  if ! command -v herdr >/dev/null 2>&1; then
    skipped "all herdr integrations: 'herdr' is not on PATH"
    return 0
  fi

  local status target
  status="$(herdr integration status 2>/dev/null || true)"

  for target in pi claude codex; do
    if printf '%s\n' "$status" | grep -qE "^${target}: +installed"; then
      skipped "herdr integration $target (already installed)"
      continue
    fi
    if herdr integration install "$target"; then
      did "herdr integration $target"
    else
      echo "  [fail] herdr integration $target" >&2
      return 1
    fi
  done
}

# --- external tools (--tools) ------------------------------------------------

install_npm_tools() {
  echo "External npm tools:"

  if ! command -v npm >/dev/null 2>&1; then
    skipped "all npm tools: 'npm' is not on PATH"
    return 0
  fi

  local missing=() pkg
  for pkg in "${NPM_TOOLS[@]}"; do
    if npm_global_version "$pkg" >/dev/null 2>&1; then
      skipped "$pkg (already installed)"
    else
      missing+=("$pkg")
    fi
  done

  if [ "${#missing[@]}" -eq 0 ]; then
    return 0
  fi

  npm install -g "${missing[@]}"
  for pkg in "${missing[@]}"; do
    did "$pkg"
  done
}

install_no_mistakes() {
  echo "no-mistakes:"

  if command -v no-mistakes >/dev/null 2>&1; then
    skipped "no-mistakes (already on PATH)"
    return 0
  fi

  # Piping a remote script into a shell is never done without being asked.
  if [ ! -t 0 ]; then
    skipped "no-mistakes (needs an interactive terminal to confirm the curl | sh installer)"
    return 0
  fi

  echo "  The no-mistakes installer runs a remote script:"
  echo "    curl -fsSL $NO_MISTAKES_URL | sh"
  local reply
  read -r -p "  Run it? [y/N] " reply
  case "$reply" in
    y|Y|yes|YES)
      curl -fsSL "$NO_MISTAKES_URL" | sh
      did "no-mistakes (via $NO_MISTAKES_URL)"
      ;;
    *)
      skipped "no-mistakes (declined)"
      ;;
  esac
}

# --- vendored herdr skill (--refresh-herdr-skill) ----------------------------

refresh_herdr_skill() {
  echo "Vendored herdr skill:"

  if ! command -v herdr >/dev/null 2>&1; then
    echo "  [fail] 'herdr' is not on PATH" >&2
    return 1
  fi

  mkdir -p "$HERDR_SKILL_DIR"

  local tmp
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' RETURN

  herdr --skill > "$tmp"

  # The sync script validates every skill: frontmatter must parse and `name`
  # must equal the directory name. Refuse to write output that would fail that.
  if ! head -1 "$tmp" | grep -qx -- '---'; then
    echo "  [fail] 'herdr --skill' did not emit YAML frontmatter" >&2
    return 1
  fi
  if ! sed -n '2,20p' "$tmp" | grep -qE '^name:[[:space:]]*herdr[[:space:]]*$'; then
    echo "  [fail] 'herdr --skill' frontmatter does not carry 'name: herdr'" >&2
    return 1
  fi

  mv "$tmp" "$HERDR_SKILL_DIR/SKILL.md"
  chmod 644 "$HERDR_SKILL_DIR/SKILL.md"
  trap - RETURN
  did "regenerated ${HERDR_SKILL_DIR#"$AGENT_DIR"/}/SKILL.md from 'herdr --skill'"
  echo "  Review and commit it: the skill is vendored from the installed binary."
}

# --- summary -----------------------------------------------------------------

print_summary() {
  echo
  echo "Summary"
  if [ "${#DONE_LINES[@]}" -eq 0 ]; then
    echo "  Installed: nothing (everything was already in place)"
  else
    echo "  Installed:"
    printf '    - %s\n' "${DONE_LINES[@]}"
  fi
  if [ "${#SKIPPED_LINES[@]}" -gt 0 ]; then
    echo "  Skipped:"
    printf '    - %s\n' "${SKIPPED_LINES[@]}"
  fi
}

main() {
  parse_args "$@"

  if [ "$REFRESH_HERDR_SKILL" -eq 1 ]; then
    refresh_herdr_skill
    print_summary
    return 0
  fi

  install_pi_packages
  echo
  install_herdr_integrations

  if [ "$WITH_TOOLS" -eq 1 ]; then
    echo
    install_npm_tools
    echo
    install_no_mistakes
  fi

  print_summary
}

main "$@"
