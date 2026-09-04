# GNHF agent-platform coherence assessment — 2026-09-04

This assessment compares the leased dotfiles snapshot with [the architecture contract](../ARCHITECTURE.md),
[the project map](../../AGENTS.md), and [portable memory](../../memory/global.md). It records defects and
proposed checks; it does not amend the contract, implement fixes, or close the platform's live-trial gate.

**Status: the GNHF coherence assessment is complete.** All requested domains and all 25 personal skill
headers and their relevant procedural bodies were reviewed. There are 15 findings below. Completion means
assessment coverage, not that the platform is defect-free or its live integrations have passed.

## Scope and evidence limits

- Audited source: commit `920d4f1a54b6a790d5a9cdc8d907538e5931418d` in the current Treehouse lease.
  Repository citations below are relative to that snapshot, with one-based line numbers.
- The existing root `AGENTS.md` is an absolute symlink into the primary checkout. It was not used as a
  write target. This report is the only intended tracked change. No implementation, HOME configuration,
  external playbook, worktree lifecycle, git commit, push, GUI, or live integration was changed.
- The parent reports fixes for state precedence, Claude user MCP scope, global/project map leakage,
  duplicate Codex skill links, the root AGENTS link, the Python requirement, and the Codex manual. Those
  fixes are not independently established by this older snapshot and are not re-filed here. The
  remaining skill, manual, pipeline, and ownership findings are for reconciliation with the parent's work.
- The aborted run's six agent messages were read selectively. Its completion and verification claims
  were not adopted as evidence; this report was reconstructed from source and fresh checks.
- External `agentic-rules` and installed package/plugin source were read only. Installed-source evidence
  is dated machine evidence, not a guarantee about another installation or a future package version.
- Severity: **High** can materially misdirect work or conclusions; **Medium** breaks a stated ownership,
  reliability, or command contract; **Low** is bounded drift or ambiguity with an existing mitigating rule.
  Consequences inferred from instructions are distinguished from executed reproductions.

## Verification actually performed

| Check | Observed result | What it establishes |
|---|---|---|
| `agent/tests/run.sh` | Exit 1: 38 of 39 checks passed | The failing check expects the leased `agentctl`, while sourcing the canonical zshrc resolves the primary checkout. Other checks cover fixtures, dry-run construction, and a fake Treehouse/GNHF execution. |
| `agent/scripts/agentctl doctor` | Exit 0 | Found installed tools and matching adopted-tool pins. It does not establish links, MCP health, plugin parity, or successful harness orchestration; see F08. |
| Individual `bash -n` calls for `agent/scripts/*.sh`, `agent/scripts/agentctl`, `agent/tests/*.sh` | Passed | Every matching shell entry point parsed. A single `bash -n file1 file2` would only parse the first script, so each was checked separately. |
| Independent PyYAML frontmatter parse | 25 personal + 8 external headers parsed; no missing name/description or cross-tree name collisions | Header validity and unique names, not trigger quality, permissions, or live skill discovery. |
| Installed Claude playbook versus local playbook | Two of eight `SKILL.md` bodies differ | Cached `architecture-contract` and `changelog-release` still prescribe raw Git worktree creation; see F04. |
| Offline command probes | Confirmed false doctor success, argv splitting, undocumented exit 23, and incomplete memory-field screening | Actual repository commands ran with temporary fixtures/stub dependencies. No real remote, tool install, or lease operation ran. |
| Pi checkpoint callback probe | Failed fake stash apply still produced a success notification | Imported the actual TypeScript extension with fake Pi/GUI/Git interfaces; no real UI or Git operation ran. |
| Legacy Git bootstrap probes | Valid invocation exits 1 before initialization; direct helper probe executes description text | The injection demonstration applies to the helper, not a successful end-to-end CLI invocation; see F11. |

Raw logs, fixture files, the snapshot diff, and structured probe results are confined to
`.gnhf/runs/assess-the-agentic-c-f8ef2b/audit-evidence/`; they are not report attachments to commit.
The platform failure is existing snapshot behavior, not introduced by this documentation-only change.
Coordinate its correction with the parent's test-coverage work.

## Confirmed findings

### F01 — High: a general manuscript review imports one study's facts as requirements

**Evidence.** `agent/skills/manuscript-review/SKILL.md:4` triggers for a scientific manuscript generally;
its pass definitions at lines 57–59 prescribe the left insula and a particular statistical contrast.
`agent/skills/manuscript-review/checklists/consistency.md:12` says sample size “must read identically
everywhere: `n = 43` total, `32 active + 11 sham`”; line 14 requires `0.0942`, line 18 requires 5000
permutations, and line 25 says the target “must be the **left insula** everywhere.” These are operative
checks, not merely labeled examples. `agent/skills/manuscript-review/SKILL.md:78` says decisions belong to
the project but then embeds the sleepTI decision list. This conflicts with the ownership boundary in
`agent/docs/ARCHITECTURE.md:54` and the project-facts boundary in `agent/memory/global.md:53`.

