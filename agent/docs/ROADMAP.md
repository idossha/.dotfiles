# Agent platform roadmap

## What exists

- Canonical shared policy, personal skills, MCP declarations, and three harness adapters under `agent/`.
- [PHILOSOPHY.md](PHILOSOPHY.md): skills teach, CLIs act, MCP exposes; one checkout, one agent, one
  explicit owner per Git mutation.
- The external `agentic-rules` engineering playbook linked from one source into Claude, Pi and Codex.
- Idempotent configuration validation and synchronization.
- Explicit user-selected Codex workspace sandbox without approval prompts, preserved by synchronization.
- Pinned AXI helper CLIs for GitHub operations, browser exploration, Lavish review artifacts and quota
  visibility.
- The `agentctl doctor | sync | ship` operator surface with a project-opted-in no-mistakes delivery gate.

## What is next

- [x] Separate tracked policy from mutable harness state without losing the user's current settings.
- [x] Add the `agentctl` operator surface and named project registry.
- [x] Install and expose no-mistakes as a project-local opt-in delivery gate.
- [x] Add deterministic checks for scripts, configuration, links, integrations, and dry-run safety.
- [x] Add configuration ownership, discovery drift, and interpreter regressions.
- [x] Complete the 2026-09-04 coherence audit and its hosted CI gate; the decision log keeps the retained
  summary after the detailed audit artifacts were retired.
- [x] Retire the fleet supervisor, session multiplexer, unattended-loop runner and worktree pool, and
  record the surviving worktree and delivery policy in the contract.
- [ ] Run one AXI-assisted GitHub/browser review and one no-mistakes delivery trial before declaring the
  broader platform gate closed. The current branch is set up to perform the first no-mistakes delivery
  trial for dotfiles itself.
- [ ] Exercise representative skill activation across the three harnesses, including two distinct
  manuscripts.
