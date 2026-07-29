---
name: reviewer-response-docx
description: Compose Microsoft Word .docx response-to-reviewers documents for academic manuscripts using the docx-tools workflow. Use when drafting, restructuring, or generating a point-by-point reviewer response letter, rebuttal letter, revision response, reviewer response matrix, or cover response document as a Word file.
---

# Reviewer Response DOCX

Use this skill to produce polished academic response-to-reviewers documents as `.docx` files. Pair it with the `docx-tools` skill for the actual Word document build, read, patch, comment, and verification commands.

## Inputs to Gather

Work from the best available materials:

- Reviewer/editor comments, decision letter, or annotated manuscript.
- Revised manuscript text, change log, tracked-change summary, or user-provided edits.
- Target journal, manuscript title, author list, and revision round when available.
- Desired tone, deadline, and whether the response should include manuscript line/page references.

If critical inputs are missing, make conservative placeholders clearly marked with `TODO:` rather than inventing facts, line numbers, experiments, statistics, or editorial decisions.

## Document Structure

Default to this order unless the user or journal asks for another format:

1. Title: `Response to Reviewers`.
2. Manuscript metadata: title, journal, manuscript ID, revision round, date, and corresponding author if available.
3. Opening letter to the editor: concise thanks, summary of major revisions, and note that changes are highlighted or tracked if true.
4. Summary of major changes: 3-7 bullets focused on substantive revisions.
5. Point-by-point responses grouped by `Editor`, `Reviewer 1`, `Reviewer 2`, etc.
6. Optional closing note.

For each comment, use a repeated block:

```text
Comment [Reviewer N].[number]
[Reviewer comment, quoted or paraphrased accurately.]

Response
[Polite response that directly answers the concern.]

Changes made
[Exact manuscript change, location, and concise quote or summary. Use TODO for missing line/page numbers.]
```

## Response Writing Standards

- Keep tone professional, grateful, and direct; avoid defensiveness.
- Answer every separable reviewer request explicitly.
- Preserve reviewer meaning. Do not soften, exaggerate, or silently combine unrelated criticisms.
- Lead with the action taken when the reviewer requested a change.
- When disagreeing, acknowledge the concern, explain the rationale, and offer a limited clarification added to the manuscript when appropriate.
- Use precise manuscript locations only when supported by supplied material.
- Prefer concise paragraphs over long rebuttal blocks.
- Keep formatting easy to scan: reviewer headings, numbered comments, and consistent labels for `Response` and `Changes made`.

## DOCX Workflow

Use `docx-tools` as the Word generation backend:

1. If starting fresh, create a project directory and JSON spec:
   ```bash
   docx-tools init <project-dir> --title "Response to Reviewers"
   ```
2. Build or edit the response content in `spec.json`, using headings and paragraphs that preserve the structure above.
3. Generate the Word file:
   ```bash
   docx-tools build <project-dir>/spec.json -o <project-dir>/output/response-to-reviewers.docx
   ```
4. If revising an existing `.docx`, first read it to a spec:
   ```bash
   docx-tools read existing-response.docx -o <project-dir>/spec.json
   ```
5. If reviewer comments should remain Word comments, use `docx-tools inject` rather than placing annotations inline.
6. Verify the generated `.docx` exists and, when practical, read it back with `docx-tools read` to catch malformed output.

Do not overwrite a user-provided Word file unless explicitly asked. Write a new output path, usually under `output/`.

## Coverage Requirements

- Answer every reviewer and editor comment. None may be dropped silently.
- Distinguish completed changes from planned or unavailable ones.
- Source every factual claim, page/line number, figure, table, sample size, p-value, and citation from the user's materials, or mark it `TODO:`.
- Close with a note naming the source materials used, the output `.docx` path, and any remaining TODOs.
