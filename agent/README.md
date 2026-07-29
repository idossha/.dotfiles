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
  skills/
    <skill-name>/SKILL.md   # Reusable skills
  scripts/
    sync-agent-config.sh    # Links this directory into ~/.claude
```

Claude Code is the only harness in use. Retired harness config (Codex, Pi)
lives under the repo-root `deprecated/` directory and is not synced.

## Sync Model

Content here is canonical and version-controlled; `~/.claude` is a thin set of
symlinks pointing back at it. After editing anything in `agent/`, run:

```bash
~/.dotfiles/agent/scripts/sync-agent-config.sh
```

The sync script:

- links Claude skills to `agent/skills`
- links Claude settings/statusline/templates to `agent/claude`
- links Claude global memory to `~/.claude/CLAUDE.md`
- links portable instructions to `~/AGENTS.md` and repo-root `AGENTS.md`
- links `~/.mcp.json` to `agent/mcps/mcp-servers.json`

Runtime state stays local: auth files, caches, logs, sessions, todos, managed
jobs, and project-specific memory are not committed to dotfiles.
