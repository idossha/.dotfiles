# Agent Platform — Architecture Contract

> The dotfiles agent platform gives one developer a shared policy, tool, and session layer across
> Claude Code, Codex, and Pi, with Herdr providing visible multi-project multiplexing and Treehouse
> providing every agent-owned worktree.

This file is the **contract**. Deviating from it requires editing this file in the same commit and
appending an entry to `agent/docs/DECISIONS.md`. Section numbers are stable and must not be renumbered.

## 1. Sources of truth

1. **`agent/` owns portable agent configuration.** Global instructions, personal skills, MCP
   definitions, and harness adapters are authored once here; generated destinations are not edited.
2. **`agent/AGENTS.md` is the portable map.** Harness-specific files contain only settings or hooks
   that another harness cannot consume; shared development doctrine lives in AGENTS.md or a skill.
3. **`agentic-rules` owns cross-project engineering procedures.** Testing, documentation,
   architecture, CI, and release doctrine remain in that repository and are linked or installed;
   copying those skills here would create two versions of the same rule.

## 2. Runtime layers

1. **Herdr is the terminal and session substrate.** One workspace represents one primary repository;
   tabs and panes expose editors, agents, logs, and visualizations without using terminal position as
   task identity. Herdr may open an existing worktree path but does not allocate or retire agent worktrees.
2. **Treehouse is the sole worktree provider.** Every agent-owned project worktree is a managed
   [Treehouse](https://github.com/kunchenguid/treehouse) pool slot. Standalone or detached automation
   uses a durable lease, while an orchestrator may use its guarded Treehouse owner lifecycle. Harness-native
   worktree tools, Herdr's create/remove commands, GNHF's worktree flag, and raw `git worktree` lifecycle
   commands are not alternate allocators.
3. **FirstMate is an optional fleet supervisor over Herdr.** It runs from its own upstream checkout
   and state home; dotfiles configure and launch it but do not vendor its operating contract. Its
   configured Herdr backend already acquires Treehouse worktrees.
4. **GNHF is the bounded unattended-loop runner.** Dotfiles acquire a retained Treehouse lease and
   require explicit iteration or token limits for unattended runs; direct pushing is never the default.
5. **no-mistakes is an optional delivery gate.** Repositories opt in with project-local configuration;
   dotfiles provide discovery and launch, not a universal test command.

## 3. Configuration ownership

1. **Tracked files contain stable policy, not harness-written state.** Onboarding flags, changelog
   cursors, hook trust hashes, per-project trust, themes, and session state remain local or are merged
   from a gitignored overlay; otherwise launching a harness dirties the dotfiles repository.
2. **One canonical declaration feeds every compatible harness.** MCP servers and portable skills are
   declared once and rendered or linked by `agent/scripts/sync-agent-config.sh`.
3. **External executables are pinned or explicitly reported as floating.** A silent `@latest` makes
   two sessions with the same dotfiles run different code.

## 4. Shared development doctrine

1. **AGENTS.md routes; skills teach procedures; automation enforces invariants.** Repeating testing or
   release procedures in every harness lowers compliance and creates drift.
2. **The agentic-rules testing split remains authoritative.** Backend tests derive expected values
   independently; rendering tests make analytic assertions and run hidden; goldens are regression-only.
3. **Project facts remain with the project.** Global configuration cannot name Tetravox, TI-Toolbox,
   datasets, secrets, or project-specific deployment posture because every other project would inherit it.

## 5. Operator surface

1. **`agentctl` is the single human and agent entry point.** `agentctl start` launches or attaches
   Herdr without implicitly starting a model harness; separate commands expose health checks,
   synchronization, workspace entry, fleet launch, bounded overnight work, and delivery gates with
   stable exit codes.
2. **Commands compose instead of hiding upstream tools.** `agentctl` prints the resolved command in
   dry-run mode and preserves upstream logs and recovery instructions.
3. **Fast project switching is name-based.** A small project registry maps stable names to repository
   paths and optional visualization commands; paths are not duplicated across shell aliases and harness files.
4. **Fast worktree switching uses Treehouse's native selector.** `treehouse status` supplies stable
   names or numbers, `treehouse enter <name>` opens a subshell, and
   `cd "$(treehouse enter --print-path <name>)"` moves the current shell without another wrapper.
5. **Chat is a synopsis surface and Lavish is the explanation surface.** Agents return the outcome,
   decisive evidence, and next action in chat; diagrams, comparisons, plans, dense tables, and extended
   walkthroughs are local Lavish artifacts so the user can inspect and annotate them.

## 6. Verification

The platform gate is command-based:

- `agent/scripts/sync-agent-config.sh --check` validates canonical inputs without modifying them.
- `agent/scripts/agentctl doctor` reports harness versions, integrations, tools, links, and floating dependencies.
- Shell scripts pass `bash -n`; JSON and TOML parse; project aliases resolve to existing directories.
- A dry-run test proves GNHF acquires Treehouse isolation without its own worktree flag, receives a finite
  cap, and leaves no push enabled; no-mistakes remains opt-in.

## 7. Frozen interfaces

Changing these requires this contract and `agent/docs/DECISIONS.md` in the same commit:

1. `agent/scripts/agentctl` — the operator CLI and exit-code contract.
2. `agent/projects.json` — the named-project registry schema.
3. `agent/mcps/mcp-servers.json` — the shared MCP declaration.
4. `agent/scripts/sync-agent-config.sh` — tracked/generated/local ownership boundaries.

Additive fields are optional; when absent, they reproduce the previous behavior.
