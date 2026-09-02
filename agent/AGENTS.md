# Agent Instructions

Use this as the instruction entry point for coding agents. Claude Code is the
harness in use; this file is linked to `~/AGENTS.md` and the repo-root
`AGENTS.md`.

## Source of Truth

Reusable agent configuration lives in `~/.dotfiles/agent/`:

- skills: `~/.dotfiles/agent/skills`
- global memory: `~/.dotfiles/agent/memory/global.md`
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
- Keep the Claude adapter thin. Canonical content belongs in `agent/`, not
  under `.claude` directly.

## Cross-project Playbook

Engineering conventions shared across projects live in the `agentic-rules` plugin
(canonical repo `git@github.com:idossha/agentic-rules.git`; local clone
`/Users/idohaber/00_development/agentic-rules`). Read its `docs/PRINCIPLES.md` before
setting up, documenting, testing or releasing a project; its skills load as
`agentic-rules:<skill>` and are meant to be used unprompted:

- `project-docs` — the markdown roster (README, CONTRIBUTING, SECURITY, CITATION, docs/).
- `agent-instructions` — AGENTS.md as a map, CLAUDE.md as `@AGENTS.md`, path-scoped rules.
- `architecture-contract` — intent documents with gate tests, the contract, the decision log.
- `testing-backend` / `testing-frontend-offscreen` — fixtures from an independent reader;
  GUI tests hidden by default and proved quiet.
- `docs-website` — a VitePress site generated from `docs/`.
- `changelog-release` — Keep a Changelog entries, commit messages, a release that stops at the tag.
- `ci-guards` — CI split by cost, guards with their own red tests.

Dotfiles carry only the marketplace registration and the enable flag in
`agent/claude/settings.json`, never a copy of those skills: a second copy loads the same
skill twice. Edit the plugin in its own repository; after a push, run
`claude plugin update agentic-rules@agentic-rules` (the installed plugin is a snapshot).

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
