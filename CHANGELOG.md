# Changelog

Notable changes to the dotfiles are recorded here using the
[Keep a Changelog](https://keepachangelog.com/en/2.0.0/) format.

## [Unreleased]

### Added

- **One command surface now operates the shared agent platform.** `agentctl` can switch named Herdr
  projects, launch FirstMate on Herdr, start bounded GNHF worktree runs, and enter project-approved
  no-mistakes delivery gates. Existing Claude Code, Codex, Pi, Neovim, and direct Herdr workflows remain
  available; adopted upstream tools are pinned and remain independently updateable.
- **The agent platform is available from every zsh directory.** The canonical shell path exposes
  `agentctl`; `agentctl start` opens Herdr directly, while FirstMate/Pi remains the explicit
  `agentctl fleet --harness pi` operation.

### Changed

- **Launching an agent no longer writes runtime state into tracked policy.** Claude Code, Codex, and Pi
  now receive generated effective settings whose mutable values remain in local overlays. Shared
  AGENTS.md, skill, memory, MCP, testing, and development doctrine continues to be authored once under
  `agent/` or the external agentic-rules playbook.
- **Agent replies now default to a terse synopsis.** Explanations that benefit from diagrams,
  comparisons, plans, or dense review surfaces move to local Lavish artifacts; safety and authority
  prompts remain visible even while optional clarification is minimized.
