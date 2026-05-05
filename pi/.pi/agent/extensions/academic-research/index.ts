import { Type, StringEnum } from "@mariozechner/pi-ai";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const SOURCES = ["all", "arxiv", "pubmed", "preprints", "europepmc", "semantic_scholar", "openalex"] as const;
type Source = (typeof SOURCES)[number];

interface PaperResult {
  source: string;
  id: string;
  title: string;
  authors: string[];
  year?: string;
  date?: string;
  venue?: string;
  doi?: string;
  url?: string;
  pdfUrl?: string;
  abstract?: string;
  citationCount?: number;
  openAccess?: boolean;
}

function text(value: unknown): string {
  return typeof value === "string" ? value.trim().replace(/\s+/g, " ") : "";
}

function decodeXml(s: string): string {
  return s
    .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, "$1")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#39;|&apos;/g, "'")
    .replace(/<[^>]+>/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function tag(block: string, name: string): string {
  const m = block.match(new RegExp(`<${name}(?:\\s[^>]*)?>([\\s\\S]*?)</${name}>`, "i"));
  return m ? decodeXml(m[1]) : "";
}

function tags(block: string, name: string): string[] {
  const out: string[] = [];
  const re = new RegExp(`<${name}(?:\\s[^>]*)?>([\\s\\S]*?)</${name}>`, "gi");
  let m: RegExpExecArray | null;
  while ((m = re.exec(block))) out.push(decodeXml(m[1]));
  return out.filter(Boolean);
}

async function getJson(url: string, signal?: AbortSignal): Promise<any> {
  const resp = await fetch(url, { signal, headers: { "User-Agent": "pi-academic-research/1.0" } });
  if (!resp.ok) throw new Error(`${resp.status} ${resp.statusText}: ${(await resp.text()).slice(0, 300)}`);
  return await resp.json();
}

async function getText(url: string, signal?: AbortSignal): Promise<string> {
  const resp = await fetch(url, { signal, headers: { "User-Agent": "pi-academic-research/1.0" } });
  if (!resp.ok) throw new Error(`${resp.status} ${resp.statusText}: ${(await resp.text()).slice(0, 300)}`);
  return await resp.text();
}

function applyYearFilter(results: PaperResult[], yearFrom?: number, yearTo?: number): PaperResult[] {
  if (!yearFrom && !yearTo) return results;
  return results.filter((r) => {
    const y = Number(r.year || r.date?.slice(0, 4));
    if (!Number.isFinite(y)) return true;
    if (yearFrom && y < yearFrom) return false;
    if (yearTo && y > yearTo) return false;
    return true;
  });
}

async function searchArxiv(query: string, limit: number, signal?: AbortSignal, yearFrom?: number, yearTo?: number): Promise<PaperResult[]> {
  const url = new URL("https://export.arxiv.org/api/query");
  url.searchParams.set("search_query", `all:${query}`);
  url.searchParams.set("start", "0");
  url.searchParams.set("max_results", String(Math.min(limit, 50)));
  url.searchParams.set("sortBy", "relevance");
  url.searchParams.set("sortOrder", "descending");
  const xml = await getText(url.toString(), signal);
  const entries = [...xml.matchAll(/<entry>([\s\S]*?)<\/entry>/gi)].map((m) => m[1]);
  const results = entries.map((entry): PaperResult => {
    const absUrl = tag(entry, "id");
    const id = absUrl.split("/").pop() || absUrl;
    const pdf = entry.match(/<link[^>]+title="pdf"[^>]+href="([^"]+)"/i)?.[1];
    const doi = entry.match(/<arxiv:doi[^>]*>([\s\S]*?)<\/arxiv:doi>/i)?.[1];
    return {
      source: "arXiv",
      id,
      title: tag(entry, "title"),
      authors: tags(entry, "name"),
      date: tag(entry, "published"),
      year: tag(entry, "published").slice(0, 4),
      url: absUrl,
      pdfUrl: pdf,
      doi: doi ? decodeXml(doi) : undefined,
      abstract: tag(entry, "summary"),
      openAccess: true,
    };
  });
  return applyYearFilter(results, yearFrom, yearTo).slice(0, limit);
}

