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
assert chr(36) + "HOME/.dotfiles/agent/scripts:" in Path(sys.argv[1]).read_text()
' "$agent_dir/../zsh/.zshrc"
expect_status 0 "canonical zshrc exposes the installed agentctl path"

fixture_count=$(find "$fixtures" -type f -name 'projects.*.json' | wc -l | tr -d ' ')
if [ "$fixture_count" -ne 3 ]; then
  printf 'not ok - expected 3 registry fixtures, found %s\n' "$fixture_count" >&2
  exit 1
fi

scratch=$(mktemp -d "${TMPDIR:-/tmp}/agentctl-tests.XXXXXX")
trap 'rm -rf "$scratch"' EXIT HUP INT TERM
repo="$scratch/project with spaces"
mkdir -p "$repo" "$scratch/bin"
git -C "$repo" init -q
git -C "$repo" commit -q --allow-empty -m "fixture: initial revision"

escaped_repo=$(printf '%s' "$repo" | sed 's/[&|]/\\&/g')
sed "s|@PROJECT@|$escaped_repo|g" "$fixtures/projects.valid.json" > "$scratch/projects.json"

# A dry-run must not execute either the visualization or an upstream orchestration tool.
invocation_log="$scratch/invocations.log"
for tool in fixture-editor herdr gnhf no-mistakes pi treehouse; do
  # shellcheck disable=SC2016 # The fake must expand these only if agentctl wrongly executes it.
  printf '#!/bin/sh\nprintf "%%s\\n" "$0 $*" >> "$AGENTCTL_TEST_LOG"\n' > "$scratch/bin/$tool"
  chmod +x "$scratch/bin/$tool"
done
export AGENTCTL_TEST_LOG="$invocation_log"
test_path="$scratch/bin:$PATH"

run_capture env PATH="$test_path" "$agentctl" start --dry-run
expect_status 0 "single entrypoint dry-run opens Herdr"
expect_contains "DRY-RUN: herdr" "single entrypoint resolves directly to Herdr"
if [ ! -e "$invocation_log" ]; then
  pass "entrypoint dry-run does not launch Herdr"
else
  fail "entrypoint dry-run does not launch Herdr"
fi

run_capture env PATH="$test_path" "$agentctl" start --harness pi --dry-run
expect_status 2 "start rejects the former ambiguous harness option"

run_capture env AGENTCTL_PROJECTS_FILE="$scratch/projects.json" PATH="$test_path" \
  "$agentctl" project fixture --visualization editor --dry-run
expect_status 0 "valid registry and visualization resolve"
expect_contains "DRY-RUN:" "dry-run is visibly labelled"
expect_contains "fixture-editor" "visualization stays an argv command"
if [ ! -e "$invocation_log" ]; then
  pass "dry-run executes no upstream command"
else
  fail "dry-run executes no upstream command"
fi

mkdir -p "$scratch/firstmate/.git"
run_capture env AGENTCTL_FIRSTMATE_DIR="$scratch/firstmate" PATH="$test_path" \
  "$agentctl" fleet --harness pi --dry-run
expect_status 0 "FirstMate fleet dry-run accepts the Pi harness"
expect_contains "FM_BACKEND=herdr" "FirstMate is explicitly configured for Herdr"
expect_contains "crew-dispatch.json" "FirstMate dry-run applies token-aware dispatch profiles"
expect_contains "pi" "FirstMate dry-run preserves the selected harness"
if [ ! -e "$invocation_log" ]; then
  pass "fleet dry-run executes no harness"
else
  fail "fleet dry-run executes no harness"
fi

run_capture env AGENTCTL_PROJECTS_FILE="$fixtures/projects.invalid-shell-string.json" \
  "$agentctl" project unsafe --dry-run
expect_status 2 "shell-string visualization is rejected as invalid registry"

run_capture env AGENTCTL_PROJECTS_FILE="$fixtures/projects.empty.json" \
  "$agentctl" project anything --dry-run
expect_status 2 "empty registry cannot pass vacuously"

run_capture env AGENTCTL_PROJECTS_FILE="$scratch/projects.json" \
  "$agentctl" project missing --dry-run
