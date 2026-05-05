import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { getAgentDir } from "@mariozechner/pi-coding-agent";
import { StringEnum } from "@mariozechner/pi-ai";
import { Text, truncateToWidth } from "@mariozechner/pi-tui";
import { mkdirSync, openSync, readFileSync, readdirSync, rmSync, unlinkSync, writeFileSync } from "node:fs";
import { basename, join, resolve } from "node:path";
import { homedir } from "node:os";
import { spawn } from "node:child_process";
import { Type } from "typebox";

const ROOT = join(getAgentDir(), "managed-jobs");
const POLL_MS = Number(process.env.PI_JOB_POLL_MS ?? 5000);
const AUTO_FOLLOW_UP = (process.env.PI_JOB_AUTO_FOLLOW_UP ?? "1") !== "0";
const DEFAULT_TAIL_LINES = 24;
const SUMMARY_TAIL_LINES = 18;
const MAX_SUMMARY_CHARS = 1800;

const PROGRESS_PREFIX = "JOB_PROGRESS ";
const STAGE_PREFIX = "JOB_STAGE ";
const ARTIFACT_PREFIX = "JOB_ARTIFACT ";
const EXIT_MARKER = "__PI_JOB_EXIT_CODE__=";
const FAIL_MARKER = "__PI_JOB_FAILURE_REASON__=";

type JobStatus = "running" | "succeeded" | "failed" | "stopped" | "timed_out";

interface ManagedJob {
	id: string;
	name?: string;
	command: string;
	cwd: string;
	status: JobStatus;
	pid: number;
	startedAt: number;
	createdAt: number;
	endedAt?: number;
	exitCode?: number | null;
	timeoutSec?: number;
	progressRegex?: string;
	progressText?: string;
	stage?: string;
	lastLine?: string;
	artifacts: string[];
	tags: string[];
	logPath: string;
	scriptPath: string;
	metaPath: string;
	notified?: boolean;
}

interface PersistedState {
	expanded: boolean;
	jobs: ManagedJob[];
}

function ensureRoot(): void {
	mkdirSync(ROOT, { recursive: true });
}

function now(): number {
	return Date.now();
}

function isoNow(): string {
	return new Date().toISOString();
}

function sanitize(text: string): string {
	return (text || "job")
		.toLowerCase()
		.replace(/[^a-z0-9]+/g, "-")
		.replace(/^-+|-+$/g, "")
		.slice(0, 40) || "job";
}

function makeId(name: string | undefined, command: string): string {
	const stamp = new Date().toISOString().replace(/[-:TZ.]/g, "").slice(0, 14);
	const rand = Math.floor(Math.random() * 9000 + 1000);
	return `job-${stamp}-${rand}-${sanitize(name || command)}`;
}

function jobDir(id: string): string {
	return join(ROOT, id);
}

function duration(job: ManagedJob): string {
	const end = job.endedAt ?? now();
	const sec = Math.max(0, Math.round((end - job.startedAt) / 1000));
	if (sec < 60) return `${sec}s`;
	const min = Math.floor(sec / 60);
	const rem = sec % 60;
	if (min < 60) return `${min}m ${rem}s`;
	const hrs = Math.floor(min / 60);
	return `${hrs}h ${min % 60}m`;
}

function summarizeCommand(command: string, width = 96): string {
	return truncateToWidth(command.replace(/\s+/g, " ").trim(), width, "…");
}

function isPidAlive(pid: number | undefined): boolean {
	if (!pid || pid <= 0) return false;
	try {
		process.kill(pid, 0);
		return true;
	} catch {
		return false;
	}
}

