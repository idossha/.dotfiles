# Agent Platform Tests

`run.sh` exercises the public `agentctl` interface with a temporary project registry and repository. It
does not use the operator's registry, home-directory configuration, Herdr server, GUI, network, or
remotes.

## What each fixture is for

| Fixture | Why it is the test file |
|---|---|
| `projects.valid.json` | Pins schema version 1, an argv-array visualization, and a path substituted with a temporary repository. |
| `projects.invalid-shell-string.json` | Pins rejection of a shell string where an argv array is required; accepting it would restore shell-injection ambiguity. |
| `projects.empty.json` | Pins the non-vacuous registry rule; a registry with nothing to resolve is not valid configuration. |

The runner asserts that it found all three fixtures, drives every rejected shape red, and checks dry-run
output as argv fragments rather than executing upstream tools. It also pins the one-command FirstMate
entrypoint to Pi plus the Herdr backend. It returns nonzero when `agentctl` or its fixtures are absent;
zero tests collected is never a pass.