expect_status 2 "unknown project alias is a usage/configuration error"

run_capture env AGENTCTL_PROJECTS_FILE="$scratch/projects.json" PATH="$test_path" \
  "$agentctl" overnight fixture --dry-run -- "bounded fixture task"
expect_status 0 "overnight dry-run accepts an objective"
expect_contains "treehouse get --lease" "overnight always requests a durable Treehouse lease"
expect_not_contains "gnhf --worktree" "overnight does not delegate worktree creation to GNHF"
expect_contains "--max-iterations" "overnight supplies a finite default cap"
expect_contains "10" "overnight default cap is ten iterations"

run_capture env AGENTCTL_PROJECTS_FILE="$scratch/projects.json" PATH="$test_path" \
  "$agentctl" overnight fixture --max-iterations 0 --dry-run -- "invalid cap"
expect_status 2 "zero iteration cap is rejected"

run_capture env AGENTCTL_PROJECTS_FILE="$scratch/projects.json" PATH="$test_path" \
  "$agentctl" overnight fixture --dry-run
expect_status 2 "overnight run without an objective is rejected"

run_capture env AGENTCTL_PROJECTS_FILE="$scratch/projects.json" PATH="$test_path" \
  "$agentctl" ship fixture --dry-run
expect_status 3 "shipping requires project-local no-mistakes opt-in"

touch "$repo/.no-mistakes.yaml"
run_capture env AGENTCTL_PROJECTS_FILE="$scratch/projects.json" PATH="$test_path" \
  "$agentctl" ship fixture --dry-run
expect_status 0 "project-local no-mistakes opt-in enables shipping dry-run"
expect_contains "no-mistakes" "shipping resolves the upstream delivery tool"

git -C "$repo" add .no-mistakes.yaml
git -C "$repo" commit -q -m "fixture: delivery opt-in"

leased="$scratch/leased tree"
mkdir -p "$leased"
cp "$repo/.no-mistakes.yaml" "$leased/.no-mistakes.yaml"
# Synthetic linked checkout metadata: shares only this temporary repository's Git directory.
printf 'gitdir: %s/.git\n' "$repo" > "$leased/.git"
leased_real="$(cd "$leased" && pwd -P)"
cat > "$scratch/bin/treehouse" <<EOF
#!/bin/sh
printf '%s\n' "\$0 \$*" >> "\$AGENTCTL_TEST_LOG"
case "\$1" in
  --version) printf 'v2.3.0\n' ;;
  get) printf '%s\n' '{"path":"$leased","lease_id":"fixture-lease"}' ;;
esac
EOF
cat > "$scratch/bin/gnhf" <<'EOF'
#!/bin/sh
if [ "$1" = --version ]; then printf '0.1.49\n'; exit 0; fi
printf '%s\n' "$PWD $0 $*" >> "$AGENTCTL_TEST_LOG"
exit "${AGENTCTL_TEST_GNHF_STATUS:-0}"
EOF
chmod +x "$scratch/bin/treehouse" "$scratch/bin/gnhf"
export AGENT_CONFIG_HOME="$scratch/config-home"
mkdir -p "$AGENT_CONFIG_HOME/.gnhf"
cp "$agent_dir/gnhf/config.yml" "$AGENT_CONFIG_HOME/.gnhf/config.yml"
: > "$invocation_log"
run_capture env AGENTCTL_PROJECTS_FILE="$scratch/projects.json" PATH="$test_path" \
  "$agentctl" overnight fixture --max-iterations 1 -- "retained fixture task"
expect_status 0 "overnight runs from an allocated Treehouse lease"
expect_contains "Treehouse lease retained: $leased_real" "overnight reports the retained worktree path"
expect_contains "--if-lease-id fixture-lease" "overnight prints identity-bound return guidance"
run_capture cat "$invocation_log"
expect_contains "$leased_real" "GNHF execution records the leased worktree as its working directory"
expect_not_contains "gnhf --worktree" "actual overnight execution does not ask GNHF to allocate another worktree"

run_capture env AGENTCTL_PROJECTS_FILE="$scratch/projects.json" PATH="$test_path" \
  AGENTCTL_TEST_GNHF_STATUS=7 "$agentctl" overnight fixture --max-iterations 1 -- "upstream failure"
