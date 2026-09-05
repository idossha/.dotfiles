#!/usr/bin/env bash
set -u
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=Fixture GIT_AUTHOR_EMAIL=fixture@example.invalid
export GIT_COMMITTER_NAME=Fixture GIT_COMMITTER_EMAIL=fixture@example.invalid

test_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
agent_dir=$(CDPATH='' cd -- "$test_dir/.." && pwd)
AGENT_DIR="$agent_dir"
# shellcheck source=../scripts/python-runtime.sh
source "$agent_dir/scripts/python-runtime.sh"
agentctl="$agent_dir/scripts/agentctl"
fixtures="$test_dir/fixtures"
pass_count=0
fail_count=0
last_output=
last_status=0

pass() {
  pass_count=$((pass_count + 1))
  printf 'ok %d - %s\n' "$pass_count" "$1"
}

fail() {
  fail_count=$((fail_count + 1))
  printf 'not ok - %s\n' "$1" >&2
  if [ -n "$last_output" ]; then
    printf '%s\n' "$last_output" >&2
  fi
}

run_capture() {
  set +e
  last_output=$("$@" 2>&1)
  last_status=$?
  set -e
}

expect_status() {
  expected=$1
  description=$2
  if [ "$last_status" -eq "$expected" ]; then
    pass "$description"
  else
    fail "$description (expected exit $expected, got $last_status)"
  fi
}

expect_contains() {
  needle=$1
  description=$2
  case "$last_output" in
    *"$needle"*) pass "$description" ;;
    *) fail "$description (missing: $needle)" ;;
  esac
}

expect_not_contains() {
  needle=$1
  description=$2
  case "$last_output" in
    *"$needle"*) fail "$description (unexpected: $needle)" ;;
    *) pass "$description" ;;
  esac
}

if [ ! -x "$agentctl" ]; then
  printf 'not ok - agent/scripts/agentctl is absent or not executable\n' >&2
  exit 1
fi

# Read the shell surface without sourcing the user's GUI, plugins or filesystem state.
run_capture "$AGENT_PYTHON" -c '
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text()
assert "export PATH=\"$HOME/.local/bin:$PATH\"" in source
assert chr(36) + "HOME/.dotfiles/agent/scripts:" in source
' "$agent_dir/../zsh/.zshrc"
expect_status 0 "canonical zshrc exposes .local/bin and agentctl paths"

fixture_count=$(find "$fixtures" -type f -name 'projects.*.json' | wc -l | tr -d ' ')
if [ "$fixture_count" -ne 3 ]; then
  printf 'not ok - expected 3 registry fixtures, found %s\n' "$fixture_count" >&2
  exit 1
fi

scratch=$(mktemp -d "${TMPDIR:-/tmp}/agentctl-tests.XXXXXX")
trap 'rm -rf "$scratch"' EXIT HUP INT TERM
repo="$scratch/project with spaces"
mkdir -p "$repo" "$scratch/bin"
git -C "$repo" init -q -b main
git -C "$repo" commit -q --allow-empty -m "fixture: initial revision"

escaped_repo=$(printf '%s' "$repo" | sed 's/[&|]/\\&/g')
sed "s|@PROJECT@|$escaped_repo|g" "$fixtures/projects.valid.json" > "$scratch/projects.json"

# A dry-run must not execute an upstream delivery tool.
invocation_log="$scratch/invocations.log"
for tool in gh-axi no-mistakes pi; do
  # shellcheck disable=SC2016 # The fake must expand these only if agentctl wrongly executes it.
  printf '#!/bin/sh\nprintf "%%s\\n" "$0 $*" >> "$AGENTCTL_TEST_LOG"\n' > "$scratch/bin/$tool"
  chmod +x "$scratch/bin/$tool"
done
export AGENTCTL_TEST_LOG="$invocation_log"
test_path="$scratch/bin:$PATH"

