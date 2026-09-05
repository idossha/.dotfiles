# Configuration and upgrade operations

This is the operator manual for [ARCHITECTURE.md](ARCHITECTURE.md) §3; [ROADMAP.md](ROADMAP.md)
tracks live integrations that remain unproven.

## Bootstrap and verify

Select Python 3.11 or newer. A local virtual environment keeps these script dependencies out of the
system interpreter:

```bash
uv venv --python 3.11 agent/.venv
uv pip install --python agent/.venv/bin/python -r agent/requirements.txt
agent/scripts/sync-agent-config.sh --check
agent/tests/run.sh
agent/scripts/agentctl sync
agent/scripts/agentctl doctor
```

The scripts prefer `agent/.venv/bin/python`, then a Python with TOML support; `AGENT_PYTHON`
selects an explicit interpreter. Install the pinned requirements there. Missing parsers fail visibly.
`AGENT_CONFIG_HOME` selects a temporary destination for tests and previews without changing HOME.
Live sync runs from the canonical checkout after the changes land, so generated links cannot point
at a lease that will later be returned.

## What sync owns

| Input | Destination / boundary |
|---|---|
| `policy/global.md` | Codex/Pi global AGENTS.md and Claude's imported AGENTS.md |
| `AGENTS.md` | Relative repository-root project link only |
| `skills/` and external playbook skills | One discovery route per harness; provider-bundled skills survive |
| `claude/settings.json`, `pi/settings.json`, `codex/config.toml` | Real generated files; unknown local fields preserved, canonical keys authoritative |
| `mcps/mcp-servers.json` | Claude user scope in local `~/.claude.json`, Pi JSON link, Codex generated TOML |
| `gnhf/config.yml` | Real runner config with explicit execution modes; local model/path preferences survive |
| `codex/rules/default.rules` | Real generated policy plus local approvals |

Ignored `agent/local/` overlays and their ownership manifest are machine state, not portable memory.
Unknown real files displaced by links are backed up. Managed stale links are retired; unrelated
skills and MCP servers are preserved. Never commit the full Claude app-state file.

FirstMate is configured outside sync because it lives in an external upstream checkout. The canonical
crew-dispatch template is `agent/firstmate/crew-dispatch.json`; `agentctl fleet` and
`install-agent-tools.sh --tools` copy it to FirstMate's local `config/crew-dispatch.json` beside
`config/backend=herdr`, and `agentctl doctor` reports drift. A Pi-backed `agentctl fleet` also runs
`herdr integration install pi` and then checks `herdr integration status` before starting Pi, because a
Herdr upgrade can change the agent-status bridge. The profile tells FirstMate to spend low-effort
Luna/mini candidates on small bounded worker tasks, medium profiles by default, and stronger high-effort
Codex profiles on large or ambiguous work.

Claude MCP user scope was checked against
[the official scope reference](https://code.claude.com/docs/en/mcp#mcp-installation-scopes)
on 2026-09-04. Codex discovery and schema references are in [../codex/README.md](../codex/README.md).

## Upgrade one boundary at a time

1. Change the one owning pin/declaration, record the reason in DECISIONS.md, and inspect upstream help
   or schema. Do not simultaneously rewrite portable doctrine to match a provider's product vocabulary.
2. Run source checks and the fixture suite. Unsupported MCP shapes require a tested adapter.
3. Sync from the landed canonical checkout, then run doctor and each changed harness's discovery
   check. For Pi (Node 20+): `node agent/scripts/pi-resources.mjs` uses offline native RPC without a model prompt.
   It reports command/skill discovery, not every extension diagnostic or project-context activation.
4. Verify Claude, Pi and Codex still resolve each engineering skill to the same local source.
   Claude's duplicate agentic-rules plugin must remain disabled. Review other plugin upgrades for
   overlapping skills, MCP definitions and hooks; version equality alone does not prove content parity.
5. Run a bounded live trial for changed execution behavior. Record its outcome and untested
   capabilities explicitly. GNHF's stop status and reviewed commits matter more than its launch output.

MCP network health, account authentication, provider model availability, skill activation quality,
and end-to-end FirstMate/no-mistakes delivery are separate from offline configuration checks.

## AXI helper policy

The active AXI catalog at `https://axi.md/` names agent-ergonomic CLI wrappers for GitHub, browser
automation, human review and quota visibility. This platform adopts only the helpers that match standing
workflows:

| Helper | Use in this platform | Boundary |
|---|---|---|
| `gh-axi` | GitHub issues, PRs, workflow runs, releases and API calls. | Prefer over raw `gh` for agent-facing reads/writes; remote mutation authority is still the current session boundary. |
| `chrome-devtools-axi` | Exploratory browser automation and live-page inspection. | Does not replace Playwright tests, hidden-app quiet checks or CI gates. |
| `lavish-axi` | Local HTML artifacts for plans, comparisons and dense review. | Hosted sharing is opt-in only. |
| `quota-axi` | Local quota/usage visibility before routing work to a strong model or FirstMate worker. | Data-only; it does not choose the worker by itself. |

`agent/tools.env` pins the reviewed versions and `install-agent-tools.sh --tools` installs them globally
through npm. `agentctl doctor` reports absent or mismatched helpers without making them a hard platform
failure. Do not add `mem-axi` or other memory AXIs here; `idosleep` is the memory owner.

## Fast Herdr/FirstMate troubleshooting

- `command not found`: open a fresh terminal and confirm `export PATH="$HOME/.local/bin:$PATH"` is in
  the shell configuration.
- Herdr does not show Pi's agent status: run `herdr integration install pi`, then
  `herdr integration status`, and restart Pi afterward.
- Pi did not load FirstMate extensions: start Pi from the FirstMate checkout selected by
  `AGENTCTL_FIRSTMATE_DIR` (default `~/00_development/agent-tools/firstmate`), run `/trust`, approve the
  project, quit, and relaunch with `agent/scripts/agentctl fleet --harness pi`.
- FirstMate reports a missing tool: let FirstMate print the exact install command, review that command,
  approve it, then ask it to rerun session startup.

Claude's [official skill discovery reference](https://code.claude.com/docs/en/skills#where-skills-live)
documents per-skill symlinks and separate plugin namespaces (checked 2026-09-04). This local setup uses
real discovery directories with per-skill links. Remote/cloud sessions do not inherit local user paths;
they need a separately verified provisioning adapter before being treated as part of this platform.
