# Decision log

This append-only log records why the current rules in `agent/docs/ARCHITECTURE.md` exist. The
architecture contract says what is true now; later entries supersede earlier ones without deleting them.

## 2026-09-04 — shared agent platform

- 2026-09-04 — **Herdr remains the session substrate** — it already exposes persistent named
  workspaces, panes, agent lifecycle state, and worktree operations for all three installed harnesses —
  returning to tmux rejected because it would discard the agent-aware control surface.
- 2026-09-04 — **FirstMate is integrated upstream, not reimplemented** — its durable supervision,
  restart recovery, worktree lifecycle, and delivery modes exceed a thin captain skill — vendoring or
  immediately building a local clone rejected because either creates a second orchestration codebase.
- 2026-09-04 — **GNHF and no-mistakes remain distinct execution modes** — unattended iteration and
  delivery validation have different failure and authority boundaries — one universal autonomous
  pipeline rejected because it would make routine interactive work inherit unattended mutation policy.
- 2026-09-04 — **Stable policy is separated from mutable harness state** — the live Claude, Codex, and
  Pi processes have already written project context, trust hashes, onboarding state, and UI preferences
  through tracked symlinks — whole-file symlinks rejected where the destination self-mutates.
- 2026-09-04 — **The agentic-rules playbook remains external and authoritative** — it already owns the
  shared testing, documentation, CI, architecture, and release procedures — copying those skills into
  dotfiles rejected because duplicate skills drift and can load twice.
- 2026-09-04 — **`agentctl start` is the normal entry point** — it creates or reuses one FirstMate
  workspace, starts Pi by default, and attaches Herdr — a remembered sequence of Herdr and harness
  commands rejected because it recreates the tab-juggling the platform is intended to remove.
- 2026-09-04 — **Chat stays terse and explanation moves to Lavish** — concise outcomes remain readable
  in a terminal while rich local HTML supports diagrams and anchored feedback — long prose in every
  harness rejected because it is difficult to scan, compare, and annotate.
- 2026-09-04 — **Optional questions are suppressed, authority questions are not** — established defaults
  and narrow pre-approved commands remove routine interruptions — disabling all safety prompts rejected
  because it would grant destructive and external authority without a bounded decision.
- 2026-09-04 — **`agentctl start` enters Herdr and nothing else** — the operator expects the entry point
  to expose the multiplexer before choosing a harness — implicitly launching Pi/FirstMate superseded
  because it hid the workspace interface behind one model's TUI; proved by `agent/tests/run.sh`.
- 2026-09-04 — **Treehouse owns every agent worktree while Herdr owns terminal visibility** — one pooled,
  lease-aware lifecycle keeps concurrent work isolated and lets native `treehouse enter <name>` provide
  fast navigation — Herdr creation, harness-native worktrees, GNHF's worktree flag, and raw Git worktree
  allocation rejected because multiple owners can recycle, reset, or orphan another owner's work.
