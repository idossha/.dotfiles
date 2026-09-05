# Agent Platform

Source of truth for shared agent policy and adapters across Claude Code, Codex, and Pi, with one operator
CLI and an optional project-local delivery gate.

Start with [AGENTS.md](AGENTS.md), then [docs/PHILOSOPHY.md](docs/PHILOSOPHY.md),
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the contract, and [docs/ROADMAP.md](docs/ROADMAP.md).

## Layout

| Path | Owns |
|---|---|
| `AGENTS.md` | Portable routing and load-bearing global rules |
| `docs/` | Philosophy, current architecture, decisions, and roadmap |
| `projects.json` | Stable project names, repository paths, and delivery posture |
| `scripts/agentctl` | Doctor, sync, and shipping commands |
| `policy/global.md` | User-level policy shared by every harness |
| `skills/` | Personal and domain skills authored here exactly once |
| `mcps/mcp-servers.json` | Shared MCP server declarations |
| `claude/`, `codex/`, `pi/` | Thin harness-only settings and hooks |
| `tests/` | Nonmutating fixture-driven platform checks |

Cross-project testing, documentation, architecture, CI, commit, and release procedures live in the
separate `agentic-rules` repository and are installed as skills, never copied here.

## Operator Workflow

```bash
agent/scripts/agentctl doctor
agent/scripts/sync-agent-config.sh --check
agent/tests/run.sh
agent/scripts/agentctl sync
agent/scripts/agentctl ship dotfiles --intent "state the user's goal" --dry-run
```

The first three commands are nonmutating; `sync` renders or links effective harness configuration and
must run from the canonical checkout after changes land.

Agents work in the checkout they were launched in and do not create worktrees. Registered projects that
carry `.no-mistakes.yaml` ship through `agentctl ship`; others use ordinary PRs. Never push or merge red
work. `ship` runs the gate against the stated intent from a clean feature branch and schedules a guarded
auto-merge unless `--no-automerge` is passed; `--dry-run` prints the exact command. If a command is
missing, confirm `export PATH="$HOME/.local/bin:$PATH"` is in the shell configuration.

## Configuration Boundary

Tracked files contain stable policy. Generated destinations and gitignored overlays hold onboarding,
themes, trust hashes, changelog cursors, sessions, auth, caches, and other harness-written state. Edit
canonical files here, not live files under `~/.claude`, `~/.codex`, or `~/.pi`; operational detail is in
[docs/CONFIGURATION.md](docs/CONFIGURATION.md).

External tools are opt-in: `scripts/install-agent-tools.sh --tools` installs the pinned no-mistakes and
AXI helper CLIs recorded in [tools.env](tools.env).

## AXI helper workflow

Use AXI CLIs where they reduce agent turns without replacing project gates: `gh-axi` for GitHub reads and
writes, `chrome-devtools-axi` for browser exploration (Playwright and hidden-app tests remain the test
authority), `lavish-axi` for review artifacts too dense for a terminal, `quota-axi` for local quota
checks. Do not adopt AXI memory tools here: `idosleep` owns capture, recall, and consolidation.
