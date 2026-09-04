# Multi-harness agent system: Claude Code, Pi and Codex under herdr

> **Historical design record.** `agent/docs/ARCHITECTURE.md` and `agent/docs/DECISIONS.md` supersede
> this plan. In particular, Treehouse now owns every agent worktree and Herdr owns only terminal/session
> visibility; do not follow the Herdr-created worktree recommendations below.

**What this is.** The design for running three coding harnesses from one canonical configuration
in `~/.dotfiles/agent`, with herdr as the session layer and the `agentic-rules` playbook as the
shared engineering doctrine, and the decision on which of Kun Chen's tools to adopt versus build.
Written 2026-09-03 from the facts in `agent/*/README.md`, Pi's bundled docs for 0.73, Codex
0.136's source, herdr 0.8.2's CLI and the tool repositories. It is the roadmap for `agent/`;
`AGENTS.md` here is the working manual.

## 1. Goals

1. One memory file, one skills tree, one MCP list — edited once, read by every harness.
2. Pi and Codex sessions follow the same doctrine as Claude Code: the agentic-rules skills fire
   unprompted, the hidden-app testing rule holds, releases stop at the tag.
3. herdr owns sessions: one workspace per repository, agents visible with their state, parallel
   work in worktrees, scripted control of one agent by another.
4. A "done" pipeline before a PR, an overnight loop with hard caps, and plan review as an artefact —
   the three things the playbook lacked that Kun Chen's workflow has.

## 2. The facts the design rests on (verified on this machine, 2026-09-03)

| Fact | Consequence |
|---|---|
| Pi reads `~/.pi/agent/AGENTS.md` plus every `AGENTS.md`/`CLAUDE.md` from cwd up to the filesystem root, so under `~` it also reads `~/AGENTS.md` (verified from inside tetravox with `pi-resources.mjs`); Codex reads `~/.codex/AGENTS.md` plus a root-to-cwd walk capped at 32 KiB; Claude reads `~/.claude/CLAUDE.md` | One file, three symlinks. `~/AGENTS.md` (linked since May to the 74-line dotfiles manual `agent/AGENTS.md`) lands in every Pi session as a second global file; keep it short and about the harness layout only, or drop the link if it ever crowds the context. |
| Pi's resource discovery honours `.gitignore`, `.ignore` and `.fdignore` inside the directories it scans (extensions, skills, packages) | A generated extension is excluded from git one level up (`agent/pi/.gitignore`), never from inside `extensions/`; the herdr integration was invisible to Pi until this was fixed on 2026-09-03. |
| In print mode `pi -p` reads piped stdin and waits for end-of-file; a non-TTY stdin that never closes blocks the run with no output | Every scripted call is `pi -p ... </dev/null` unless content is meant to be piped. `agent/scripts/pi-resources.mjs` checks what loads without a model call. |
| Pi and Codex both read `~/.agents/skills` natively; Codex's parser keeps only `name`, `description` and ignores other keys; Pi warns and loads | The playbook's name+description skills are portable as they are. `~/.agents/skills` is generated as one symlink per skill; nothing is copied. |
| Claude Code reads only `~/.claude/skills` and namespaces plugin skills `agentic-rules:<name>` | The playbook stays a Claude plugin; it is never linked under `~/.claude/skills` (it would load twice). |
| `pi-mcp-adapter` reads `~/.agents/mcp.json` (the `mcpServers` schema); Codex wants a TOML `[mcp_servers.*]` block | One JSON list, one symlink for Pi, one generated block for Codex. |
| herdr 0.8.2 has `worktree create/open/remove`, `agent start/prompt/wait/list`, `integration install pi\|claude\|codex`, a socket API, `--remote`, named sessions, and ships a skill (`herdr --skill`) | herdr already does what `treehouse` and the session half of `firstmate` do. |
| Codex plugins install only from a `plugins/<name>/` layout with `.codex-plugin/plugin.json`; a plugin at the marketplace root is not listed (tested in an isolated `CODEX_HOME`) | The playbook can become a Codex plugin later by adding that layout; for this machine the symlinks are simpler and live. |
| Pi ≥ 0.82 auto-installs packages listed in global settings at startup; `pi install` writes through the settings symlink into the dotfiles | Packages are pinned in `pi/settings.json`; `install-agent-tools.sh` installs them explicitly so a fresh machine does not wait for the first launch. |
| Codex `--full-auto` is a deprecated no-op at 0.136; headless is `codex exec --json -o <file> -C <dir>` | Scripts use `exec`, never the alias. |