**Affected harnesses and impact.** All three receive this personal skill through
`agent/scripts/sync-agent-config.sh:378`. A different study can be falsely flagged or steered toward
another study's target, numbers, and analysis decisions. That consequence is inferred; no manuscript was
processed during this audit.

**Minimal fix.** Move those invariants and decisions into the relevant manuscript project. Keep the
number-ledger, source verification, ownership, and annotation mechanics generic. Derive invariants from
each target's own materials; label illustrative numbers explicitly.

**Regression check.** Use two synthetic manuscripts with different valid targets, sample sizes, and
permutation counts. Each must pass its own consistent facts; plant one within-document discrepancy and
require a finding. No finding may import sleepTI constants into the other manuscript.

### F02 — Medium: canonical-edit instructions escape the leased checkout

**Evidence.** `agent/skills/write-skill/SKILL.md:24` says “Always write to
`~/.dotfiles/agent/skills/<skill-name>/SKILL.md`, then run” the home checkout's sync script; lines 160–161
repeat it. `agent/skills/mcp-authoring/SKILL.md:15` and line 21 give the same primary-checkout edit/sync
route for MCP work. `agent/herdr/README.md:38` gives a primary-checkout editor command, and line 113
redirects generated skill output there. In contrast, `agent/treehouse/README.md:35` says to work only
under the leased path, and lines 49–50 forbid redirecting an agent to edit the source checkout.

**Affected harnesses and impact.** Claude, Codex, and Pi editing dotfiles in a lease. These instructions
can bypass isolation or activate unfinished policy in live HOME configuration. Global/session worktree
rules currently take precedence; this is a confirmed instruction conflict, not an observed escaped write.

**Minimal fix.** Resolve canonical files inside the active dotfiles checkout. Separate authoring and
read-only checks from activation, using the landed installation source for an authorized sync. A read-only
reference to an installed skill is not itself a violation.

**Regression check.** In a synthetic primary/lease layout, exercise skill and MCP edit instructions with
an immutable primary sentinel. Only lease files may change and no sync may run during assessment or
authoring-only work; validate activation separately after landing.

### F03 — Medium: shared skills assume Claude's tools and runtime contracts

**Evidence.** `agent/skills/orchestrator/SKILL.md:13` requires the `Agent` tool; lines 17–19 prescribe
`Explore`, `Plan`, and `general-purpose`, and line 31 universally says subagents inherit no conversation.
Pi instead has explicit context/skills inheritance fields in `agent/pi/agents/scout.md:6` and
`agent/pi/agents/oracle.md:6`, and installs its own subagent implementation at `agent/pi/settings.json:8`.
`agent/skills/mne-python/SKILL.md:15` and lines 25–27 require `${CLAUDE_SKILL_DIR}` for an otherwise
portable Python helper. `agent/skills/write-skill/SKILL.md:66` presents Claude model, tool-approval, fork,
and argument fields as the authoring schema; lines 152–156 present fixed compaction budgets without a
harness/version qualifier. None of these bodies is translated by `sync_skills` at
`agent/scripts/sync-agent-config.sh:395`.

**Affected harnesses and impact.** Primarily Pi/Codex, plus Claude after provider changes. An unset
`CLAUDE_SKILL_DIR` makes the documented helper path `/scripts/mne_api_lookup.py` rather than the skill's
actual file. A metadata declaration is not a portable authorization boundary. The installed Pi parser
at `/opt/homebrew/lib/node_modules/@earendil-works/pi-coding-agent/dist/core/skills.js:255` retains
name, description, paths, source, and `disableModelInvocation`; it does not turn the other listed fields
into Claude-equivalent runtime controls. Pi does recognize `disable-model-invocation`; it would be wrong
to claim that every extended field is ignored.

**Minimal fix.** Keep delegation criteria portable and route tool names, inheritance, model selection,
and invocation controls through a small harness-specific section. Resolve helpers relative to the loaded
skill's path, with a Claude variable only as an optional adapter. Qualify or remove runtime budget claims.

**Regression check.** Evaluate the same bounded delegation and MNE-lookup prompts in each harness with
Claude variables absent in Pi/Codex. Require available tool names, deliberate context inheritance, and
the existing helper path. Test declared side-effect controls against actual discovery, not YAML parsing.

### F04 — Medium: Claude's playbook snapshot contradicts the live Pi/Codex playbook

**Evidence.** `agent/scripts/sync-agent-config.sh:400` links the external working-copy skills for
Pi/Codex. Claude enables the plugin at `agent/claude/settings.json:141`, with marketplace auto-update at
line 156. `agent/skills/README.md:93` explicitly acknowledges that the installed plugin is a snapshot.
There is no revision/content parity check in `agent/scripts/agentctl:170`.

