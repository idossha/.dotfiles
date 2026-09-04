# Agent platform roadmap

## What exists

- Canonical shared memory, personal skills, MCP declarations, and three harness adapters under `agent/`.
- Herdr configuration and current integrations for Pi, Claude Code, and Codex.
- Treehouse as the pinned, shared worktree provider with native status/enter navigation.
- The external `agentic-rules` engineering playbook linked into Pi and Codex and installed for Claude.
- Idempotent configuration validation and synchronization.
- A global `agentctl start` entry point that opens Herdr without implicitly launching a model harness.

## What is next

- [x] Separate tracked policy from mutable harness state without losing the user's current settings.
- [x] Add the `agentctl` operator surface and named project registry.
- [x] Configure and verify FirstMate with Herdr from an independent upstream checkout.
- [x] Make Treehouse the sole worktree allocator and document its native jump workflow.
- [x] Install and expose GNHF with mandatory bounded-work defaults.
- [x] Install and expose no-mistakes as a project-local opt-in delivery gate.
- [x] Add deterministic checks for scripts, configuration, links, integrations, and dry-run safety.
- [x] Add configuration ownership, discovery drift, interpreter and memory-boundary regressions.
- [ ] Complete the 2026-09-04 coherence audit and its hosted CI gate.
- [ ] Run one multi-project Herdr trial, one FirstMate fleet task, one bounded GNHF task, and one
  no-mistakes delivery trial before declaring the platform gate closed.
