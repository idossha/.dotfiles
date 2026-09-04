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
- **Superseded 2026-09-04 by the Herdr-only entry below.**
  2026-09-04 — **`agentctl start` is the normal entry point** — it creates or reuses one FirstMate
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

## 2026-09-04 — coherence audit: configuration ownership (§§1, 2, 3, 8)

- **Global policy and the dotfiles map have separate scopes** — the root map cited a missing path,
  and the home link injected project commands into unrelated repositories; relative project links and
  Claude imports replace that accidental second global source. Evidence: authored scope fixtures in
  `agent/tests/test_config.py`; intent R2 in `requirements/2026-09-04-user-coherence.md`.
- **Canonical configuration wins and unowned runtime state survives** — the prior JSON overlay won
  conflicts while Codex preserved only a narrow list of tables. One parsed renderer handles both
  ownership directions and rejects unsupported MCP fields. The fixture suite reads output independently
  and proves repeated-sync byte equality, stale-entry retirement and duplicate-link cleanup.
- **Python 3.11+, PyYAML and tomli-w are explicit script dependencies** — observed macOS Python 3.9
  failed TOML checks, while unavailable YAML silently skipped validation. The floor comes from the
  standard-library TOML API; exact parser pins live only in `agent/requirements.txt`.
- **Installed checks are part of doctor and adopted pins have one owner** — the old doctor passed with
  stale links and duplicated version constants. `--check-installed` and `agent/tools.env` replace those
  false greens; floating MCP/plugin dependencies remain explicitly reported.
- **GNHF uses a reviewed execution mode and the source revision** — the installed upstream default
  bypasses Codex sandboxing, and Treehouse allocates from its own base. Preflight validates the runner
  config and a clean source; same-repository and fast-forward checks pin the starting revision.
  Authored CLI fixtures cover failure codes, dirty input and unsupported adapters. The iteration default
  remains ten (existing behavior); usage-limit waiting defaults to zero (chosen to bound unattended waits).
- **Project memory cannot leave its declared root** — absolute, relative and symlink escapes were
  possible through `--file`. Resolved containment and source-field secret checks are pinned by temporary
  fixtures in `agent/tests/test_memory.py`. Native run logs stay with their original owner.
