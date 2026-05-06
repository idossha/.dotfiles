# Agent Configuration

This directory is the source of truth for reusable agent-coding context.

## Layout

```text
agent/
  AGENTS.md                 # Portable coding-agent instructions
  memory/
    global.md               # Cross-harness global memory/instructions
  mcps/
    mcp-servers.json        # Canonical MCP server definitions
  claude/
    settings.json           # Durable Claude settings
    statusline-command.sh   # Claude statusline command
    templates/              # Claude templates
  codex/
    config.toml             # Durable Codex config, including project trust
    rules/default.rules     # Durable Codex command approval rules
  pi/
    settings.json           # Durable Pi settings
    agents/                 # Pi agents
    extensions/             # Pi extensions
  skills/
    <skill-name>/SKILL.md   # Reusable skills
  scripts/
    sync-agent-config.sh    # Links/generates harness-specific config
```

## Sync Model

Harnesses do not all read the same files. Keep canonical content here, then run:

```bash
~/.dotfiles/agent/scripts/sync-agent-config.sh
```

The sync script:

- links Claude skills to `agent/skills`
- links Pi skills to `agent/skills`
- links Codex skills per skill, preserving `~/.codex/skills/.system`
- links Claude settings/statusline/templates to `agent/claude`
- links Pi settings/agents/extensions to `agent/pi`
- links Claude global memory to `~/.claude/CLAUDE.md`
- links portable instructions to `~/AGENTS.md` and repo-root `AGENTS.md`
- writes `.mcp.json` from `agent/mcps/mcp-servers.json`
- updates `agent/codex/config.toml` with generated MCP server blocks
- links `~/.codex/config.toml` and `~/.codex/rules` to `agent/codex/`

Runtime state stays local: auth files, caches, logs, sessions, todos, managed
jobs, and project-specific memory are not committed to dotfiles.
