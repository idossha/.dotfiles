# Changelog

Notable changes to the dotfiles are recorded here using the
[Keep a Changelog](https://keepachangelog.com/en/2.0.0/) format.

## [Unreleased]

### Removed

- **The fleet supervisor, session multiplexer, unattended-loop runner and pooled worktree provider are
  gone** — the platform no longer installs, configures or launches them, and `agentctl start`, `project`,
  `fleet` and `overnight` are removed with them. Agents now work in the checkout they were launched in and
  do not create worktrees. Delivery is unchanged for projects that opted in: those carrying
  `.no-mistakes.yaml` still ship through `agentctl ship`, and every other project uses ordinary pull
  requests. Nothing red is pushed or merged. Existing checkouts keep their history; if a pooled worktree
  is still on disk, land or discard its work and remove it by hand.

### Added

- **A short statement of how the agents are meant to work** — `agent/docs/PHILOSOPHY.md` records the
  rule for choosing between a skill, a CLI and an MCP server, and the failure each platform rule prevents.

### Fixed

- **MCP server versions remain stable between sessions** — all three shared servers use exact versions
  of the locally installed packages.
- **Pi discovery survives an SDK packaging failure** — the offline probe now uses native RPC, with
  explicit limits on what command/skill discovery proves.
- **The engineering playbook is identical across local harnesses** — Claude now links to the same
  skill sources as Codex and Pi; its duplicate cached agentic-rules plugin is disabled.
- **Shared review skills no longer impose another project's results** — manuscript review derives
  facts from project evidence, and telemetry triage resolves current repositories/releases once.

- **Shared policy remains authoritative across harnesses** — synchronization preserves local runtime
  state while correcting duplicate skill discovery and Claude user MCP scope. Run `agentctl sync`,
  then `agentctl doctor`; Python 3.11+ and the pinned `agent/requirements.txt` parsers are required.
- **Overnight audits start from the requested revision** — bounded GNHF runs validate their execution
  mode, retain their Treehouse lease, reject dirty sources and report upstream failures consistently.
- **Project memory stays inside its project** — escaping `--file` paths and secret-looking source
  fields are rejected.

### Added

- **Agent platform CI runs the local gate** on Python 3.11 and 3.14, with self-tested source and
  per-commit contract guards. Provider activation and live delivery remain separate checks.

- **One command surface now operates the shared agent platform.** `agentctl` can switch named Herdr
  projects, launch FirstMate on Herdr, start bounded GNHF worktree runs, and enter project-approved
  no-mistakes delivery gates. Existing Claude Code, Codex, Pi, Neovim, and direct Herdr workflows remain
  available; adopted upstream tools are pinned and remain independently updateable.
- **The agent platform is available from every zsh directory.** The canonical shell path exposes
  `agentctl`; `agentctl start` opens Herdr directly, while FirstMate/Pi remains the explicit
  `agentctl fleet --harness pi` operation.
- **Codex plan usage is visible in SketchyBar.** The new Codex item reads authenticated usage through
  `quota-axi`, caches it locally, and exposes session and weekly windows in its popup. Existing
  SketchyBar items remain unchanged; without usage data the item shows an unavailable marker.

### Changed

- **FirstMate spends worker tokens by task size** — `agentctl fleet` and the tool installer now seed a
  crew-dispatch profile that routes small bounded tasks to low-effort Luna/mini agents and reserves
  stronger high-effort Codex profiles for large or ambiguous work. Existing Herdr, Treehouse, and
  FirstMate supervision boundaries remain unchanged.
- **Git has one explicit workflow owner** — the legacy shell GitHub publisher and Pi's misleading
  stash-restore extension are retired. Git collaboration routes commit/release rules to agentic-rules.
- **Docker checks report their actual scope** — environment and installer syntax only, with upstream
  failures preserved. The old work installer test is retired; it no longer swallows failures.

- **Launching an agent no longer writes runtime state into tracked policy.** Claude Code, Codex, and Pi
  now receive generated effective settings whose mutable values remain in local overlays. Shared
  AGENTS.md, skill, memory, MCP, testing, and development doctrine continues to be authored once under
  `agent/` or the external agentic-rules playbook.
- **Agent replies now default to a terse synopsis.** Explanations that benefit from diagrams,
  comparisons, plans, or dense review surfaces move to local Lavish artifacts; safety and authority
  prompts remain visible even while optional clarification is minimized.
