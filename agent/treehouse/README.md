# Treehouse worktrees

[Treehouse](https://github.com/kunchenguid/treehouse) is the sole worktree allocator for agent-owned
project work in this setup.
Herdr remains the terminal and session layer: it may open a Treehouse path, but it does not create or
remove the underlying worktree.

## Fast native navigation

Run these from the primary repository or one of its managed worktrees:

```bash
treehouse status                    # list numbered and named pool slots
treehouse enter 1                   # enter slot 1 in a subshell
exit                                # return to the previous shell
cd "$(treehouse enter --print-path 1)" # move the current shell instead
```

`treehouse enter <name>` accepts the names printed by `treehouse status`, so no absolute path needs to
be remembered.
Use Herdr's sidebar for cross-project navigation and Treehouse's native `enter` command for worktrees
within the selected project.

## Standalone agent lease lifecycle

Standalone or detached automation uses durable leases rather than the interactive process-owned form.
FirstMate already uses Treehouse through its own guarded task-owner lifecycle, which remains authoritative
for FirstMate-launched work:

```bash
allocation=$(treehouse get --lease --lease-holder "$task" --json)
path=$(printf '%s' "$allocation" | jq -r .path)
lease_id=$(printf '%s' "$allocation" | jq -r .lease_id)

# Work only under "$path"; open it in Herdr when a visible pane is useful.
herdr worktree open --path "$path" --no-focus

# Return only after the branch is landed and the worktree is clean.
treehouse return "$path" --if-lease-id "$lease_id"
```

The lease ID prevents an old cleanup command from returning a slot that has since been reassigned.
A failed return is a stop-and-inspect result, not permission to reset, prune, or force removal.
Never use `treehouse return --force`, `treehouse destroy`, or raw `git worktree remove` when unlanded
work may exist unless the user explicitly authorizes discarding that exact work.

Do not use `herdr worktree create`, Claude's native worktree tools, another harness's worktree flag, or
raw `git worktree add` for agent-owned work.
When a task must inherit uncommitted source state, acquire a Treehouse lease first and copy a verified
snapshot into it; never redirect the agent to edit the source checkout.
`agentctl overnight` acquires and retains a durable Treehouse lease so its resulting branch remains
inspectable.

## Installation and checks

```bash
agent/scripts/install-agent-tools.sh --tools
agent/scripts/agentctl doctor
treehouse --version
treehouse status --json
```

The installer downloads the exact release archive and published checksum named in the canonical script.
`treehouse prune --dry-run` is the nonmutating way to inspect reclaimable pool slots.