The machine's installed snapshot
`/Users/idohaber/.claude/plugins/cache/agentic-rules/agentic-rules/0.2.0/skills/architecture-contract/SKILL.md:92`
still recommends `git worktree add ../<repo>-gate <tag>`.
`/Users/idohaber/.claude/plugins/cache/agentic-rules/agentic-rules/0.2.0/skills/changelog-release/SKILL.md:63`
recommends `git worktree add ../<repo>-wt-<name> -b feat/<name> origin/main`. The read-only local files
now defer to the selected provider at
`/Users/idohaber/00_development/agentic-rules/skills/architecture-contract/SKILL.md:92` and
`/Users/idohaber/00_development/agentic-rules/skills/changelog-release/SKILL.md:62`. The other six bodies match.

**Affected harnesses and impact.** Claude receives stale lifecycle procedures while Pi/Codex receive
the corrected ones. The global Treehouse override and Claude worktree deny rules mitigate this; no raw
worktree was allocated. Auto-update of a marketplace does not prove the installed skill bodies match a
local working copy.

**Minimal fix.** Reconcile the authorized plugin snapshot with the intended playbook revision, then
report installed versus intended revision/content in health checks. Do not copy plugin skills into the
personal skills tree or modify external doctrine from this audit.

**Regression check.** Compare all eight body digests for the intended revision and the installed plugin.
A fixture containing the stale raw-worktree instruction must produce an actionable drift result; missing
plugin/source inputs must report unavailable rather than match.

### F05 — Low: fallback commit procedures retain a competing house style

**Evidence.** `agent/skills/git-collaboration/SKILL.md:40` through line 73 owns commit formatting and
trailers, including “Use trailers consistently: `Co-authored-by: Name <email>`” at line 71. Its copy-ready
templates at `agent/skills/git-collaboration/references/templates.md:5` and line 143 provide additional
commit/release formats. The external authoritative
`/Users/idohaber/00_development/agentic-rules/skills/changelog-release/SKILL.md:49` owns title/body grammar,
and line 60 says “No `Co-Authored-By`, no session-URL trailers.” Ownership is assigned to that playbook at
`agent/docs/ARCHITECTURE.md:16`.

**Affected harnesses and impact.** All three. This is bounded procedural duplication: the generic skill
already defers to the house skill “when it is loaded” at lines 169–170, and global routing calls for it.
It is not evidence of an AI attribution actually being added, and a human coauthor example is not itself
an AI trailer. The remaining defect is maintaining contradictory copy-ready instructions behind a
conditional handoff.

**Minimal fix.** Keep git safety, branch/PR/issue collaboration, and authorization handling here; route
commit/changelog/release formatting to `changelog-release` before its first competing recipe. Remove or
clearly subordinate conflicting fallback examples.

**Regression check.** A commit-message prompt loading only the generic entry point must route to the
house formatter and obey its trailer policy. An issue-only prompt must remain an issue workflow and must
not start release preparation or remote writes.

### F06 — Medium: skill-authoring and a Claude template misroute project doctrine and memory

**Evidence.** `agent/skills/write-skill/SKILL.md:167` says “Facts about the codebase belong in CLAUDE.md.”
`agent/skills/manuscript-review/SKILL.md:50` directs project-context intake to `CLAUDE.md`, and line 78
again uses it for the decision list. `agent/claude/templates/track-template.md:14` collects architecture
decisions separately; lines 34–38 prescribe `pytest`, `black .`, and memory in `memory/agent-state.md` or
`MEMORY.md`. The template is installed at `agent/scripts/sync-agent-config.sh:422`; no current caller
was observed.
`agent/docs/ARCHITECTURE.md:14` assigns portable doctrine to the map/skills, while
`agent/skills/remember/SKILL.md:48` routes design decisions to project `docs/DECISIONS.md` and line 29
documents the CLI's project-memory destination.

**Affected harnesses and impact.** All skill authors; the extra template is Claude-only. Following the
recipe creates another project-facts authority and a second design/memory/test checklist. Fixed Python
commands are also inappropriate for non-Python projects. Existing AGENTS-first rules mitigate the conflict.

**Minimal fix.** Route facts through project AGENTS/docs, keep CLAUDE as their import plus actual
Claude-specific settings, and use the architecture decision log. Retire the unreferenced legacy template
or make it a task outline that links the project-owned tests, decisions, and memory locations.

**Regression check.** Give the authoring workflow a project with `AGENTS.md`, a one-line CLAUDE import,
and a non-Python test command. It must leave the import intact, select that command, and record a design
decision in the existing log without creating a parallel memory/decision authority.

### F07 — Low: active manuals still describe the superseded platform

**Evidence.** `README.md:147` says “Claude Code is the only harness in use” and Pi/Codex are not synced.
`agent/skills/README.md:3` likewise says Claude is the only linked harness, contrary to the actual
three-harness dispatch at `agent/scripts/sync-agent-config.sh:470`. `agent/herdr/README.md:96` and line 97
say integration installation writes through Claude/Codex settings symlinks into tracked files, whereas
`agent/scripts/sync-agent-config.sh:319` and line 345 remove those symlinks before replacing effective
files. `agent/tests/README.md:16` still describes the entrypoint as FirstMate/Pi while
`agent/scripts/agentctl:150` starts Herdr alone. `agent/skills/grafana/SKILL.md:376` points to absent
`references/dashboard-design.md`; its two related skills at lines 380–381 are absent from both reviewed
skill inventories.

