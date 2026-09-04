#!/usr/bin/env node
// Lists what Pi's DefaultResourceLoader discovers for a directory — extensions,
// skills, context files — without starting a session or calling a model.
// Usage: node agent/scripts/pi-resources.mjs [cwd]     (add --json for the raw list)
// Requires a global Pi install (@earendil-works/pi-coding-agent). Exit 0 when nothing
// failed to load, 1 when an extension errored or a skill has a diagnostic, 2 when Pi
// cannot be found.
import { execFileSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";
import { pathToFileURL } from "node:url";

function findPi() {
  let root;
  try {
    root = execFileSync("npm", ["root", "-g"], { encoding: "utf8" }).trim();
  } catch {
    return null;
  }
  const dir = join(root, "@earendil-works", "pi-coding-agent");
  const pkgJson = join(dir, "package.json");
  if (!existsSync(pkgJson)) return null;
  const pkg = JSON.parse(readFileSync(pkgJson, "utf8"));
  let entry = pkg.exports?.["."] ?? pkg.main ?? "dist/index.js";
  while (entry && typeof entry === "object") entry = entry.import ?? entry.default ?? entry.node;
  return join(dir, typeof entry === "string" ? entry : "dist/index.js");
}

const entry = findPi();
if (!entry) {
  console.error("pi-resources: @earendil-works/pi-coding-agent not found in the global npm root");
  process.exit(2);
}
const { DefaultResourceLoader } = await import(pathToFileURL(entry).href);
const args = process.argv.slice(2);
const json = args.includes("--json");
const cwd = args.find((a) => !a.startsWith("--")) || process.cwd();
const agentDir = process.env.PI_CODING_AGENT_DIR || join(homedir(), ".pi", "agent");
const loader = new DefaultResourceLoader({ cwd, agentDir });
await loader.reload();

const home = homedir();
const short = (p) => String(p).replace(home, "~");
const ext = loader.getExtensions();
const skills = loader.getSkills();
const agents = loader.getAgentsFiles();
const report = {
  cwd: short(cwd),
  agentDir: short(agentDir),
  extensions: ext.extensions.map((e) => short(e.path)),
  extensionErrors: ext.errors.map((e) => `${short(e.path)}: ${e.error}`),
  skills: skills.skills.map((s) => ({ name: s.name, path: short(s.filePath ?? s.path ?? "") })),
  skillDiagnostics: skills.diagnostics.map((d) => `${d.type ?? ""} ${short(d.path ?? "")}: ${d.message ?? ""}`.trim()),
  contextFiles: agents.agentsFiles.map((f) => short(f.path)),
};
const names = report.skills.map((s) => s.name);
const duplicates = [...new Set(names.filter((n, i) => names.indexOf(n) !== i))];
const bad = report.extensionErrors.length > 0 || report.skillDiagnostics.length > 0 || duplicates.length > 0;

if (json) {
  console.log(JSON.stringify({ ...report, duplicates }, null, 2));
} else {
  console.log(`cwd ${report.cwd}   agentDir ${report.agentDir}`);
  console.log(`extensions (${report.extensions.length})`);
  for (const e of report.extensions) console.log(`  ${e}`);
  for (const e of report.extensionErrors) console.log(`  ERROR ${e}`);
  console.log(`skills (${report.skills.length}): ${names.sort().join(", ")}`);
  for (const d of report.skillDiagnostics) console.log(`  DIAG ${d}`);
  if (duplicates.length) console.log(`  DUPLICATE ${duplicates.join(", ")}`);
  console.log(`context files: ${report.contextFiles.join(", ") || "(none)"}`);
}
process.exit(bad ? 1 : 0);
