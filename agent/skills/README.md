# Unified Skills

This directory is the canonical source for reusable agent skills. Claude Code, Pi and Codex discover the same personal skills through generated links;
the contract in `agent/docs/ARCHITECTURE.md` defines ownership.

## Layout

```text
agent/skills/
  <skill-name>/
    SKILL.md
    references/
    scripts/
    templates/
```

`SKILL.md` must start with YAML frontmatter:

```yaml
---
name: <skill-name>
description: Specific trigger-oriented description.
---
```

The `name` must match the directory name. Keep descriptions focused on routing:
what the skill does and when an agent should load it.

## Harness discovery

From the assigned checkout, run `agent/scripts/sync-agent-config.sh --check`.
After landing, run `agent/scripts/agentctl sync` from the primary checkout.

Claude receives one link per personal and playbook skill in `~/.claude/skills`.
Pi and Codex use the same sources through `~/.agents/skills`. Both discovery roots are real generated
directories. The duplicate Claude agentic-rules plugin is disabled so an older snapshot cannot supply
a different engineering procedure. Supporting references and scripts stay with their owning skill.

## Inventory

Domain knowledge (auto-loaded when relevant):

| Skill | Purpose |
|---|---|
| `bids` | BIDS dataset layout, filenames, sidecars, derivatives. |
| `code-quality` | Production code standards: security, errors, complexity, naming, tests. |
| `eeglab` | EEGLAB/MATLAB EEG processing reference. |
| `engineering-discipline` | Scope, evidence, and verification discipline for code changes. |
| `mne-python` | MNE-Python workflows plus an API lookup helper script. |
| `neuroimaging` | NIfTI/DICOM/SimpleITK/nibabel patterns. |
| `python-production` | Python production patterns and anti-patterns. |
| `scientific-computing` | NumPy/SciPy/matplotlib patterns for imaging and neuroscience. |
| `security-review` | Security review checklist for code, tools, and configuration. |

Workflows and playbooks:

| Skill | Purpose |
|---|---|
| `grill-me` | Interview the user to stress-test a plan before implementing. |
| `librarian` | Find, download, rename, and strategically summarize papers. |
| `manuscript-review` | Full soundness/consistency/literature review of a manuscript. |
| `matlab` | Run MATLAB in batch mode from the terminal. |
| `mcp-authoring` | Author and configure MCP servers. |
| `suna` | Work on a SUNA manuscript project (figures, references, review comments, compliance). |
| `write-skill` | Author or refactor a skill in this directory. |

Document-format skills (`pdf`, `pptx`, `xlsx`) are **not** kept here. Use the current harness's bundled format capabilities when available; local copies can shadow provider updates.

## External packages

The eight engineering skills live in the local `agentic-rules` clone selected by
`AGENTIC_RULES_DIR` (default `~/00_development/agentic-rules`). They are linked, never copied into
this directory. A missing clone is reported as unchecked by source validation and fails installed
validation, because missing engineering doctrine is not a healthy installed platform.

Provider plugins remain appropriate for provider-specific bundles such as Claude LSP or frontend
tools. Their enablement lives in the harness adapter, and doctor reports enabled floating packages.
A package is a distribution mechanism, not another owner of global policy. Inspect plugin-provided
skill names, MCP servers and hooks for duplicate ownership when adding or upgrading one.

## Validation

Run:

```bash
agent/scripts/sync-agent-config.sh --check
```

This verifies that each skill has a `SKILL.md`, a matching frontmatter `name`,
and a frontmatter `description`.
