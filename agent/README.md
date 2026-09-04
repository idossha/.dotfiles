# Agent Configuration

This directory is the source of truth for reusable agent-coding context.

## Layout

```text
agent/
  AGENTS.md                 # Portable coding-agent instructions
  memory/
    global.md               # Global memory, linked to ~/.claude/CLAUDE.md
  mcps/
    mcp-servers.json        # Canonical MCP server definitions
  claude/
    settings.json           # Durable Claude settings
    statusline-command.sh   # Claude statusline command
    templates/              # Claude templates
  pi/
    settings.json           # Pi global settings (packages pinned)
    extensions/             # Pi TypeScript extensions
    agents/                 # Pi subagent definitions (pi-subagents)
  codex/
    config.toml             # Codex config; the MCP block is generated from mcps/
    rules/                  # Codex execpolicy rules
  herdr/
    config.toml             # herdr session-manager config
  skills/
    <skill-name>/SKILL.md   # Reusable skills (personal and domain)
  scripts/
    sync-agent-config.sh    # Links this directory into ~/.claude, ~/.pi, ~/.codex, ~/.agents, ~/.config/herdr
    install-agent-tools.sh  # Opt-in: Pi packages, herdr integrations, the adopted external tools
  MULTI-HARNESS-PLAN.md     # The design: one canonical config, three harnesses, herdr as the session layer
```

Three harnesses are in use — Claude Code, Pi and Codex — under herdr as the session layer.
The retired 2026-07 harness configs under the repo-root `deprecated/` directory are the ancestors of
`pi/` and `codex/` and are kept for history only.

## Sync Model

Content here is canonical and version-controlled; `~/.claude` is a thin set of
symlinks pointing back at it. After editing anything in `agent/`, run:

```bash
~/.dotfiles/agent/scripts/sync-agent-config.sh
```

The sync script:

- links Claude skills to `agent/skills`, and generates `~/.agents/skills` as one symlink per skill
  (the skills here plus the agentic-rules playbook skills) for Pi and Codex
- links the global memory to `~/.claude/CLAUDE.md`, `~/.pi/agent/AGENTS.md` and `~/.codex/AGENTS.md`
- links Claude settings/statusline/templates to `agent/claude`
- links Pi settings, extensions, agents and prompts to `agent/pi`
- regenerates the Codex MCP block from `agent/mcps/mcp-servers.json`, then links `~/.codex/config.toml` and `rules`
- links `~/.mcp.json` (Claude) and `~/.agents/mcp.json` (Pi's MCP adapter) to `agent/mcps/mcp-servers.json`
- links `~/.config/herdr/config.toml` to `agent/herdr`
- links portable instructions to `~/AGENTS.md` and repo-root `AGENTS.md`

Runtime state stays local: auth files, caches, logs, sessions, todos, managed
jobs, and project-specific memory are not committed to dotfiles.