**Affected harnesses and impact.** All operators and skill consumers. These are active manual/reference
defects. In contrast, `agent/MULTI-HARNESS-PLAN.md:3` is explicitly historical and superseded; its old
recommendations are not independently re-filed as current instructions. The parent owns the separately
identified Codex-manual correction.

**Minimal fix.** Correct the active routing/manual text, link to current ownership documentation, and
remove or supply the missing reference. Identify optional external related skills as such. Keep dated
history intact rather than rewriting it into a second current manual.

**Regression check.** Validate repository-relative references and manually/assertion-check the small
current ownership/command table against the sync/CLI code. A missing reference and the old
FirstMate-on-start statement must fail the check; explicitly historical records must remain allowed.

### F08 — Medium: doctor can report healthy tools without checking its advertised properties

**Evidence.** `agent/scripts/agentctl:142` discards version-command failure with `|| true`, then line 143
prints `[ok]`. `doctor` at lines 170–242 checks registry paths, executables, pins, and the FirstMate backend;
it never checks generated links, installed Herdr hook health, skills, or MCP declarations. Nevertheless
`agent/AGENTS.md:8` advertises links/integrations/floating-dependency inspection, and
`agent/docs/ARCHITECTURE.md:45` requires pins or explicit floating reports.
`agent/mcps/mcp-servers.json:6`, line 13, and line 20 contain three floating npx packages. None appeared
in the successful doctor output.

**Affected harnesses and impact.** All three and every caller treating doctor success as the platform
gate. An offline fixture made every harness plus Herdr/jq version probe exit 17; doctor still exited 0
and printed their error text as `[ok]`. This proves the failure masking, not merely a missing test.

**Minimal fix.** Preserve probe exit status and explicitly classify optional/unavailable tools. Add the
promised nonmutating link, integration, and floating-input checks, or narrow the health claim and provide
separate gates. Retain honest “not checked” results when live inspection is out of scope.

**Regression check.** With stub version failures, broken generated links, stale plugin bodies, and
floating MCP packages, assert each is visible and required failures are nonzero. Missing optional tools
must be labeled optional, never healthy. The test must not require network or live hooks.

### F09 — Medium: the visualization argv contract splits embedded newlines

**Evidence.** `agent/scripts/agentctl:98` validates visualizations as arrays of nonempty strings, but
`project_field` at line 125 serializes them with `"\n".join(command)`. Lines 266–267 then reconstruct the
array one line at a time. This loses argv boundaries for legal string values.

**Affected harnesses and impact.** Any `agentctl project --visualization` caller. A real offline command
with one argument containing `first\nsecond` received two arguments, `first` and `second`, and exited 0.
No shell eval is involved here; the confirmed defect is argument corruption.

**Minimal fix.** Use a boundary-preserving encoding, or explicitly reject newline-containing arguments
in the schema if they are intentionally unsupported. Keep execution as an argv array.

**Regression check.** Use an independent argv-recording executable and cover spaces, quotes, embedded
newlines, and leading hyphens. Assert exact array equality after actual execution, rather than searching
dry-run output for fragments.

### F10 — Low: upstream exit codes contradict the documented closed CLI code set

**Evidence.** `agent/scripts/agentctl:44` documents only 0–4 and assigns failed upstream commands to 1.
However `run_command` at line 67, `fleet` at line 339, `overnight` at line 396, and `ship` at line 414
propagate arbitrary upstream statuses. A fake opted-in no-mistakes process exiting 23 made `ship` exit 23.

**Affected harnesses and impact.** Shell scripts and all harnesses branching on the advertised codes.
Preserving upstream status can be a valid design; the confirmed problem is the incompatible public claim.

**Minimal fix.** Choose one contract: normalize upstream failure to 1 while reporting the original code,
or document explicit upstream-code propagation and its ambiguity with local codes. Update the frozen
CLI contract/decision log when implementing that choice.

**Regression check.** Run stub commands exiting 0, 2, 23, and a signal-derived status through each
execution path and assert the selected documented mapping. Retain local usage/precondition/dependency
checks so they cannot silently change meaning.

### F11 — Medium: the legacy GitHub bootstrap is a broken, separate publishing path

**Evidence.** `zsh/GITHUB_SETUP.md:7` advertises the script. In `zsh/init_github_repo.sh:28` visibility
defaults to public; line 29 ends the argument-parser function with a false `[[ ... ]] && ...` for valid
input. With `set -e` at line 4 and the ordinary call at line 59, a valid invocation exits 1 before
initialization. The offline full-script probe reproduced this with fake git/gh.

The dormant publisher at lines 46–49 constructs `CMD` from repository name/description and uses `eval`,
including `--push`. Invoking that function alone with a harmless command substitution as description
created a fixture marker and called fake gh with public/push flags. Line 54 additionally stages all files.
The script does not select an SSH remote protocol, contrary to `agent/memory/global.md:13`; no claim is
made that a real remote was HTTPS, since no remote was created. This duplicates publication decisions
outside the shared git workflow and project-opted-in delivery surface.

