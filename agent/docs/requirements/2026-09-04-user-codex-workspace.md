# User requirements — 2026-09-04 (Codex workspace-sandbox gate items R1)

These are hard gate items for the Codex workspace-permission correction gate, proven by TOML parsing,
`agent/scripts/sync-agent-config.sh --check-installed`, and `agent/tests/run.sh` on the canonical and
generated Codex configuration. They refine §3.7 and §6 of `docs/ARCHITECTURE.md`; where they conflict
with the contract, they win and the contract is amended in the same commit.

## Asks, verbatim

1. "Use `approval_policy = "never"` and `sandbox_mode = "workspace-write"` for Codex."

## R1 — Keep Codex in the workspace sandbox without approval prompts

* New Codex sessions shall set `approval_policy = "never"` and `sandbox_mode = "workspace-write"` in the
  canonical `agent/codex/config.toml`, superseding the earlier full-access sandbox proposal.
* Commands outside the workspace sandbox shall fail instead of asking for escalation; explicit invocation
  overrides and managed requirements remain effective.
* Gate test: `agent/tests/run.sh` and `agent/scripts/sync-agent-config.sh --check-installed` shall parse
  the canonical and installed TOML and prove `approval_policy` and `sandbox_mode` equal the requested
  strings exactly.
