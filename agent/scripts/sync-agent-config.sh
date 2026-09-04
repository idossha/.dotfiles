#!/usr/bin/env bash
#
# Link the canonical agent configuration in ~/.dotfiles/agent into every harness that reads it:
# Claude Code (~/.claude), Pi (~/.pi/agent), Codex (~/.codex), the tool-agnostic ~/.agents
# directory that Pi and Codex both read natively, and herdr (~/.config/herdr).
#
# Stable policy is canonical and version-controlled here. Harness settings that the tools mutate are
# rendered as real files from tracked policy plus gitignored agent/local overlays. Other destinations
# remain symlinks. Runtime state (auth, sessions, caches, logs) is never touched.
#
#   sync-agent-config.sh            # validate, then link everything
#   sync-agent-config.sh --check    # validate only
#
# Skills: the whole skills tree is linked to ~/.claude/skills (Claude reads only that path), and
# ~/.agents/skills is a generated directory of one symlink per skill — the maintainer's skills from
# agent/skills plus the agentic-rules playbook skills from $AGENTIC_RULES_DIR/skills. Pi and Codex
# read ~/.agents/skills natively, so nothing is copied and an edit is live in every harness. Claude
# gets the playbook as a plugin instead (namespaced agentic-rules:<skill>), which is why those
# skills are never linked under ~/.claude/skills: a second copy would load twice.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DOTFILES_DIR="$(cd "$AGENT_DIR/.." && pwd)"

SKILLS_SRC="$AGENT_DIR/skills"
MEMORY_SRC="$AGENT_DIR/memory/global.md"
MCP_SRC="$AGENT_DIR/mcps/mcp-servers.json"
CLAUDE_SRC="$AGENT_DIR/claude"
PI_SRC="$AGENT_DIR/pi"
CODEX_SRC="$AGENT_DIR/codex"
HERDR_SRC="$AGENT_DIR/herdr"
LOCAL_DIR="$AGENT_DIR/local"
CLAUDE_LOCAL="$LOCAL_DIR/claude-settings.local.json"
PI_LOCAL="$LOCAL_DIR/pi-settings.local.json"
CODEX_LOCAL="$LOCAL_DIR/codex-config.local.toml"
CODEX_RULES_LOCAL="$LOCAL_DIR/codex-rules.local.rules"
# The playbook repository (github.com/idossha/agentic-rules). Its skills are linked into
# ~/.agents/skills when the clone exists; absent, the link step is skipped with a note.
AGENTIC_RULES_DIR="${AGENTIC_RULES_DIR:-$HOME/00_development/agentic-rules}"