**Affected harnesses and impact.** Any agent/operator following this setup manual. Today the valid CLI
path is broken; fixing only its early return would expose the unsafe publisher. The injection result is
explicitly a helper-level reproduction, not evidence of successful end-to-end exploitation.

**Minimal fix.** Retire this surface or repair the parser together with the publisher: use argv, explicit
visibility/publication authority, intended-file staging, and SSH. Reuse the shared git workflow; do not
make a parser-only repair that silently enables the old eval/public-push behavior.

**Regression check.** Stub git and gh to log argv and never contact a remote. Valid input must reach the
intended phase; quotes, spaces, dollar substitutions, and semicolons must remain literal descriptions.
Publication must require its selected explicit mode and must preserve unrelated files and SSH policy.

### F12 — Medium: Pi's checkpoint extension announces restoration after a failed merge

**Evidence.** `agent/pi/extensions/git-checkpoint.ts:4` promises fork restoration. Lines 22–25 create a
dangling stash checkpoint in a process-local map; lines 44–45 await `git stash apply` but ignore its
result and unconditionally notify “Code restored to checkpoint.” Lines 49–51 clear the map when the
agent settles. `stash apply` reapplies changes onto the current tree; it is not exact replacement of a
past tree, and it can conflict. This is a second Git mutation owner beyond the agent's explicit workflow.

**Affected harnesses and impact.** Pi with this discovered extension. A callback-level probe of the
actual TypeScript module returned code 1 from the fake apply operation and still received the success
notification. After `agent_settled`, the same fork entry caused no apply call. No real Git or UI ran.
Durability and exact restoration were not proved by this extension's name or notification.

**Minimal fix.** Check errors and report conflicts. Decide whether the feature is a temporary patch
reapply aid or a durable, exact checkpoint system; name and document that boundary before adding restore
behavior. Any replacement must preserve current user work and remain separate from Treehouse allocation.

**Regression check.** Fake-Pi callback tests must cover failed create/apply, canceled confirmation,
headless operation, and fork after settlement. A later real temporary-repository test should compare
tracked/untracked/index states before claiming exact restore, with no destructive implicit fallback.

### F13 — Medium: the advertised test surfaces do not form an enforced platform gate

**Evidence.** `README.md:48` routes testing to `testing/test_docker.sh test`. That script labels execution
of installers “Testing script help output” at line 68, but lines 69–70 call them without help flags and
pipe output into `head`. The inner shell has no fail-fast/pipefail setting and ends with success text at
lines 73–74. The work variant at line 100 turns installation failure into an “expected” warning and
line 115 similarly swallows uninstall failure. Neither invokes the agent-platform suite.

There are no tracked `.github` workflow files (`git ls-files .github` returned empty), while
`agent/docs/ARCHITECTURE.md:86` enumerates four frozen interfaces whose changes require contract and
decision updates. The current suite at `agent/tests/run.sh:95` onward validates useful CLI cases but
does not enforce that diff relationship. Its zsh-path check at lines 66–68 also fails in this actual lease.
Remote branch protection or external CI was not inspected and cannot be declared absent from this evidence.

**Affected harnesses and impact.** All agents relying on local/CI green as proof. Distinct installation
and platform suites are legitimate; success-shaped installer output and an unconnected platform gate are
the defects. Docker was not run, and its host-socket mount was not exercised.

**Minimal fix.** Label environment smoke checks honestly and propagate installer failures. Provide one
repository-owned gate entrypoint for offline platform checks and wire the required frozen-interface
guard using the external playbook. Keep expensive install tests separate by cost; coordinate with the
parent's test-isolation work instead of adding a competing suite.

**Regression check.** A fake failing installer must make the advertised install test fail. A frozen-file
only diff must fail the guard; a paired contract/decision update must pass; missing base/input must report
degradation or failure honestly. Run the offline platform entrypoint from a leased path as well as the
primary checkout. Server-side required-check configuration remains a separate verification.

### F14 — Medium: memory's credential-shaped-text rejection covers only the message

**Evidence.** `agent/skills/remember/SKILL.md:9` says the CLI refuses text that looks like a secret.
`agent/scripts/remember:239`, line 253, and line 261 call `reject_secrets(args.message)` only. The same
commands persist `topic` and `source` at lines 201–206, line 227, and lines 279–286 without that check.
The three storage routes themselves match the documented defaults at lines 299–318.

**Affected harnesses and impact.** All callers. An offline project-memory fixture rejected a synthetic
credential-shaped marker in `--message` with exit 1, but accepted the same marker in `--source`, exited
0, and stored it. No real credential was used or copied into this report. The heuristic is a backstop,
not a comprehensive secret detector; this finding concerns inconsistent application of that backstop.

**Minimal fix.** Apply screening to all persisted free-text fields before creating/writing a destination.
Keep the documented human judgment requirement and explicit destination overrides; an override is not
itself a routing defect.

