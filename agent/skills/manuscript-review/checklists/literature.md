## Literature verification

Verify the manuscript against the works it cites: every citation resolves and is bibliographically correct, every load-bearing claim is faithfully represented by its source, framing of adjacent/own work is accurate, no strong claim is left uncited, and no citation is stale. This is the highest-yield and most labor-intensive review pass — budget accordingly and prioritize load-bearing/quantitative claims over decorative ones.

This pass uses the OpenAlex MCP tools, `WebFetch`, the local `literature.md`, and local PDFs under `literature/`. Do NOT re-derive `literature.md` summaries or re-download PDFs yourself — that is the `librarian` skill's job; call it (or read its outputs) and consume the result here.

### 0. Build the citation inventory first (do this before any check)

- [ ] Parse `paper/spec.json`: walk `content[]`, concatenate every `body` block `text` plus figure captions, and regex out every in-text citation marker. For IEEE these render as `[n]`, `[n], [m]`, and ranges `[n]–[m]` (watch the unicode en-dash `–` inside ranges; expand ranges to individual integers).
- [ ] Parse `references.bib` (use `docx-tools` BibTeX parsing, not a hand-rolled regex) into an ordered list; the IEEE number `[n]` = the n-th entry in citation order. Build a map `n -> {bibkey, title, authors, year, venue, doi}`.
- [ ] Build the reverse map `bibkey -> set(in-text locations)` so orphan/missing detection and per-claim lookups share one structure.
- [ ] Record, per citation, the exact anchor slice (a unique verbatim substring of the body block, citations rendered as `[n]`) so any finding can later be injected as a Word comment without re-searching. Keep anchors short and unique; avoid spans crossing em-dashes/non-breaking spaces.
- [ ] Cross-check that the supplement is handled as a SEPARATE document with its own numbering space — do not assume main-text `[7]` equals supplement `[7]`. Run bibliography hygiene independently on each, then reconcile shared references for consistent metadata.

### 1. Bibliography hygiene

- [ ] **Orphan entries**: every `references.bib` entry is cited at least once in the body. Flag uncited entries (left over from earlier drafts).
- [ ] **Missing entries**: every in-text `[n]` resolves to an existing entry; flag any `[n]` with no n-th entry or an out-of-range index.
- [ ] **Monotonic numbering**: in IEEE, the first appearance of citations must be `[1],[2],[3]…` in reading order. Walk the body in document order and assert each newly-introduced number is exactly previous-max+1. Flag the first non-monotonic introduction (signals a renumbering drift after an edit).
- [ ] **DOI presence + resolvability**: every entry has a `doi`; resolve each via `mcp__openalex__get_work` (DOI lookup) or `WebFetch` `https://doi.org/<doi>`. Flag missing, 404, or DOI-points-to-different-paper.
- [ ] **Metadata correctness**: for each entry call `mcp__openalex__get_work` and diff OpenAlex `title / publication_year / authorships / host_venue` against the bib `title/year/author/journal`. Flag year off by ≥1, wrong/abbreviated venue, truncated or wrong author list, title typos. Use `mcp__openalex__batch_resolve_references` to resolve the whole bib in one pass, then drill into mismatches with `get_work`.
- [ ] **Venue quality / retraction / predatory**: run `mcp__openalex__check_venue_quality` on each host venue; flag predatory or non-indexed venues. Check OpenAlex `is_retracted` and search the title + "retracted/retraction" via `WebSearch`. Surface any retraction as a blocking issue.
- [ ] **Duplicate entries**: detect near-identical entries (same DOI, or same title with different bibkeys) cited under two numbers — common after merges. Flag for consolidation.
- [ ] **Preprint-vs-published mismatch**: for any `@misc`/arXiv/medRxiv/bioRxiv/`@unpublished` entry, query OpenAlex for a published version of the same title/authors (and `find_open_access_version`); if a peer-reviewed version now exists, flag to upgrade (see §5 Currency). For the exemplar: confirm the Schaeffer et al. entry's preprint DOI is real and current.
- [ ] **Type/field sanity**: `@article` has journal+volume; `@inproceedings` has booktitle; software/toolboxes (YASA, SimNIBS, MNE) cite the canonical paper, not a bare URL.

### 2. Source acquisition ladder (per claim, cheapest-first)

For each claim to verify, obtain the actual source text in this order and record which rung you used in the ledger:
1. [ ] **Local PDF** named in `literature.md` (preferred — full text). Read the relevant section, not just the abstract.
2. [ ] **`literature.md` summary** if it already states the relevant number/finding (fast triage; still confirm against full text for load-bearing numbers).
3. [ ] **OpenAlex**: `mcp__openalex__get_work` for abstract + metadata; `mcp__openalex__find_open_access_version` for an OA full text; `get_work_references`/`get_work_citations` to trace a number to its true origin.
4. [ ] **WebFetch** the DOI landing page / publisher abstract / OA PDF for the specific quantitative claim.
5. [ ] If none yield the claimed specifics, mark the claim **UNVERIFIABLE** in the ledger (do not silently pass it) and note what was consulted.

