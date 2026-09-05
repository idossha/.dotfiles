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
#   2. herdr integrations - refresh `herdr integration install pi` every run,
#      then install claude/codex only when `herdr integration status` is not current.
#
# Optional:
#   --tools                 Install the pinned adopted tools: Treehouse, GNHF,
#                           no-mistakes, AXI helper CLIs, and an external
#                           FirstMate checkout with Herdr backend plus
#                           token-aware dispatch config.
#   --dry-run               Print mutating commands without running them.
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

# shellcheck source=../tools.env
source "$AGENT_DIR/tools.env"
# shellcheck source=python-runtime.sh
source "$SCRIPT_DIR/python-runtime.sh"
AGENT_TOOLS_DIR="${AGENT_TOOLS_DIR:-$HOME/00_development/agent-tools}"
FIRSTMATE_DIR="${AGENTCTL_FIRSTMATE_DIR:-$AGENT_TOOLS_DIR/firstmate}"
FIRSTMATE_REMOTE="git@github.com:kunchenguid/firstmate.git"
FIRSTMATE_DISPATCH_TEMPLATE="$AGENT_DIR/firstmate/crew-dispatch.json"

WITH_TOOLS=0
REFRESH_HERDR_SKILL=0
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

write_firstmate_runtime_config() {
  if [ ! -f "$FIRSTMATE_DISPATCH_TEMPLATE" ]; then
    echo "  [fail] FirstMate dispatch template missing: $FIRSTMATE_DISPATCH_TEMPLATE" >&2
    return 1
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    print_command mkdir -p "$FIRSTMATE_DIR/config"
    printf '  [dry-run] write %q with value herdr\n' "$FIRSTMATE_DIR/config/backend"
    print_command install -m 0644 "$FIRSTMATE_DISPATCH_TEMPLATE" "$FIRSTMATE_DIR/config/crew-dispatch.json"
    return 0
  fi
  mkdir -p "$FIRSTMATE_DIR/config"
  printf 'herdr\n' > "$FIRSTMATE_DIR/config/backend"
  install -m 0644 "$FIRSTMATE_DISPATCH_TEMPLATE" "$FIRSTMATE_DIR/config/crew-dispatch.json"
}

usage() {
  sed -n '3,28p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      --tools) WITH_TOOLS=1 ;;
      --dry-run) DRY_RUN=1 ;;
      --refresh-herdr-skill) REFRESH_HERDR_SKILL=1 ;;
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
    if [ "$target" = pi ]; then
      if run_mutation herdr integration install pi; then
        did "herdr integration pi (refreshed after Herdr updates)"
      else
        echo "  [fail] herdr integration pi" >&2
        return 1
      fi
      continue
    fi
    if printf '%s\n' "$status" | grep -qE "^${target}: +(current|installed)([[:space:]]|$)"; then
      skipped "herdr integration $target (already current)"
      continue
    fi
    if run_mutation herdr integration install "$target"; then
      did "herdr integration $target"
    else
      echo "  [fail] herdr integration $target" >&2
      return 1
    fi
  done
}

# --- external tools (--tools) ------------------------------------------------

