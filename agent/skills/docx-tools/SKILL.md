---
name: docx-tools
description: Use the global docx-tools CLI for Microsoft Word .docx writing workflows, including building documents from JSON specs, reading .docx files back to specs, patching specs, generating tracked-changes (redline) documents for co-authors, handling comments, adding authors/figures, and parsing BibTeX.
argument-hint: [task-or-file]
allowed-tools: Bash(docx-tools *), Bash(which docx-tools), Bash(command -v docx-tools), Bash(python3 -m pip show docx-tools), Bash(soffice *), Bash(open -a *), Read, Write, Edit
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
docx-tools redline old.docx new.docx -o redline.docx --author "Name"
```

## Working Rules

1. Treat `spec.json` as the source of truth for generated papers unless the user says the `.docx` has newer human edits.
2. When ingesting human Word edits, run `docx-tools read <docx> -o <spec.json>` and preserve any existing project layout.
3. When changing a generated paper, prefer editing the JSON spec or applying `docx-tools patch` operations, then rebuild the `.docx`.
4. When comments are involved, keep comments as `.docx` annotations and use `extract` or `inject`; do not fold reviewer comments into the body text unless requested.
5. Before overwriting a user-provided `.docx`, write to a new output path unless the user explicitly asked to overwrite.
6. Check generated outputs exist after CLI commands and report the exact output path.
7. When a deliverable is meant for a co-author to review, produce a tracked-changes version — see
   "Tracked changes (redline)" below. Never hand-edit revision XML.

## Tracked changes (redline) for co-authors

When the user asks for "track changes", "tracked changes", "a redline", "changes Giulio can
accept/reject", or anything they intend to share with a co-author for review, use:

```bash
docx-tools redline old.docx new.docx -o redline.docx --author "Ido Haber" [--date ISO8601]
```

This emits real OOXML revision markup (`w:ins` / `w:del` plus the `w:pPr/w:rPr` paragraph-mark
revisions) so Word shows individually acceptable/rejectable edits. Diff the **built** `.docx`
files, not the specs: build the new version first, then redline it against the previous build.

**Never hand-roll an XML diff script for this.** That was tried and produced two silent defects:
it flattened every run in a changed paragraph onto the first run's `rPr` (destroying italic
journal names throughout the reference list), and it never marked paragraph marks, so Reject All
left stray blank lines instead of removing inserted paragraphs. `docx-tools redline` handles both.

### The delivery trap — this is the failure mode that actually bites

The clean build contains **zero** markup by design. Users repeatedly open the clean file, see no
markup, and report the redline as broken. Prevent it:

1. Write the redline **into the same directory the user actually looks at** (usually `paper/output/`,
   not just a `drafts/` snapshot), with an unmistakable name such as
   `<paper>_v1.1_TRACKED-CHANGES.docx`.
2. In your summary, state plainly which file has the markup and which is clean, with revision counts.
3. Also export a PDF of the redline (`soffice --headless --convert-to pdf`). Markup is baked into the
   page, so it survives any viewer or Word setting — the reliable thing to send a co-author who just
   wants to see the diff.
4. Offer to open it: `open -a "Microsoft Word" <redline.docx>`.

### Viewer gotchas — a clean-looking file is usually not a broken file

- **Word defaults to Simple Markup**, which renders final text with only a thin margin change bar.
  Always tell the recipient: **Review → Display for Review → All Markup**. No document can override
  this; it is a sticky per-user app setting.
- **macOS Quick Look and Preview.app render .docx with all changes silently accepted** — zero markup,
  visually identical to the clean build. Never verify a redline with Finder spacebar or `qlmanage`,
  and warn the user not to.
- `w:trackRevisions` in `settings.xml` only enables *recording* of the recipient's future edits. It
  has no bearing on whether existing revisions display. Do not offer it as a fix for "I see no markup".
- It is `w:trackRevisions`, not `w:trackChanges` — the latter is the dead ECMA-376 first-edition name,
  absent from the schema Word validates against.

### Verifying a redline (do this before reporting success)

```bash
soffice --headless --convert-to fodt --outdir <tmp> redline.docx
# then count text:changed-region / text:insertion / text:deletion in the .fodt
```
Non-zero `text:changed-region` proves the revisions survive a real office-suite parse. Cross-check
the clean build the same way and confirm it yields zero, so the check is known to discriminate.
The decisive correctness property is the round trip: simulate Word's semantics and confirm
**Accept All reproduces NEW exactly and Reject All reproduces OLD exactly**.

### Known limitations

- Formatting-only changes are not tracked (no `w:rPrChange` / `w:pPrChange` is emitted).
- Paragraphs inside tables are not diffed.
- Paragraphs containing inline images, fields, footnote refs, math, or hyperlinks are passed through
  untouched and reported as `skipped`.

## Multi-document projects (main + supplement)

A paper and its Supplementary Information are **separate documents, each with its own spec
file and its own built `.docx`**. Do not append SI content into the main `spec.json`.

- Look for an existing supplement spec (e.g. `supplement_spec.json`) before creating one; match
  its `citation_style`, table numbering (`S1`, `S2`, ...), and heading structure.
- Add new SI material by editing the supplement spec, then build it to a new versioned output
  (e.g. `*_supplement_v0.2.docx`); leave the main paper untouched.
- The supplement may share `references.bib` and `authors.json` with the main paper.
- `build` aborts on the first missing figure image. If a placeholder figure block references an
  image that does not exist yet, that blocks the whole build — flag it rather than deleting the
  block. To verify unrelated edits render, build a temp copy of the spec with the missing-figure
  block stripped; never work around it by mutating the canonical spec.

## Exit Conditions

Finish by telling the user which `docx-tools` command ran, what file was produced or changed, and whether verification passed. If the global CLI is unavailable, report the PATH lookup result and the fallback attempted.
