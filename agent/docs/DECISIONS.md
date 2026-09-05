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
  **Amended 2026-09-04** for Codex runtime permissions by the explicit YOLO request below.
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
  `agent/tests/test_config.py`; original coherence intent R2.
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
- **Superseded 2026-09-05 by the idosleep memory-owner entry below.**
  **Project memory cannot leave its declared root** — absolute, relative and symlink escapes were
  possible through `--file`. Resolved containment and source-field secret checks were pinned by temporary
  fixtures until the local memory router was removed. Native run logs stay with their original owner.

## 2026-09-04 — coherence audit: procedure owners and CI (§§4, 8, 9)

- **Skills retain one procedure owner** — git-collaboration duplicated commit/release formats and
  attribution, write-skill forced primary-checkout writes and Claude metadata, and orchestrator assumed
  one Agent tool and context model. The local skills now route to the engineering playbook and current
  provider capabilities. Prior plans are explicitly historical; all Pi research roles retain global
  policy even when project context is omitted. Intent: coherence R3.
- **The local gate is the CI gate** — there was no hosted workflow for the platform. One read-only
  workflow invokes the existing scripts; a fast guard self-tests its rejected cases before checking
  each commit against the contract-owned frozen list. A missing Git base cannot masquerade as success.
  Intent: coherence R4. Branch-protection administration remains outside this dotfiles change.
- **CI checks Python 3.11 and 3.14** — the floor is the TOML-reader requirement and 3.14 is the measured
  development interpreter. Local source checks take under one second and the fixture suite under five;
  chosen job caps are three/five minutes to allow hosted setup while bounding hangs. Checkout v4 and
  setup-python v5 action SHAs were resolved from their upstream Git refs on 2026-09-04.


## 2026-09-04 — one skill source and explicit Git owners (§§3–4, 6, 8)

GNHF found two Claude plugin skills diverged from the local playbook, which contains pre-existing
uncommitted work. Native plugin updates cannot reproduce those edits. All harnesses now use per-skill
links to the same sources, with real discovery roots and the duplicate Claude plugin disabled.
This removes snapshot reconciliation as a required operating step and preserves the external work.
Provider plugins still supply capabilities when they do not duplicate shared doctrine.

General manuscript review now derives facts from each project's protocol and evidence. Telemetry
triage resolves repositories/releases once and consumes project-owned queries/workflows. Shared skill
authoring, MCP and Herdr edits stay in the assigned checkout; activation follows landing. Task templates
route decisions/testing/memory instead of maintaining parallel conventions.

The shell publisher and Pi stash checkpoint extension are retired: they added implicit Git owners,
and stash apply never proved exact restoration. Docker checks now claim environment/syntax smoke
only, preserve command failures and mount source read-only without the host socket. The retired work
installer test returns an explicit error. Tests use fake failing commands, not a real Docker daemon.

Sync preflights all mutable JSON/TOML/YAML destinations before writing, so malformed late inputs do not
partially activate policy. Writes are individually atomic; filesystem failure across files is not a
transaction. Regression fixtures cover shared skill targets, disabled duplicate policy, missing
playbook, malformed live state, memory routes and upstream command/argv boundaries.

The guard and workflow are frozen interfaces too (§7); changing enforcement requires its rationale
in the same commit. CI resolves the merge base for a PR whose target advanced. Doctor treats absent
optional runners as unavailable features and failed installed version probes as failures.


## 2026-09-04 — coherence audit gates verified (§6)

The retained resolution summary closes the five audit-intent gates with command evidence and reconciles
all 15 GNHF findings. The broader operational gate stays open
for fleet/session/delivery and representative model-activation trials. The report keeps GNHF's exact
end status, test scope, provider limits and concurrent-work preservation explicit.

## 2026-09-04 — Pi discovery uses native RPC (§§6–8)

The installed Pi 0.85.0 public SDK and its resource-loader module both fail to import because they
transitively require the absent experimental @earendil-works/pi-server package. The native bundled CLI
works. The diagnostic now uses get_commands over offline RPC with no session, prompt, tools or TUI,
instead of relying on SDK implementation imports or installing an unrelated server dependency.

The probe has a 30-second timeout and validates the correlated response, nonempty skills, unique names
and source paths. It explicitly does not prove context-file loading or every extension diagnostic.
Authored fake CLI responses exercise empty success, upstream failure and a valid skill identity.
The real Pi CLI returned 38 skills, including all 33 shared skills and five package-owned skills.


