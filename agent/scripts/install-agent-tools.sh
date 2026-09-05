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
#
# Optional:
#   --tools     Install the pinned adopted tools: no-mistakes and the AXI helper CLIs.
#   --dry-run   Print mutating commands without running them.
#   --help      Show usage.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PI_SETTINGS="$AGENT_DIR/pi/settings.json"

# shellcheck source=../tools.env
source "$AGENT_DIR/tools.env"
# shellcheck source=python-runtime.sh
source "$SCRIPT_DIR/python-runtime.sh"

WITH_TOOLS=0
DRY_RUN=0

DONE_LINES=()
SKIPPED_LINES=()

did() {
  DONE_LINES+=("$1")
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [plan] $1"
  else
    echo "  [do]   $1"
  fi
}
skipped() { SKIPPED_LINES+=("$1"); echo "  [skip] $1"; }

print_command() {
  printf '  [dry-run]'
  printf ' %q' "$@"
  printf '\n'
}

run_mutation() {
  if [ "$DRY_RUN" -eq 1 ]; then
    print_command "$@"
  else
    "$@"
  fi
}

usage() {
  sed -n '3,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      --tools) WITH_TOOLS=1 ;;
      --dry-run) DRY_RUN=1 ;;
      *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
  done
}

# --- Pi packages -------------------------------------------------------------

pinned_packages() {
  "$AGENT_PYTHON" - "$PI_SETTINGS" <<'PY'
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
  "$AGENT_PYTHON" - "$root/$pkg/package.json" <<'PY'
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

    if run_mutation pi install "$source"; then
      did "$source${installed:+ (was $installed)}"
    else
      echo "  [fail] $source" >&2
      return 1
    fi
  done < <(pinned_packages)
}

# --- external tools (--tools) ------------------------------------------------

install_no_mistakes() {
  echo "no-mistakes:"

  local installed=""
  if command -v no-mistakes >/dev/null 2>&1; then
    installed="$(no-mistakes version 2>/dev/null | head -1 || no-mistakes --version 2>/dev/null | head -1 || true)"
  fi
  if [[ "$installed" == *"$NO_MISTAKES_VERSION"* ]]; then
    skipped "no-mistakes@$NO_MISTAKES_VERSION (already installed)"
    return 0
  fi

  local os arch filename base_url install_dir link_dir
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"
  case "$os" in darwin|linux) ;; *) skipped "no-mistakes: unsupported OS $os"; return 0 ;; esac
  case "$arch" in x86_64|amd64) arch=amd64 ;; arm64|aarch64) arch=arm64 ;; *) skipped "no-mistakes: unsupported architecture $arch"; return 0 ;; esac
  filename="no-mistakes-v${NO_MISTAKES_VERSION}-${os}-${arch}.tar.gz"
  base_url="https://github.com/kunchenguid/no-mistakes/releases/download/v${NO_MISTAKES_VERSION}"
  install_dir="${NO_MISTAKES_INSTALL_DIR:-$HOME/.no-mistakes/bin}"
  link_dir="${NO_MISTAKES_LINK_DIR:-$HOME/.local/bin}"

  if [ "$DRY_RUN" -eq 1 ]; then
    print_command curl -fsSL "$base_url/$filename" -o "<temporary>/$filename"
    print_command curl -fsSL "$base_url/checksums.txt" -o "<temporary>/checksums.txt"
    print_command install -m 755 "<verified temporary>/no-mistakes" "$install_dir/no-mistakes"
    print_command ln -sfn "$install_dir/no-mistakes" "$link_dir/no-mistakes"
    print_command "$install_dir/no-mistakes" daemon restart
    did "no-mistakes@$NO_MISTAKES_VERSION (planned)"
    return 0
  fi

  local temp_dir
  temp_dir="$(mktemp -d)"
  trap 'rm -rf "$temp_dir"' RETURN
  curl -fsSL "$base_url/$filename" -o "$temp_dir/$filename"
  curl -fsSL "$base_url/checksums.txt" -o "$temp_dir/checksums.txt"
  (cd "$temp_dir" && grep "  $filename\$" checksums.txt | shasum -a 256 -c -)
  tar xzf "$temp_dir/$filename" -C "$temp_dir"
  mkdir -p "$install_dir" "$link_dir"
  install -m 755 "$temp_dir/no-mistakes" "$install_dir/no-mistakes"
  ln -sfn "$install_dir/no-mistakes" "$link_dir/no-mistakes"
  "$install_dir/no-mistakes" daemon restart
  trap - RETURN
  rm -rf "$temp_dir"
  did "no-mistakes@$NO_MISTAKES_VERSION${installed:+ (was $installed)}"
}

install_axi_helpers() {
  echo "AXI helpers:"

  if ! command -v npm >/dev/null 2>&1; then
    skipped "AXI helpers: 'npm' is not on PATH"
    return 0
  fi

  local package version installed
  while IFS=' ' read -r package version; do
    [ -n "$package" ] || continue
    installed="$(npm_global_version "$package" || true)"
    if [ "$installed" = "$version" ]; then
      skipped "$package@$version (already installed)"
      continue
    fi
    if run_mutation npm install -g "$package@$version"; then
      did "$package@$version${installed:+ (was $installed)}"
    else
      echo "  [fail] $package@$version" >&2
      return 1
    fi
  done <<EOF
gh-axi $GH_AXI_VERSION
chrome-devtools-axi $CHROME_DEVTOOLS_AXI_VERSION
lavish-axi $LAVISH_AXI_VERSION
quota-axi $QUOTA_AXI_VERSION
EOF
}

# --- summary -----------------------------------------------------------------

print_summary() {
  echo
  echo "Summary"
  if [ "${#DONE_LINES[@]}" -eq 0 ]; then
    echo "  Changed: nothing (everything was already in place)"
  else
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "  Planned:"
    else
      echo "  Installed:"
    fi
    printf '    - %s\n' "${DONE_LINES[@]}"
  fi
  if [ "${#SKIPPED_LINES[@]}" -gt 0 ]; then
    echo "  Skipped:"
    printf '    - %s\n' "${SKIPPED_LINES[@]}"
  fi
}

main() {
  parse_args "$@"

  install_pi_packages

  if [ "$WITH_TOOLS" -eq 1 ]; then
    echo
    install_no_mistakes
    echo
    install_axi_helpers
  fi

  print_summary
}

main "$@"
