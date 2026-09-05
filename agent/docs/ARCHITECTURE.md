# Agent Platform — Architecture Contract

> The dotfiles agent platform gives one developer a shared policy and tool layer across Claude Code,
> Codex, and Pi, with one operator CLI and an optional project-local delivery gate.

[PHILOSOPHY.md](PHILOSOPHY.md) states why the platform is shaped this way; this file is the **contract**. Deviating from it requires editing this file in the same commit and
appending an entry to `agent/docs/DECISIONS.md`. Section numbers are stable and must not be renumbered.

## 1. Sources of truth

1. **`agent/` owns portable agent configuration.** Global instructions, personal skills, MCP
   definitions, and harness adapters are authored once here; generated destinations are not edited.
2. **Global policy, project routing, and memory capture have separate scopes.** `agent/policy/global.md`
   supplies user instructions; `agent/AGENTS.md` is the dotfiles project map, reached by a relative root
   link; `idosleep` owns agent memory capture, recall, and consolidation outside dotfiles. Claude imports
   AGENTS.md. Installing the project map at the home ancestor would leak its commands and contract into
   unrelated repositories.
3. **`agentic-rules` owns cross-project engineering procedures.** Testing, documentation,
   architecture, CI, and release doctrine remain in that repository and are linked or installed;
   copying those skills here would create two versions of the same rule.

## 2. Runtime layers

1. **Harness adapters are the runtime.** Claude Code, Codex, and Pi each run in the checkout the user
   launched them in; dotfiles supply their policy, skills, and MCP declaration and nothing else. There is
   no session multiplexer, fleet supervisor, or unattended loop runner in this platform.
2. **Agents do not allocate worktrees.** Agents work in the checkout they were launched in and do not
   create worktrees, because a second checkout splits ownership of a branch, its commits, and its cleanup
   between processes that cannot see each other. Harness-native worktree tools and raw `git worktree`
   lifecycle commands stay denied.
3. *Retired 2026-09-05* (formerly the optional fleet supervisor over a session substrate).
4. *Retired 2026-09-05* (formerly the bounded unattended-loop runner).
5. **no-mistakes is the project-opted-in delivery gate.** Registered projects that carry a reviewed
   `.no-mistakes.yaml` ship through `agentctl ship`; others use ordinary PRs, and red work is never pushed
   or merged. Project config owns the concrete lint/test commands; dotfiles provide discovery, launch, and
   guarded auto-merge scheduling for GitHub PRs.

## 3. Configuration ownership

1. **Tracked files contain stable policy, not harness-written state.** Onboarding flags, changelog
   cursors, hook trust hashes, per-project trust, themes, and session state remain local or are merged
   from a gitignored overlay; otherwise launching a harness dirties the dotfiles repository.
2. **One canonical declaration feeds every compatible harness.** MCP servers and portable skills are
   declared once and rendered or linked by `agent/scripts/sync-agent-config.sh`.
3. **External executables are pinned or explicitly reported as floating.** A silent `@latest` makes
   two sessions with the same dotfiles run different code.
4. **Canonical keys win over local state.** Generated JSON/TOML/YAML files retain unowned runtime
   fields, including newly introduced provider fields, in ignored overlays. A local overlay cannot
   silently replace policy-owned permissions or package pins.
5. **MCP declarations are adapted at the documented scope.** Claude user servers are merged into
   its local app-state file without storing that file in Git; Pi receives the shared JSON and Codex
   receives generated TOML. Unsupported portable fields fail validation instead of disappearing.
   Previously managed entries are retired through a local ownership manifest; unrelated entries survive.
6. **Skill discovery has one route per skill per harness.** Retire legacy managed Codex/Pi links;
   preserve provider-bundled skills. All three local harnesses link to the same personal and playbook
   skill directories. Pi package guides that prescribe a competing supervisor/worktree policy are
   excluded through package resource filters; their extensions remain available. Disable the duplicate Claude engineering plugin; its cached snapshot otherwise
   can prescribe different procedures. Other plugins remain adapter-specific capabilities.
7. **Codex defaults to the user's explicitly selected workspace permissions.** Canonical configuration sets
   `approval_policy = "never"`, `sandbox_mode = "workspace-write"`, and automatic tool overrides;
   this prevents new sessions or a later sync from restoring routine permission prompts. Existing
   conversations retain their native session IDs during reload. Explicit invocation overrides and
   managed requirements remain effective; other harness adapters keep their own settings.