The shared MCP declaration now pins the packages already installed in the local npx cache:
@upstash/context7-mcp 4.0.5, openalex-research-mcp 0.5.0 and @playwright/mcp 0.0.80.
This prevents @latest or omitted versions changing the next session's server implementation.
The source JSON remains the sole pin owner and all adapters consume it. These are top-level version
pins, not a fully locked transitive dependency graph or evidence of remote service health.


Native Pi discovery also exposed three automatically loaded guides from pi-subagents and
pi-interactive-shell. The former prescribes a supervisor posture for substantial tasks; the latter
recommends its native worktree flag. Shared orchestrator/Treehouse policy owns those decisions.
The documented Pi package object filter disables those packages' skill resources while retaining
their extensions. Provider mechanics remain available from installed help/source on demand.
The two remaining package skills (intercom and MCP scripting) describe transport/tool mechanics.

## 2026-09-04 — Codex uses explicit YOLO defaults (§3.7)

**Superseded 2026-09-04** for the sandbox mode by the workspace-write correction below.

- 2026-09-04 — **New Codex sessions use never/full-access and automatic tool overrides** — the user
  explicitly requested no permission prompts, supplying the decision absent from the earlier rationale
  "it would grant destructive and external authority without a bounded decision". Canonical settings
  replace forced MCP prompts and survive sync; an alias or editing only the generated file would miss
  other launch paths or be overwritten. Intent: original user Codex-permissions request.
  Verification uses `agent/tests/run.sh`, source/installed configuration checks, and Codex's resolved
  configuration. Restart verification uses native conversation IDs and Herdr state; active work must
  reach a safe boundary before reload. Managed requirements and other harnesses are outside this change.

## 2026-09-04 — Codex retains the workspace sandbox without approval prompts (§3.7)

- 2026-09-04 — **Codex uses `approval_policy = "never"` and `sandbox_mode = "workspace-write"`** —
  the user supplied these exact values after the YOLO request. Full filesystem access is superseded;
  commands outside the sandbox fail rather than requesting escalation. Canonical and generated TOML
  agree after sync, and `sync-agent-config.sh --check-installed` verifies persistence. Intent:
  the original user Codex-workspace request.

## 2026-09-04 — FirstMate uses token-aware crew dispatch (§2.3, §3.8, §5.1, §6, §7.11)

- 2026-09-04 — **FirstMate worker spawns use a dotfiles-seeded size-aware dispatch profile** — the
  user gave standing permission to spend cheaper low-effort Luna/mini profiles on small bounded tasks
  and stronger high-effort profiles on large or ambiguous work. A single static worker model was rejected
  because it either wastes tokens on mechanical tasks or underpowers hard work; an untracked hand edit was
  rejected because `doctor` could not prove it remained active; silent intelligence downgrades remain
  rejected by FirstMate's own standing-permission rule, so this tracked profile is the permission source.
  Intent: original user FirstMate-dispatch request. Verification: `agent/tests/run.sh`,
  `agent/tests/test_cli.py::ExecutionTests.test_fleet_launch_writes_firstmate_dispatch_config`, and
  `agentctl doctor` drift reporting.

## 2026-09-05 — idosleep owns agent memory (§§1, 4, 8)

- 2026-09-05 — **`idosleep` is the sole agent-memory owner** — the installed CLI already exposes
  automatic hook capture/injection plus `recall`, `sleep`, MCP tools and manual `idosleep remember`, while
  the dotfiles `scripts/remember` CLI and `skills/remember` maintained a second routing policy and second
  set of stores. Keeping both was rejected because agents would split facts across two dedupe, secret
  screening and retrieval systems; evidence: `idosleep --help`, `idosleep remember --help`, and
  `tests.test_config.OwnershipTests.test_memory_policy_has_no_local_router_overlap`.
- 2026-09-05 — **Global instructions move from `agent/memory/global.md` to `agent/policy/global.md`** —
  the file is policy loaded by every harness, not a memory substrate. Removing the `memory/` source path
  prevents it being confused with idosleep's vault while preserving the same shared instruction scope;
  deleting global policy outright was rejected because Codex, Pi and Claude still need one portable policy
  source separate from the dotfiles project map.
- 2026-09-05 — **The dotfiles adapter keeps only active local skills, prompts and retained summaries** —
  the detailed 2026-09-04 intent/audit files, Claude track template, custom Pi subagent roles, and several
  personal workflow skills were intentionally removed by the maintainer. Synchronization now treats
  `claude/templates` and `pi/agents` as optional adapter directories and retires old generated symlinks
  when their sources are absent; tests assert the optional-link behavior instead of restoring deleted
  content.

