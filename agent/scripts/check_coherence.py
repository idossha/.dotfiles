#!/usr/bin/env python3
"""Source and per-commit coherence guards. No dependencies or network (§§6–7)."""
from __future__ import annotations

import argparse
from pathlib import Path
import re
import subprocess
import sys

CONTRACT = "agent/docs/ARCHITECTURE.md"
DECISIONS = "agent/docs/DECISIONS.md"


def frozen_paths(contract: str) -> set[str]:
    match = re.search(r"^## 7\. Frozen interfaces\n(.*?)(?=^## |\Z)", contract, re.M | re.S)
    if not match:
        raise ValueError("contract has no frozen-interface section")
    # A numbered entry marked retired keeps its position without naming a live frozen path.
    lines = [line for line in match[1].splitlines() if "retired" not in line.lower()]
    paths = set(re.findall(r"^\d+\.\s+\x60([^\x60]+)\x60", "\n".join(lines), re.M))
    if not paths:
        raise ValueError("contract has no frozen paths to check")
    return paths


def diff_issues(changed: set[str], frozen: set[str]) -> list[str]:
    if not changed:
        return ["no changed paths supplied; this comparison cannot prove a commit"]
    if changed & frozen and not {CONTRACT, DECISIONS} <= changed:
        return [f"frozen change requires both {CONTRACT} and {DECISIONS} in the same commit"]
    return []


def map_issues(root: Path) -> list[str]:
    issues = []
    project_map = root / "AGENTS.md"
    if not project_map.is_symlink() or project_map.readlink() != Path("agent/AGENTS.md"):
        issues.append("root AGENTS.md must be a relative link to agent/AGENTS.md")
    claude = root / "CLAUDE.md"
    if not claude.is_file() or claude.read_text().strip() != "@AGENTS.md":
        issues.append("root CLAUDE.md must import @AGENTS.md")
    content = (root / "agent/AGENTS.md").read_text()
    if len(content.splitlines()) > 150:
        issues.append("project agent map exceeds its 150-line budget")
    if "agent/docs/ARCHITECTURE.md" not in content:
        issues.append("project map must route to the repository-relative contract")
    return issues


def source_issues(root: Path) -> list[str]:
    issues = map_issues(root)
    for relative in ("agent/scripts/agentctl", "agent/scripts/install-agent-tools.sh"):
        source = (root / relative).read_text()
        if 'source "$AGENT_DIR/tools.env"' not in source:
            issues.append(f"{relative}: consume the shared tool pins")
        if re.search(r"^(?:NO_MISTAKES|\w*_?AXI)_\w+=[\"']?\d", source, re.M):
            issues.append(f"{relative}: duplicated adopted-tool version")
    paid_conflicts = {
        "agent/skills/manuscript-review/SKILL.md": ("43 = 32 active + 11 sham", "target = **left insula**"),
        "agent/skills/manuscript-review/checklists/consistency.md": ("must be the **left insula**", "p must be \x600.0942"),
        "agent/skills/mne-python/SKILL.md": ("CLAUDE_SKILL_DIR",),
        "agent/skills/mcp-authoring/SKILL.md": ("~/.dotfiles/agent/mcps/mcp-servers.json",),
        "agent/skills/telemetry-triage/SKILL.md": ("/Users/idohaber/01_production/", "v2.3.1"),
        "agent/skills/git-collaboration/SKILL.md": ("Use trailers consistently:", "Co-authored-by:"),
        "agent/skills/write-skill/SKILL.md": ("Facts about the codebase belong in CLAUDE.md",
                                           "Always write to \x60~/.dotfiles/agent/skills"),
        "agent/skills/orchestrator/SKILL.md": ("Subagents are launched with the Agent tool.",
                                            "Subagents inherit none of the conversation."),
    }
    for relative, forbidden in paid_conflicts.items():
        path = root / relative
        if not path.exists():
            continue
        source = path.read_text()
        for phrase in forbidden:
            if phrase in source:
                issues.append(f"{relative}: retired conflicting procedure returned")
    for relative in ("agent/IMPLEMENTATION-PLAN.md", "agent/MULTI-HARNESS-PLAN.md"):
        path = root / relative
        if path.exists() and "Historical" not in path.read_text()[:500]:
            issues.append(f"{relative}: archived plans must not appear authoritative")
    if (root / "agent/pi/extensions/git-checkpoint.ts").exists():
        issues.append("retired Pi stash checkpoint reintroduced a second Git owner")
    return issues


def git_output(root: Path, *args: str) -> str:
    result = subprocess.run(["git", "-C", str(root), *args], text=True, capture_output=True)
    if result.returncode:
        raise ValueError("Git comparison unavailable; fetch the requested base before checking")
    return result.stdout


def commit_paths(root: Path, commit: str) -> set[str]:
    # Resolve parents explicitly: diff-tree -m can include every parent despite --first-parent.
    revisions = git_output(root, "rev-list", "--parents", "-n", "1", commit).split()
    if len(revisions) > 1:
        changed = git_output(root, "diff", "--name-only", "--no-renames", "-z",
                             revisions[1], revisions[0])
    else:
        changed = git_output(root, "diff-tree", "--root", "--no-commit-id", "--name-only",
                             "--no-renames", "-r", "-z", revisions[0])
    return set(changed.split(chr(0))) - {""}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    selection = parser.add_mutually_exclusive_group()
    selection.add_argument("--base", help="check each commit from this revision through HEAD")
    selection.add_argument("--files", nargs="+", help="explicit changed paths for a fixture or review")
    args = parser.parse_args(argv)
    root = args.root.resolve()
    try:
        issues = source_issues(root)
        frozen = frozen_paths((root / CONTRACT).read_text())
        for path in frozen:
            if not (root / path).is_file():
                issues.append(f"frozen path is missing: {path}")
        if args.files:
            issues.extend(diff_issues(set(args.files), frozen))
        elif args.base:
            git_output(root, "rev-parse", "--verify", args.base + "^{commit}")
            if subprocess.run(["git", "-C", str(root), "merge-base", "--is-ancestor",
                               args.base, "HEAD"], capture_output=True).returncode:
                raise ValueError("requested base is not an ancestor of HEAD")
            commits = git_output(root, "rev-list", "--reverse", f"{args.base}..HEAD").splitlines()
            if not commits:
                raise ValueError("no commits to compare; supply the actual pre-change base")
            for commit in commits:
                changed = commit_paths(root, commit)
                issues.extend(f"{commit[:12]}: {issue}" for issue in diff_issues(changed, frozen))
            print(f"checked {len(commits)} commits against {len(frozen)} contract-owned frozen paths")
        else:
            print(f"source checks only; {len(frozen)} frozen paths exist (no commit comparison requested)")
        for issue in issues:
            print(f"coherence: {issue}", file=sys.stderr)
        if issues:
            return 1
        print("coherence checks passed")
        return 0
    except (OSError, ValueError) as exc:
        print(f"coherence: could not check: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