### 3. Representation fidelity (core job)

For every LOAD-BEARING or QUANTITATIVE claim attributed to a citation, confirm the source actually says it, with the correct number, metric, and direction. Triage: a claim is load-bearing if removing/altering it would change a Methods justification, a stat choice, a mechanistic argument, or a headline interpretation.

- [ ] **Number fidelity**: every quoted statistic (percentage, n, effect size, frequency, coordinate, p-value, sample size) matches the source exactly, including units and the metric it indexes. Exemplar failure mode — "**46% of slow waves originate in the insula**" is an *origin* statistic from the slow-wave source-modeling reference (Murphy 2009-style); do not attach it to a *density*, *involvement*, or *count* metric, and do not attribute it to a different paper. Flag number-drift even when the number is "in the right ballpark."
- [ ] **Direction/sign fidelity**: increases vs decreases, faster vs slower, anterior vs posterior, deep vs superficial all match the source. Especially check claims that support the manuscript's own positive direction.
- [ ] **Misattribution**: the cited paper actually contains the claim. Flag "paper does not say that" — claim present nowhere in the source.
- [ ] **Method-citation correctness**: each method is cited to its canonical primary source, and the cited paper is the right one:
  - [ ] Cluster-based permutation → Maris & Oostenveld 2007.
  - [ ] sLORETA → Pascual-Marqui 2002. If the manuscript asserts **sLORETA is noise-normalized and therefore depth-insensitive** (the justification for depth weighting 0.8 rather than 2–5), that specific claim must cite the source that establishes it (Lin et al. 2006, NeuroImage 31:160) — and confirm that source actually says the 2–5 guidance applies to plain MNE, not sLORETA. This is a textbook spot for citing-the-wrong-paper or overgeneralization.
  - [ ] Slow-wave detection → the YASA reference; same-wave dedup / traveling-wave framing → Massimini 2004; source modeling of SWs → Murphy 2009.
  - [ ] Head model / leadfield → SimNIBS 4 + CHARM segmentation (Puonti 2020); cortical surfaces → Fischl 2012 if asserted.
  - [ ] Effect sizes → Kerby 2014 (within, matched-pairs rank-biserial) and Wendt 1972 (between); Lakens 2013 for grounding. Confirm Kerby is not cited for the between-group formula or vice versa.
- [ ] **Overgeneralization**: a narrow source result (one ROI, one band, one species, n=4, nap not overnight) is cited as a general fact. Flag scope inflation; require the manuscript to scope the claim to match the source.
- [ ] **Review-as-primary**: a claim of a specific empirical result is cited to a review/meta-analysis instead of the primary study. Use `mcp__openalex__get_work` `type` and `find_review_articles` to detect reviews; recommend the primary citation (trace via `get_work_references`).
- [ ] **Speculation laundering**: the manuscript states as established something the source only hypothesizes/speculates/discusses. Check the source's own hedging language; if the source says "may/might/could," the citing claim cannot say "does/shows."
- [ ] **Quote/paraphrase integrity**: any near-verbatim phrasing is attributable and not lifted without citation; paraphrases preserve the source's caveats.
- [ ] **Figure/caption claims** are verified too — captions often carry uncited quantitative assertions.

### 4. Self / adjacent-work framing

- [ ] **Shared-data lineage**: when a cited study shares subjects, hardware, or dataset lineage with this manuscript, confirm the framing is accurate and neither over- nor under-claimed. Exemplar rule: cite Schaeffer et al. as a **plain reference only** — never "the parent study," "our prior study," or "a re-analysis," because the dataset is roughly-but-not-1:1 the same. Grep the body for "parent study / re-analysis / our previous / same data / reanaly" near that citation and flag any such framing.
- [ ] **Novelty claims vs prior art**: statements like "first study to apply TI during sleep for deep slow-wave modulation" must be defensible — search OpenAlex (`search_works`, `find_seminal_papers`) for prior TI-during-sleep or deep-target TI work and confirm the novelty claim survives, or recommend softening ("to our knowledge").
- [ ] **Reproduction vs origination**: when the manuscript says it "reproduces" or "is consistent with" a prior finding, verify the prior finding is actually what that paper reported (a within-active spectral SWA increase, say), not a paraphrase that drifts.
- [ ] **Target-identity consistency with cited rationale**: the deep-target justification must match the actual target. The left **insula** is the target (earlier drafts mislabeled left mPFC); confirm every citation invoked to justify the target's depth/role is about the insula (or generic deep-target TI), not a leftover mPFC-rationale reference.

