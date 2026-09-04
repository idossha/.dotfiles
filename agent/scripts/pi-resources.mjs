#!/usr/bin/env node
// Probe Pi's native RPC command discovery without sending a prompt or opening its TUI.
// Usage: node agent/scripts/pi-resources.mjs [cwd] [--json]
// Exit 0: nonempty, unique skills/commands returned; 1: rejected/malformed probe;
// 2: missing Pi, timeout or unavailable discovery. This does not expose every extension diagnostic.
import { spawnSync } from "node:child_process";
import { realpathSync } from "node:fs";
import { homedir } from "node:os";

const args = process.argv.slice(2);
const unknown = args.find((arg) => arg.startsWith("--") && arg !== "--json");
const paths = args.filter((arg) => !arg.startsWith("--"));
if (unknown || paths.length > 1) {
  console.error("Usage: pi-resources.mjs [cwd] [--json]");
  process.exit(2);
}
const cwd = paths[0] || process.cwd();
const id = "agent-platform-resource-probe";
const result = spawnSync("pi", ["--mode", "rpc", "--no-session", "--offline", "--no-approve", "--no-tools"], {
  cwd, encoding: "utf8", input: JSON.stringify({ id, type: "get_commands" }) + "\n",
  timeout: 30000, maxBuffer: 8 * 1024 * 1024,
});
if (result.error || result.signal || result.status === null) {
  console.error("pi-resources: Pi discovery unavailable (missing CLI, invalid cwd or 30-second timeout)");
  process.exit(2);
}
if (result.status !== 0) {
  console.error("pi-resources: native Pi exited " + result.status + "; no discovery established");
  process.exit(1);
}
const responses = result.stdout.split("\n").filter(Boolean).flatMap((line) => {
  try { return [JSON.parse(line)]; } catch { return []; }
});
const response = responses.find((item) => item.id === id && item.command === "get_commands");
const commands = response?.data?.commands;
if (!response?.success || !Array.isArray(commands) || commands.length === 0 ||
    commands.some((item) => !item || typeof item.name !== "string" || !item.name)) {
  console.error("pi-resources: missing, empty or malformed get_commands response");
  process.exit(1);
}
const skills = commands.filter((item) => item.source === "skill").map((item) => ({
  name: item.name.replace(/^skill:/, ""), path: item.sourceInfo?.path || "",
}));
const names = skills.map((skill) => skill.name);
const duplicates = [...new Set(names.filter((name, index) => names.indexOf(name) !== index))];
let unresolved = false;
for (const skill of skills) {
  try { skill.resolvedPath = realpathSync(skill.path); }
  catch { unresolved = true; }
}
const scope = "Native command/skill discovery only; no model prompt. Project-local resources ignored. " +
  "Extension diagnostics, context loading and model activation are not established.";
const report = { cwd, scope, commandCount: commands.length, skills, duplicates, unresolved };
if (args.includes("--json")) {
  console.log(JSON.stringify(report, null, 2));
} else {
  console.log(scope);
  console.log("skills (" + skills.length + "): " + names.sort().join(", "));
  console.log("commands: " + commands.length);
  for (const skill of skills) {
    console.log("  " + skill.name + " -> " + (skill.resolvedPath || skill.path).replace(homedir(), "~"));
  }
  if (duplicates.length) console.error("duplicate skills: " + duplicates.join(", "));
  if (unresolved) console.error("one or more skill source paths do not resolve");
}
process.exit(skills.length === 0 || duplicates.length || unresolved ? 1 : 0);