## 3. Layout

```
~/.dotfiles/agent/
  memory/global.md        -> ~/.claude/CLAUDE.md, ~/.pi/agent/AGENTS.md, ~/.codex/AGENTS.md
  skills/<name>/          -> ~/.claude/skills (whole tree); one link each in ~/.agents/skills
  mcps/mcp-servers.json   -> ~/.mcp.json, ~/.agents/mcp.json; rendered into codex/config.toml
  claude/                 -> ~/.claude/{settings.json,statusline-command.sh,templates}
  pi/                     -> ~/.pi/agent/{settings.json,extensions,agents,prompts}
  codex/                  -> ~/.codex/{config.toml,rules}
  herdr/config.toml       -> ~/.config/herdr/config.toml
  scripts/sync-agent-config.sh      links everything above (idempotent; --check validates)
  scripts/install-agent-tools.sh    opt-in: Pi packages, herdr integrations, external tools
~/00_development/agentic-rules/skills/<name>/   one link each in ~/.agents/skills (Pi, Codex);
                                                 Claude gets the same skills as the plugin
```

Rules that keep it coherent: a skill is authored in exactly one place; a harness-only setting lives
in that harness's own file; generated files (`~/.agents/skills`, the Codex MCP block, the vendored
herdr skill) are never hand-edited.

## 4. Adopt, build, or skip: the tool decision

The criterion: adopt a tool when it does one thing the stack lacks and supports all three
harnesses; build only the doctrine layer no tool can carry; skip what herdr already provides.

| Need | Decision | Why |
|---|---|---|
| Session layer, parallel worktrees, agent state, scripted control | **herdr (already installed)** | Native `worktree` and `agent` commands, integrations for pi/claude/codex, a socket API. `treehouse` adds pooled reuse but no terminal awareness; not needed. |
| Orchestrating a crew from one conversation | **Build thin, on herdr** (phase 3) | `firstmate` is an "agent distro" you run your primary session inside, with its own AGENTS.md as captain identity; it conflicts with a dotfiles-canonical AGENTS.md. Its herdr backend is worth reading (`bin/backends/herdr.sh`), and Claude Code's workflows plus the herdr skill cover the orchestration; a `captain` skill is the missing piece. |
| A definition-of-done pipeline to a clean PR | **Adopt `no-mistakes`, wrap with a `ship` skill** | It supports claude, codex and pi natively, runs in a disposable worktree with a fixed intent → rebase → review → test → document → lint → push → PR → CI pipeline, and reads gate-control config only from the trusted default branch. The `ship` skill supplies the doctrine it lacks (evidence from the hidden app, docs guard, decision line, PR body with risk). Trial on one repo first. |
| Overnight loops with hard caps | **Adopt `gnhf`** | Agent-agnostic (pi/codex/claude), iteration and token caps, commit per iteration, rollback on failure. The playbook gains the rule that an unattended run carries a cap. |
| Plan review as an artefact for Pi and Codex | **Adopt `lavish-axi`** | Claude Code has Artifacts; Pi and Codex do not. Skill-only install; prompt-level design-system matching. |
| AGENTS.md maintenance from transcripts | **Trial `backpass`** | Reads Claude, Codex and Pi transcripts; two-session evidence per edit; human-gated apply. Needs `acpx`. Compare with the playbook's manual gotcha rule after one month. |
| GitHub and browser tools that cost less than MCP | **Adopt `gh-axi` skill; keep Playwright MCP for tests** | Benchmarked 100% success at lower cost than `gh` and the GitHub MCP. `chrome-devtools-axi` is optional; the frontend skill's review loop already uses Playwright. |
| Tool design for our own CLIs (docx-tools, TI-Toolbox, idosleep) | **Adopt the AXI principles into `mcp-authoring`** | TOON output, minimal schemas, truncation with `--full`, definitive empty states, structured errors and exit codes: the guard exit-code rule generalized. |
| Headless driving of any harness from a script | **Adopt `acpx` when a tool needs it** | Only `backpass` and non-native `no-mistakes` targets need it; herdr's `agent prompt --wait` covers interactive control. |
| Pi MCP, subagents, messaging | **Adopt `pi-mcp-adapter`, `pi-subagents`, `pi-intercom` (pinned)** | Pi ships none of these by design; these are the maintained packages the maintainer already used. |
| Voice input | Personal choice; not configured here | |

