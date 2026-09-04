# codex

Canonical configuration for the OpenAI Codex CLI (`codex-cli`, verified against
0.136.0). Everything here is version-controlled; `~/.codex` holds symlinks back
to it, created by `agent/scripts/sync-agent-config.sh`.

## Files

| File | Linked to | What it is |
| --- | --- | --- |
| `config.toml` | `~/.codex/config.toml` | TUI settings, feature flags, trusted project roots, per-tool MCP approvals, and the generated MCP server block. |
| `rules/` | `~/.codex/rules` | Directory link. `rules/default.rules` is the execpolicy allow-list of command prefixes that run without an approval prompt. |
| — | `~/.codex/AGENTS.md` | Not stored here. The sync script links it to `agent/memory/global.md`, so Claude and Codex read the same global instructions. |

Codex treats `~/.codex/AGENTS.md` as *user instructions*, spliced in separately
from the per-directory project-doc walk — it is concatenated with project
`AGENTS.md` files, never overridden by them.

## The MCP block

`config.toml` ends with:

```toml
# BEGIN DOTFILES AGENT MCP
...
# END DOTFILES AGENT MCP
```

`sync-agent-config.sh` deletes everything between those two marker lines and
re-appends a freshly generated block at the end of the file, built from
`agent/mcps/mcp-servers.json` (`command` / `args` / `url` / `env` per server).
So:

- add or remove a server by editing the JSON, then re-running the sync script;
- never hand-edit inside the markers, and never delete a marker line;
- hand-written MCP settings that must survive a regeneration — the per-tool
  `[mcp_servers.<server>.tools.<tool>] approval_mode` entries — live *above* the
  `BEGIN` marker. Declaring a sub-table before its parent table is legal TOML.

## Writes that arrive through the symlink

`~/.codex/config.toml` is a symlink, so anything Codex or a companion tool writes
to it lands in this file and shows up in `git status`. Expected writers:

- **Trusting a folder** appends `[projects."<path>"] trust_level = "trusted"`.
- **`codex plugin marketplace add <url>`** appends a `[marketplaces.<name>]` table
  recording `source`, `source_type`, `last_revision` and `last_updated`. That is
  Codex's own marketplace format — Claude Code's plugin marketplaces are a
  separate registry and are *not* readable from here, which is why no
  `[marketplaces.*]` entry is carried over from the retired config.
- **`herdr integration install codex`** appends a `[hooks]` table (it also writes
  `~/.codex/herdr-agent-state.sh`, which is runtime state and stays out of git).
  It lands after the generated MCP block; a later sync moves the block below it,
  which is still valid TOML.

Review those additions like any other diff before committing; delete the ones
that are pure runtime state (Codex's `[notice.*]` prompt timestamps, for
example, which is why they were dropped when this config was rebuilt).

## Discovery facts worth remembering

- **Skills.** Codex reads `~/.agents/skills` natively, so no skills config
  belongs here. The sync script populates that directory from `agent/skills`.
  Codex also walks `<dir>/.agents/skills` for every directory from the project
  root down to cwd, plus `<repo>/.codex/skills`. `SKILL.md` frontmatter only
  needs `name` + `description`; unknown keys are ignored, so one skill tree
  serves Claude Code and Codex unchanged. Invoke with `$skill-name` or
  `/skills` — there is no `codex skills` subcommand.
- **AGENTS.md.** The walk starts at the nearest `.git` root and descends to cwd,
  taking at most one file per directory
  (`AGENTS.override.md` > `AGENTS.md` > `project_doc_fallback_filenames`) and
  stopping once the loaded text hits `project_doc_max_bytes`, 32 KiB by default.
  `config.toml` sets the fallback list to `["CLAUDE.md"]` so a repo whose only
  agent file is `CLAUDE.md` still gets read.
- **Headless runs.** Use
  `codex exec --json --output-last-message <file> -C <dir> "<prompt>"` for
  scripted work: `--json` streams machine-readable events, `--output-last-message`
  captures the final answer. `codex exec resume --last` continues the most recent
  session in the cwd.
- **`--full-auto` is a deprecated no-op** at 0.136.0 — it prints a warning and
  does nothing, and is removed on newer builds. Use `--sandbox workspace-write`,
  or `--dangerously-bypass-approvals-and-sandbox` (alias `--yolo`) for genuinely
  unattended runs.

## Checking the files

```bash
python3 -c 'import tomllib,sys; tomllib.load(open(sys.argv[1],"rb"))' \
  ~/.dotfiles/agent/codex/config.toml
codex execpolicy check --rules ~/.dotfiles/agent/codex/rules/default.rules -- git status
codex features list      # confirm every [features] key is still stable/experimental
```

Feature flags churn between releases. A key that `codex features list` reports as
`removed` should be deleted from `[features]`; a key missing from the list
entirely was never valid.
