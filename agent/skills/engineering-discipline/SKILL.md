---
name: engineering-discipline
description: Practical engineering discipline for agentic coding. Use when planning or implementing code changes to keep edits simple, scoped, evidence-driven, and verified.
user-invocable: false
---

# Engineering Discipline

Use this skill to keep coding work concrete, small, and verifiable.

## Operating Loop

1. State the actual user outcome in one sentence.
2. Inspect the relevant code before choosing an approach.
3. Identify the smallest coherent change that achieves the outcome.
4. Make assumptions explicit when they affect behavior, data, or user workflow.
5. Edit only the files required for the task.
6. Verify with the narrowest meaningful command first, then broader checks when risk warrants it.
7. Report what changed, what was verified, and what remains uncertain.

## Defaults

- Prefer boring, local, readable code over clever abstractions.
- Preserve existing conventions, naming, error handling, and test style.
- Avoid speculative generalization.
- Do not mix formatting churn with behavior changes unless formatting is the task.
- Do not silently change public APIs, file formats, migrations, or user-visible flows.
- Treat missing tests, flaky commands, and unverifiable assumptions as facts to report.

## Red Flags

Stop and re-evaluate if the change touches unrelated modules, adds a new framework, expands scope, changes persistence/auth/security, or cannot be verified locally despite meaningful risk.

## Final Answer Shape

Include files changed, behavior changed, verification run, and known gaps.