expect_status 1 "upstream GNHF failure maps to the documented command-failure exit"

printf 'uncommitted' > "$repo/dirty-fixture"
run_capture env AGENTCTL_PROJECTS_FILE="$scratch/projects.json" PATH="$test_path" \
  "$agentctl" overnight fixture --max-iterations 1 -- "dirty source"
expect_status 3 "overnight rejects a dirty source instead of auditing an older revision"
rm "$repo/dirty-fixture"

run_capture env AGENTCTL_PROJECTS_FILE="$scratch/projects.json" PATH="$test_path" \
  "$agentctl" overnight fixture --max-iterations 1 --agent unreviewed-provider -- "new adapter"
expect_status 3 "unreviewed GNHF execution mode cannot silently inherit upstream permission bypass"

# Keep ordinary system utilities available while ensuring GNHF itself cannot resolve.
missing_path="$scratch/missing-bin:/usr/bin:/bin"
mkdir -p "$scratch/missing-bin"
printf '#!/bin/sh\nexit 0\n' > "$scratch/missing-bin/treehouse"
printf '#!/bin/sh\nexit 0\n' > "$scratch/missing-bin/jq"
chmod +x "$scratch/missing-bin/treehouse" "$scratch/missing-bin/jq"
run_capture env AGENTCTL_PROJECTS_FILE="$scratch/projects.json" PATH="$missing_path" \
  "$agentctl" overnight fixture --max-iterations 1 -- "dependency check"
expect_status 4 "missing GNHF dependency has the stable missing-tool exit code"

run_capture "$AGENT_PYTHON" -c '
import json, sys
settings = json.load(open(sys.argv[1]))
allow = settings["permissions"]["allow"]
deny = settings["permissions"]["deny"]
assert "EnterWorktree(*)" not in allow and "ExitWorktree(*)" not in allow
assert "EnterWorktree(*)" in deny and "ExitWorktree(*)" in deny
assert "Bash(git worktree add:*)" in deny
assert "Bash(herdr worktree create:*)" in deny
assert "Bash(gnhf --worktree:*)" in deny
' "$agent_dir/claude/settings.json"
expect_status 0 "Claude native worktree allocation is denied in canonical settings"

run_capture grep -F "Treehouse for every agent-owned worktree" "$agent_dir/AGENTS.md"
expect_status 0 "portable instructions make Treehouse the worktree owner"

run_capture grep -F "treehouse enter --print-path" "$agent_dir/treehouse/README.md"
expect_status 0 "Treehouse guide documents native current-shell jumping"

installer="$agent_dir/scripts/install-agent-tools.sh"
# shellcheck disable=SC2016 # The fake must expand $1 only when the installer probes it.
printf '#!/bin/sh\n[ "$1" = --version ] && printf "v0.0.0\\n"\n' > "$scratch/bin/treehouse"
chmod +x "$scratch/bin/treehouse"
run_capture env PATH="$test_path" AGENT_TOOLS_DIR="$scratch/agent-tools" \
  AGENTCTL_FIRSTMATE_DIR="$scratch/agent-tools/firstmate" "$installer" --tools --dry-run
expect_status 0 "tool installer dry-run accepts the Treehouse integration"
expect_contains "treehouse-v2.3.0-" "tool installer selects the exact Treehouse release archive"
expect_contains "kunchenguid/treehouse/releases/download/v2.3.0/checksums.txt" \
  "tool installer verifies Treehouse against the published checksum list"
expect_contains "crew-dispatch.json" "tool installer seeds FirstMate token-aware dispatch profiles"

run_capture "$AGENT_PYTHON" -c '
import sys, unittest
suite = unittest.defaultTestLoader.discover(sys.argv[1], pattern="test_*.py")
if suite.countTestCases() == 0:
    raise SystemExit("no unit/regression tests collected")
result = unittest.TextTestRunner(verbosity=1).run(suite)
raise SystemExit(0 if result.wasSuccessful() else 1)
' "$test_dir"
expect_status 0 "configuration, memory and architecture regressions pass"

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
