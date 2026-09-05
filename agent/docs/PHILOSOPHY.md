# How our agents work: skills teach, CLIs act, MCP exposes

This is the shortest statement of why the platform is shaped the way it is. The binding rules are in
[ARCHITECTURE.md](ARCHITECTURE.md); the history is in [DECISIONS.md](DECISIONS.md). Each principle below
names the failure it prevents.

## Principles

1. **One checkout, one agent, one explicit owner per git mutation.** Agents work in the checkout they
   were launched in and do not create worktrees. Orchestrators and worktree pools split lifecycle
   ownership, so nobody can say which process is allowed to commit, merge, or delete the work.

2. **AGENTS.md routes, a skill teaches a procedure, a CLI performs an operation, an MCP server exposes
   structured read/write capability.** Pick the lightest mechanism that does the job and state a rule in
   exactly one of them; the same rule in two places drifts, and the copy that is not read is the one with
   the stale instruction.

3. **Author once under `agent/`, generate everywhere.** Harness files are thin adapters produced by
   `agentctl sync`; policy hand-copied into Claude, Codex, or Pi diverges the moment one copy changes.

4. **Prefer a pinned CLI when a shell call suffices; prefer MCP when the agent needs typed, discoverable
   capability or the tool must run out of process.** An MCP server for a one-line shell call costs a
   process and context on every session; a shell wrapper for a discoverable capability makes the agent
   guess argument shapes it cannot see.

5. **Evidence over narration.** Tests, dry-runs, and `agentctl doctor` output are proof; chat carries the
   outcome and the next action; long explanations become Lavish artifacts. A claim with no command behind
   it cannot be re-checked by the next session.

6. **Authority comes from the user session and harness enforcement, never from a tool, plugin, or
   prompt.** Treating tool metadata as permission lets any installed package widen what an agent may do.

7. **Memory belongs to `idosleep`, project facts belong to the project, secrets belong outside git.** A
   second memory router splits recall across two stores; global project facts leak into unrelated
   repositories.

8. **Registered projects that carry `.no-mistakes.yaml` ship through `agentctl ship`; others use ordinary
   PRs. Never push or merge red work.** Delivering without a review/test gate turns a broken change into
   the published state of the repository.

## Need → mechanism → example

| Need | Mechanism | Example |
|---|---|---|
| Domain knowledge or a repeatable procedure an agent should follow | Skill under `agent/skills/` or the `agentic-rules` playbook | `bids`, `architecture-contract` |
| Perform an operation deterministically from a shell | Pinned CLI | `agentctl`, `gh-axi`, `no-mistakes` |
| Typed, discoverable, or out-of-process capability | MCP server in `agent/mcps/mcp-servers.json` | `context7`, `openalex`, `playwright` |
| Route an agent to the right document or rule | `AGENTS.md` (this repository's map) | `agent/AGENTS.md` |
| An invariant that must hold every time, unattended | Hook, test, or CI guard | `agent/scripts/check_coherence.py` |
