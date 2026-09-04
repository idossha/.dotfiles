# Agent Platform Tests

`run.sh` is the platform gate for [../docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md) §6. It runs
CLI fixtures plus the Python regression suite against temporary state; it does not load the operator's
shell profile, home configuration, vault, Herdr server, GUI, network, or remotes.

## What each fixture is for

| Fixture | Why it is the test file |
|---|---|
| `projects.valid.json` | Pins schema version 1, an argv-array visualization, and a path substituted with a temporary repository. |
| `projects.invalid-shell-string.json` | Pins rejection of a shell string where an argv array is required; accepting it would restore shell-injection ambiguity. |
| `projects.empty.json` | Pins the non-vacuous registry rule; a registry with nothing to resolve is not valid configuration. |

The runner asserts that it found all three registry fixtures and checks dry-run output without
executing upstream tools. Fakes record actual CLI arguments and working directories and return failing
statuses. A synthetic linked Git directory shares only a temporary repository's metadata; it proves
repository identity checks without allocating real worktrees. `start` enters Herdr; `fleet` explicitly
selects FirstMate and its harness.

`test_config.py` uses authored policy/runtime fixtures and independent JSON/TOML readers to prove
state preservation, precedence, idempotence, discovery cleanup, and rejected malformed shapes.
`test_memory.py` checks project-root containment and secret rejection without touching a real store.
Run these directly with the selected Python's `-m unittest discover -s agent/tests -p 'test_*.py'`.
Missing fixtures, missing dependencies and zero collected checks cannot be presented as successful
validation. Model behavior and live provider compatibility remain separate gates.