run_capture env PATH="$test_path" "$agentctl" --help
expect_status 0 "help is available without a registry"
expect_contains "doctor" "help documents the doctor command"
expect_contains "sync" "help documents the sync command"
expect_contains "ship" "help documents the ship command"
for retired in start project fleet overnight; do
  run_capture env AGENTCTL_PROJECTS_FILE="$scratch/projects.json" PATH="$test_path" \
    "$agentctl" "$retired" fixture --dry-run
  expect_status 2 "retired command '$retired' is a usage error"
done

# sync is the only command allowed to write configuration, and --dry-run must write nothing.
printf '#!/bin/sh\nprintf "%%s\\n" "$0 $*" >> "$AGENTCTL_TEST_LOG"\n' > "$scratch/bin/fixture-sync"
chmod +x "$scratch/bin/fixture-sync"
run_capture env PATH="$test_path" AGENTCTL_SYNC_SCRIPT="$scratch/bin/fixture-sync" \
  "$agentctl" sync --dry-run
expect_status 0 "sync dry-run resolves the canonical sync script"
expect_contains "DRY-RUN:" "sync dry-run is visibly labelled"
if [ ! -e "$invocation_log" ]; then
  pass "sync dry-run executes no configuration write"
else
  fail "sync dry-run executes no configuration write"
fi

run_capture env PATH="$test_path" AGENTCTL_SYNC_SCRIPT="$scratch/bin/fixture-sync" \
  "$agentctl" sync --unknown-option
expect_status 2 "unknown sync option is a usage error"

run_capture env AGENTCTL_PROJECTS_FILE="$fixtures/projects.invalid-shell-string.json" \
  "$agentctl" ship unsafe --intent "fixture goal" --dry-run
expect_status 2 "shell-string visualization is rejected as invalid registry"

run_capture env AGENTCTL_PROJECTS_FILE="$fixtures/projects.empty.json" \
  "$agentctl" ship anything --intent "fixture goal" --dry-run
expect_status 2 "empty registry cannot pass vacuously"

run_capture env AGENTCTL_PROJECTS_FILE="$scratch/projects.json" \
  "$agentctl" ship missing --intent "fixture goal" --dry-run
expect_status 2 "unknown project alias is a usage/configuration error"

run_capture env AGENTCTL_PROJECTS_FILE="$scratch/projects.json" PATH="$test_path" \
  "$agentctl" ship fixture --dry-run
expect_status 3 "shipping requires project-local no-mistakes opt-in"

touch "$repo/.no-mistakes.yaml"
run_capture env AGENTCTL_PROJECTS_FILE="$scratch/projects.json" PATH="$test_path" \
  "$agentctl" ship fixture --dry-run
expect_status 0 "project-local no-mistakes opt-in enables shipping dry-run"
expect_contains "no-mistakes axi run" "shipping resolves the no-mistakes AXI delivery gate"
expect_contains "gh-axi pr merge" "shipping schedules guarded GitHub auto-merge by default"

run_capture env AGENTCTL_PROJECTS_FILE="$scratch/projects.json" PATH="$test_path" \
  "$agentctl" ship fixture --no-automerge --dry-run
expect_status 0 "shipping accepts an explicit no-automerge run"
expect_not_contains "gh-axi pr merge" "no-automerge withholds the guarded merge step"

if [ ! -e "$invocation_log" ]; then
  pass "every ship dry-run executes no upstream command"
else
  fail "every ship dry-run executes no upstream command"
fi

git -C "$repo" add .no-mistakes.yaml
git -C "$repo" commit -q -m "fixture: delivery opt-in"

# ship must refuse a dirty or base-branch checkout before no-mistakes can start.
run_capture env AGENTCTL_PROJECTS_FILE="$scratch/projects.json" PATH="$test_path" \
  "$agentctl" ship fixture --intent "fixture goal"
expect_status 3 "ship refuses to run from the base branch"
git -C "$repo" checkout -q -b feature
printf 'uncommitted' > "$repo/dirty-fixture"
run_capture env AGENTCTL_PROJECTS_FILE="$scratch/projects.json" PATH="$test_path" \
  "$agentctl" ship fixture --intent "fixture goal"