8. *Retired 2026-09-05* (formerly the seeded worker model/effort dispatch template).
9. *Retired 2026-09-05* (formerly the supervisor project-posture rendering from the registry).

## 4. Shared development doctrine

1. **AGENTS.md routes; skills teach procedures; automation enforces invariants.** Repeating testing or
   release procedures in every harness lowers compliance and creates drift.
2. **The agentic-rules testing split remains authoritative.** Backend tests derive expected values
   independently; rendering tests make analytic assertions and run hidden; goldens are regression-only.
3. **Project facts remain with the project.** The global project registry may map names to paths, but datasets, secrets and deployment posture
   stay project-local because every other project would otherwise inherit them. Domain review skills
   derive sample sizes, outcomes and defaults from the target's records; they do not prescribe one
   study's results. Task templates route decisions and validation to project-owned documents/scripts.
   `idosleep` traces may recall context, but they do not replace reviewable project documents.
4. **Each Git mutation has one explicit owner.** Pi session forks do not apply stash patches. The old
   shell repository publisher is retired; collaboration routes to the shared playbook and project
   gates. Provider extensions must not introduce a second implicit checkpoint or publishing lifecycle.

## 5. Operator surface

1. **`agentctl` is the single human and agent entry point.** Its surface is
   `agentctl doctor | sync | ship <name> --intent <goal> [--dry-run] [--no-automerge]`, with stable exit
   codes. `doctor` is read-only, `sync` renders or links effective harness configuration from the landed
   canonical checkout, and `ship` runs a repository's no-mistakes AXI PR gate from a clean feature branch
   and schedules a guarded GitHub auto-merge unless disabled. A wrapper for every upstream tool was
   rejected: an unused command still has to be tested and kept true.
2. **Commands compose instead of hiding upstream tools.** `agentctl` prints the resolved command in
   dry-run mode and preserves upstream logs and recovery instructions.
   GitHub inspection defaults to `gh-axi` when available; browser exploration defaults to
   `chrome-devtools-axi`; dense human review uses `lavish-axi`; routing diagnostics use `quota-axi`.
   Project tests and delivery gates remain the source of truth.
3. **Project naming is registry-based.** `agent/projects.json` maps stable names to repository paths and
   delivery posture, so paths are not duplicated across shell aliases and harness files.
4. **Agents do not switch checkouts on their own.** The user launches a harness in the repository the
   work belongs to; §2.2 forbids allocating another.
5. **Chat is a synopsis surface and Lavish is the explanation surface.** Agents return the outcome,
   decisive evidence, and next action in chat; diagrams, comparisons, plans, dense tables, and extended
   walkthroughs are local Lavish artifacts so the user can inspect and annotate them.

## 6. Verification

The platform gate is command-based:

- `agent/scripts/sync-agent-config.sh --check` validates canonical inputs without modifying them.
- `agent/scripts/agentctl doctor` reports harness versions, integrations, tools, links, and floating dependencies.
- Each shell script passes its own `bash -n <file>` invocation; JSON and TOML parse; project aliases resolve to existing directories.
- A dry-run test proves `agentctl ship` stays opt-in: it refuses a project without a reviewed
  `.no-mistakes.yaml` and prints the auto-merge decision rather than performing it.
- `agent/tests/run.sh` is the platform test entry point. Authored temporary configurations are read
  back with independent JSON/TOML parsers; tests neither source the user's shell profile nor access
  real homes, vaults, remotes or visible apps.
- `--check` validates source without writing; `--check-installed` detects generated configuration
  and discovery drift. `doctor` includes the installed check and reports floating dependencies.

## 7. Frozen interfaces

Changing these requires this contract and `agent/docs/DECISIONS.md` in the same commit:

1. `agent/scripts/agentctl` — the operator CLI and exit-code contract.
2. `agent/projects.json` — the named-project registry schema.
3. `agent/mcps/mcp-servers.json` — the shared MCP declaration.
4. `agent/scripts/sync-agent-config.sh` — tracked/generated/local ownership boundaries.
5. `agent/scripts/agent_config.py` — configuration validation, rendering and discovery semantics.
6. *Retired 2026-09-05* (formerly the unattended-loop runner's execution defaults).
7. `agent/tools.env` — shared adopted-tool pins.
8. `agent/scripts/check_coherence.py` — source and commit guard semantics.
9. `.github/workflows/agent-platform.yml` — platform verification triggers and jobs.
10. `agent/scripts/pi-resources.mjs` — native resource-discovery probe and evidence scope.
11. *Retired 2026-09-05* (formerly the worker model/effort dispatch defaults).
12. *Retired 2026-09-05* (formerly the managed project-posture rendering script).
13. `.no-mistakes.yaml` — dotfiles delivery-gate commands and evidence policy.

Additive fields are optional; when absent, they reproduce the previous behavior.

## 8. Portability and change boundaries

**Portable means shared intent and verifiable adapters, not identical provider capabilities.**
AGENTS.md routes policy; skills own procedures; CLI programs perform operations; MCP exposes structured
capabilities; plugins distribute provider-compatible bundles ([PHILOSOPHY.md](PHILOSOPHY.md)). Tools and
plugins do not grant authority. Provider-specific frontmatter is optional metadata, never the sole place
an essential constraint is stated.

| Concern | Sole procedural or state owner |
|---|---|
| Engineering contract, testing, CI and release procedures | External agentic-rules playbook |
| Git collaboration and remote coordination | Active harness Git tools plus the external changelog-release playbook for commit/release grammar |
| In-session delegation and unattended iterations | The active harness in its checkout, one explicit owner per task |
| Worktrees and terminal sessions | The active harness in its checkout; agents do not create worktrees |
| Test assertions and delivery commands | Each project; local checks and CI invoke the same scripts |
| Agent memory capture, recall and consolidation | `idosleep` vault, hooks and MCP; project docs remain the reviewable source for project decisions |
| Session logs and caches | Native runtime owner; no automatic second memory copy in dotfiles |
| User authorization | Current session and enforced harness boundary; adapters do not broaden it |

| Dependency | Source of version truth | Why |
|---|---|---|
| Python | 3.11 minimum | Standard-library TOML reader; interpreter preflight prevents false validation on macOS's older Python |
| Node.js | 20+ for Pi discovery and its fixture checks | Native RPC adapter uses built-in modules only |
| PyYAML and tomli-w | `agent/requirements.txt` | Real YAML parsing and TOML serialization; handwritten parsers and skipped checks rejected |
| no-mistakes | `agent/tools.env` | One pin source for installation and doctor prevents two independent upgrade lists |
| AXI helper CLIs: gh-axi, chrome-devtools-axi, lavish-axi, quota-axi | `agent/tools.env` | Agent-ergonomic shell helpers are pinned by the same installer surface; absent helpers are optional, mismatched installed helpers are reported |
| Pi packages | `agent/pi/settings.json` | Adapter-specific exact package references |
| Canonical MCP packages | `agent/mcps/mcp-servers.json` | Exact versions of the locally exercised servers |
| Harness binaries, Claude plugins, any future unpinned MCP packages | Doctor's explicit floating inventory | Provider-managed updates remain visible; future compatibility is verified, never promised |

The operator manual for §3 and upgrades is [CONFIGURATION.md](CONFIGURATION.md).
After a provider upgrade, inspect its installed help/schema and discovery, run the platform gate and
doctor, then exercise any changed adapter. Green fixtures do not prove model activation, remote
service health, or a live delivery workflow.

## 9. Continuous integration

`.github/workflows/agent-platform.yml` runs source guards independently of the parser/test matrix.
`agent/scripts/check_coherence.py` reads the frozen list from §7 and checks each introduced commit
for both contract and decision updates; missing comparison inputs are reported as uncheckable, not green.
Its source checks catch the paid instruction-scope, duplicate-pin and procedural conflicts.
Docker's optional environment/syntax smoke is separately labeled and propagates failures; it does not
claim installer execution. Its quick wrapper invokes the same smoke command.
CI invokes `agent/tests/run.sh` on the Python floor and development interpreter, plus the same
source validation used locally. No duplicate GitHub test or delivery implementation lives in a skill.

Both jobs use read-only repository permissions, bounded timeouts and pinned actions. No deploy,
release, automatic merge or remote mutation is part of this workflow. Branch protections remain
repository administration; a successful workflow is evidence, not proof that bypass is impossible.