### 5. Missing-citation sweep

- [ ] **Uncited empirical/quantitative claims**: scan body blocks for sentences stating a specific number, prevalence, anatomical fact, or prior result as fact with NO `[n]`. For each, search a supporting source via `mcp__openalex__search_works` / `find_seminal_papers` and propose a citation (or flag as the authors' own unpublished result needing "(this study)" framing).
- [ ] **Mechanistic claims as fact**: physiological/mechanistic assertions (e.g. TI envelope demodulation drives membrane effects; slow waves reflect cortical down-states) stated flatly without a reference. Propose canonical refs; if none exist, recommend hedging.
- [ ] **Canonical methods lacking their canonical reference**: every method named in §3 above must carry its citation at first use — flag any of cluster permutation, sLORETA, YASA, SimNIBS/CHARM, rank-biserial, bootstrap CI, Iglewicz–Hoaglin modified z-score, fsaverage5 that appears uncited.
- [ ] **"Previous studies show / it is well established / prior work suggests"** with no specific `[n]` — flag every vague-attribution phrase and require concrete references. Use `find_seminal_papers` / `find_review_articles` to surface candidates the authors can choose from.
- [ ] **Statistical-threshold provenance**: nonstandard choices (5000 permutations, FWE<0.05 max-cluster-mass, one-sided [-150,0] ms origin window, cluster-forming p<0.05) should each trace to a method paper or be justified in-text; flag unjustified magic numbers.

### 6. Currency

- [ ] **Stale-for-newer-canonical**: where a foundational citation has a more recent canonical/primary replacement (e.g. an updated toolbox paper, a superseding method paper), use `mcp__openalex__get_related_works` / `find_seminal_papers` to surface it and recommend (don't force — sometimes the original is the correct historical citation).
- [ ] **Preprint→published upgrade**: for every preprint citation, query OpenAlex by title+authors for a now-published peer-reviewed version (`search_works` then confirm via `get_work`); recommend swapping the DOI/venue and updating year. This pairs with the §1 preprint-mismatch check.
- [ ] **Outdated quantitative landscape**: if the manuscript cites an old prevalence/effect-size as "current," check whether a larger/newer study revises it; note in the ledger without over-editing.

### 7. Verification ledger (required deliverable)

Emit a single table; one row per checked claim. This is the audit trail and the source for `comments.json` anchors. Use exactly these columns:

| location/anchor | claim as stated | citation | source consulted | verdict | note |
|---|---|---|---|---|---|

- `location/anchor` — section + the unique verbatim slice usable as a Word-comment anchor (citations as `[n]`).
- `claim as stated` — the manuscript's wording (trimmed), including the number/direction.
- `citation` — `[n]` plus bibkey.
- `source consulted` — which acquisition rung (local PDF path / `literature.md` / OpenAlex workID / WebFetch URL).
- `verdict` — one of **SUPPORTED / PARTIAL / MISREPRESENTED / UNVERIFIABLE**.
- `note` — the exact correction or recommendation (the right number, the right paper, "scope to nap study," "cite primary not review," "upgrade preprint to DOI x").

Verdict rubric:
- [ ] **SUPPORTED** — source states the claim with matching number/metric/direction.
- [ ] **PARTIAL** — directionally right but scope-inflated, number slightly off, or hedge dropped; needs softening or a number fix.
- [ ] **MISREPRESENTED** — wrong number/metric/paper/direction, or source doesn't say it; blocking.
- [ ] **UNVERIFIABLE** — source not obtainable or too vague to confirm; record what was tried.

Also emit two short appendices to the ledger:
- [ ] **Bibliography defects list** (orphans, missing, non-monotonic introductions, bad/duplicate DOIs, venue/retraction flags, preprint mismatches) — each with the bibkey and fix.
- [ ] **Missing-citation list** — each uncited strong claim with 1–2 proposed references (OpenAlex IDs/DOIs) so the author can accept directly.

### 8. Handoff to comments

- [ ] Convert every PARTIAL/MISREPRESENTED/UNVERIFIABLE row and every defect into a `comments.json` object `{author, date, anchor, comment}` where `anchor` is the verbatim slice from the ledger and `comment` states the verdict + concrete fix. Verify each anchor is a unique substring of the rendered text before handing to `docx-tools inject` (em-dashes, non-breaking spaces, and `[n]` rendering are the usual anchor-match failures). Defer the actual injection mechanics to the `docx-tools` skill; this checklist only produces the verified content.
