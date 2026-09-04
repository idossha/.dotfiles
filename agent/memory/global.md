# Global Agent Memory

User-level memory for every coding harness: linked to `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`
and `~/.pi/agent/AGENTS.md` by `~/.dotfiles/agent/scripts/sync-agent-config.sh`.

## Preferences

- Keep changes scoped and pragmatic.
- Prefer existing repo conventions over new abstractions.
- Protect user work and avoid destructive git operations unless explicitly
  requested.
- When setting up or configuring a git remote, always use SSH
  (`git@github.com:owner/repo.git`), never HTTPS with an embedded token.
- Use `rg`/`rg --files` for repository search when available.
- Put reusable agent instructions, MCP definitions, and skills under
  `~/.dotfiles/agent/`.
- Vault path: `/Users/idohaber/00_development/vault/`.
- Crystallized knowledge belongs in the Obsidian Zettelkasten.
- Project-specific memory belongs in Markdown inside the project directory.
- Raw logs and high-volume event memory belong in SQLite.
- Use `~/.dotfiles/agent/scripts/remember` for low-friction memory capture.

## Cross-project Playbook

- House engineering conventions are the `agentic-rules` playbook (local clone
  `/Users/idohaber/00_development/agentic-rules`, `docs/PRINCIPLES.md` is the spine). Its skills
  load in Claude Code as the plugin `agentic-rules:<skill>`, and in Pi and Codex from
  `~/.agents/skills`; use them without being asked: `project-docs` when
  starting or auditing a repo's markdown, `agent-instructions` for AGENTS.md/CLAUDE.md,
  `architecture-contract` when requirements, a contract or a decision are involved,
  `testing-backend` and `testing-frontend-offscreen` when adding tests, `docs-website` for a
  docs site, `changelog-release` for changelog entries, commits and releases, `ci-guards` for
  workflows and guards.
- Always-on rules from it: every rule states the failure it prevents; an agent judges
  numbers, not pictures; GUI and e2e tests run against a hidden app and never take the
  screen; AGENTS.md is canonical and CLAUDE.md imports it; commits carry no AI co-author
  trailers; a release script stops at the local tag and never pushes.
- Sessions run under herdr (one workspace per repository, agents visible in the sidebar);
  parallel work gets its own `herdr worktree`; inside a herdr pane (`HERDR_ENV=1`) the `herdr`
  skill controls panes and other agents. Unattended loops carry a cost or iteration cap.

## Boundaries

- Do not store secrets, API keys, tokens, or auth material here.
- Do not store large project-specific facts here. Use project-local memory or
  project docs instead.
- Do not treat session logs, caches, todos, or managed jobs as portable memory.
