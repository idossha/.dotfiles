# Agent Platform

This directory is the source of truth for shared agent policy and adapters across Claude Code, Codex,
and Pi. Herdr supplies visible multi-project sessions, Treehouse owns pooled worktrees, and FirstMate,
GNHF, and no-mistakes are optional upstream tools launched through one operator CLI.

Start with [AGENTS.md](AGENTS.md), then read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the contract
and [docs/ROADMAP.md](docs/ROADMAP.md) for incomplete gates.

## Layout

| Path | Owns |
|---|---|
| `AGENTS.md` | Portable routing and load-bearing global rules |
| `docs/` | Requirements, current architecture, decisions, and roadmap |
| `projects.json` | Stable project names, repository paths, and optional visualizations |
| `scripts/agentctl` | Doctor, sync, project, fleet, overnight, and shipping commands |
| `policy/global.md` | User-level policy shared by every harness |
| `skills/` | Personal and domain skills authored here exactly once |
| `mcps/mcp-servers.json` | Shared MCP server declarations |
| `claude/`, `codex/`, `pi/` | Thin harness-only settings and hooks |
| `herdr/` | Session and multiplexing configuration |
| `treehouse/` | Worktree policy, lease lifecycle, and native jump commands |
| `tests/` | Nonmutating fixture-driven platform checks |

Cross-project testing, documentation, architecture, CI, commit, and release procedures live in the
separate `agentic-rules` repository and are installed as skills. They are intentionally not copied here.

## Operator Workflow

```bash
agent/scripts/agentctl doctor
agentctl start
agent/scripts/agentctl project dotfiles
treehouse status
treehouse enter 1
agent/scripts/agentctl fleet --harness pi
agent/scripts/agentctl overnight dotfiles --max-iterations 3 --dry-run -- "address the accepted issues"
agent/scripts/agentctl ship dotfiles --intent "state the user's goal" --dry-run
```

`agentctl start` is the normal entry point. It launches or attaches the Herdr interface and does not
implicitly start a model harness. Use `agentctl fleet --harness pi` when you explicitly want the
FirstMate supervisor backed by Herdr. `fleet` refreshes `herdr integration install pi`, checks Herdr's Pi
integration status, and reapplies the managed FirstMate `config/crew-dispatch.json` from
[`firstmate/crew-dispatch.json`](firstmate/crew-dispatch.json), so small worker tasks route to low-effort
Luna/mini profiles while larger ambiguous work routes to stronger high-effort profiles.

Project switching is name-based. `project` enters or creates the repository's Herdr workspace; `fleet`
starts the optional FirstMate supervisor on Herdr; visualization commands are explicit and do not launch
by default. Treehouse, not Herdr or a model harness, allocates every agent worktree. `overnight` acquires a
durable Treehouse lease and requires a finite cap. `ship` requires a project-local no-mistakes opt-in,
runs the no-mistakes PR gate against the stated intent, and schedules a guarded GitHub auto-merge by
default after the pipeline produces a PR.

Within a repository, `treehouse status` lists numbered/name-addressable slots and `treehouse enter 1`
opens the selected slot in a subshell. To move the current shell instead, use
`cd "$(treehouse enter --print-path 1)"`. These are native Treehouse commands; see
[`treehouse/README.md`](treehouse/README.md) for lifecycle and Herdr handoff details.

Use `--dry-run` before any mutating or GUI-opening command to inspect the exact upstream command.

Fast troubleshooting: if a command is missing, open a fresh terminal and confirm
`export PATH="$HOME/.local/bin:$PATH"` is in the shell configuration. If Herdr stops showing Pi agent
status, run `herdr integration install pi && herdr integration status` and restart Pi. If Pi does not load
FirstMate from `agentctl fleet`, run `/trust` in the Pi session launched from the FirstMate checkout,
quit, and relaunch. If FirstMate reports a missing tool, review the exact install command it prints before
approving it.

## Configuration Boundary

Tracked files contain stable policy. Generated destinations and gitignored overlays hold onboarding,
themes, trust hashes, per-project trust, changelog cursors, sessions, auth, caches, and other
harness-written state. Edit canonical files here rather than live files under `~/.claude`, `~/.codex`,
or `~/.pi`.

After editing canonical configuration:

```bash
agent/scripts/sync-agent-config.sh --check
agent/tests/run.sh
agent/scripts/agentctl sync
```

The first two commands are nonmutating checks. The final command renders or links effective harness
configuration.

External tools remain opt-in. `scripts/install-agent-tools.sh --tools` installs the pinned Treehouse,
GNHF, no-mistakes, and AXI helper CLIs, then clones FirstMate into its own checkout; dotfiles configure
its Herdr backend, token-aware crew-dispatch profile, and managed project registry. The generated
FirstMate project defaults are `no-mistakes +yolo`: use Treehouse worktrees, ship through no-mistakes PRs,
and merge green in-scope work without another confirmation. Dotfiles do not vendor FirstMate's policy,
state, or skills.

## AXI helper workflow

Use AXI CLIs where they reduce agent turns without replacing project gates:

- `gh-axi` for GitHub issues, PRs, workflow runs, releases, and API reads/writes.
- `chrome-devtools-axi` for exploratory browser automation and live page inspection; keep Playwright and
  hidden-app tests as the repeatable test authority.
- `lavish-axi` for reviewable local HTML artifacts when a terminal answer would be too dense.
- `quota-axi` for local quota/usage checks before selecting an expensive worker profile.

Do not adopt AXI memory tools here: `idosleep` owns capture, recall, and consolidation.
