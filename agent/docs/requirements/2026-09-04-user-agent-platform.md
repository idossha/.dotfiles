# User requirements — 2026-09-04 (agent-platform gate items R1–R7)

These are hard gate items for the agent-platform rollout. They refine §§1–6 of
`agent/docs/ARCHITECTURE.md`; where they conflict with older plans, they win and the contract is amended
with them.

## Asks, verbatim

1. "use herdr with firstmate, no mistakes and good night have fun"
2. "centralize all the agentic logic in my dot files"
3. "use agents.md when possible and not codex clode etc"
4. "all the different harnesses and models ... share as much logic as possible"
5. "create a plan to build this and then hand it off to agents for the actual implementation"
6. "manage easily multiple projects ... and be able to switch visualizations ... fast and ... smooth"
7. "going forward whenever you're working with worktrees, let's always work with
   https://github.com/kunchenguid/treehouse ... If there is a native way [to jump around], great just
   teach me"

## R1 — Run the adopted tools through Herdr

- FirstMate can use Herdr as its backend; GNHF and no-mistakes can be launched from a Herdr workspace.
- Gate test: dry-run output identifies the selected tool, repository, and finite safety boundary exactly;
  `agentctl doctor` reports each installed tool and Herdr integration without modifying the repository.

## R2 — Author shared logic once

- Shared instructions live in `agent/AGENTS.md`, personal skills, or the external agentic-rules skills;
  harness files contain only irreducibly harness-specific configuration.
- Gate test: the configuration check finds no duplicated skill names or copied shared instruction file,
  and all three harness targets resolve to the canonical source selected for them.

## R3 — Preserve the engineering playbook

- Agentic-rules remains authoritative for backend tests, offscreen frontend tests, documentation,
  architecture, CI, and releases; tool integrations call those procedures rather than restating them.
- Gate test: each shared procedure is named once in the AGENTS routing map and resolves to exactly one
  installed skill directory.

## R4 — Keep runtime state out of tracked policy

- Harness-generated preferences, trust records, onboarding state, and project-specific context do not
  modify tracked canonical configuration.
- Gate test: after sync and read-only harness resource discovery, `git diff -- agent/claude agent/codex
  agent/pi` is byte-identical to its pre-run capture.

## R5 — Switch projects by stable name

- The operator can select dotfiles, TI-Toolbox, or Tetravox without remembering paths, and each opens
  as a distinct Herdr workspace with optional visualization commands kept project-specific.
- Gate test: registry validation resolves all three names to existing repository roots exactly and a
  dry run prints the expected Herdr workspace and visualization command without launching a GUI.

## R6 — Keep autonomous work bounded and reviewable

- GNHF defaults to an isolated Treehouse lease with a finite iteration or token cap; no-mistakes remains
  an explicit project opt-in; neither pushes or merges by default.
- Gate test: fixture-driven CLI tests reject an uncapped unattended invocation and show no `--push`,
  merge, current-branch, or GNHF-native worktree flag in the accepted default command.

## R7 — Use Treehouse for worktree lifecycle and native jumping

- Treehouse is the only allocator and retiree for agent-owned worktrees; Herdr opens leased paths for
  visibility, while harness-native, Herdr-native, GNHF-native, and raw Git alternatives are disallowed.
- Standalone and detached automation uses durable leases with task labels and preserves them until work is
  landed; a configured orchestrator may use its own guarded Treehouse owner lifecycle. Cleanup cannot
  force-return unlanded work or act on a durable lease without its identity.
- The operator uses `treehouse status` and `treehouse enter <name>` to jump without memorizing paths; the
  documented `--print-path` form changes the current shell when a subshell is undesirable.
- Gate test: shared instructions and Herdr documentation name the ownership split, Claude's native
  worktree tools are denied, the exact Treehouse release is installed and checked, and an overnight
  dry-run prints `treehouse get --lease` without GNHF's `--worktree` flag.
