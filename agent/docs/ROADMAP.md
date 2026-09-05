# Agent platform roadmap

## What exists

- Canonical shared policy, personal skills, MCP declarations, and three harness adapters under `agent/`.
- Herdr configuration and current integrations for Pi, Claude Code, and Codex.
- Treehouse as the pinned, shared worktree provider with native status/enter navigation.
- The external `agentic-rules` engineering playbook linked from one source into Claude, Pi and Codex.
- Idempotent configuration validation and synchronization.
- Explicit user-selected Codex workspace sandbox without approval prompts, preserved by synchronization.
- Token-aware FirstMate crew dispatch seeded from dotfiles so small worker tasks use lightweight
  low-effort profiles and large/ambiguous tasks use stronger high-effort profiles.
- Managed FirstMate project defaults from `agent/projects.json`: Treehouse worktrees, no-mistakes PR
  gates, and `+yolo` green auto-merge for registered projects.
- Pinned AXI helper CLIs for GitHub operations, browser exploration, Lavish review artifacts and quota
  visibility.
- A global `agentctl start` entry point that opens Herdr without implicitly launching a model harness.

## What is next

- [x] Separate tracked policy from mutable harness state without losing the user's current settings.
- [x] Add the `agentctl` operator surface and named project registry.
- [x] Configure and verify FirstMate with Herdr from an independent upstream checkout.
- [x] Make Treehouse the sole worktree allocator and document its native jump workflow.
- [x] Install and expose GNHF with mandatory bounded-work defaults.
- [x] Install and expose no-mistakes as a project-local opt-in delivery gate.
- [x] Add deterministic checks for scripts, configuration, links, integrations, and dry-run safety.
- [x] Add configuration ownership, discovery drift, and interpreter regressions.
- [x] Complete the 2026-09-04 coherence audit and its hosted CI gate; the decision log keeps the retained summary after the detailed audit artifacts were retired.
- [x] Run a bounded GNHF assessment and review its committed report; the resolution records its exact end status.
- [ ] Run one multi-project Herdr trial, one FirstMate fleet task, one AXI-assisted GitHub/browser review,
  and one no-mistakes delivery trial
  before declaring the broader platform gate closed. The current branch is set up to perform the first
  no-mistakes delivery trial for dotfiles itself.
- [ ] Exercise representative skill activation across the three harnesses, including two distinct manuscripts.
