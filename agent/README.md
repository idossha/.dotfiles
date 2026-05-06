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
- links Claude global memory to `~/.claude/CLAUDE.md`
- links portable instructions to `~/AGENTS.md` and repo-root `AGENTS.md`
- writes `.mcp.json` from `agent/mcps/mcp-servers.json`
- updates `~/.codex/config.toml` with generated MCP server blocks

Runtime state stays local: auth files, caches, logs, sessions, todos, managed
jobs, and project-specific memory are not committed to dotfiles.
