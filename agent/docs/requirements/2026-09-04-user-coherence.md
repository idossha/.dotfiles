# Agent coherence audit intent — 2026-09-04

These requirements gate the coherence audit. They refine [ARCHITECTURE.md](../ARCHITECTURE.md)
§§1–7. User intent takes precedence; reconciliations belong in the contract and decision log together.
Gates use authored temporary fixtures, parsed outputs and repository-source checks. Acceptance is
boolean: all required assertions pass; untested live capabilities remain explicitly open.

## R1 — Establish one owner for every layer

> "assess the agentic coherence and consistency in our dotfiles"

Assess orchestration, memory, development, testing, CI/CD and version control. Record confirmed
conflicts separately from intentional specialization and provider capability gaps.

* Gate test: a GNHF assessment and a reconciled report cover all named layers with source evidence
  and a disposition for each confirmed finding; no claim that a dry run proves live behavior.

## R2 — Keep portable policy independent of providers

> "clear CLI, skills, MCP, and plugins according to good “first principles”"

Use one canonical source per concern, explicit adapters, preserved runtime state and
capability/version checks. Validate YAML/TOML with real parsers and test generated destinations
without loading the operator's shell or touching real configuration.

* Gate test: temporary-state tests prove policy precedence, unknown-state preservation, repeated-sync
  byte equality, shared MCP equivalence, skill uniqueness, and global/project scope separation.

## R3 — Remove conflicting procedural ownership

> "one skill steps on top of a different skill"

Keep engineering procedures in agentic-rules, local collaboration/discipline as scoped supplements,
and domain workflows as opt-in specializations. Shared skill content must not force a Claude tool,
context model, primary-checkout write path, or competing commit/release procedure.

* Gate test: source checks pin the removed conflicts and frontmatter validation rejects duplicate
  names or malformed inputs; the report distinguishes these checks from model activation trials.

## R4 — Use the same verification locally and in CI

> "we don't have one version control GitHub pipeline in one place and in another place the same or a different one"

CI invokes repository scripts. Frozen interfaces require their contract and decision record in the
same commit. Optional delivery tools consume project gates and retain their project-local opt-in.

* Gate test: guard fixtures reject a frozen edit without both documents and missing comparison
  inputs; hosted CI runs the same platform test entry point and reports its actual conclusion.

## R5 — Apply and publish scoped fixes

> "You have permissions to make changes to the agentic dot files, make incremental Commits to the remote repo and push."

Work in Treehouse leases, protect the starting branch, make reviewable commits without AI trailers,
and push the authorized branch over the existing SSH remote. This is not a release request.

* Gate test: clean outgoing commits contain only scoped changes, local verification passes, the
  remote branch contains those commits, and any retained lease or unclosed live trial is reported.
