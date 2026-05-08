#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DOTFILES_DIR="$(cd "$AGENT_DIR/.." && pwd)"

SKILLS_SRC="$AGENT_DIR/skills"
MEMORY_SRC="$AGENT_DIR/memory/global.md"
MCP_SRC="$AGENT_DIR/mcps/mcp-servers.json"
CODEX_CONFIG_SRC="$AGENT_DIR/codex/config.toml"
CODEX_RULES_SRC="$AGENT_DIR/codex/rules"
CLAUDE_SRC="$AGENT_DIR/claude"
PI_SRC="$AGENT_DIR/pi"

CODEX_BEGIN="# BEGIN DOTFILES AGENT MCP"
CODEX_END="# END DOTFILES AGENT MCP"

usage() {
  cat <<'EOF'
Usage: sync-agent-config.sh [--check]

Synchronizes canonical dotfiles agent config into harness-specific locations:
  skills: Claude, Pi, Codex
  memory: Claude user memory, Codex developer instructions
  MCPs: Claude .mcp.json, Codex config.toml
  Codex config and command approval rules

Runtime state is intentionally left local.
EOF
}

backup_path() {
  local path="$1"
  local ts
  ts="$(date +%Y%m%d_%H%M%S)"
  mv "$path" "${path}.backup.${ts}"
  echo "  backed up $path -> ${path}.backup.${ts}"
}

link_path() {
  local label="$1"
  local src="$2"
  local dst="$3"

  mkdir -p "$(dirname "$dst")"

  if [ -L "$dst" ]; then
    local current
    current="$(readlink "$dst")"
    if [ "$current" = "$src" ]; then
      echo "  [ok] $label: $dst -> $src"
      return 0
    fi
    rm -f "$dst"
  elif [ -e "$dst" ]; then
    backup_path "$dst"
  fi

  ln -s "$src" "$dst"
  echo "  [ok] $label: $dst -> $src"
}

is_skill_dir() {
  [ -d "$1" ] && [ -f "$1/SKILL.md" ]
}

skill_name() {
  sed -n 's/^name:[[:space:]]*//p' "$1/SKILL.md" | head -1
}

check_skill_yaml() {
  python3 - "$1" <<'PY'
from pathlib import Path
import sys

try:
    import yaml
except Exception:
    sys.exit(0)

path = Path(sys.argv[1])
text = path.read_text()
if not text.startswith("---\n"):
    print(f"Invalid skill: {path.parent.name} missing YAML frontmatter", file=sys.stderr)
    sys.exit(1)

end = text.find("\n---", 4)
if end == -1:
    print(f"Invalid skill: {path.parent.name} missing closing frontmatter marker", file=sys.stderr)
    sys.exit(1)

try:
    data = yaml.safe_load(text[4:end]) or {}
except Exception as exc:
    print(f"Invalid skill YAML: {path}: {exc}", file=sys.stderr)
    sys.exit(1)

if not isinstance(data, dict):
    print(f"Invalid skill YAML: {path}: frontmatter must be a mapping", file=sys.stderr)
    sys.exit(1)
PY
}