## 5. Phases and their gates

**Phase 1 — foundation (this change).** `agent/pi`, `agent/codex`, `agent/herdr`, the extended
sync script, `~/.agents/skills` generation, the harness-neutral memory file, `install-agent-tools.sh`.
Gate: `sync-agent-config.sh --check` green; after `sync`, `readlink` of every target in §3 resolves;
Pi lists the playbook skills at startup; `codex mcp list` shows the three servers; `herdr config
check` passes; `herdr integration status` shows pi, claude and codex installed.
Status 2026-09-03: every item verified except a live model reply from Pi, which is blocked on
the `openai-codex` login (`refresh_token_reused`; run `/login` in an interactive `pi`). The Pi
skill check used `agent/scripts/pi-resources.mjs`: 11 extensions, 38 skills including the 8
playbook skills, no duplicates, no diagnostics; Codex listed the same 33 dotfiles and playbook
skills. Phase 2's tools are not installed yet (`install-agent-tools.sh --tools` is opt-in).

**Phase 2 — the pipeline and the loop.** Install `no-mistakes` and `gnhf` (`install-agent-tools.sh
--tools`); run `no-mistakes init` in one low-stakes repo (tetravox-seeg or docx-tools); write
`.no-mistakes.yaml` with the repo's test and lint commands; add the `ship` skill to agentic-rules
(intent recap → worktree → rebase → adversarial review → hidden-app evidence → docs pass → PR body
with intent, changes, tests, evidence, risk) with six eval cases; add the loop-cap rule to
`agent-instructions`. Gate: one PR produced end to end by the pipeline with evidence attached; one
overnight `gnhf` run on a verifiable objective that ends at its cap.

**Phase 3 — the captain.** A `captain` skill (agentic-rules) that, inside a herdr pane, splits a
request into tasks, creates a worktree per task with `herdr worktree create`, starts an agent per
task with `herdr agent start`, waits with `herdr agent wait`, and reports; Claude Code sessions use
workflows for the same shape. Gate: three parallel tasks from one prompt, each landing as a PR
through the pipeline.

**Phase 4 — maintenance.** `backpass` trial on tetravox; `agent-instructions` records the outcome;
the trigger evals run for Pi and Codex too (`pi -p --mode json` and `codex exec --json` with the
must-trigger prompts, graded on whether the skill's doctrine appears in the answer).

## 6. Open questions

- Whether Codex resolves symlinked entries under `~/.agents/skills` (its walk reads directory
  entries; the entry type of a symlink may not test as a directory). Verified empirically in
  phase 1's gate; the fallback is `~/.codex/skills` as a whole-directory symlink.
- Pi was upgraded from 0.73 to 0.84.4 on 2026-09-03 with `npm install -g @earendil-works/pi-coding-agent`
  (it was an npm global, not a brew formula; the package was renamed from `@mariozechner`, and the
  three tracked extensions import the new name). Current package releases require it.
- herdr's licence: its site says Apache-2.0, firstmate's docs say AGPL/commercial. Read the
  LICENSE file before redistributing anything that embeds it.
- The `.claude/settings.json` on this machine is a regular file that the sync script will replace
  with the dotfiles symlink; the dotfiles copy was reconciled on 2026-09-02, so nothing is lost,
  but any setting changed since then in the live file should be diffed first.