function tailLines(filePath: string, n: number): string[] {
	try {
		const text = readFileSync(filePath, "utf8");
		return text
			.split(/\r?\n/)
			.map((line) => line.replace(/\x1b\[[0-9;]*m/g, ""))
			.filter((line) => line.trim().length > 0)
			.slice(-n);
	} catch {
		return [];
	}
}

function parseProgress(job: ManagedJob, lines: string[]): void {
	let progressText = job.progressText;
	let stage = job.stage;
	let lastLine = lines[lines.length - 1];
	const artifacts: string[] = [];
	let exitCode = job.exitCode;
	let failure: string | undefined;

	for (const line of lines) {
		if (line.startsWith(PROGRESS_PREFIX)) progressText = line.slice(PROGRESS_PREFIX.length).trim() || progressText;
		if (line.startsWith(STAGE_PREFIX)) stage = line.slice(STAGE_PREFIX.length).trim() || stage;
		if (line.startsWith(ARTIFACT_PREFIX)) {
			const artifact = line.slice(ARTIFACT_PREFIX.length).trim();
			if (artifact) artifacts.push(artifact);
		}
		if (line.includes(EXIT_MARKER)) {
			const raw = line.split(EXIT_MARKER)[1];
			const num = Number(raw);
			if (Number.isFinite(num)) exitCode = num;
		}
		if (line.includes(FAIL_MARKER)) failure = line.split(FAIL_MARKER)[1]?.trim();
	}

	if (job.progressRegex) {
		try {
			const rx = new RegExp(job.progressRegex);
			for (let i = lines.length - 1; i >= 0; i--) {
				const m = lines[i]!.match(rx);
				if (!m) continue;
				progressText = m.length > 1 ? m.slice(1).filter(Boolean).join("/") : m[0];
				break;
			}
		} catch {
			// ignore invalid regex in background poll loop
		}
	}

	job.progressText = progressText;
	job.stage = stage;
	job.lastLine = lastLine;
	job.exitCode = exitCode;
	job.artifacts = [...new Set([...job.artifacts, ...artifacts])];
	if (failure === "timeout") job.status = "timed_out";
}

function writeJob(job: ManagedJob): void {
	writeFileSync(job.metaPath, JSON.stringify(job, null, 2));
}

function removeJobFiles(job: ManagedJob): void {
	for (const path of [job.metaPath, job.logPath, job.scriptPath]) {
		try {
			unlinkSync(path);
		} catch {
			// ignore
		}
	}
	try {
		rmSync(jobDir(job.id), { recursive: true, force: true });
	} catch {
		// ignore
	}
}

function buildScript(job: ManagedJob): string {
	return `#!/usr/bin/env bash
exec >> ${JSON.stringify(job.logPath)} 2>&1
set -o pipefail
cd ${JSON.stringify(job.cwd)} || exit 1
echo "__PI_JOB_ID__=${job.id}"
echo "__PI_JOB_STARTED_AT__=${job.startedAt}"
export PI_JOB_ID=${JSON.stringify(job.id)}
export PI_JOB_LOG=${JSON.stringify(job.logPath)}
export PI_JOB_META=${JSON.stringify(job.metaPath)}
${job.command}
ec=$?
if [ "$ec" -eq 124 ]; then echo "${FAIL_MARKER}timeout"; fi
echo "${EXIT_MARKER}$ec"
exit "$ec"
`;
}

function killJobProcess(job: ManagedJob): void {
	try {
		process.kill(-job.pid, "SIGTERM");
		return;
	} catch {
		// ignore
	}
	try {
		process.kill(job.pid, "SIGTERM");
	} catch {
		// ignore
	}
}

function restoreState(ctx: ExtensionContext): PersistedState | null {
	const entries = ctx.sessionManager.getEntries();
	for (let i = entries.length - 1; i >= 0; i--) {
		const entry = entries[i] as { type?: string; customType?: string; data?: unknown };
		if (entry.type === "custom" && entry.customType === "managed-jobs" && entry.data) {
			return entry.data as PersistedState;
		}
	}
	return null;
}

function collectJobsFromDisk(): ManagedJob[] {
	ensureRoot();
	try {
		return readdirSync(ROOT, { withFileTypes: true })
			.filter((entry) => entry.isDirectory())
			.map((entry) => join(ROOT, entry.name, "job.json"))
			.map((path) => JSON.parse(readFileSync(path, "utf8")) as ManagedJob);
	} catch {
		return [];
	}
}

export default function jobExtension(pi: ExtensionAPI) {
	ensureRoot();

	let latestCtx: ExtensionContext | null = null;
	let expanded = false;
	let jobs = new Map<string, ManagedJob>();
	let poller: NodeJS.Timeout | null = null;

	const persist = () => {
		pi.appendEntry("managed-jobs", {
			expanded,
			jobs: [...jobs.values()].sort((a, b) => a.createdAt - b.createdAt),
		} satisfies PersistedState);
	};

	const setUi = () => {
		if (!latestCtx?.hasUI) return;
		const ctx = latestCtx;
		const theme = ctx.ui.theme;
		const list = [...jobs.values()].sort((a, b) => b.createdAt - a.createdAt);
		if (list.length === 0) {
			ctx.ui.setStatus("jobs", undefined);
			ctx.ui.setWidget("jobs", undefined);
			return;
		}

		const running = list.filter((job) => job.status === "running");
		const finished = list.length - running.length;
		const head = running[0] || list[0]!;
		const icon = running.length > 0 ? theme.fg("accent", "⏱") : theme.fg("success", "✓");
		ctx.ui.setStatus(
			"jobs",
			`${icon}${theme.fg("dim", ` jobs ${running.length}R/${finished}D`)}${theme.fg("muted", ` · ${head.id}`)}${head.progressText ? theme.fg("accent", ` ${head.progressText}`) : ""}`,
		);

		if (!expanded) {
			const line = `${theme.fg("dim", "job:")} ${theme.bold(head.name || head.id)}${head.stage ? theme.fg("accent", ` · ${head.stage}`) : ""}${head.lastLine ? theme.fg("muted", ` · ${truncateToWidth(head.lastLine, 72, "…")}`) : ""}`;
			ctx.ui.setWidget("jobs", [line]);
			return;
		}

		const lines: string[] = [theme.fg("accent", "Managed jobs")];
		for (const job of list.slice(0, 8)) {
			const color = job.status === "running" ? "accent" : job.status === "succeeded" ? "success" : "warning";
			lines.push(`${theme.fg(color as any, job.status.padEnd(9))} ${theme.bold(job.id)} ${theme.fg("dim", duration(job))}${job.progressText ? theme.fg("accent", ` · ${job.progressText}`) : ""}`);
			lines.push(`  ${theme.fg("muted", summarizeCommand(job.command, 108))}`);
			if (job.stage) lines.push(`  ${theme.fg("accent", `stage: ${job.stage}`)}`);
			if (job.lastLine) lines.push(`  ${theme.fg("dim", truncateToWidth(job.lastLine, 108, "…"))}`);
			lines.push(`  ${theme.fg("muted", basename(job.logPath))}`);
		}
		ctx.ui.setWidget("jobs", lines);
	};

	const refreshJobs = () => {
		for (const job of jobs.values()) {
			parseProgress(job, tailLines(job.logPath, 300));
			if (job.status !== "running") continue;
			if (job.timeoutSec && now() - job.startedAt > job.timeoutSec * 1000) {
				killJobProcess(job);
				job.status = "timed_out";
				job.endedAt = job.endedAt ?? now();
				job.exitCode = 124;
				writeJob(job);
				continue;
			}
			if (isPidAlive(job.pid)) {
				writeJob(job);
				continue;
			}
			job.endedAt = job.endedAt ?? now();
			if (job.status === "timed_out" || job.exitCode === 124) job.status = "timed_out";
			else if (job.exitCode === 0) job.status = "succeeded";
			else if (job.status === "stopped") job.status = "stopped";
			else job.status = "failed";
			writeJob(job);
		}
		persist();
		setUi();
	};

	const maybeFollowUp = () => {
		if (!AUTO_FOLLOW_UP || !latestCtx) return;
		for (const job of jobs.values()) {
			if (job.status === "running" || job.notified) continue;
			const tail = tailLines(job.logPath, SUMMARY_TAIL_LINES).join("\n").slice(-MAX_SUMMARY_CHARS);
			const message = [
				`Managed job ${job.id} finished with status ${job.status}${job.exitCode !== undefined && job.exitCode !== null ? ` (exit ${job.exitCode})` : ""}.`,
				`Command: ${job.command}`,
				`Working directory: ${job.cwd}`,
				`Duration: ${duration(job)}`,
				`Log: ${job.logPath}`,
				job.artifacts.length > 0 ? `Artifacts:\n${job.artifacts.join("\n")}` : "",
				`Recent output:\n${tail || "(no output)"}`,
				"Please inspect outputs/logs and continue if appropriate.",
			]
				.filter(Boolean)
				.join("\n\n");
			try {
				const idle = typeof (latestCtx as any).isIdle === "function" ? Boolean((latestCtx as any).isIdle()) : true;
				if (idle) pi.sendUserMessage(message);
				else pi.sendUserMessage(message, { deliverAs: "followUp" });
				job.notified = true;
				writeJob(job);
				persist();
			} catch {
				// ignore and retry later
			}
		}
	};

	const tick = () => {
		refreshJobs();
		maybeFollowUp();
	};

	const startJob = (params: {
		command: string;
		name?: string;
		cwd: string;
		timeoutSec?: number;
		progressRegex?: string;
		tags?: string[];
	}): ManagedJob => {
		ensureRoot();
		const id = makeId(params.name, params.command);
		const dir = jobDir(id);
		mkdirSync(dir, { recursive: true });
		const job: ManagedJob = {
			id,
			name: params.name,
			command: params.command,
			cwd: params.cwd,
			status: "running",
			pid: -1,
			startedAt: now(),
			createdAt: now(),
			timeoutSec: params.timeoutSec,
			progressRegex: params.progressRegex,
			artifacts: [],
			tags: params.tags || [],
			logPath: join(dir, "job.log"),
			scriptPath: join(dir, "run.sh"),
			metaPath: join(dir, "job.json"),
			notified: false,
		};
		writeFileSync(job.logPath, `# ${isoNow()} ${job.id}\n# cwd: ${job.cwd}\n# command: ${job.command}\n`);
		writeFileSync(job.scriptPath, buildScript(job), { mode: 0o755 });
		const out = openSync(job.logPath, "a");
		const child = spawn(process.env.SHELL || "/bin/bash", [job.scriptPath], {
			cwd: job.cwd,
			detached: true,
			stdio: ["ignore", out, out],
			env: {
				...process.env,
				PI_JOB_ID: job.id,
				PI_JOB_LOG: job.logPath,
				PI_JOB_META: job.metaPath,
				HOME: process.env.HOME || homedir(),
			},
		});
		child.unref();
		job.pid = child.pid ?? -1;
		jobs.set(job.id, job);
		writeJob(job);
		persist();
		setUi();
		return job;
	};

	const stopJob = (id: string): ManagedJob => {
		const job = jobs.get(id);
		if (!job) throw new Error(`Unknown job: ${id}`);
		if (job.status === "running") {
			killJobProcess(job);
			job.status = "stopped";
			job.endedAt = now();
			job.notified = true;
			writeJob(job);
			persist();
			setUi();
		}
		return job;
	};

	const retryJob = (id: string): ManagedJob => {
		const job = jobs.get(id);
		if (!job) throw new Error(`Unknown job: ${id}`);
		return startJob({
			command: job.command,
			name: job.name,
			cwd: job.cwd,
			timeoutSec: job.timeoutSec,
			progressRegex: job.progressRegex,
			tags: job.tags,
		});
	};

	const forgetJob = (target: string): number => {
		let removed = 0;
		if (target === "all") {
			for (const job of jobs.values()) removeJobFiles(job);
			removed = jobs.size;
			jobs.clear();
		} else if (target === "done") {
			for (const [id, job] of jobs.entries()) {
				if (job.status === "running") continue;
				removeJobFiles(job);
				jobs.delete(id);
				removed++;
			}
		} else {
			const job = jobs.get(target);
			if (!job) throw new Error(`Unknown job: ${target}`);
			removeJobFiles(job);
			jobs.delete(target);
			removed = 1;
		}
		persist();
		setUi();
		return removed;
	};

	const listText = (): string => {
		const list = [...jobs.values()].sort((a, b) => b.createdAt - a.createdAt);
		if (list.length === 0) return "No managed jobs.";
		return list
			.map((job) => {
				const head = `${job.id}${job.name ? ` (${job.name})` : ""} · ${job.status} · ${duration(job)}${job.progressText ? ` · ${job.progressText}` : ""}${job.stage ? ` · ${job.stage}` : ""}`;
				return [head, `  ${job.command}`, `  ${job.logPath}`].join("\n");
			})
			.join("\n");
	};

	pi.on("session_start", async (_event, ctx) => {
		latestCtx = ctx;
		const state = restoreState(ctx);
		expanded = Boolean(state?.expanded);
		jobs = new Map((state?.jobs || collectJobsFromDisk()).map((job) => [job.id, job]));
		if (poller) clearInterval(poller);
		poller = setInterval(tick, POLL_MS);
		tick();
	});

	pi.on("session_shutdown", async () => {
		if (poller) clearInterval(poller);
		poller = null;
		if (latestCtx?.hasUI) {
			latestCtx.ui.setStatus("jobs", undefined);
			latestCtx.ui.setWidget("jobs", undefined);
		}
		latestCtx = null;
	});

	pi.registerTool({
		name: "job",
		label: "job",
		description:
			"Manage long-running jobs inside pi. Use action='run' to start a background job with a shell command, then use list/status/tail/stop/retry/forget to manage it. Designed for explicit long operations that should continue outside the current agent turn.",
		promptSnippet: "Start and manage long-running background jobs inside pi",
		promptGuidelines: [
			"Use job with action='run' for long operations that should continue in the background while pi remains responsive.",
			"Use job instead of bash for explicit long-running pipelines, preprocessing, model fitting, source reconstruction, ICA, simulations, and other multi-minute or multi-hour tasks.",
			"When using job action='run', pass a full shell command string and optionally a progressRegex or rely on JOB_PROGRESS/JOB_STAGE/JOB_ARTIFACT log lines printed by the underlying process.",
		],
		parameters: Type.Object({
			action: StringEnum(["run", "list", "status", "tail", "stop", "retry", "forget"] as const),
			command: Type.Optional(Type.String({ description: "Shell command to run when action='run'" })),
			name: Type.Optional(Type.String({ description: "Optional human-readable job name" })),
			cwd: Type.Optional(Type.String({ description: "Working directory for action='run'" })),
			timeoutSec: Type.Optional(Type.Number({ description: "Optional timeout in seconds for action='run'" })),
			progressRegex: Type.Optional(Type.String({ description: "Optional regex to parse progress from log lines" })),
			tags: Type.Optional(Type.Array(Type.String(), { description: "Optional job tags" })),
			id: Type.Optional(Type.String({ description: "Job id for status/tail/stop/retry/forget" })),
			lines: Type.Optional(Type.Number({ description: "Tail line count for action='tail'" })),
			target: Type.Optional(Type.String({ description: "Forget target: job id, 'done', or 'all'" })),
		}),
		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			tick();
			switch (params.action) {
				case "run": {
					if (!params.command) throw new Error("job action='run' requires command");
					const cwd = resolve(ctx.cwd, params.cwd || ".");
					const job = startJob({
						command: params.command,
						name: params.name,
						cwd,
						timeoutSec: params.timeoutSec,
						progressRegex: params.progressRegex,
						tags: params.tags,
					});
					return {
						content: [{ type: "text", text: `Started managed job ${job.id}.\nLog: ${job.logPath}` }],
						details: { managedJob: true, job },
						terminate: true,
					};
				}
				case "list":
					return { content: [{ type: "text", text: listText() }], details: { jobs: [...jobs.values()] } };
				case "status": {
					if (!params.id) throw new Error("job action='status' requires id");
					const job = jobs.get(params.id);
					if (!job) throw new Error(`Unknown job: ${params.id}`);
					return {
						content: [{ type: "text", text: `${job.id}${job.name ? ` (${job.name})` : ""} · ${job.status} · ${duration(job)}${job.progressText ? ` · ${job.progressText}` : ""}${job.stage ? ` · ${job.stage}` : ""}\n${job.command}\n${job.logPath}` }],
						details: { job },
					};
				}
				case "tail": {
					if (!params.id) throw new Error("job action='tail' requires id");
					const job = jobs.get(params.id);
					if (!job) throw new Error(`Unknown job: ${params.id}`);
					const lines = tailLines(job.logPath, Math.max(1, params.lines || DEFAULT_TAIL_LINES));
					return { content: [{ type: "text", text: lines.join("\n") || "(no log output)" }], details: { job, lines } };
				}
				case "stop": {
					if (!params.id) throw new Error("job action='stop' requires id");
					const job = stopJob(params.id);
					return { content: [{ type: "text", text: `Stopped ${job.id}` }], details: { job } };
				}
				case "retry": {
					if (!params.id) throw new Error("job action='retry' requires id");
					const job = retryJob(params.id);
					return {
						content: [{ type: "text", text: `Restarted as ${job.id}.\nLog: ${job.logPath}` }],
						details: { managedJob: true, job },
						terminate: true,
					};
				}
				case "forget": {
					const removed = forgetJob(params.target || params.id || "done");
					return { content: [{ type: "text", text: `Forgot ${removed} job(s).` }], details: { removed } };
				}
			}
		},
		renderCall(args, theme) {
			const text = `${theme.fg("toolTitle", theme.bold("job "))}${theme.fg("accent", String(args.action || ""))}${args.name ? theme.fg("muted", ` ${args.name}`) : ""}`;
			return new Text(text, 0, 0);
		},
		renderResult(result, { expanded: isExpanded }, theme) {
			const details = (result.details || {}) as { managedJob?: boolean; job?: ManagedJob };
			if (details.managedJob && details.job) {
				const job = details.job;
				const lines = [
					`${theme.fg("accent", "managed job")} ${theme.bold(job.id)}`,
					`${theme.fg("muted", summarizeCommand(job.command, 110))}`,
					`${theme.fg("dim", job.logPath)}`,
				];
				if (isExpanded) lines.push(theme.fg("dim", "Pi will follow up automatically when the job completes."));
				return new Text(lines.join("\n"), 0, 0);
			}
			const text = result.content?.[0]?.type === "text" ? result.content[0].text : "";
			return new Text(text || theme.fg("dim", "job complete"), 0, 0);
		},
	});

	pi.registerCommand("jobs", {
		description: "Managed jobs: list, expand, collapse, tail <id> [n], stop <id>, retry <id>, forget <id|done|all>",
		handler: async (args, ctx) => {
			tick();
			const [cmd = "list", a1, a2] = args.trim().split(/\s+/).filter(Boolean);
			if (!args.trim() || cmd === "list") {
				ctx.ui.notify(listText(), "info");
				return;
			}
			if (cmd === "expand" || cmd === "collapse" || cmd === "toggle") {
				expanded = cmd === "expand" ? true : cmd === "collapse" ? false : !expanded;
				persist();
				setUi();
				ctx.ui.notify(`Jobs widget ${expanded ? "expanded" : "collapsed"}.`, "info");
				return;
			}
			if (cmd === "tail" && a1) {
				const job = jobs.get(a1);
				ctx.ui.notify(job ? tailLines(job.logPath, Math.max(1, Number(a2 || DEFAULT_TAIL_LINES))).join("\n") || "(no log output)" : `Unknown job: ${a1}`, job ? "info" : "error");
				return;
			}
			if (cmd === "stop" && a1) {
				try {
					const job = stopJob(a1);
					ctx.ui.notify(`Stopped ${job.id}`, "warning");
				} catch (error: any) {
					ctx.ui.notify(error.message || String(error), "error");
				}
				return;
			}
			if (cmd === "retry" && a1) {
				try {
					const job = retryJob(a1);
					ctx.ui.notify(`Restarted as ${job.id}`, "info");
				} catch (error: any) {
					ctx.ui.notify(error.message || String(error), "error");
				}
				return;
			}
			if (cmd === "forget") {
				try {
					const removed = forgetJob(a1 || "done");
					ctx.ui.notify(`Forgot ${removed} job(s).`, "info");
				} catch (error: any) {
					ctx.ui.notify(error.message || String(error), "error");
				}
				return;
			}
			ctx.ui.notify("Usage: /jobs [list|expand|collapse|toggle|tail <id> [n]|stop <id>|retry <id>|forget <id|done|all>]", "error");
		},
	});

	pi.registerShortcut("ctrl+alt+j", {
		description: "Toggle jobs widget",
		handler: async (ctx) => {
			expanded = !expanded;
			persist();
			setUi();
			ctx.ui.notify(`Jobs widget ${expanded ? "expanded" : "collapsed"}.`, "info");
		},
	});
}
