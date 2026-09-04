---
name: telemetry-triage
description: Triage TI-Toolbox telemetry using the stats project's artifact-first workflow, compare failures with a verified release, and prepare or apply reviewed issue actions within the user's authorization.
disable-model-invocation: true
argument-hint: "[stats-repo-path] [toolbox-repo-path] [release-tag]"
---

# Telemetry Triage

Use when the user requests TI-Toolbox telemetry triage. This skill owns evidence classification;
the stats project owns its workflow, query schema, deployment and validation commands. Use
git-collaboration for remote coordination, and honor authorization already supplied in the session.

## Resolve once

1. Resolve stats and toolbox repositories from supplied arguments or the named project registry.
   Confirm each path and remote with read-only Git inspection. Use those resolved paths for every
   subsequent command; an override must not fall back to a personal machine's hardcoded location.
2. Read each project's AGENTS.md and telemetry documentation. Discover the artifact workflow,
   artifact names, query schema and test commands there. Do not maintain another SQL query or CI
   implementation in this global skill.
3. Resolve an explicit requested release, or verify the current published release and release notes
   through GitHub using gh-axi (gh for unsupported commands). A local highest tag is not proof of
   the current deployed release. Record release tag/SHA, publication date and evidence source.
   If remote evidence is unavailable, state that limit before classifying something as current.

## Evidence and classification

- Read the latest relevant completed artifact run first. Record run ID, time window and whether the
  collection step actually succeeded. Missing/stale artifacts cannot establish absence of errors.
- Scheduled collection defaults to evidence only. Dispatch a collection workflow only when within
  task authorization and using the project's documented artifact-only inputs.
- Inspect fingerprint, error detail, operation, event count, distinct clients, first/last seen,
  reported versions and interfaces. Sanitize identifiers and secrets before issue/report output.
- Query additional evidence through the project's maintained query surface when the artifact cannot
  answer a specific question. Do not invent column names from memory.
- Compare clusters with verified release notes and code. One root cause can generate several strings;
  group by evidence rather than opening one issue per message.
- Classify as suppress (expected preflight/user state), monitor (stale, unknown or insufficient
  evidence), open/update (actionable defect), or close (duplicate, superseded or resolved).
- Missing input/tools, inaccessible Docker and existing outputs may be expected preflight states.
  Verify the condition before suppression; a valid environment being rejected is still a defect.
- Older or unknown versions need recurrence evidence, not a hardcoded version cutoff. Lack of
  current-release recurrence alone does not prove a root cause is fixed.

## Reviewed issue actions

Prepare a triage artifact with rationale, evidence and proposed action per root cause. Apply issue
writes when both review and the session's authorization cover them; reuse existing authorization
instead of requesting it again. Collection by itself does not authorize publishing.

Each issue needs operation, sanitized detail, fingerprint, counts, time range, versions, reproduction
or code evidence, and why the failure is actionable. Closing rationale must identify resolution,
duplication or expected state precisely. Report actual issue URLs and failed writes honestly.

When the stats implementation changes, use its own test and CI entrypoints. Report artifact/schema
gaps to that project; do not silently patch another repository during an unrelated task.
