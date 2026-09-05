# Global Agent Policy

User-level policy for every coding harness: imported by Claude and linked to `~/.codex/AGENTS.md`
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
- How the platform is shaped and why: `~/.dotfiles/agent/docs/PHILOSOPHY.md` (skills teach, CLIs act,
  MCP exposes).
- Agents work in the checkout they were launched in and do not create worktrees; a second checkout
  splits ownership of a branch between processes that cannot see each other.
- Agent memory capture, recall, and consolidation belong to `idosleep`; do not add a second memory
  router, CLI, or store under dotfiles.
- Project facts that must guide every agent or be reviewed with code belong in project Markdown;
  architecture decisions belong in `docs/DECISIONS.md`.
- Prefer AXI helper CLIs when available: `gh-axi` for GitHub reads/writes, `chrome-devtools-axi` for
  browser exploration, `lavish-axi` for rich review artifacts, and `quota-axi` for local quota checks.
  Do not add an AXI memory tool; `idosleep` owns memory.
- Registered projects that carry `.no-mistakes.yaml` ship through `agentctl ship`; others use ordinary
  PRs. Never push or merge red work. Guarded automatic merge applies only to green, in-scope PRs; red,
  destructive, irreversible, security-sensitive, or out-of-scope work still escalates.
- Keep conversational output to a minimal outcome, evidence, and next action. When an explanation
  needs a diagram, comparison, plan, dense table, or extended walkthrough, create a local Lavish HTML
  artifact and reply with only a short synopsis plus its path; long chat output is hard to scan and annotate.
- Avoid optional confirmation questions by using established defaults and approved narrow command
  surfaces. Mandatory safety, authorization, destructive-action, secret, and consequential external-state
  boundaries require a user decision only when existing session authorization does not cover them;
  never ask again for authority already granted. Harness enforcement still applies.

## Cross-project Playbook

- House engineering conventions are the `agentic-rules` playbook (local clone
  `/Users/idohaber/00_development/agentic-rules`, `docs/PRINCIPLES.md` is the spine). Its skills
  load from the same local source through generated links in `~/.claude/skills` and
  `~/.agents/skills`; the duplicate Claude plugin is disabled; use them without being asked: `project-docs` when
  starting or auditing a repo's markdown, `agent-instructions` for AGENTS.md/CLAUDE.md,
  `architecture-contract` when requirements, a contract or a decision are involved,
  `testing-backend` and `testing-frontend-offscreen` when adding tests, `docs-website` for a
  docs site, `changelog-release` for changelog entries, commits and releases, `ci-guards` for
  workflows and guards.
- Always-on rules from it: every rule states the failure it prevents; an agent judges
  numbers, not pictures; GUI and e2e tests run against a hidden app and never take the
  screen; AGENTS.md is canonical and CLAUDE.md imports it; commits carry no AI co-author
  trailers; a release script stops at the local tag and never pushes.

## Boundaries

- Do not store secrets, API keys, tokens, or auth material here.
- Do not store large project-specific facts here. Use project docs instead.
- Do not treat session logs, caches, todos, managed jobs, or `idosleep` traces as portable policy.

- Invocation metadata, orchestration tools and plugins do not grant authority. Shared procedures state
  essential constraints in prose because provider-specific frontmatter and permission behavior differ.
- Native run logs stay with their runtime owner; `idosleep` owns any deliberate memory capture and recall.
