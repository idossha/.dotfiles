#!/usr/bin/env python3
"""Render the dotfiles project registry into FirstMate's private project registry.

The generated block is intentionally small: FirstMate owns delivery mechanics and
Treehouse lifecycle; dotfiles only seeds the captain's standing project posture.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys

BEGIN = "<!-- BEGIN agentctl managed FirstMate projects -->"
END = "<!-- END agentctl managed FirstMate projects -->"
MODES = {"no-mistakes", "direct-PR", "local-only", "no-mistakes-prod-only"}
DEFAULT_MODE = "no-mistakes"
DEFAULT_AUTOMERGE = True


class RegistryError(ValueError):
    """Project registry content cannot be rendered safely for FirstMate."""


def _string(value: object, label: str) -> str:
    if not isinstance(value, str) or not value:
        raise RegistryError(f"{label} must be a non-empty string")
    if any(ord(char) < 32 for char in value):
        raise RegistryError(f"{label} must not contain control characters")
    return value


def project_lines(projects_file: Path) -> list[str]:
    try:
        registry = json.loads(projects_file.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        raise RegistryError(f"invalid project registry: {exc}") from exc
    if not isinstance(registry, dict):
        raise RegistryError("project registry must have schema_version 1 and a projects object")
    projects = registry.get("projects")
    if registry.get("schema_version") != 1 or not isinstance(projects, dict) or not projects:
        raise RegistryError("project registry must have schema_version 1 and a projects object")

    lines: list[str] = []
    for alias, project in projects.items():
        alias = _string(alias, "project alias")
        if re.search(r"[\s\[\]]", alias):
            raise RegistryError(f"project alias {alias!r} cannot be rendered in FirstMate data/projects.md")
        if not isinstance(project, dict):
            raise RegistryError(f"project {alias!r} must be an object")
        path = _string(project.get("path"), f"project {alias!r} path")
        if not path.startswith("/"):
            raise RegistryError(f"project {alias!r} path must be absolute")
        label = _string(project.get("label"), f"project {alias!r} label")
        delivery = project.get("delivery", {})
        if not isinstance(delivery, dict):
            raise RegistryError(f"project {alias!r} delivery must be an object")
        mode = delivery.get("mode", DEFAULT_MODE)
        if not isinstance(mode, str) or mode not in MODES:
            raise RegistryError(f"project {alias!r} delivery.mode must be one of {', '.join(sorted(MODES))}")
        automerge = delivery.get("automerge", DEFAULT_AUTOMERGE)
        if not isinstance(automerge, bool):
            raise RegistryError(f"project {alias!r} delivery.automerge must be a boolean")
        description = delivery.get("description", label)
        if description == "":
            description = label
        description = _string(description, f"project {alias!r} delivery.description")
        if "\n" in description or "\r" in description:
            raise RegistryError(f"project {alias!r} delivery.description must fit on one line")
        annotation = mode + (" +yolo" if automerge else "")
        lines.append(f"- {alias} [{annotation}] - {description} (managed by agentctl; path {path})")
    return lines


def render_block(projects_file: Path) -> str:
    body = [
        BEGIN,
        "<!-- Source: agent/projects.json. Edit that file, not this generated block. -->",
        "<!-- Default posture: Treehouse worktree -> no-mistakes PR -> green checks -> +yolo merge. -->",
        *project_lines(projects_file),
        END,
    ]
    return "\n".join(body) + "\n"


def without_existing_block(content: str) -> str:
    lines = content.splitlines()
    output: list[str] = []
    index = 0
    removed = False
    while index < len(lines):
        if lines[index].strip() == BEGIN:
            removed = True
            index += 1
            while index < len(lines) and lines[index].strip() != END:
                index += 1
            if index < len(lines):
                index += 1
            while index < len(lines) and lines[index] == "":
                index += 1
            continue
        output.append(lines[index])
        index += 1
    if not removed:
        return content
    return "\n".join(output).strip("\n") + ("\n" if output else "")


def desired_content(projects_file: Path, target: Path) -> str:
    existing = target.read_text() if target.exists() else "# FirstMate project registry\n"
    remainder = without_existing_block(existing).strip("\n")
    block = render_block(projects_file).rstrip("\n")
    if remainder:
        return block + "\n\n" + remainder + "\n"
    return block + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--projects", type=Path, required=True)
    parser.add_argument("--firstmate", type=Path, required=True)
    parser.add_argument("--check", action="store_true", help="report drift without writing")
    parser.add_argument("--dry-run", action="store_true", help="print the managed block without writing")
    args = parser.parse_args(argv)

    target = args.firstmate / "data/projects.md"
    try:
        desired = desired_content(args.projects, target)
    except RegistryError as exc:
        print(f"firstmate-projects: {exc}", file=sys.stderr)
        return 2

    if args.check:
        if not target.exists():
            print(f"firstmate-projects: missing {target}", file=sys.stderr)
            return 1
        if target.read_text() != desired:
            print(f"firstmate-projects: drift in {target}", file=sys.stderr)
            return 1
        return 0

    if args.dry_run:
        print(f"DRY-RUN: update {target} from {args.projects} with managed no-mistakes +yolo project defaults")
        print(render_block(args.projects), end="")
        return 0

    target.parent.mkdir(parents=True, exist_ok=True)
    if not target.exists() or target.read_text() != desired:
        target.write_text(desired)
        target.chmod(0o600)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