expect_status 3 "ship refuses uncommitted work before the gate starts"
rm "$repo/dirty-fixture"

run_capture env AGENTCTL_PROJECTS_FILE="$scratch/projects.json" PATH="$test_path" \
  "$agentctl" ship fixture
expect_status 2 "ship without --intent cannot judge the change"

# Keep ordinary system utilities available while ensuring no-mistakes cannot resolve.
missing_path="$scratch/missing-bin:/usr/bin:/bin"
mkdir -p "$scratch/missing-bin"
run_capture env AGENTCTL_PROJECTS_FILE="$scratch/projects.json" PATH="$missing_path" \
  "$agentctl" ship fixture --intent "fixture goal"
expect_status 4 "missing delivery dependency has the stable missing-tool exit code"

# doctor is read-only: a failing sync check must surface, never be repaired silently.
printf '#!/bin/sh\nprintf "%%s\\n" "$0 $*" >> "$AGENTCTL_TEST_LOG"\nexit 1\n' > "$scratch/bin/failing-sync"
chmod +x "$scratch/bin/failing-sync"
: > "$invocation_log"
run_capture env AGENTCTL_PROJECTS_FILE="$scratch/projects.json" PATH="$test_path" \
  AGENTCTL_SYNC_SCRIPT="$scratch/bin/failing-sync" AGENT_CONFIG_HOME="$scratch/doctor-home" \
  AGENTIC_RULES_DIR="$scratch/missing-playbook" "$agentctl" doctor
expect_status 1 "doctor reports a failed installed-configuration check"
run_capture cat "$invocation_log"
expect_contains "--check-installed" "doctor asks the sync script only for a check"

run_capture env AGENTCTL_PROJECTS_FILE="$scratch/projects.json" PATH="$test_path" \
  "$agentctl" doctor --repair
expect_status 2 "doctor accepts no arguments"

run_capture "$AGENT_PYTHON" -c '
import json, sys
settings = json.load(open(sys.argv[1]))
allow = settings["permissions"]["allow"]
deny = settings["permissions"]["deny"]
assert "EnterWorktree(*)" not in allow and "ExitWorktree(*)" not in allow
assert "EnterWorktree(*)" in deny and "ExitWorktree(*)" in deny
assert "Bash(git worktree add:*)" in deny
' "$agent_dir/claude/settings.json"
expect_status 0 "Claude native worktree allocation is denied in canonical settings"

run_capture grep -F "Work in the launched checkout" "$agent_dir/AGENTS.md"
expect_status 0 "portable instructions keep agents in the launched checkout"

installer="$agent_dir/scripts/install-agent-tools.sh"
run_capture env PATH="$test_path" "$installer" --tools --dry-run
expect_status 0 "tool installer dry-run resolves the adopted tools"
expect_contains "no-mistakes" "tool installer includes the pinned delivery gate"
expect_contains "gh-axi@" "tool installer includes pinned AXI GitHub helper"
expect_contains "chrome-devtools-axi@" "tool installer includes pinned AXI browser helper"
expect_contains "lavish-axi@" "tool installer includes pinned AXI review helper"
expect_contains "quota-axi@" "tool installer includes pinned AXI quota helper"

run_capture "$AGENT_PYTHON" -c '
import sys, unittest
suite = unittest.defaultTestLoader.discover(sys.argv[1], pattern="test_*.py")
if suite.countTestCases() == 0:
    raise SystemExit("no unit/regression tests collected")
result = unittest.TextTestRunner(verbosity=1).run(suite)
raise SystemExit(0 if result.wasSuccessful() else 1)
' "$test_dir"
expect_status 0 "configuration and architecture regressions pass"

total=$((pass_count + fail_count))
if [ "$total" -eq 0 ]; then
  printf 'not ok - no checks ran\n' >&2
  exit 1
fi
printf '1..%d\n' "$total"
if [ "$fail_count" -ne 0 ]; then
  printf '# %d checks failed\n' "$fail_count" >&2
  exit 1
fi
printf '# %d checks passed\n' "$pass_count"
