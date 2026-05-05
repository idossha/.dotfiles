---
name: web-research
description: Web search and fetching workflow for current facts, documentation, code examples, URLs, companies, and deep research. Use when the task needs internet evidence outside the local repo or Obsidian vault.
---

# Web Research

Use this skill for current information, docs, URLs, company/background research, or broad web synthesis.

## Tools

Prefer the existing Yagami-style tools already configured in Pi:

- `web_search` — general web search.
- `fetch_content` — read a known URL.
- `get_code_context` — code examples, docs, Stack Overflow/GitHub-style programming context.
- `web_search_advanced` — domain/category-filtered search.
- `find_similar` — alternatives or related pages from a URL.
- `company_research` — company/product/background info.
- `deep_research_start` + `deep_research_check` — multi-step research reports; always poll until completion.

Use `academic_search` / `paper_fetch` instead for scholarly papers.

## Workflow

1. Clarify the research question in one sentence.
2. Search narrowly first: official docs, primary sources, standards, repositories.
3. Fetch the best URLs; do not rely on snippets alone.
4. Cross-check important claims with at least two independent sources when possible.
5. Report facts with source URLs and dates/version numbers where relevant.

## Output

Use this structure for non-trivial research:

- **Answer:** concise synthesis.
- **Evidence:** bullets with source URLs.
- **Details:** only what matters for the user's decision/task.
- **Caveats:** uncertainty, version-specific behavior, inaccessible pages, or stale docs.
- **Next action:** what to implement, read, or verify next.
