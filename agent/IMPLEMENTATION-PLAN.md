# Agent platform implementation plan — 2026-09-04

**Historical plan; no current execution authority.** The contract and roadmap in `agent/docs/`
are authoritative. This plan originally superseded the unfinished implementation phases in `MULTI-HARNESS-PLAN.md` where the two
disagree. The architecture and acceptance gates are in `agent/docs/`.

## Phase 1 — configuration boundary

1. Inventory which Claude, Codex, and Pi fields are stable policy versus harness-written state.
2. Preserve the current uncommitted settings while moving mutable values to local, gitignored overlays
   or generated effective files.
3. Keep AGENTS.md, skills, and MCP declarations canonical and shared.
4. Pin executable package references or make floating references fail visibly in `doctor`.

## Phase 2 — one operator CLI

1. Add `agent/scripts/agentctl` with `doctor`, `sync`, `project`, `fleet`, `overnight`, and `ship` commands.
2. Add `agent/projects.json` with stable aliases for dotfiles, TI-Toolbox, and Tetravox plus optional,
   non-launched visualization commands.
3. Make every mutating or GUI-opening command support `--dry-run`; emit actionable errors and stable
   nonzero exit codes.
4. Require a retained Treehouse lease and a finite cap for GNHF; require project-local no-mistakes configuration.

## Phase 3 — upstream integrations

1. Extend the opt-in installer to install pinned GNHF and no-mistakes versions.
2. Clone FirstMate over SSH into a configurable external tools directory and configure its backend as
   Herdr without copying its AGENTS.md or internal skills into dotfiles.
3. Record version and compatibility checks in `agentctl doctor`; treat FirstMate's Herdr support as
   experimental until a live fleet trial passes.

## Phase 4 — shared doctrine and verification

1. Reduce `agent/AGENTS.md` to routing and load-bearing global rules; point testing, architecture, CI,
   docs, and release work at their single agentic-rules skills.
2. Add fixture-driven tests for registry parsing, dry-run commands, cap enforcement, and missing tools.
3. Validate shell, JSON, TOML, links, skill uniqueness, and live Herdr integrations.
4. Leave live FirstMate, GNHF, no-mistakes, GUI, push, merge, and package-install trials for explicit
   operator execution; no automated test takes focus or changes a remote repository.

## Handoff boundaries

- Configuration agent: Phase 1 and sync checks; do not alter project registry or operator CLI.
- Integration agent: Phases 2–3; do not rewrite shared instruction doctrine.
- Doctrine/test agent: Phase 4 documentation and tests; do not modify live harness destinations.
- Coordinating agent: reconcile overlaps, run all non-destructive checks, and report remaining live gates.
