---
name: engineering-discipline
description: Scope, evidence and verification discipline for any code change in any language — find the smallest coherent change, verify it with a command, report what was and was not proved. Use when planning, implementing or reporting a code change, or when handing one off. Not for over-engineering review (ponytail), security review (security-review), test design (testing-backend), or Python idioms (python-production).
user-invocable: false
---

# Engineering Discipline

## Loop

1. State the user outcome in one sentence and the evidence that will prove it.
2. Read the code that will change and its callers before choosing an approach.
3. Make the smallest coherent change. Touch only files the outcome needs; keep formatting churn out of
   behavior changes.
4. Verify with the narrowest command that would fail if the change were wrong, then broaden when the
   blast radius warrants it. A command you did not run is not evidence.
5. Report files changed, behavior changed, commands run with their result, and what stayed unproved.

## Defaults

- Match the surrounding code: naming, error handling, comment density, test style. If the codebase
  says `user_id`, do not introduce `userId`.
- Validate at boundaries (user input, files, network, env, model and tool output); trust values your own
  code already validated.
- Fail fast and loudly. Catch the specific exception you can handle; never swallow one silently.
- Comments say why, never what. A name that needs a "what" comment needs a better name.
- Delete dead code and unused compatibility paths instead of preserving them.
- Treat a missing test, a flaky command, or an unverifiable assumption as a finding to report, not a gap
  to paper over.

## Stop and re-plan when

The change spreads into unrelated modules, adds a framework or dependency, alters a public API, file
format, migration, persistence, auth or user-visible flow that the task did not name, or cannot be
verified locally despite real risk. Say which, and what decision is needed.