async function fetchArxiv(id: string, signal?: AbortSignal): Promise<PaperResult | null> {
  const clean = id.replace(/^arxiv:/i, "").replace(/^https?:\/\/arxiv\.org\/(abs|pdf)\//i, "").replace(/\.pdf$/i, "");
  const url = new URL("https://export.arxiv.org/api/query");
  url.searchParams.set("id_list", clean);
  url.searchParams.set("max_results", "1");
  const res = await searchArxiv(clean, 1, signal);
  if (res.length > 0 && (res[0].id.includes(clean) || clean.includes(res[0].id))) return res[0];
  const xml = await getText(url.toString(), signal);
  const entry = xml.match(/<entry>([\s\S]*?)<\/entry>/i)?.[1];
  if (!entry) return null;
  return (await searchArxiv(tag(entry, "title") || clean, 1, signal))[0] || null;
}

function pubmedParams(): string {
  const p = new URLSearchParams({ retmode: "json", tool: "pi_academic_research" });
  const key = process.env.NCBI_API_KEY || process.env.PUBMED_API_KEY;
  const email = process.env.NCBI_EMAIL || process.env.PUBMED_EMAIL;
  if (key) p.set("api_key", key);
  if (email) p.set("email", email);
  return p.toString();
}

async function fetchPubMedArticles(ids: string[], signal?: AbortSignal): Promise<PaperResult[]> {
  if (ids.length === 0) return [];
  const params = pubmedParams().replace(/^retmode=json&?/, "");
  const url = `https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&retmode=xml&id=${encodeURIComponent(ids.join(","))}${params ? `&${params}` : ""}`;
  const xml = await getText(url, signal);
  const articles = [...xml.matchAll(/<PubmedArticle>([\s\S]*?)<\/PubmedArticle>/gi)].map((m) => m[1]);
  return articles.map((a): PaperResult => {
    const pmid = tag(a, "PMID");
    const year = tag(a, "Year") || tag(a, "MedlineDate").match(/\d{4}/)?.[0] || undefined;
    const abstract = tags(a, "AbstractText").join("\n");
    const doi = a.match(/<ArticleId[^>]+IdType="doi"[^>]*>([\s\S]*?)<\/ArticleId>/i)?.[1];
    const pmc = a.match(/<ArticleId[^>]+IdType="pmc"[^>]*>([\s\S]*?)<\/ArticleId>/i)?.[1];
    return {
      source: "PubMed",
      id: pmid,
      title: tag(a, "ArticleTitle"),
      authors: [...a.matchAll(/<Author(?:\s[^>]*)?>([\s\S]*?)<\/Author>/gi)]
        .map((m) => `${tag(m[1], "ForeName")} ${tag(m[1], "LastName")}`.trim())
        .filter(Boolean),
      year,
      venue: tag(a, "Title") || tag(a, "ISOAbbreviation"),
      doi: doi ? decodeXml(doi) : undefined,
      url: pmid ? `https://pubmed.ncbi.nlm.nih.gov/${pmid}/` : undefined,
      pdfUrl: pmc ? `https://www.ncbi.nlm.nih.gov/pmc/articles/${decodeXml(pmc)}/pdf/` : undefined,
      abstract,
      openAccess: Boolean(pmc),
    };
  });
}

async function searchPubMed(query: string, limit: number, signal?: AbortSignal, yearFrom?: number, yearTo?: number): Promise<PaperResult[]> {
  let term = query;
  if (yearFrom || yearTo) term += ` AND (${yearFrom || 1800}:${yearTo || new Date().getFullYear()}[pdat])`;
  const url = `https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=${encodeURIComponent(term)}&retmax=${Math.min(limit, 50)}&${pubmedParams()}`;
  const data = await getJson(url, signal);
  const ids = data?.esearchresult?.idlist || [];
  return fetchPubMedArticles(ids, signal);
}

async function searchEuropePmc(query: string, limit: number, signal?: AbortSignal, preprintsOnly = false, yearFrom?: number, yearTo?: number, openAccessOnly?: boolean): Promise<PaperResult[]> {
  let q = preprintsOnly ? `(${query}) AND SRC:PPR` : query;
  if (yearFrom) q += ` AND FIRST_PDATE:[${yearFrom}-01-01 TO 9999-12-31]`;
  if (yearTo) q += ` AND FIRST_PDATE:[0001-01-01 TO ${yearTo}-12-31]`;
  if (openAccessOnly) q += " AND OPEN_ACCESS:y";
  const url = new URL("https://www.ebi.ac.uk/europepmc/webservices/rest/search");
  url.searchParams.set("query", q);
  url.searchParams.set("format", "json");
  url.searchParams.set("pageSize", String(Math.min(limit, 50)));
  url.searchParams.set("resultType", "core");
  const data = await getJson(url.toString(), signal);
  const rows = data?.resultList?.result || [];
  return rows.map((r: any): PaperResult => {
    const urls = r.fullTextUrlList?.fullTextUrl || [];
    const pdfUrl = urls.find((u: any) => String(u.documentStyle || "").toLowerCase() === "pdf")?.url;
    return {
      source: preprintsOnly ? "Preprints/Europe PMC" : `Europe PMC:${r.source || ""}`,
      id: text(r.id || r.pmid || r.pmcid || r.doi),
      title: text(r.title),
      authors: text(r.authorString).split(/,\s*/).filter(Boolean).slice(0, 12),
      year: text(r.pubYear),
      date: text(r.firstPublicationDate || r.pubYear),
      venue: text(r.journalTitle || r.bookOrReportDetails?.publisher),
      doi: text(r.doi) || undefined,
      url: r.pmid ? `https://pubmed.ncbi.nlm.nih.gov/${r.pmid}/` : r.doi ? `https://doi.org/${r.doi}` : r.fullTextUrlList?.fullTextUrl?.[0]?.url,
      pdfUrl,
      abstract: text(r.abstractText),
      citationCount: Number.isFinite(Number(r.citedByCount)) ? Number(r.citedByCount) : undefined,
      openAccess: r.isOpenAccess === "Y" || Boolean(pdfUrl),
    };
  });
}

async function searchSemanticScholar(query: string, limit: number, signal?: AbortSignal, yearFrom?: number, yearTo?: number, openAccessOnly?: boolean): Promise<PaperResult[]> {
  const url = new URL("https://api.semanticscholar.org/graph/v1/paper/search");
  url.searchParams.set("query", query);
  url.searchParams.set("limit", String(Math.min(limit, 20)));
  url.searchParams.set("fields", "title,authors,year,abstract,url,venue,citationCount,externalIds,publicationDate,openAccessPdf,isOpenAccess");
  if (yearFrom || yearTo) url.searchParams.set("year", `${yearFrom || ""}-${yearTo || ""}`);
  const data = await getJson(url.toString(), signal);
  return (data?.data || [])
    .filter((r: any) => !openAccessOnly || r.isOpenAccess || r.openAccessPdf?.url)
    .map((r: any): PaperResult => ({
      source: "Semantic Scholar",
      id: text(r.paperId),
      title: text(r.title),
      authors: (r.authors || []).map((a: any) => text(a.name)).filter(Boolean).slice(0, 12),
      year: r.year ? String(r.year) : undefined,
      date: text(r.publicationDate),
      venue: text(r.venue),
      doi: text(r.externalIds?.DOI) || undefined,
      url: text(r.url) || undefined,
      pdfUrl: text(r.openAccessPdf?.url) || undefined,
      abstract: text(r.abstract),
      citationCount: Number.isFinite(r.citationCount) ? r.citationCount : undefined,
      openAccess: Boolean(r.isOpenAccess || r.openAccessPdf?.url),
    }));
}

function reconstructOpenAlexAbstract(inv: Record<string, number[]> | null | undefined): string | undefined {
  if (!inv) return undefined;
  const words: string[] = [];
  for (const [word, positions] of Object.entries(inv)) for (const p of positions) words[p] = word;
  return words.join(" ").trim() || undefined;
}

async function searchOpenAlex(query: string, limit: number, signal?: AbortSignal, yearFrom?: number, yearTo?: number, openAccessOnly?: boolean): Promise<PaperResult[]> {
  const url = new URL("https://api.openalex.org/works");
  url.searchParams.set("search", query);
  url.searchParams.set("per-page", String(Math.min(limit, 50)));
  const filters: string[] = [];
  if (yearFrom) filters.push(`from_publication_date:${yearFrom}-01-01`);
  if (yearTo) filters.push(`to_publication_date:${yearTo}-12-31`);
  if (openAccessOnly) filters.push("open_access.is_oa:true");
  if (filters.length) url.searchParams.set("filter", filters.join(","));
  const email = process.env.OPENALEX_EMAIL || process.env.NCBI_EMAIL;
  if (email) url.searchParams.set("mailto", email);
  const data = await getJson(url.toString(), signal);
  return (data?.results || []).map((r: any): PaperResult => ({
    source: "OpenAlex",
    id: text(r.id),
    title: text(r.title || r.display_name),
    authors: (r.authorships || []).map((a: any) => text(a.author?.display_name)).filter(Boolean).slice(0, 12),
    year: r.publication_year ? String(r.publication_year) : undefined,
    date: text(r.publication_date),
    venue: text(r.primary_location?.source?.display_name),
    doi: text(r.doi).replace(/^https:\/\/doi\.org\//, "") || undefined,
    url: text(r.primary_location?.landing_page_url || r.doi || r.id) || undefined,
    pdfUrl: text(r.open_access?.oa_url || r.primary_location?.pdf_url) || undefined,
    abstract: reconstructOpenAlexAbstract(r.abstract_inverted_index),
    citationCount: Number.isFinite(r.cited_by_count) ? r.cited_by_count : undefined,
    openAccess: Boolean(r.open_access?.is_oa),
  }));
}

async function fetchSemantic(identifier: string, signal?: AbortSignal): Promise<PaperResult | null> {
  const id = identifier.match(/^10\./i) ? `DOI:${identifier}` : identifier;
  const url = new URL(`https://api.semanticscholar.org/graph/v1/paper/${encodeURIComponent(id)}`);
  url.searchParams.set("fields", "title,authors,year,abstract,url,venue,citationCount,externalIds,publicationDate,openAccessPdf,isOpenAccess");
  try {
    const r = await getJson(url.toString(), signal);
    return {
      source: "Semantic Scholar",
      id: text(r.paperId || identifier),
      title: text(r.title),
      authors: (r.authors || []).map((a: any) => text(a.name)).filter(Boolean).slice(0, 12),
      year: r.year ? String(r.year) : undefined,
      date: text(r.publicationDate),
      venue: text(r.venue),
      doi: text(r.externalIds?.DOI) || undefined,
      url: text(r.url) || undefined,
      pdfUrl: text(r.openAccessPdf?.url) || undefined,
      abstract: text(r.abstract),
      citationCount: Number.isFinite(r.citationCount) ? r.citationCount : undefined,
      openAccess: Boolean(r.isOpenAccess || r.openAccessPdf?.url),
    };
  } catch {
    return null;
  }
}

function formatPaper(p: PaperResult, idx?: number): string {
  const head = `${idx ? `${idx}. ` : ""}${p.title || "(untitled)"}`;
  const meta = [p.source, p.year, p.venue, p.citationCount != null ? `${p.citationCount} citations` : "", p.openAccess ? "OA" : ""]
    .filter(Boolean)
    .join(" · ");
  const authors = p.authors?.length ? p.authors.slice(0, 6).join(", ") + (p.authors.length > 6 ? " et al." : "") : "";
  const ids = [p.id ? `ID: ${p.id}` : "", p.doi ? `DOI: ${p.doi}` : ""].filter(Boolean).join(" · ");
  const links = [p.url ? `URL: ${p.url}` : "", p.pdfUrl ? `PDF: ${p.pdfUrl}` : ""].filter(Boolean).join("\n   ");
  const abs = p.abstract ? `\n   Abstract: ${p.abstract.slice(0, 900)}${p.abstract.length > 900 ? "…" : ""}` : "";
  return [`${head}`, meta ? `   ${meta}` : "", authors ? `   ${authors}` : "", ids ? `   ${ids}` : "", links ? `   ${links}` : "", abs].filter(Boolean).join("\n");
}

function normalizeIdentifier(raw: string): string {
  return raw.trim()
    .replace(/^https?:\/\/doi\.org\//i, "")
    .replace(/^doi:/i, "")
    .replace(/^pmid:/i, "pubmed:")
    .replace(/^arxiv:/i, "arxiv:");
}

export default function activate(pi: ExtensionAPI) {
  pi.registerTool({
    name: "academic_search",
    label: "Academic Search",
    description:
      "Search scholarly literature without MCP. Sources: arXiv, PubMed, Europe PMC/preprints (bioRxiv/medRxiv via Europe PMC), Semantic Scholar, and OpenAlex. Google Scholar has no stable public API; use Semantic Scholar/OpenAlex/PubMed/arXiv first.",
    promptSnippet:
      "Search papers across arXiv, PubMed, bioRxiv/medRxiv preprints, Europe PMC, Semantic Scholar, and OpenAlex",
    promptGuidelines: [
      "Use academic_search for literature discovery before general web_search when the user asks for papers, PubMed, arXiv, bioRxiv, medRxiv, Semantic Scholar, OpenAlex, DOI lookup, or scholarly evidence.",
      "Use academic_search with source='preprints' for bioRxiv/medRxiv-style preprint searches.",
    ],
    parameters: Type.Object({
      query: Type.String({ description: "Search query, e.g. 'closed-loop tES sleep spindle stimulation'" }),
      source: Type.Optional(StringEnum(SOURCES, { description: "Source to search. Default: all." })),
      max_results: Type.Optional(Type.Number({ description: "Max results per selected source (default 5, max 20)." })),
      year_from: Type.Optional(Type.Number({ description: "Earliest publication year." })),
      year_to: Type.Optional(Type.Number({ description: "Latest publication year." })),
      open_access_only: Type.Optional(Type.Boolean({ description: "Prefer/filter open-access results where source supports it." })),
    }),
    async execute(_id, params, signal) {
      const source = (params.source || "all") as Source;
      const limit = Math.max(1, Math.min(Math.round(params.max_results || 5), 20));
      const jobs: Array<Promise<PaperResult[]>> = [];
      const add = (s: Source, fn: () => Promise<PaperResult[]>) => {
        if (source === "all" || source === s) jobs.push(fn().catch((e) => [{ source: s, id: "error", title: `ERROR: ${e.message}`, authors: [] }]));
      };
      add("arxiv", () => searchArxiv(params.query, limit, signal, params.year_from, params.year_to));
      add("pubmed", () => searchPubMed(params.query, limit, signal, params.year_from, params.year_to));
      add("preprints", () => searchEuropePmc(params.query, limit, signal, true, params.year_from, params.year_to, params.open_access_only));
      add("europepmc", () => searchEuropePmc(params.query, limit, signal, false, params.year_from, params.year_to, params.open_access_only));
      add("semantic_scholar", () => searchSemanticScholar(params.query, limit, signal, params.year_from, params.year_to, params.open_access_only));
      add("openalex", () => searchOpenAlex(params.query, limit, signal, params.year_from, params.year_to, params.open_access_only));
      const results = (await Promise.all(jobs)).flat().filter((p) => p.title);
      const grouped = results.slice(0, source === "all" ? limit * 6 : limit);
      const body = grouped.length
        ? grouped.map((p, i) => formatPaper(p, i + 1)).join("\n\n")
        : "No academic results found.";
      return {
        content: [{ type: "text" as const, text: body }],
        details: { query: params.query, source, count: grouped.length, results: grouped },
      };
    },
  });

  pi.registerTool({
    name: "paper_fetch",
    label: "Fetch Paper",
    description:
      "Fetch metadata, abstract, links, DOI, and open-access PDF URL for a paper by arXiv ID/URL, PubMed ID, DOI, Semantic Scholar ID, or title-like identifier.",
    promptSnippet: "Fetch scholarly paper metadata and abstracts by DOI, arXiv ID, PubMed ID, URL, or title",
    promptGuidelines: [
      "Use paper_fetch after academic_search when the user asks to inspect a specific paper, DOI, arXiv ID, or PubMed ID.",
    ],
    parameters: Type.Object({
      identifier: Type.String({ description: "DOI, arXiv ID/URL, PubMed ID/URL, Semantic Scholar ID, or paper title" }),
      source: Type.Optional(StringEnum(["auto", "arxiv", "pubmed", "semantic_scholar", "europepmc"] as const, { description: "Preferred source. Default: auto." })),
    }),
    async execute(_id, params, signal) {
      const raw = normalizeIdentifier(params.identifier);
      const source = params.source || "auto";
      let paper: PaperResult | null = null;

      const arxivId = raw.match(/arxiv\.org\/(?:abs|pdf)\/([^\s?#]+)|^arxiv:([^\s]+)|^(\d{4}\.\d{4,5}(?:v\d+)?)$/i)?.slice(1).find(Boolean);
      const pubmedId = raw.match(/pubmed\.ncbi\.nlm\.nih\.gov\/(\d+)|^pubmed:(\d+)$|^(\d{6,9})$/i)?.slice(1).find(Boolean);
      const doi = raw.match(/(10\.\d{4,9}\/[-._;()/:A-Z0-9]+)/i)?.[1];

      if (!paper && (source === "auto" || source === "arxiv") && arxivId) paper = await fetchArxiv(arxivId, signal);
      if (!paper && (source === "auto" || source === "pubmed") && pubmedId) paper = (await fetchPubMedArticles([pubmedId], signal))[0] || null;
      if (!paper && (source === "auto" || source === "semantic_scholar")) paper = await fetchSemantic(doi || raw, signal);
      if (!paper && (source === "auto" || source === "europepmc")) paper = (await searchEuropePmc(doi ? `DOI:${doi}` : raw, 1, signal))[0] || null;
      if (!paper && source === "auto") paper = (await searchSemanticScholar(raw, 1, signal))[0] || null;

      if (!paper) throw new Error(`Could not fetch paper: ${params.identifier}`);
      return {
        content: [{ type: "text" as const, text: formatPaper(paper) }],
        details: { identifier: params.identifier, paper },
      };
    },
  });
}
