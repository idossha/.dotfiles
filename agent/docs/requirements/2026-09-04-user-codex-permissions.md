# User requirements — 2026-09-04 (Codex permission gate items R1)

These are hard gate items for the Codex runtime-permission configuration gate, proven by TOML parsing,
`agent/scripts/sync-agent-config.sh --check-installed`, and `agent/tests/run.sh` on the canonical and
generated Codex configuration. They refine §3.7 and §6 of `docs/ARCHITECTURE.md`; where they conflict
with the contract, they win and the contract is amended in the same commit.

## Asks, verbatim

1. "Set Codex up so routine work does not stop for permission prompts."

## R1 — Make Codex permission prompts automatic

* New Codex sessions shall set `approval_policy = "never"` and automatic tool approval overrides in the
  canonical `agent/codex/config.toml`, so future syncs preserve the no-routine-prompt behavior.
* Explicit invocation overrides, managed requirements, and other harness adapters stay unchanged.
* Gate test: `agent/tests/run.sh` and `agent/scripts/sync-agent-config.sh --check-installed` shall parse
  the canonical and installed TOML and prove the owned Codex permission keys equal the requested values
  exactly.