**Regression check.** Run message/topic/source fixtures through crystal, project, and raw routes using
temporary destinations and SQLite. Matching synthetic markers must reject before any file or row is
written; ordinary safe metadata must remain usable.

### F15 — Medium: telemetry's dynamic repository/release claims are hardcoded in its procedure

**Evidence.** `agent/skills/telemetry-triage/SKILL.md:21` says supplied paths override defaults, but actual
commands at lines 41–42 and lines 79–80 still name fixed checkouts. Step 5 at line 77 says “Compare against
the current release,” then explicitly reads tag `v2.3.1` and its release-note file. Line 104 embeds another
fixed version in suppression guidance. These duplicate current project facts instead of reading the
target projects' authoritative state. `agent/skills/telemetry-triage/SKILL.md:139` also restates the stats
repository's implementation/validation contract, which needs verification before maintenance.

**Affected harnesses and impact.** All three when this explicitly scoped domain skill is invoked. The
generic classification and artifact-first procedure is useful specialization, but an alternate checkout
or later release can be assessed against the wrong evidence. No claim is made about the latest remote
TI-Toolbox release or current BigQuery state; neither was queried.

**Minimal fix.** Resolve target paths once from the invocation/project registry, read current release and
triage schema from those projects, and substitute those values into commands. Treat human/agent review
at lines 28–35 as eligibility for an issue action, not additional authority to publish: existing user
authorization and the shared git boundary still govern lines 89–91. Do not add repeated approval prompts
when authorization is already present.

**Regression check.** Use two fixture checkouts with different release tags and triage data, plus a fake
GitHub CLI. Path overrides must select the requested checkout; classification must use its selected
release. An assessment-only request must produce artifacts with zero issue/workflow writes. Authorized
application must act only on reviewed targets.

## Complete personal-skill overlap review

All 25 frontmatter blocks were parsed independently. All relevant ownership, trigger, tool, write,
testing, reporting, and delegation instructions were inspected. Scientific algorithms and third-party
API accuracy were not revalidated as a neuroscience/library audit. The rows below account for every
personal skill; overlap alone is not treated as a defect.

