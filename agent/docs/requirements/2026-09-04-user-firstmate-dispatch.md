# User requirements — 2026-09-04 (agent-platform configuration gate items R1)

These are hard gate items for the agent-platform configuration gate, each proven by the shell and Python
fixture suites on temporary FirstMate homes and by exact JSON equality where stated. They refine §2.3,
§3, §5.1, §6, and §7 of `docs/ARCHITECTURE.md`; where they conflict with the contract, they win and the
contract is amended in the same commit.

## Asks, verbatim

1. "please make sure to set up our workflow such the when firstmate calls agents it does so in a smart way to preserve tokens. meaning - for smaller tasks it can spin up simpler models like gpt luna with low effort while for bigger tasks it will allocate a stronger model."

## R1 — Seed token-aware FirstMate dispatch profiles

* `agent/firstmate/crew-dispatch.json` shall be the canonical dotfiles profile copied into the external
  FirstMate checkout's local `config/crew-dispatch.json` whenever the pinned FirstMate install or
  `agentctl fleet` launch path prepares runtime configuration.
* The profile shall distinguish small explicit low-risk work from ordinary scoped work and large,
  ambiguous, high-blast-radius work. Small work gets low-effort lightweight candidates including Luna;
  large ambiguous work gets stronger high-effort candidates. The Herdr backend, Treehouse ownership,
  FirstMate upstream supervision contract, and explicit harness choice remain unchanged.
* Gate test: `agent/tests/run.sh` shall show `crew-dispatch.json` in both FirstMate fleet and installer
  dry-runs, and `agent/tests/test_cli.py::ExecutionTests.test_fleet_launch_writes_firstmate_dispatch_config`
  shall prove the launched fixture FirstMate home's `config/crew-dispatch.json` is byte-identical to the
  canonical template and `config/backend` equals `herdr\n` exactly.
