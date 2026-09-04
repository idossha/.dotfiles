# Pi

Canonical configuration for the [Pi coding agent](https://pi.dev). Everything
here is version-controlled; `~/.pi/agent` is a thin set of symlinks pointing
back at it, created by `agent/scripts/sync-agent-config.sh`.

Pinned against Pi **0.84.4**.

## Files

| File | What it is |
|---|---|
| `settings.json` | Pi global settings: provider, model, thinking level, startup behaviour, and the pinned package list. |
| `extensions/` | Local TypeScript extensions, loaded by Pi from `~/.pi/agent/extensions`. |
| `agents/` | Subagent definitions read by `pi-subagents` from `~/.pi/agent/agents`. |
| `prompts/` | Prompt templates (`/name` slash commands) read from `~/.pi/agent/prompts`. Empty for now; `.gitkeep` keeps the directory so the symlink target exists. |

## Symlinks the sync script creates

| Target | Source |
|---|---|
| `~/.pi/agent/settings.json` | `agent/pi/settings.json` |
| `~/.pi/agent/extensions` | `agent/pi/extensions` |
| `~/.pi/agent/agents` | `agent/pi/agents` |
| `~/.pi/agent/prompts` | `agent/pi/prompts` |
| `~/.pi/agent/AGENTS.md` | `agent/memory/global.md` |

Two things Pi picks up without any setting here:

- **Skills.** Pi reads `~/.agents/skills` natively, and the sync script
  generates that directory (personal and domain skills from `agent/skills`,
  plus the agentic-rules playbook skills). There is deliberately no `skills`
  array in `settings.json` — adding one would load the same skills twice.
- **MCP servers.** `pi-mcp-adapter` reads `~/.agents/mcp.json`, which the sync
  script links to `agent/mcps/mcp-servers.json`. There is no `mcp.json` here.

## settings.json is written by Pi

Pi owns this file at runtime. `pi install`, `pi remove`, `/settings`, and the
changelog check all write through the `~/.pi/agent/settings.json` symlink into
this tracked file. Consequences:

- **Any `pi install` is a dotfiles change and must be committed.** Add a
  package with `pi install npm:<pkg>@<version>` (always with an explicit
  version), then commit the resulting `settings.json` diff.
- Pi adds a `lastChangelogVersion` key on first run after an update. That is
  harmless churn; commit it or leave it, but do not be surprised by it.
- Comments cannot live in the file — it must stay valid JSON. They live here.

Non-package settings, and why:

| Setting | Value | Why |
|---|---|---|
| `defaultProvider` | `openai-codex` | Codex subscription auth. |
| `defaultModel` | `gpt-5.5` | |
| `defaultThinkingLevel` | `xhigh` | |
| `quietStartup` | `true` | Hides the startup header. |
| `collapseChangelog` | `true` | Condensed changelog after an update instead of the full wall. |

## Packages

Every package is pinned to an exact version (`npm:<pkg>@<version>`). Pinned
specs are **skipped by `pi update` and `pi update --extensions`**, which is the
point: Pi itself updates freely, the extension surface does not move under the
maintainer. Bumping a package is a deliberate `pi install npm:<pkg>@<newver>`
plus a commit.

| Package | Version | What it does |
|---|---|---|
| `pi-subagents` | 0.64.0 | Delegation to focused child Pi sessions; reads `agents/*.md`, adds the `subagent` tool, FleetView, `/council`, `/subagents-doctor`. |
| `pi-intercom` | 0.13.0 | Child-to-parent (and user) messaging channel used by subagent runs. |
| `pi-interactive-shell` | 0.15.1 | An interactive shell tool for commands that need a live TTY. |
| `pi-web-access` | 0.27.0 | Web tools: `web_search`, `fetch_content`, `get_search_content`, `source_check`, plus the search curator UI. |
| `pi-side-chat` | 0.2.0 | A side conversation against a second model without polluting the main context. |
| `pi-boomerang` | 0.7.0 | Send work out and get it back into the session; round-trip task handoff. |
| `pi-mcp-adapter` | 2.32.1 | Bridges MCP servers from `~/.agents/mcp.json` into Pi tools (and `mcp:` entries in subagent frontmatter). |

### Packages are not auto-installed on 0.84

On Pi 0.84, packages listed in **global** settings are not installed at
startup — only project settings (`.pi/settings.json`) do that. Startup
auto-install of global packages arrived in Pi 0.82. So on a fresh machine the
list above is inert until something installs it. That is what
`agent/scripts/install-agent-tools.sh` is for: it runs `pi install` for each
pinned spec, skipping the ones already installed at the pinned version. It is
opt-in and never run by the sync script.

## Extensions

Local `.ts` files, each a default-export factory taking `ExtensionAPI`.

| File | What it does |
|---|---|
| `permission-gate.ts` | Confirms before `bash` runs `rm -rf`, `sudo`, or `chmod/chown 777`; blocks outright when there is no UI. |
| `git-checkpoint.ts` | `git stash create` at each `turn_start`, so `/fork` can offer to restore the code state of that point. |
| `vim-mode.ts` | Modal editing in the input box: escape for normal mode, `hjkl w b 0 $ x i a I A o O dd u p`, with a NORMAL/INSERT indicator. |

`permission-gate.ts` and `git-checkpoint.ts` are byte-identical to the examples
Pi 0.84 ships in `examples/extensions/`, so they track upstream exactly.
`vim-mode.ts` is local, and its API (`CustomEditor` from
`@earendil-works/pi-coding-agent`; `matchesKey`, `truncateToWidth`,
`visibleWidth` from `@earendil-works/pi-tui`; the
`setEditorComponent((tui, theme, keybindings) => ...)` factory signature) is
current for 0.84. The package was renamed from `@mariozechner/*` before 0.84;
extensions importing the old name fail to load.

`herdr-agent-state.ts` in this directory is generated by
`herdr integration install pi`, which writes it through the symlink. It is
produced from the installed herdr binary, so it is machine state, not
configuration, and `agent/pi/.gitignore` excludes it. The rule deliberately
does not live in `extensions/.gitignore`: Pi's resource discovery honours
`.gitignore`, `.ignore` and `.fdignore` files inside the directories it scans,
so an ignore file there hid the herdr integration from Pi itself (found and
fixed 2026-09-03; `herdr integration status` still said "current").

## Headless runs and verification

Three rules for driving Pi from a script:

- **Redirect stdin.** In print mode (`pi -p`) Pi reads piped stdin and merges
  it into the prompt, and it waits for end-of-file. A script whose stdin is an
  open pipe or socket that never closes hangs Pi forever with no output. Use
  `pi -p ... </dev/null` unless you mean to pipe content in.
- **Check what loads without spending a model call.**
  `node agent/scripts/pi-resources.mjs [dir]` runs Pi's own resource loader and
  prints the extensions, skills and context files a session in `dir` would get;
  it exits 1 on a load error, a skill diagnostic or a duplicate skill name. On
  2026-09-03 from `~/00_development` it reported 11 extensions (4 local, 7
  packages), 38 skills (the 8 playbook skills, 25 personal, 3 shipped by
  packages, herdr's), and two context files: `~/.pi/agent/AGENTS.md` (the
  shared memory file) and `~/AGENTS.md` (the dotfiles manual, which Pi picks up
  because it walks every ancestor directory up to the filesystem root).
- **A `refresh_token_reused` error is the login, not the config.** The
  `openai-codex` provider keeps an OAuth refresh token in `~/.pi/agent/auth.json`;
  when it has been rotated away Pi prints `OAuth refresh failed for openai-codex
  ... refresh_token_reused` and exits 1. Fix it interactively: start `pi`, run
  `/login`, pick `openai-codex`. Nothing in this directory can repair it.

## Agents

Markdown files with YAML frontmatter, read by `pi-subagents` from
`~/.pi/agent/agents`. A file here overrides a builtin of the same name
(`scout`, `researcher`, and `oracle` all ship with `pi-subagents`).

| Agent | Purpose |
|---|---|
| `scout` | Local codebase recon; read-only, returns a compact map. |
| `researcher` | Web/docs research with sources; returns a brief. |
| `oracle` | Adversarial second opinion on a plan before acting. |
| `academic-researcher` | Paper search plus local open-PDF verification, via the `librarian` skill. |

### Frontmatter

The core keys are the ones in Pi's own subagent example (`name`,
`description`, `tools`, optional `model`). The rest come from `pi-subagents`
and are confirmed supported in 0.64.0 (`docs/agents.md`, "Frontmatter
reference"):

- `systemPromptMode: replace` — the agent prompt replaces Pi's base prompt
  instead of appending to it.
- `inheritProjectContext` — keep or strip repository instruction files
  (`AGENTS.md`, `CLAUDE.md`).
- `inheritSkills` — let the child see Pi's discovered skills catalog.
- `skills` — select specific skills regardless of `inheritSkills`.

One behaviour change since these files were retired: `inheritProjectContext:
true` used to carry the operator's **global** context file too. In current
`pi-subagents` that is a separate key, `inheritGlobalContext`, defaulting to
`false`. `scout` and `oracle` therefore now set `inheritGlobalContext: true`
explicitly, which keeps their old meaning — they still see
`~/.pi/agent/AGENTS.md`, i.e. `agent/memory/global.md`. `researcher` and
`academic-researcher` set `inheritProjectContext: false`, which already
disables all context files, so they need no such key.

### Tool allowlists

`tools` is a **strict allowlist**: a name that no loaded package registers is
simply dead weight in the list. The retired files listed tools from an older
`pi-web-access` and from Codex's runtime (`web.run`, `web_search_advanced`,
`find_similar`, `get_code_context`, `deep_research_*`, `academic_search`,
`paper_fetch`, `academic_pdf_download`, `pdf_extract`, `arxiv_search`,
`arxiv_paper`). None of those exist under the packages pinned above, so the
lists were trimmed to what actually resolves:

- Pi builtins: `read`, `bash`, `edit`, `write`, `grep`, `find`, `ls`.
- `pi-web-access` 0.27.0: `web_search`, `fetch_content`, `get_search_content`,
  `source_check`.

The arXiv tools would come back with `pi-arxiv`; it is installed globally on
this machine but deliberately not in the pinned list.

Similarly, the retired `researcher` and `oracle` selected skills named
`web-research` and `academic-research`, which do not exist in `agent/skills`.
Those selections were dropped (`inheritSkills: true` still gives them the full
catalog); `academic-researcher` now selects `librarian`, the real skill for
that job.

Optional, not applied: `pi-subagents` supports `completionGuard: false` for
bash-enabled read-only agents (`researcher`, `academic-researcher`) so they are
never judged as implementation agents. Add it if the guard ever misfires.