| Personal skill and body evidence | Ownership assessment |
|---|---|
| `bids` — `agent/skills/bids/SKILL.md:55`, line 254, line 347 | Dataset naming/metadata/validator specialization. Complementary to MNE, EEGLAB, and volume I/O; not a replacement for backend fixture provenance. |
| `code-quality` — `agent/skills/code-quality/SKILL.md:9`, line 65 | Broad review trigger is intentional. Behavior tests and boundary mocks complement the authoritative testing split; no independent release pipeline. |
| `docx-tools` — `agent/skills/docx-tools/SKILL.md:50`, line 106 | Owns Word mechanics and readback/revision semantics. Preserving human edits, independent office-suite parsing, and explicit output checks are useful specialization. |
| `eeglab` — `agent/skills/eeglab/SKILL.md:234`, line 241 | MATLAB/EEG conventions and sample-data smoke checks. These do not prove numerical correctness or replace backend tests; explicit `nogui` is aligned. |
| `engineering-discipline` — `agent/skills/engineering-discipline/SKILL.md:11` | Small scoped changes and meaningful verification are compatible general defaults, not a second CI/release implementation. |
| `git-collaboration` — `agent/skills/git-collaboration/SKILL.md:10`, line 165 | Git/PR/issue safety is distinct from release mechanics; commit/release recipes remain redundant (F05). Existing permission at lines 33–37 avoids repeat approval. |
| `grafana` — `agent/skills/grafana/SKILL.md:22`, line 370 | Dashboard JSON, queries, and provisioning are domain-specific, not the Lavish explanation surface. Missing reference/related-skill routing is F07; no dashboard was deployed. |
| `grill-me` — `agent/skills/grill-me/SKILL.md:14` | Explicit design-interview trigger and no implementation while questions remain. Its question loop is intentional when requested, not a default replacement for autonomous implementation. |
| `herdr` — `agent/skills/herdr/SKILL.md:10`, line 90, line 187 | Session control is separate from allocation. Explicit Herdr trigger, context checks, and no-focus defaults are useful. Same-cwd delegation at line 92 is appropriate for read-only review; writable parallel work must still honor Treehouse ownership. No collision was observed. |
| `librarian` — `agent/skills/librarian/SKILL.md:23`, line 34, line 107 | Owns collection/search/renaming/indexing, not manuscript critique. Explicit source acquisition and PDF checks complement reviewers. Claude-named tools/arguments need the provider routing in F03. |
| `manuscript-review` — `agent/skills/manuscript-review/SKILL.md:27`, line 52, line 100 | Soundness/consistency/literature owners and sequential fallback are useful. Cross-study facts are harmful (F01); provider/project routing is F03/F06. Annotation mechanics should continue consuming docx-tools. |
| `matlab` — `agent/skills/matlab/SKILL.md:11`, line 57 | Batch execution and numeric coding conventions specialize the backend/hidden-app rules. Batch/figure visibility statements are not a measured window-server test; none ran here. |
| `mcp-authoring` — `agent/skills/mcp-authoring/SKILL.md:10`, line 26 | Focused tool/config design complements general security review. Primary-checkout edit/activation recipe is F02. |
| `mne-python` — `agent/skills/mne-python/SKILL.md:10`, line 52, line 64 | MNE object/metadata preservation, synthetic data, and headless plotting are complementary. Helper-location assumption is F03. Writer readback is a smoke property, not an independent numerical oracle. |
| `neuroimaging` — `agent/skills/neuroimaging/SKILL.md:125`, line 172 | Coordinate/volume interoperability specialization; library ordering complements `web-neuroimaging`. No competing git/CI/release ownership. |
| `orchestrator` — `agent/skills/orchestrator/SKILL.md:11`, line 28 | Bounded in-session delegation is distinct from FirstMate supervision; provider assumptions are F03. Conditional manuscript fan-out adds domain decomposition, not an unconditional second orchestrator. |
| `python-production` — `agent/skills/python-production/SKILL.md:87`, line 93, line 160 | Python-specific refinements of code-quality; repeated import/type/subprocess defaults agree. No need to remove useful specialization just because triggers co-load. |
| `remember` — `agent/skills/remember/SKILL.md:12`, line 34 | Explicitly routes crystals/project facts/raw events and excludes design decisions from its memory log. Aligned storage responsibilities; field-screening implementation is F14. |
| `reviewer-response-docx` — `agent/skills/reviewer-response-docx/SKILL.md:8`, line 56, line 78 | Rhetorical structure and coverage for rebuttals; explicitly consumes docx-tools. Useful separation from critique, source acquisition, and raw document mechanics. |
| `scientific-computing` — `agent/skills/scientific-computing/SKILL.md:74`, line 94 | Array/plotting conventions, Agg backend, close figures, and profiling are useful numerical specialization. Plot output is not treated as proof of a rendered UI. |
| `security-review` — `agent/skills/security-review/SKILL.md:10`, line 33 | Review-order/trust-boundary checklist complements code-quality and MCP authoring. It does not supply or expand an execution permission policy. |
| `suna` — `agent/skills/suna/SKILL.md:15`, line 19, line 29 | Thin, project-triggered route to app-owned context and project memory. This is intentional provider specialization; do not impose generic spec.json/Word layout over a SUNA project. Installed SUNA context was not loaded or executed. |
| `telemetry-triage` — `agent/skills/telemetry-triage/SKILL.md:23`, line 77, line 139 | Domain classification and reviewed artifacts are legitimate; hardcoded project/release facts are F15. Its scheduled collector is a different operation from a publishing pipeline. |
| `web-neuroimaging` — `agent/skills/web-neuroimaging/SKILL.md:22`, line 59 | Documentation-research procedure complements numeric libraries and librarian's paper collection. Broad fallback sources are not equivalent to a verified primary source. |
| `write-skill` — `agent/skills/write-skill/SKILL.md:22`, line 66, line 167 | Correctly assigns cross-project procedures to the external playbook, but active authoring guidance has F02/F03/F06 conflicts. It should route harness-specific creator tooling, not become another portable doctrine authority. |

The eight external skills were compared for ownership: project-docs owns document shells,
agent-instructions owns agent maps, architecture-contract owns requirements/decisions/gates,
testing-backend owns nonvisual evidence, testing-frontend-offscreen owns rendering evidence, ci-guards
owns enforcement/job shape, docs-website owns the generated site, and changelog-release owns publication
preparation. Their triggers explicitly hand off adjacent concerns. For example,
`/Users/idohaber/00_development/agentic-rules/skills/testing-backend/SKILL.md:11` excludes GUI tests,
and `/Users/idohaber/00_development/agentic-rules/skills/docs-website/SKILL.md:8` excludes the markdown roster
and CI job shape. These are intentional
boundaries, not duplicate authorities. External changes are out of this audit's modification scope.

## Cross-layer coverage and ownership conclusions

