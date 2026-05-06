# Global Agent Memory

This file is shared user-level memory for agentic coding harnesses.

## Preferences

- Keep changes scoped and pragmatic.
- Prefer existing repo conventions over new abstractions.
- Protect user work and avoid destructive git operations unless explicitly
  requested.
- Use `rg`/`rg --files` for repository search when available.
- Put reusable agent instructions, MCP definitions, and skills under
  `~/.dotfiles/agent/`.
- Vault path: `/Users/idohaber/00_development/vault/`.
- Crystallized knowledge belongs in the Obsidian Zettelkasten.
- Project-specific memory belongs in Markdown inside the project directory.
- Raw logs and high-volume event memory belong in SQLite.
- Use `~/.dotfiles/agent/scripts/remember` for low-friction memory capture.

## Boundaries

- Do not store secrets, API keys, tokens, or auth material here.
- Do not store large project-specific facts here. Use project-local memory or
  project docs instead.
- Do not treat session logs, caches, todos, or managed jobs as portable memory.
