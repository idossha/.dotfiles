## Ingest, anchors and emission

The docx-tools skill owns the CLI/schema mechanics. Verify installed help when an option or round-trip
property is uncertain. This procedure owns the review deliverables and their fidelity.

### 1. Resolve inputs

- Resolve the project's canonical spec, source Word file, bibliography and supplement at ingest.
  Paths in examples are placeholders, not a required study layout.
- Prefer the canonical spec for metadata, bibliography and citation keys. Compare it with Word
  edits before treating it as current; modification time is a hint, not proof of provenance.
- Read Word to a scratch spec when needed and compare prose. Readback may lose rebuild metadata or
  render citation keys; never overwrite a canonical spec with a readback.
- Build a stable section/block index, number ledger and citation inventory. Keep main and supplement
  document identities and rendered citation maps separate.
- Record source hashes and existing comments before review so output checks can distinguish prior
  comments from this run's additions.

### 2. Choose anchors

- Use unique, verbatim, unicode-exact text from the rendered document surface supported by the
  installed comment injector. Prefer one contiguous plain-prose span in one body block.
- Check uniqueness in rendered text; counting a phrase in raw JSON does not prove this.
- Avoid spans crossing citations, formatting boundaries or subscripts whose rendered text differs
  from the spec. Extend a repeated phrase with adjacent text until unique.
- If no precise anchor works, use the nearest unique prose and identify the exact target in the
  comment. Record a coverage gap if reliable anchoring remains impossible.

### 3. Author and verify

- Author comments as `Manuscript Review`, dated with the current ISO date. Give each a run-unique
  finding ID and a severity, dimension and confidence matching the report.
- Include the defect, evidence, competing explanation where relevant, and concrete suggested change.
  Preserve the project's notation using docx-tools formatting rules.
- Assemble the injector's supported comments schema, then inject into a NEW reviewed file.
  Never overwrite a source or an earlier reviewed output.
- Extract the reviewed comments and compare this run's IDs, anchors and text with the requested
  additions. Account for existing same-author comments; counting every comment with that author
  can falsely report success or failure on a re-review.
- Verify existing comments are preserved and no expected addition was silently dropped. Repair
  failed anchors and re-inject from the source to a fresh output. Counts alone are insufficient.

### 4. Report and revisions

Write `reports/review/manuscript_review_<document>_<version>.md` using the project's resolved
document/version identity. Include source paths/hashes, date, coverage, severity counts, findings
(ID, dimension, location/anchor, issue, evidence, suggested change, confidence), the literature
ledger from literature.md, and unresolved items.

Review proposes revisions by default. When revision application is already authorized, apply those
changes to a NEW versioned canonical-spec copy and build a NEW Word file. Otherwise leave suggestions
in comments. Verify required figure assets; report missing assets rather than silently substituting
a placeholder in a scientific deliverable.

### 5. Close

Verify output files exist, source hashes are unchanged, comments reconcile by identity/content and
each document has coverage and an open-items list. Report per-document counts and absolute paths.
Do not claim that mechanical output verification validates the science or the cited sources.