| Requested domain | Source traced and conclusion |
|---|---|
| Orchestration | `agent/scripts/agentctl:321` launches the selected harness in FirstMate with `FM_BACKEND=herdr`; Pi roles and generic delegation are separate in-session facilities (F03). FirstMate is not copied into shared instructions. Running its own supervisor necessarily loads its own project doctrine; that is not evidence that dotfiles vendored it. |
| Worktree lifecycle | `agent/scripts/agentctl:378` allocates a durable lease, rejects the primary path, runs in the returned path, retains it, and prints lease-ID-bound return guidance. F02/F04 are remaining instruction conflicts. The happy path was tested with fakes; real allocation/reassignment/return was not exercised. |
| FirstMate's layer split | Read-only installed source: `/Users/idohaber/00_development/agent-tools/firstmate/bin/backends/herdr.sh:9` scopes Herdr to sessions; `/Users/idohaber/00_development/agent-tools/firstmate/bin/fm-spawn.sh:2550` sends `treehouse get`, then line 2596 validates isolation. `/Users/idohaber/00_development/agent-tools/firstmate/bin/fm-teardown.sh:1378` contains force-return machinery behind upstream lifecycle gates. Presence of that word alone does not prove unauthorized discard; the complete live guard/recovery path was not tested. |
| Memory routing | `agent/scripts/remember:239`, line 253, line 261, and line 295 implement the three destinations. Architecture decisions are explicitly delegated by the skill. F01/F06 are misplaced durable facts; F14 is incomplete screening. This task's requested `.gnhf` raw-log location overrides the general SQLite default. |
| Development doctrine | `agent/docs/ARCHITECTURE.md:48` assigns procedures to the external playbook. Shared standards mostly complement it; F05/F06 identify remaining recipe/routing duplication. |
| Testing | Existing fixtures have actual negative cases and a no-tests failure at `agent/tests/run.sh:235`; fake execution goes beyond dry-run at line 186. The failing lease-path assertion and legacy success masking are documented, not greenwashed (F13). Numeric/hidden-rendering doctrine was reviewed without running a GUI. |
| CI/CD | No tracked local workflow was found. F13 records the unenforced local gate and misleading legacy tests. External playbook CI/site/release templates are procedures to adopt, not extra pipelines already installed in this repository. Remote required checks and hosted workflows remain unverified. |
| Git and GitHub ownership | GNHF command construction at `agent/scripts/agentctl:366` adds limits without a push flag; ship at line 409 requires project opt-in. F11 exposes the separate legacy publisher; F12 exposes Pi's independent stash mutation. No-mistakes may own delivery after opt-in, but this audit did not prove its configuration or remote behavior. |
| CLI contracts | F08–F10 reproduce health, argv, and exit-contract defects. Registry argv validation, positive caps, and missing-tool checks are real, bounded improvements already present. The caps limit iterations/tokens, not guaranteed elapsed time or successful external completion. |
| Skills overlap | Every personal header/body is accounted for above. Unique names do not imply consistent procedures; F01–F07/F15 distinguish semantic conflicts from useful domain co-loading. |
| MCP declarations | `agent/mcps/mcp-servers.json:2` declares three servers once; `agent/scripts/sync-agent-config.sh:268` generates Codex's command/args/env/url form, and line 432 supplies Pi's shared JSON link. Floating packages are F08. Parent-owned Claude scope fixes are excluded. Richer transport/auth combinations are not exercised by these three declarations and were not certified. |
| Plugin discovery | Personal links and external playbook links are separate from Claude namespaced plugin installation. All 33 reviewed names are unique. F04 proves actual snapshot drift. `agent/scripts/pi-resources.mjs:41` calls the real loader's `reload`; it was inspected but not run because loading extensions can execute package code. The other declared plugins at `agent/claude/settings.json:138` (Rust LSP, frontend design, TI-Toolbox) are Claude adapter capabilities; their presence does not establish equivalent discovery in Pi/Codex. Their installed bodies were not audited as personal skills. |
| Provider assumptions | F03 and the inventory distinguish portable prose from Claude Agent/argument/environment assumptions, Pi event hooks, SUNA context, MATLAB installation paths, and app-specific document procedures. Frontmatter/tool allowlists are not equivalent enforcement across providers. |
| Upgrade robustness | Installer pins at `agent/scripts/install-agent-tools.sh:36` currently match doctor pins at `agent/scripts/agentctl:12`; maintaining two copies is a future drift risk, not an observed mismatch. Treehouse/no-mistakes archive checksums are checked before install at installer lines 226 and 304. Plugin drift and unreported floating MCP packages are already observable (F04/F08). |
| Authority boundaries | `agent/memory/global.md:25` preserves mandatory authorization while suppressing optional repeated prompts. Project ship opt-in and Treehouse retained leases are explicit boundaries. Pi's regex permission hook at `agent/pi/extensions/permission-gate.ts:11` handles a few bash patterns; it is not a general sandbox or proof that all external actions are gated. Parent owns permission-default remediation. No permission configuration was changed here. |

## Remaining live verification and handoff

The following remain **unverified**, rather than missing assessment coverage: actual harness startup and
model replies; effective Claude/Codex/Pi discovery after the parent's fixes; authenticated MCP tool calls
and browser headlessness; live Herdr state/focus and hook installation; FirstMate allocation, supervision,
wake/recovery, and guarded return; real GNHF execution/rollback/cap termination; no-mistakes project config,
delivery stages, merge/push authority, and CI results; plugin update behavior; remote GitHub protection
and workflow state; fresh-machine installs/upgrades; real GUI/rendering behavior and neuroscience API
correctness. Existing open live gates in `agent/docs/ROADMAP.md:21` should remain open until measured.

Reconcile findings against the parent's newer work, prioritize cross-project fact leakage and lifecycle
instructions, then repair the proven command/verification defects. Preserve the shared sources of truth:
do not duplicate release/testing doctrine into each harness, treat instruction precedence as mitigation
rather than a repair, and distinguish local fixture evidence from successful external operations.

No background process started by this assessment remains running. No commit or push was made. The
GNHF coherence assessment is complete; implementation and live integration trials are separate work.