usage() {
  cat <<'USAGE'
Usage: sync-agent-config.sh [--check]

Synchronizes canonical dotfiles agent config into every harness:
  Claude Code : ~/.claude/skills, ~/.claude/CLAUDE.md, settings, statusline, templates, ~/.mcp.json
  Pi          : ~/.pi/agent/{settings.json,extensions,agents,prompts,AGENTS.md}
  Codex       : ~/.codex/{config.toml,rules,AGENTS.md}  (MCP block regenerated from mcp-servers.json)
  ~/.agents   : skills/ (one link per skill, incl. agentic-rules) and mcp.json (Pi + Codex read both)
  herdr       : ~/.config/herdr/config.toml
  AGENTS.md   : ~/AGENTS.md and the dotfiles root

Harness-written settings are preserved in ignored agent/local overlays. --check validates and writes nothing.
USAGE
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

# Move a stale real directory aside. Used for paths a harness would read in ADDITION to the linked
# one (e.g. ~/.pi/agent/skills beside ~/.agents/skills), where leaving old copies loads a skill twice.
retire_path() {
  local label="$1"
  local path="$2"
  if [ -L "$path" ]; then
    # A link (the pre-2026-09 layout pointed ~/.pi/agent/skills at the dotfiles tree) loads the
    # same skills a second time beside ~/.agents/skills; removing a link loses nothing.
    rm -f "$path"
    echo "  [ok] $label: removed duplicate link"
  elif [ -d "$path" ]; then
    backup_path "$path"
    echo "  [ok] $label: retired stale copy"
  fi
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

check_skills_in() {
  local root="$1"
  local failed=0
  for skill_dir in "$root"/*; do
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

check_skills() {
  if [ ! -d "$SKILLS_SRC" ]; then
    echo "Missing canonical skills directory: $SKILLS_SRC" >&2
    return 1
  fi
  local failed=0
  check_skills_in "$SKILLS_SRC" || failed=1
  if [ -d "$AGENTIC_RULES_DIR/skills" ]; then
    check_skills_in "$AGENTIC_RULES_DIR/skills" || failed=1
    # A name present in both trees would be one skill loaded twice under ~/.agents/skills.
    for d in "$AGENTIC_RULES_DIR"/skills/*/; do
      local n
      n="$(basename "$d")"
      if [ -d "$SKILLS_SRC/$n" ]; then
        echo "Skill name collision: $n exists in both agent/skills and agentic-rules/skills" >&2
        failed=1
      fi
    done
  fi
  return "$failed"
}

check_json() { python3 -m json.tool "$1" >/dev/null; }
check_toml() { python3 -c 'import tomllib,sys; tomllib.load(open(sys.argv[1],"rb"))' "$1"; }

check_files() {
  local failed=0

  [ -f "$MEMORY_SRC" ] || { echo "Missing global memory: $MEMORY_SRC" >&2; failed=1; }
  [ -f "$MCP_SRC" ] || { echo "Missing MCP source: $MCP_SRC" >&2; failed=1; }
  [ -f "$CLAUDE_SRC/settings.json" ] || { echo "Missing Claude settings source: $CLAUDE_SRC/settings.json" >&2; failed=1; }
  [ -f "$CLAUDE_SRC/statusline-command.sh" ] || { echo "Missing Claude statusline source: $CLAUDE_SRC/statusline-command.sh" >&2; failed=1; }
  [ -d "$CLAUDE_SRC/templates" ] || { echo "Missing Claude templates source: $CLAUDE_SRC/templates" >&2; failed=1; }
  [ -f "$PI_SRC/settings.json" ] || { echo "Missing Pi settings source: $PI_SRC/settings.json" >&2; failed=1; }
  [ -d "$PI_SRC/extensions" ] || { echo "Missing Pi extensions source: $PI_SRC/extensions" >&2; failed=1; }
  [ -d "$PI_SRC/agents" ] || { echo "Missing Pi agents source: $PI_SRC/agents" >&2; failed=1; }
  [ -d "$PI_SRC/prompts" ] || { echo "Missing Pi prompts source: $PI_SRC/prompts" >&2; failed=1; }
  [ -f "$CODEX_SRC/config.toml" ] || { echo "Missing Codex config source: $CODEX_SRC/config.toml" >&2; failed=1; }
  [ -d "$CODEX_SRC/rules" ] || { echo "Missing Codex rules source: $CODEX_SRC/rules" >&2; failed=1; }
  [ -f "$HERDR_SRC/config.toml" ] || { echo "Missing herdr config source: $HERDR_SRC/config.toml" >&2; failed=1; }

  [ -f "$MCP_SRC" ] && { check_json "$MCP_SRC" || failed=1; }
  [ -f "$CLAUDE_SRC/settings.json" ] && { check_json "$CLAUDE_SRC/settings.json" || failed=1; }
  [ -f "$PI_SRC/settings.json" ] && { check_json "$PI_SRC/settings.json" || failed=1; }
  [ -f "$CODEX_SRC/config.toml" ] && { check_toml "$CODEX_SRC/config.toml" || failed=1; }
  [ -f "$HERDR_SRC/config.toml" ] && { check_toml "$HERDR_SRC/config.toml" || failed=1; }
  [ ! -f "$CLAUDE_LOCAL" ] || { check_json "$CLAUDE_LOCAL" || failed=1; }
  [ ! -f "$PI_LOCAL" ] || { check_json "$PI_LOCAL" || failed=1; }
  [ ! -f "$CODEX_LOCAL" ] || { check_toml "$CODEX_LOCAL" || failed=1; }

  python3 - "$CLAUDE_SRC/settings.json" "$PI_SRC/settings.json" "$CODEX_SRC/config.toml" <<'PY' || failed=1
import json, re, sys
claude, pi, codex = sys.argv[1:]
checks = [
    (claude, set(json.load(open(claude))) & {"autoMode", "theme"}),
    (pi, set(json.load(open(pi))) & {"lastChangelogVersion", "theme"}),
]
for path, found in checks:
    if found:
        print(f"Harness-written fields remain in tracked policy {path}: {', '.join(sorted(found))}", file=sys.stderr)
        raise SystemExit(1)
runtime = re.compile(r'^\[(?:projects\.|hooks\.state(?:\.|\])|tui\.model_availability_nux\])', re.M)
if runtime.search(open(codex).read()):
    print(f"Harness-written sections remain in tracked policy {codex}", file=sys.stderr)
    raise SystemExit(1)
PY

  # Every Pi agent file needs a name and a description, or the subagent tool cannot list it.
  for f in "$PI_SRC"/agents/*.md; do
    [ -f "$f" ] || continue
    sed -n '1,15p' "$f" | grep -q '^name:' || { echo "Pi agent $f has no name" >&2; failed=1; }
    sed -n '1,15p' "$f" | grep -q '^description:' || { echo "Pi agent $f has no description" >&2; failed=1; }
  done

  if [ ! -d "$AGENTIC_RULES_DIR/skills" ]; then
    echo "  [note] agentic-rules not found at $AGENTIC_RULES_DIR — playbook skills will not be linked for Pi/Codex."
    echo "         Clone it: git clone git@github.com:idossha/agentic-rules.git $AGENTIC_RULES_DIR"
  fi

  check_skills || failed=1
  return "$failed"
}

# Rewrite the [mcp_servers.*] block in the canonical Codex config from the canonical JSON, between
# the two marker lines, so the three harnesses read one list. Codex's TOML shape: command + args.
render_codex_config() {
  local dst="$1" tmp
  mkdir -p "$LOCAL_DIR" "$(dirname "$dst")"
  tmp="$(mktemp "${TMPDIR:-/tmp}/codex-config.XXXXXX")"
  python3 - "$MCP_SRC" "$CODEX_SRC/config.toml" "$CODEX_LOCAL" "$dst" "$tmp" <<'PY'
import json, sys
mcp_path, policy_path, local_path, effective_path, output_path = sys.argv[1:]
servers = json.load(open(mcp_path)).get("mcpServers", {})
lines = ["# BEGIN DOTFILES AGENT MCP", "# Generated by agent/scripts/sync-agent-config.sh from agent/mcps/mcp-servers.json — edit the JSON."]
for name in sorted(servers):
    s = servers[name]
    lines.append(f"[mcp_servers.{name}]")
    if "command" in s:
        lines.append(f'command = {json.dumps(s["command"])}')
        lines.append(f'args = {json.dumps(s.get("args", []))}')
        if s.get("env"):
            env = ", ".join(f'{k} = {json.dumps(v)}' for k, v in s["env"].items())
            lines.append(f"env = {{ {env} }}")
    elif "url" in s:
        lines.append(f'url = {json.dumps(s["url"])}')
    lines.append("")
lines.append("# END DOTFILES AGENT MCP")
block = "\n".join(lines)
text = open(policy_path).read()
start, end = "# BEGIN DOTFILES AGENT MCP", "# END DOTFILES AGENT MCP"
if start in text and end in text:
    head = text[: text.index(start)]
    tail = text[text.index(end) + len(end):]
    new = head + block + tail
else:
    new = text.rstrip("\n") + "\n\n" + block + "\n"
def sections(value):
    chunks, current = [], []
    for line in value.splitlines(keepends=True):
        if line.startswith("[") and current:
            chunks.append("".join(current))
            current = []
        current.append(line)
    if current:
        chunks.append("".join(current))
    return chunks

def runtime(chunk):
    first = chunk.splitlines()[0] if chunk.splitlines() else ""
    return (first.startswith("[projects.") or first == "[hooks.state]" or
            first.startswith("[hooks.state.") or first == "[tui.model_availability_nux]")

saved = open(local_path).read() if __import__('os').path.isfile(local_path) else ""
effective = open(effective_path).read() if __import__('os').path.isfile(effective_path) else ""
by_header = {}
for source in (saved, effective):
    for chunk in sections(source):
        if runtime(chunk):
            by_header[chunk.splitlines()[0]] = chunk.rstrip() + "\n"
runtime_text = "\n".join(by_header.values())
open(local_path, "w").write(runtime_text)
open(output_path, "w").write(new.rstrip() + ("\n\n" + runtime_text if runtime_text else "\n"))
PY
  [ ! -L "$dst" ] || rm -f "$dst"
  mv "$tmp" "$dst"
  echo "  [ok] Codex config rendered from policy, MCP declaration, and local state"
}

render_json_settings() {
  local label="$1" policy="$2" overlay="$3" dst="$4" keys="$5" tmp
  mkdir -p "$LOCAL_DIR" "$(dirname "$dst")"
  tmp="$(mktemp "${TMPDIR:-/tmp}/agent-settings.XXXXXX")"
  python3 - "$policy" "$overlay" "$dst" "$tmp" "$keys" <<'PY'
import json, os, sys
policy_path, overlay_path, effective_path, output_path, key_text = sys.argv[1:]
keys = key_text.split(',')
policy = json.load(open(policy_path))
state = json.load(open(overlay_path)) if os.path.isfile(overlay_path) else {}
if os.path.isfile(effective_path):
    effective = json.load(open(effective_path))
    state.update({key: effective[key] for key in keys if key in effective})
with open(overlay_path, 'w') as f:
    json.dump(state, f, indent=2, ensure_ascii=False)
    f.write('\n')
policy.update(state)
with open(output_path, 'w') as f:
    json.dump(policy, f, indent=2, ensure_ascii=False)
    f.write('\n')
PY
  [ ! -L "$dst" ] || rm -f "$dst"
  mv "$tmp" "$dst"
  echo "  [ok] $label rendered from tracked policy and local state"
}

render_codex_rules() {
  local dst="$HOME/.codex/rules/default.rules" tmp
  mkdir -p "$LOCAL_DIR"
  if [ -L "$HOME/.codex/rules" ]; then
    rm -f "$HOME/.codex/rules"
  fi
  mkdir -p "$HOME/.codex/rules"
  tmp="$(mktemp "${TMPDIR:-/tmp}/codex-rules.XXXXXX")"
  python3 - "$CODEX_SRC/rules/default.rules" "$CODEX_RULES_LOCAL" "$dst" "$tmp" <<'PY'
from pathlib import Path
import sys
policy_path, local_path, effective_path, output_path = map(Path, sys.argv[1:])
policy = policy_path.read_text()
policy_lines = set(policy.splitlines())
local = local_path.read_text() if local_path.is_file() else ""
effective = effective_path.read_text() if effective_path.is_file() else ""
extras, seen = [], set()
for line in (local + "\n" + effective).splitlines():
    if line.strip() and line not in policy_lines and line not in seen:
        extras.append(line)
        seen.add(line)
local_path.write_text("\n".join(extras) + ("\n" if extras else ""))
output_path.write_text(policy.rstrip() + ("\n\n# Harness-approved local rules\n" + "\n".join(extras) if extras else "") + "\n")
PY
  mv "$tmp" "$dst"
  echo "  [ok] Codex rules rendered from tracked policy and local approvals"
}

sync_skills() {
  link_path "Claude skills" "$SKILLS_SRC" "$HOME/.claude/skills"

  # ~/.agents/skills is generated: a real directory holding one symlink per skill. Pi and Codex
  # read it natively (Pi also reads ~/.pi/agent/skills, retired below so nothing loads twice).
  local agents_skills="$HOME/.agents/skills"
  if [ -L "$agents_skills" ]; then
    rm -f "$agents_skills"
  elif [ -d "$agents_skills" ] && [ -z "$(find "$agents_skills" -maxdepth 1 -mindepth 1 ! -type l 2>/dev/null | head -1)" ]; then
    : # already a directory of symlinks
  elif [ -e "$agents_skills" ]; then
    backup_path "$agents_skills"
  fi
  mkdir -p "$agents_skills"
  # Drop links that point nowhere (a renamed or removed skill).
  find "$agents_skills" -maxdepth 1 -mindepth 1 -type l ! -exec test -e {} \; -delete 2>/dev/null || true
  local n=0
  for d in "$SKILLS_SRC"/*/; do
    is_skill_dir "$d" || continue
    link_path "agents skill" "${d%/}" "$agents_skills/$(basename "$d")" >/dev/null
    n=$((n + 1))
  done
  if [ -d "$AGENTIC_RULES_DIR/skills" ]; then
    for d in "$AGENTIC_RULES_DIR"/skills/*/; do
      is_skill_dir "$d" || continue
      link_path "agentic-rules skill" "${d%/}" "$agents_skills/$(basename "$d")" >/dev/null
      n=$((n + 1))
    done
  fi
  echo "  [ok] ~/.agents/skills: $n skill links (Pi + Codex)"
  retire_path "Pi legacy skills dir" "$HOME/.pi/agent/skills"
}

sync_memory() {
  link_path "Claude global memory" "$MEMORY_SRC" "$HOME/.claude/CLAUDE.md"
  link_path "Pi global instructions" "$MEMORY_SRC" "$HOME/.pi/agent/AGENTS.md"
  link_path "Codex global instructions" "$MEMORY_SRC" "$HOME/.codex/AGENTS.md"
  link_path "Home AGENTS.md" "$AGENT_DIR/AGENTS.md" "$HOME/AGENTS.md"
  link_path "Dotfiles AGENTS.md" "$AGENT_DIR/AGENTS.md" "$DOTFILES_DIR/AGENTS.md"
}

sync_claude_config() {
  render_json_settings "Claude settings" "$CLAUDE_SRC/settings.json" "$CLAUDE_LOCAL" "$HOME/.claude/settings.json" "autoMode,theme"
  link_path "Claude statusline" "$CLAUDE_SRC/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
  link_path "Claude templates" "$CLAUDE_SRC/templates" "$HOME/.claude/templates"
}

sync_mcp() {
  if [ -L "$HOME/.mcp.json" ] || [ ! -e "$HOME/.mcp.json" ]; then
    link_path "Claude user MCP" "$MCP_SRC" "$HOME/.mcp.json"
  else
    echo "  [skip] $HOME/.mcp.json exists and is not a symlink"
  fi
  # pi-mcp-adapter reads ~/.agents/mcp.json (same mcpServers schema); Codex gets the TOML block.
  link_path "agents MCP" "$MCP_SRC" "$HOME/.agents/mcp.json"
}

sync_pi() {
  render_json_settings "Pi settings" "$PI_SRC/settings.json" "$PI_LOCAL" "$HOME/.pi/agent/settings.json" "lastChangelogVersion,theme"
  link_path "Pi extensions" "$PI_SRC/extensions" "$HOME/.pi/agent/extensions"
  link_path "Pi agents" "$PI_SRC/agents" "$HOME/.pi/agent/agents"
  link_path "Pi prompts" "$PI_SRC/prompts" "$HOME/.pi/agent/prompts"
}

sync_codex() {
  render_codex_config "$HOME/.codex/config.toml"
  render_codex_rules
}

sync_herdr() {
  link_path "herdr config" "$HERDR_SRC/config.toml" "$HOME/.config/herdr/config.toml"
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
  sync_mcp
  sync_pi
  sync_codex
  sync_herdr
  echo "  next: agent/scripts/install-agent-tools.sh installs Pi packages and herdr integrations (opt-in)."
}

main "$@"
