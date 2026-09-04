# herdr

Canonical configuration for [herdr](https://herdr.dev) (verified against 0.8.2),
the session layer every agent in this setup runs inside.

`config.toml` is linked to `~/.config/herdr/config.toml` by
`agent/scripts/sync-agent-config.sh`.

## What herdr does here

herdr is a background session server with attachable clients — tmux-shaped
(workspace → tab → pane, prefix-key model) but not built on tmux, and agent-aware
on top of that:

- **A workspace per repo.** Each workspace holds its own tabs and split panes and
  remembers its cwd; detaching leaves every process running and re-running `herdr`
  reattaches. `herdr server stop` ends the session.
- **An agent-state sidebar.** herdr detects which coding-agent CLI is running in
  each pane and classifies it idle / working / blocked / done, rolling that state
  up through tab and workspace so a blocked agent is visible without switching to
  it. For Claude Code and Codex that state comes from live screen-buffer matching;
  the installed integration mainly supplies session identity for restore.
- **Treehouse handoff.** Treehouse owns every agent worktree; Herdr opens the leased path with
  `herdr worktree open --path <path>` so its panes remain visible. Do not use Herdr's `create` or
  `remove` subcommands for agent work because that would split lifecycle ownership.
- **Scripted control.** `herdr agent start` launches a supported agent in an
  existing pane, `herdr agent prompt` submits a prompt to it, `herdr agent wait`
  blocks until it reaches a requested state, and `herdr agent read` pulls its
  output back. Same surface over the JSON socket API (`herdr api schema`), so an
  agent can drive other agents.

See [`../treehouse/README.md`](../treehouse/README.md) for native worktree jumping, durable leases, and
safe return rules.

## Editing the config

```bash
$EDITOR ~/.dotfiles/agent/herdr/config.toml
herdr server reload-config          # or prefix+shift+r inside the UI
```

`herdr config check` validates the live `~/.config/herdr/config.toml` and takes no
path argument, so it only reports on this file once the sync script has linked it.
Before that, a plain TOML parse is the check:

```bash
python3 -c 'import tomllib,sys; tomllib.load(open(sys.argv[1],"rb"))' \
  ~/.dotfiles/agent/herdr/config.toml
```

`herdr --default-config` prints the fully commented default; this file keeps only
the lines that deviate from it or are worth pinning against a future default
change.

## Keybindings

The prefix is **ctrl+a**, mirroring the maintainer's tmux, instead of herdr's own
ctrl+b. Pane focus uses the same Vim-direction keys as tmux. Sidebar navigation
and resizing use persistent modes so repeated movement does not require another
prefix. The main bindings are stated explicitly so a release cannot move them
quietly:

| Binding | Action |
| --- | --- |
| `prefix+h` / `j` / `k` / `l` | focus the pane left / down / up / right |
| `prefix+w` | enter sidebar navigation; use `j/k` or up/down to preview Spaces, tab/shift+tab to cycle panes including Agent panes, Enter to select, Esc to exit |
| `prefix+r` | enter resize mode; press `h/j/k/l` or arrows repeatedly, then Enter or Esc to exit |
| `prefix+v` | split vertical |
| `prefix+minus` | split horizontal |
| `prefix+c` / `prefix+n` / `prefix+p` | new tab / next tab / previous tab |
| `prefix+z` | zoom the focused pane |
| `prefix+b` | toggle the sidebar |
| `prefix+q` | detach (the server and every pane keep running) |

`prefix+minus` already matches the tmux `-` split. tmux's `|` has no counterpart:
herdr accepts named punctuation only for `minus`, `comma`, `ampersand`, `plus` and
`backtick`, so `prefix+v` stands in rather than inventing a key name herdr would
reject. Herdr 0.8.2 exposes a live cursor for Space rows but not one combined cursor
across both Space and Agent rows; tab/shift+tab is the supported Agent-pane fallback.

Other set values: theme `kanagawa` (closest built-in to Ghostty's Carbonfox),
`terminal.new_cwd = "follow"` so new panes inherit the current repo,
`ui.agent_panel_sort = "spaces"` so sidebar rows stay grouped by workspace instead
of reordering into an attention queue, and `update.channel = "stable"`.

## Integrations

`herdr integration install <agent>` wires an agent's own hook system to
`herdr pane report-agent`, so state changes are pushed rather than inferred from
the screen. The hook scripts are runtime state and stay out of dotfiles; what
matters is that two of the three write **through a symlink into this repo**, so
they show up in `git status`:

| Command | Writes |
| --- | --- |
| `herdr integration install claude` | `~/.claude/hooks/herdr-agent-state.sh`. A Claude hook only fires once it is registered in settings, so expect this to also touch `~/.claude/settings.json` — which is `agent/claude/settings.json` through the link. |
| `herdr integration install codex` | `~/.codex/herdr-agent-state.sh`, plus a `[hooks]` table appended to `agent/codex/config.toml` through the link. |
| `herdr integration install pi` | `~/.pi/agent/extensions/herdr-agent-state.ts` (Pi loads extensions from that directory, so no separate registration). Git ignores it through `agent/pi/.gitignore`; an ignore file inside `extensions/` would hide it from Pi as well. |

`herdr integration status` lists all supported agents and whether each is
installed; `herdr integration uninstall <agent>` reverses it. Review the resulting
diff before committing, and re-run `install` after a herdr upgrade —
`herdr integration status --outdated-only` shows which ones drifted.

## The herdr skill

`herdr --skill` prints an agent-facing skill file describing the pane, tab,
workspace and agent commands. It is vendored at `agent/skills/herdr` so every
harness picks it up through the normal skills sync, rather than each agent
shelling out to discover herdr at runtime. Regenerate it after a herdr upgrade:

```bash
herdr --skill > ~/.dotfiles/agent/skills/herdr/SKILL.md
```