install_treehouse() {
  echo "Treehouse:"

  local installed=""
  if command -v treehouse >/dev/null 2>&1; then
    installed="$(treehouse --version 2>/dev/null | head -1 | tr -d '[:space:]' || true)"
  fi
  if [ "$installed" = "v$TREEHOUSE_VERSION" ]; then
    skipped "treehouse@$TREEHOUSE_VERSION (already installed)"
    return 0
  fi

  local os arch filename base_url install_dir
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"
  case "$os" in darwin|linux) ;; *) skipped "Treehouse: unsupported OS $os"; return 0 ;; esac
  case "$arch" in x86_64|amd64) arch=amd64 ;; arm64|aarch64) arch=arm64 ;; *) skipped "Treehouse: unsupported architecture $arch"; return 0 ;; esac
  filename="treehouse-v${TREEHOUSE_VERSION}-${os}-${arch}.tar.gz"
  base_url="https://github.com/kunchenguid/treehouse/releases/download/v${TREEHOUSE_VERSION}"
  install_dir="${TREEHOUSE_INSTALL_DIR:-$HOME/.local/bin}"

  if [ "$DRY_RUN" -eq 1 ]; then
    print_command curl -fsSL "$base_url/$filename" -o "<temporary>/$filename"
    print_command curl -fsSL "$base_url/checksums.txt" -o "<temporary>/checksums.txt"
    print_command install -m 755 "<verified temporary>/treehouse" "$install_dir/treehouse"
    did "treehouse@$TREEHOUSE_VERSION (planned)"
    return 0
  fi

  local temp_dir binary actual
  temp_dir="$(mktemp -d)"
  trap 'rm -rf "$temp_dir"' RETURN
  curl -fsSL "$base_url/$filename" -o "$temp_dir/$filename"
  curl -fsSL "$base_url/checksums.txt" -o "$temp_dir/checksums.txt"
  (cd "$temp_dir" && grep "  $filename\$" checksums.txt | shasum -a 256 -c -)
  tar xzf "$temp_dir/$filename" -C "$temp_dir"
  binary="$temp_dir/treehouse"
  if [ ! -f "$binary" ]; then
    binary="$(find "$temp_dir" -maxdepth 3 -type f -name treehouse | head -1)"
  fi
  [ -n "$binary" ] && [ -f "$binary" ] || {
    echo "  [fail] verified archive did not contain a treehouse binary" >&2
    return 1
  }
  mkdir -p "$install_dir"
  install -m 755 "$binary" "$install_dir/treehouse"
  actual="$("$install_dir/treehouse" --version 2>/dev/null | head -1 | tr -d '[:space:]')"
  [ "$actual" = "v$TREEHOUSE_VERSION" ] || {
    echo "  [fail] installed Treehouse version is ${actual:-unknown}; expected v$TREEHOUSE_VERSION" >&2
    return 1
  }
  trap - RETURN
  rm -rf "$temp_dir"
  did "treehouse@$TREEHOUSE_VERSION${installed:+ (was $installed)}"
}

install_gnhf() {
  echo "GNHF:"

  if ! command -v npm >/dev/null 2>&1; then
    skipped "GNHF: 'npm' is not on PATH"
    return 0
  fi

  local installed
  installed="$(npm_global_version gnhf || true)"
  if [ "$installed" = "$GNHF_VERSION" ]; then
    skipped "gnhf@$GNHF_VERSION (already installed)"
    return 0
  fi

  run_mutation npm install -g "gnhf@$GNHF_VERSION"
  did "gnhf@$GNHF_VERSION${installed:+ (was $installed)}"
}

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

install_firstmate() {
  echo "FirstMate:"
  if ! command -v git >/dev/null 2>&1; then
    skipped "FirstMate: 'git' is not on PATH"
    return 0
  fi

  if [ ! -d "$FIRSTMATE_DIR/.git" ]; then
    run_mutation mkdir -p "$AGENT_TOOLS_DIR"
    run_mutation git clone "$FIRSTMATE_REMOTE" "$FIRSTMATE_DIR"
  elif [ "$DRY_RUN" -eq 0 ]; then
    local remote
    remote="$(git -C "$FIRSTMATE_DIR" remote get-url origin 2>/dev/null || true)"
    [ "$remote" = "$FIRSTMATE_REMOTE" ] || {
      echo "  [fail] refusing to modify an existing checkout with unexpected origin: ${remote:-none}" >&2
      return 1
    }
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    print_command git -C "$FIRSTMATE_DIR" fetch origin "$FIRSTMATE_COMMIT"
    print_command git -C "$FIRSTMATE_DIR" checkout --detach "$FIRSTMATE_COMMIT"
    write_firstmate_runtime_config || return 1
    did "FirstMate@$FIRSTMATE_COMMIT with Herdr backend and token-aware dispatch (planned)"
    return 0
  fi

  git -C "$FIRSTMATE_DIR" fetch origin "$FIRSTMATE_COMMIT"
  git -C "$FIRSTMATE_DIR" checkout --detach "$FIRSTMATE_COMMIT"
  write_firstmate_runtime_config || return 1
  did "FirstMate@$FIRSTMATE_COMMIT with Herdr backend and token-aware dispatch"
}

# --- vendored herdr skill (--refresh-herdr-skill) ----------------------------

refresh_herdr_skill() {
  echo "Vendored herdr skill:"

  if ! command -v herdr >/dev/null 2>&1; then
    echo "  [fail] 'herdr' is not on PATH" >&2
    return 1
  fi

  run_mutation mkdir -p "$HERDR_SKILL_DIR"

  if [ "$DRY_RUN" -eq 1 ]; then
    print_command herdr --skill
    did "would regenerate ${HERDR_SKILL_DIR#"$AGENT_DIR"/}/SKILL.md"
    return 0
  fi

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
    install_treehouse
    echo
    install_gnhf
    echo
    install_no_mistakes
    echo
    install_axi_helpers
    echo
    install_firstmate
  fi

  print_summary
}

main "$@"