## 2026-09-05 — Herdr refresh and AXI helper workflow (§§2, 3, 5, 8)

- 2026-09-05 — **Pi-backed FirstMate refreshes Herdr's Pi bridge before launch** — Herdr updates can change the Pi agent-status integration, and a stale bridge makes Herdr lose Pi lifecycle state. `agentctl fleet --harness pi` and `install-agent-tools.sh` now run `herdr integration install pi` and check status before Pi starts; the fast troubleshooting path records `/trust`, restart, and missing-tool recovery.
- 2026-09-05 — **Adopt only workflow-matched AXI helpers** — `axi.md` recommends agent-ergonomic CLI wrappers with token-efficient output and contextual next steps. This platform adopts `gh-axi` for GitHub operations, `chrome-devtools-axi` for browser exploration, `lavish-axi` for local review artifacts, and `quota-axi` for local quota visibility. Broad cloud/database/package AXIs remain project-local choices, `cyber-mux` is rejected because Herdr owns terminal multiplexing, and memory AXIs are rejected because `idosleep` owns memory.

## 2026-09-05 — default delivery is worktree, no-mistakes PR and guarded green merge (§§2, 3, 5–7)

- 2026-09-05 — **Known projects default to FirstMate `no-mistakes +yolo`** — the user granted standing merge authority for work that has passed the proper testing/no-mistakes review pipeline. Encoding that posture in `agent/projects.json` and rendering it into FirstMate's private `data/projects.md` was chosen over hand-editing FirstMate state because `agentctl doctor` can report drift and future project additions inherit the same default. The `+yolo` authority is bounded to green, in-scope PRs; red, destructive, irreversible, security-sensitive, and out-of-scope work still escalates.
- 2026-09-05 — **Dotfiles opts into no-mistakes for delivery to `main`** — adding root `.no-mistakes.yaml` gives this repository a reviewed lint/test baseline (`agent/tests/run.sh` plus shell syntax) instead of relying on an ad hoc local merge. `agentctl ship` now drives the no-mistakes AXI PR path from a clean feature branch and uses `gh-axi pr merge --auto` for guarded GitHub auto-merge scheduling. Directly fast-forwarding `main` from the feature branch was rejected because it bypasses PR review, CI evidence, and branch protection.

## 2026-09-05 — Retire FirstMate, Herdr, GNHF and Treehouse; adopt PHILOSOPHY.md (§§2, 3, 5–8)

- 2026-09-05 — **The platform drops the fleet supervisor, session multiplexer, unattended-loop runner and
  worktree pool** — four upstream tools each owned part of a session, checkout or merge lifecycle, so no
  single process could be named as the owner of a branch, and each one had to be pinned, installed,
  documented and dry-run tested to stay honest. Keeping them behind flags was rejected because an unused
  command still has to be tested and kept true, and its stale prose is trusted by the next agent; keeping
  only the worktree pool was rejected because agents that allocate a second checkout split ownership of
  the branch, its commits and its cleanup between processes that cannot see each other. The worktree
  policy is now: agents work in the checkout they were launched in and do not create worktrees, with the
  existing `git worktree add` and harness-native worktree denials retained as the mechanical guard.
  Verification: `agent/tests/run.sh`, `agent/scripts/sync-agent-config.sh --check`,
  `agent/scripts/agentctl doctor`, and a repository-wide grep for the retired tool names.
- 2026-09-05 — **The operator surface is `agentctl doctor | sync | ship`** — `start`, `project`, `fleet`
  and `overnight` existed only to launch the retired tools. Exit codes are unchanged. Frozen-list items 6,
  11 and 12 are marked retired in place rather than renumbered, because §7 numbers are cited from commits,
  tests and the coherence guard, and renumbering breaks those citations silently.
- 2026-09-05 — **`agent/docs/PHILOSOPHY.md` states the mechanism-selection rule once** — skills teach,
  CLIs act, MCP exposes, and each rule names the failure it prevents. It replaces the reasoning that was
  spread across the retired tools' prose; putting it in AGENTS.md was rejected because the map has a line
  budget and philosophy is read once, not every session.
- 2026-09-05 — **`agent/MULTI-HARNESS-PLAN.md` is deleted** — it was already marked a historical design
  record superseded by this contract, and its Herdr-created-worktree recommendations directly contradicted
  the worktree policy above. A superseded plan left in the tree is read as instruction by the next agent.
