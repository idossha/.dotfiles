# Unified Skills

This directory is the canonical source for reusable agent skills. Claude Code is
the only harness these are linked into.

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

## Harness Link

Run:

```bash
~/.dotfiles/agent/scripts/sync-agent-config.sh
```

The sync script creates this link:

```text
~/.claude/skills -> ~/.dotfiles/agent/skills
```

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
| `docx-tools` | The global `docx-tools` CLI: build, read, patch, redline, comment. |
| `git-collaboration` | Commits, branches, PRs, reviews, changelogs. |
| `grafana` | Grafana dashboard provisioning. |
| `grill-me` | Interview the user to stress-test a plan before implementing. |
| `librarian` | Find, download, rename, and strategically summarize papers. |
| `manuscript-review` | Full soundness/consistency/literature review of a manuscript. |
| `matlab` | Run MATLAB in batch mode from the terminal. |
| `mcp-authoring` | Author and configure MCP servers. |
| `orchestrator` | When to delegate to subagents, and when not to. |
| `remember` | Route durable knowledge to the Zettelkasten, project docs, or SQLite. |
| `reviewer-response-docx` | Compose response-to-reviewers Word documents. |
| `telemetry-triage` | Telemetry triage workflow for the TI-toolbox projects. |
| `web-neuroimaging` | Web research for neuroimaging docs and methods. |
| `write-skill` | Author or refactor a skill in this directory. |

Document-format skills (`pdf`, `pptx`, `xlsx`) are **not** kept here. Claude Code
ships bundled equivalents; local copies would shadow them.

## Validation

Run:

```bash
~/.dotfiles/agent/scripts/sync-agent-config.sh --check
```

This verifies that each skill has a `SKILL.md`, a matching frontmatter `name`,
and a frontmatter `description`.
