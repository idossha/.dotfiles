---
name: docx-tools
description: Use the global docx-tools CLI for Microsoft Word .docx writing workflows, including building documents from JSON specs, reading .docx files back to specs, patching specs, handling comments, adding authors/figures, and parsing BibTeX.
argument-hint: [task-or-file]
allowed-tools: Bash(docx-tools *), Bash(which docx-tools), Bash(command -v docx-tools), Bash(python3 -m pip show docx-tools), Read, Write, Edit
---

# docx-tools

You are using the global `docx-tools` CLI for programmatic Microsoft Word document workflows.

## When to Use

Use this skill when the user asks to create, inspect, convert, patch, or annotate `.docx` files with the local `docx-tools` package, or when a workflow mentions `spec.json`, Word comments, author blocks, figures, equations, references, or BibTeX parsing for Word documents.

## Global CLI

1. Prefer the global CLI:
   ```bash
   docx-tools --help
   ```
2. If the command is missing, check the expected editable checkout:
   ```bash
   command -v docx-tools
   python3 -m pip show docx-tools
   ```
3. The normal global executable is `/opt/homebrew/bin/docx-tools`, installed in editable mode from:
   ```text
   /Users/idohaber/00_development/docx-tools
   ```
4. If the executable exists but behavior seems stale, inspect the checkout before reinstalling. Homebrew Python may be externally managed, so do not force `pip install --break-system-packages` unless the user explicitly approves that risk.

## Core Commands

Use these commands as the stable interface:

```bash
docx-tools init <project-dir> --title "Paper Title"
docx-tools build <project-dir>/spec.json -o <project-dir>/output/paper.docx
docx-tools read input.docx -o spec.json
docx-tools patch spec.json ops.json -o spec.json --build output/paper.docx
docx-tools inject input.docx --comments comments.json -o reviewed.docx
docx-tools extract reviewed.docx --json
docx-tools authors input.docx --data authors.json -o output.docx
docx-tools figure input.docx --image figure.png --caption "Caption." -o output.docx
docx-tools bib refs.bib
```

## Working Rules

1. Treat `spec.json` as the source of truth for generated papers unless the user says the `.docx` has newer human edits.
2. When ingesting human Word edits, run `docx-tools read <docx> -o <spec.json>` and preserve any existing project layout.
3. When changing a generated paper, prefer editing the JSON spec or applying `docx-tools patch` operations, then rebuild the `.docx`.
4. When comments are involved, keep comments as `.docx` annotations and use `extract` or `inject`; do not fold reviewer comments into the body text unless requested.
5. Before overwriting a user-provided `.docx`, write to a new output path unless the user explicitly asked to overwrite.
6. Check generated outputs exist after CLI commands and report the exact output path.

## Exit Conditions

Finish by telling the user which `docx-tools` command ran, what file was produced or changed, and whether verification passed. If the global CLI is unavailable, report the PATH lookup result and the fallback attempted.
