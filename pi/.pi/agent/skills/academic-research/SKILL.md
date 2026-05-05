---
name: academic-research
description: Literature search and paper triage across arXiv, PubMed, bioRxiv/medRxiv preprints, Europe PMC, Semantic Scholar, and OpenAlex. Use for scholarly evidence, DOI/PubMed/arXiv lookup, paper summaries, citation candidates, and research-gap scans.
---

# Academic Research

Use this skill when the user asks for papers, literature, PubMed, arXiv, bioRxiv, medRxiv, Semantic Scholar, OpenAlex, DOI lookup, or evidence for a scientific claim.

## Tool order

1. `academic_search` — first-line scholarly search across direct public APIs.
2. `paper_fetch` — inspect a specific DOI, PubMed ID, arXiv ID/URL, or title.
3. `arxiv_search` / `arxiv_paper` — use for deeper arXiv-only work.
4. `web_search` / `fetch_content` — use only after scholarly APIs for lab pages, docs, PDFs, author pages, or unavailable papers.

Do **not** use MCP for literature work unless the user explicitly asks; prefer the direct tools above.

## Search pattern

For broad literature review:

1. Run `academic_search` with `source: "all"`, 3–8 results/source.
2. Run targeted follow-ups:
   - `source: "pubmed"` for biomedical/clinical papers.
   - `source: "preprints"` for bioRxiv/medRxiv.
   - `source: "arxiv"` for computational/math/AI methods.
   - `source: "semantic_scholar"` or `"openalex"` for cross-disciplinary citation discovery.
3. Fetch the most relevant papers with `paper_fetch`.
4. Synthesize, do not dump results.

## Report format

Use concise research-note style:

- **Question:** what was searched.
- **Best evidence:** 3–7 papers with source, year, DOI/URL, and why each matters.
- **Consensus:** what the literature appears to support.
- **Caveats:** weak evidence, old papers, preprints, small samples, missing full text.
- **Next searches:** precise follow-up queries if needed.

## Citation discipline

- Always include DOI, PubMed URL, arXiv URL, or paper URL when available.
- Distinguish peer-reviewed papers from preprints.
- Say when an abstract was unavailable.
- Never imply Google Scholar coverage; it has no stable public API here. Use Semantic Scholar/OpenAlex/CrossRef-like sources instead.
