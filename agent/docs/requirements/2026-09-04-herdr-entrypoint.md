# Herdr entry-point correction — 2026-09-04

This requirement corrects the agent-platform operator surface and refines
`agent/docs/ARCHITECTURE.md` §5.1. It supersedes the earlier interpretation
that starting the platform should implicitly launch Pi through FirstMate.

## Ask, verbatim

> "it opens pi. it shoudl open hrder. also, place a zshrc such that i can do it from anywhere."

## R1 — Enter Herdr directly

`agentctl start` launches or attaches Herdr. It does not start Pi, Claude,
Codex, or FirstMate. Those remain explicit operations after entering the
multiplexer.

* Gate test: `agentctl start --dry-run` prints exactly one Herdr launch and no
  harness command; the former `--harness` option exits 2.

## R2 — Resolve agentctl from every zsh directory

The canonical `zsh/.zshrc` places `~/.dotfiles/agent/scripts` on `PATH`, so a
new interactive zsh resolves `agentctl` independently of its working directory.

* Gate test: source the canonical zshrc in an isolated shell and assert
  `command -v agentctl` resolves to `~/.dotfiles/agent/scripts/agentctl`.
