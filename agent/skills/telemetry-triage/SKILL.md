---
name: telemetry-triage
description: Triage TI-Toolbox telemetry error clusters from TI-toolbox-stats, using the artifact-first workflow to classify BigQuery-derived failures, compare them against current TI-Toolbox releases, and only open or close GitHub issues after review.
disable-model-invocation: true
argument-hint: "[stats-repo-path] [toolbox-repo-path]"
allowed-tools: Bash(git *) Bash(gh *) Bash(bq *) Bash(python3 *) Bash(rg *) Bash(sed *) Bash(cat *) Bash(nl *) Read Edit Write
---

# Telemetry Triage

You are triaging TI-Toolbox telemetry error clusters through the stats repo.
Treat telemetry issue creation as a reviewed action, not a cron side effect.

## Repos

Default paths:

- Stats repo: `/Users/idohaber/01_production/TI-toolbox-stats`
- Toolbox repo: `/Users/idohaber/01_production/TI-toolbox`

If the user supplies paths in `$ARGUMENTS`, use those instead.

## Core Policy

1. Scheduled automation must collect and classify evidence only.
2. The stats workflow should upload `telemetry-triage` artifacts containing `triage.json` and `triage.md`.
3. Do not let cron open GitHub issues by default.
4. Open or close issues only after a human/agent review of:
   - cluster fingerprint
   - event count and distinct clients
   - `first_seen` / `last_seen`
   - `tit_version`
   - error detail
   - current TI-Toolbox release tag and release notes
5. Prefer one issue per root cause, not one issue per telemetry string.

## Standard Workflow

1. Inspect repo state:
   ```bash
   git -C /Users/idohaber/01_production/TI-toolbox-stats status --short --branch
   git -C /Users/idohaber/01_production/TI-toolbox status --short --branch
   ```

2. Find the latest triage run or run the workflow in artifact-only mode:
   ```bash
   gh run list --repo idossha/TI-toolbox-stats --workflow triage-telemetry-errors.yml --limit 5
   gh workflow run triage-telemetry-errors.yml --repo idossha/TI-toolbox-stats --ref main -f apply_issues=false
   gh run watch <run-id> --repo idossha/TI-toolbox-stats --exit-status
   ```

3. Read the workflow log and artifact summary:
   ```bash
   gh run view <run-id> --repo idossha/TI-toolbox-stats --log
   ```

4. Query exact BigQuery evidence for candidate fingerprints when needed:
   ```sql
   SELECT
     error_fingerprint,
     event_name,
     error_type,
     COALESCE(error_detail, '') AS error_detail,
     COUNT(*) AS events,
     COUNT(DISTINCT client_id) AS clients,
     MIN(event_date) AS first_seen,
     MAX(event_date) AS last_seen,
     STRING_AGG(DISTINCT COALESCE(tit_version, 'unknown'), ', ' ORDER BY COALESCE(tit_version, 'unknown') LIMIT 10) AS versions,
     STRING_AGG(DISTINCT COALESCE(interface, 'unknown'), ', ' ORDER BY COALESCE(interface, 'unknown') LIMIT 10) AS interfaces
   FROM `tit-telemetry.analytics_531336528.events_flat`
   WHERE status = 'error'
     AND error_fingerprint IN ('<fingerprint>')
   GROUP BY 1, 2, 3, 4
   ORDER BY last_seen DESC, events DESC;
   ```

5. Compare against the current release:
   ```bash
   git -C /Users/idohaber/01_production/TI-toolbox show --no-patch --format='%h %ci %s' v2.3.1
   sed -n '1,220p' /Users/idohaber/01_production/TI-toolbox/docs/releases/v2.3.1.md
   ```

6. Decide action:
   - `suppress`: expected preflight/user-state failure.
   - `monitor`: stale/pre-release only, low spread, or no useful detail.
   - `open_issue`: current-release, actionable, non-preflight failure.
   - `close`: generated issue is stale, superseded, duplicate, or expected preflight noise.

7. Apply issue writes only when justified:
   ```bash
   gh issue close <number> --repo idossha/TI-toolbox --reason "not planned" --comment "<specific rationale>"
   ```

## Suppress By Default

Do not open bug issues for expected user/environment states:

- missing T1 input
- missing DWI input
- Docker CLI missing
- Docker daemon inaccessible
- no Docker / no DooD access
- existing preprocessing outputs
- stale `2.3.0` or unknown-version clusters that have not recurred on the current release

Use clear closing comments for generated issues:

```text
Closing as expected preprocessing preflight/user-state telemetry. This condition is now classified as suppressible triage noise rather than a bug issue; reopen only if it reflects a valid dataset or environment being rejected incorrectly.
```

For stale release clusters:

```text
Closing as stale generated telemetry. This cluster was only seen on pre-current-release telemetry, and the stats triage flow now monitors stale release clusters instead of opening bug issues unless they recur on current releases.
```

## Keep Or Open

Keep or open issues when telemetry shows:

- current-release failures with real subprocess exits
- multiple clients on the current release
- non-preflight exceptions with stable fingerprints
- post-run validation failures that may indicate broken output production
- regressions that align with a recent release change

When opening an issue, include:

- operation
- error type
- fingerprint
- event count and distinct clients
- first/last seen
- versions and interfaces
- sanitized error detail
- why it is not suppressed

## Stats Repo Maintenance

The expected stats repo implementation is:

- `.github/workflows/triage-telemetry-errors.yml` runs daily and uploads a `telemetry-triage` artifact.
- `scripts/triage_telemetry_errors.py` writes `triage.json` and `triage.md` by default.
- `--apply-issues` is required to write GitHub issues.
- `--dry-run` previews issue actions.
- `docs/telemetry-triage.md` explains the flow and policy.

Validate changes with:

```bash
python3 -m unittest discover -s tests
python3 -m py_compile scripts/triage_telemetry_errors.py tests/test_triage_telemetry_errors.py
git diff --check
```

Local Python may not have `google-cloud-bigquery`; if so, validate the BigQuery path by running the GitHub Actions workflow after pushing.

## Exit Criteria

You are done when:

- scheduled triage remains artifact-only
- issue creation is explicit and reviewed
- irrelevant generated issues are closed with specific rationale
- actionable issues remain open or are opened intentionally
- the stats repo docs explain the flow
- tests and workflow validation are reported