check_skills() {
  local failed=0

  if [ ! -d "$SKILLS_SRC" ]; then
    echo "Missing canonical skills directory: $SKILLS_SRC" >&2
    return 1
  fi

  for skill_dir in "$SKILLS_SRC"/*; do
    [ -d "$skill_dir" ] || continue

    local base name
    base="$(basename "$skill_dir")"

    if ! is_skill_dir "$skill_dir"; then
      echo "Invalid skill: $base has no SKILL.md" >&2
      failed=1
      continue
    fi

    if ! check_skill_yaml "$skill_dir/SKILL.md"; then
      failed=1
      continue
    fi

    name="$(skill_name "$skill_dir")"
    if [ "$name" != "$base" ]; then
      echo "Invalid skill: $base has frontmatter name '$name'" >&2
      failed=1
    fi

    if ! sed -n '1,20p' "$skill_dir/SKILL.md" | grep -q '^description:'; then
      echo "Invalid skill: $base has no frontmatter description" >&2
      failed=1
    fi
  done

  return "$failed"
}

check_files() {
  local failed=0

  [ -f "$MEMORY_SRC" ] || { echo "Missing global memory: $MEMORY_SRC" >&2; failed=1; }
  [ -f "$MCP_SRC" ] || { echo "Missing MCP source: $MCP_SRC" >&2; failed=1; }
  [ -f "$CODEX_CONFIG_SRC" ] || { echo "Missing Codex config source: $CODEX_CONFIG_SRC" >&2; failed=1; }
  [ -f "$CODEX_RULES_SRC/default.rules" ] || { echo "Missing Codex rules source: $CODEX_RULES_SRC/default.rules" >&2; failed=1; }
  [ -x "$SCRIPT_DIR/codex-obsidian-memory-hook" ] || { echo "Missing executable Codex memory hook: $SCRIPT_DIR/codex-obsidian-memory-hook" >&2; failed=1; }
  [ -f "$CLAUDE_SRC/settings.json" ] || { echo "Missing Claude settings source: $CLAUDE_SRC/settings.json" >&2; failed=1; }
  [ -f "$CLAUDE_SRC/statusline-command.sh" ] || { echo "Missing Claude statusline source: $CLAUDE_SRC/statusline-command.sh" >&2; failed=1; }
  [ -d "$CLAUDE_SRC/templates" ] || { echo "Missing Claude templates source: $CLAUDE_SRC/templates" >&2; failed=1; }
  [ -f "$PI_SRC/settings.json" ] || { echo "Missing Pi settings source: $PI_SRC/settings.json" >&2; failed=1; }
  [ -d "$PI_SRC/agents" ] || { echo "Missing Pi agents source: $PI_SRC/agents" >&2; failed=1; }
  [ -d "$PI_SRC/extensions" ] || { echo "Missing Pi extensions source: $PI_SRC/extensions" >&2; failed=1; }

  if [ -f "$MCP_SRC" ]; then
    python3 -m json.tool "$MCP_SRC" >/dev/null || failed=1
  fi

  check_skills || failed=1
  return "$failed"
}

sync_skills() {
  link_path "Claude skills" "$SKILLS_SRC" "$HOME/.claude/skills"
  link_path "Pi skills" "$SKILLS_SRC" "$HOME/.pi/agent/skills"

  local codex_dir="$HOME/.codex/skills"
  mkdir -p "$codex_dir"

  for dst in "$codex_dir"/*; do
    [ -L "$dst" ] || continue

    local current
    current="$(readlink "$dst")"
    case "$current" in
      "$DOTFILES_DIR/skills"/*|"$SKILLS_SRC"/*)
        if [ ! -e "$current" ]; then
          rm -f "$dst"
          echo "  [removed] Codex stale skill link: $dst"
        fi
        ;;
    esac
  done

  for skill_dir in "$SKILLS_SRC"/*; do
    is_skill_dir "$skill_dir" || continue

    local name dst
    name="$(basename "$skill_dir")"
    dst="$codex_dir/$name"
    link_path "Codex skill $name" "$skill_dir" "$dst"
  done
}

sync_memory() {
  link_path "Claude global memory" "$MEMORY_SRC" "$HOME/.claude/CLAUDE.md"
  link_path "Home AGENTS.md" "$AGENT_DIR/AGENTS.md" "$HOME/AGENTS.md"
  link_path "Dotfiles AGENTS.md" "$AGENT_DIR/AGENTS.md" "$DOTFILES_DIR/AGENTS.md"
}

sync_claude_config() {
  link_path "Claude settings" "$CLAUDE_SRC/settings.json" "$HOME/.claude/settings.json"
  link_path "Claude statusline" "$CLAUDE_SRC/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
  link_path "Claude templates" "$CLAUDE_SRC/templates" "$HOME/.claude/templates"
}

sync_pi_config() {
  link_path "Pi settings" "$PI_SRC/settings.json" "$HOME/.pi/agent/settings.json"
  link_path "Pi agents" "$PI_SRC/agents" "$HOME/.pi/agent/agents"
  link_path "Pi extensions" "$PI_SRC/extensions" "$HOME/.pi/agent/extensions"
}

sync_claude_mcp() {
  if [ -L "$HOME/.mcp.json" ] || [ ! -e "$HOME/.mcp.json" ]; then
    link_path "Claude user MCP" "$MCP_SRC" "$HOME/.mcp.json"
  else
    echo "  [skip] $HOME/.mcp.json exists and is not a symlink"
  fi
}

json_string() {
  python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1"
}

generate_codex_mcp_block() {
  python3 - "$MCP_SRC" <<'PY'
import json
import sys

path = sys.argv[1]
data = json.load(open(path))

print("# BEGIN DOTFILES AGENT MCP")
for name, server in sorted(data.get("mcpServers", {}).items()):
    print(f"[mcp_servers.{name}]")
    if "command" in server:
        print(f"command = {json.dumps(server['command'])}")
    if "args" in server:
        args = ", ".join(json.dumps(str(arg)) for arg in server["args"])
        print(f"args = [{args}]")
    if "url" in server:
        print(f"url = {json.dumps(server['url'])}")
    if "env" in server:
        print("env = {")
        for key, value in sorted(server["env"].items()):
            print(f"  {json.dumps(key)} = {json.dumps(str(value))}")
        print("}")
    print()
print("# END DOTFILES AGENT MCP")
PY
}

sync_codex_config() {
  local config="$CODEX_CONFIG_SRC"
  local tmp
  mkdir -p "$(dirname "$config")"
  tmp="$(mktemp)"

  if [ -f "$config" ]; then
    awk -v begin="$CODEX_BEGIN" -v end="$CODEX_END" '
      $0 == begin { skip=1; next }
      $0 == end { skip=0; next }
      /^developer_instructions = "Read ~\/\.dotfiles\/agent\/AGENTS\.md/ { next }
      skip != 1 { print }
    ' "$config" > "$tmp"
  fi

  {
    sed '/^[[:space:]]*$/N;/^\n$/D' "$tmp"
    echo ""
    generate_codex_mcp_block
  } > "$tmp.next"

  mv "$tmp.next" "$config"
  rm -f "$tmp"
  echo "  [ok] Codex config MCP block updated: $config"
  link_path "Codex config" "$CODEX_CONFIG_SRC" "$HOME/.codex/config.toml"
}

sync_codex_rules() {
  link_path "Codex rules" "$CODEX_RULES_SRC" "$HOME/.codex/rules"
}

main() {
  case "${1:-}" in
    -h|--help)
      usage
      exit 0
      ;;
    --check)
      check_files
      exit $?
      ;;
    "")
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac

  check_files
  sync_skills
  sync_memory
  sync_claude_config
  sync_pi_config
  sync_claude_mcp
  sync_codex_config
  sync_codex_rules
}

main "$@"
