# Agent Instructions

Use this as the portable instruction entry point for coding agents.

## Source of Truth

Reusable agent configuration lives in `~/.dotfiles/agent/`:

- skills: `~/.dotfiles/agent/skills`
- shared memory: `~/.dotfiles/agent/memory/global.md`
- MCP definitions: `~/.dotfiles/agent/mcps/mcp-servers.json`

After editing those files, run:

```bash
~/.dotfiles/agent/scripts/sync-agent-config.sh
```

## Operating Rules

- Preserve user work. Inspect status/diffs before mutating git state.
- Keep reusable instructions in `agent/`; keep project-specific facts in the
  project's own `AGENTS.md`, `CLAUDE.md`, or memory files.
- Do not commit runtime state, auth files, caches, logs, sessions, or local
  project memories.
- Prefer official docs and configured MCP servers for API or tool questions.
- Keep harness adapters thin. Canonical content belongs in `agent/`, not under
  `.claude`, `.pi`, or `.codex` directly.

## Memory Routing

- Crystallized, reusable knowledge goes to the Obsidian Zettelkasten:
  `/Users/idohaber/00_development/vault/Zettelkasten`.
- Project-specific knowledge goes to Markdown in the project directory,
  usually `memory/agent-memory.md` or a project `AGENTS.md`.
- Raw logs, session events, telemetry, and high-volume machine-readable memory
  go to SQLite, not Obsidian.
- Use `~/.dotfiles/agent/scripts/remember` for low-friction memory writes.
- At task end, only write memory when the session produced durable knowledge.
  Ask first if the memory is sensitive, ambiguous, or project-specific.
