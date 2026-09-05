#!/usr/bin/env python3
"""Render and inspect shared configuration; architecture §§1, 3, 6.

Generated files preserve unowned runtime fields. Canonical fields always win.
Use real YAML/TOML parsers so an unavailable parser cannot produce a false green.
"""
from __future__ import annotations

import argparse
from copy import deepcopy
from dataclasses import dataclass
import json
import os
from pathlib import Path
import re
import sys
import tempfile
import tomllib

try:
    import tomli_w
    import yaml
except ImportError as exc:
    raise SystemExit(
        "agent: install agent/requirements.txt in the selected Python environment; "
        f"missing module {exc.name}"
    ) from exc


class ConfigError(ValueError):
    """A diagnostic written by this module, safe to show without file contents."""


def read_config(path: Path) -> dict:
    """Read a supported mapping without printing potentially sensitive contents."""
    text = path.read_text()
    if path.suffix == ".toml":
        result = tomllib.loads(text)
    elif path.suffix in {".yaml", ".yml"}:
        result = yaml.safe_load(text)
    else:
        result = json.loads(text)
    if not isinstance(result, dict):
        raise ConfigError(f"{path}: expected an object")
    return result


def merge(base: dict, override: dict) -> dict:
    """Merge mappings recursively; the override owns scalar and array values."""
    result = deepcopy(base)
    for key, value in override.items():
        if isinstance(value, dict) and isinstance(result.get(key), dict):
            result[key] = merge(result[key], value)
        else:
            result[key] = deepcopy(value)
    return result


def unowned(policy: dict, effective: dict) -> dict:
    """Extract state without allowing an overlay to shadow a policy-owned field."""
    result = {}
    for key, value in effective.items():
        if key not in policy:
            result[key] = deepcopy(value)
        elif isinstance(value, dict) and isinstance(policy[key], dict):
            rest = unowned(policy[key], value)
            if rest:
                result[key] = rest
    return result


def atomic_write(path: Path, text: str) -> None:
    """Replace a generated file without following a previous policy symlink."""
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    temp = Path(name)
    try:
        with os.fdopen(descriptor, "w") as handle:
            handle.write(text)
        if path.exists() and not path.is_symlink():
            temp.chmod(path.stat().st_mode & 0o777)
        temp.replace(path)
    finally:
        temp.unlink(missing_ok=True)


def dump_config(path: Path, value: dict) -> None:
    if path.suffix == ".toml":
        text = tomli_w.dumps(value)
    elif path.suffix in {".yaml", ".yml"}:
        text = yaml.safe_dump(value, sort_keys=False)
    else:
        text = json.dumps(value, indent=2, ensure_ascii=False) + "\n"
    atomic_write(path, text)


def backup(path: Path) -> None:
    """Preserve unexpected real files instead of treating them as managed links."""
    suffix = 1
    target = path.with_name(f"{path.name}.before-agent-sync")
    while target.exists() or target.is_symlink():
        target = path.with_name(f"{path.name}.before-agent-sync.{suffix}")
        suffix += 1
    path.rename(target)
    print(f"  [backup] {path} -> {target.name}")


def link(source: Path, target: Path, *, relative: bool = False) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    text = os.path.relpath(source, target.parent) if relative else str(source)
    if target.is_symlink():
        if os.readlink(target) == text:
            return
        target.unlink()
    elif target.exists():
        backup(target)
    target.symlink_to(text)


def check_mcp(value: dict) -> dict:
    servers = value.get("mcpServers")
    if not isinstance(servers, dict) or not servers:
        raise ConfigError("MCP declaration needs a non-empty mcpServers object")
    for name, server in servers.items():
        if not re.fullmatch(r"[a-zA-Z0-9_-]+", name) or not isinstance(server, dict):
            raise ConfigError("MCP server names and entries must be valid")
        if "command" in server:
            allowed = {"command", "args", "env", "type"}
            valid = (
                isinstance(server["command"], str) and bool(server["command"])
                and isinstance(server.get("args", []), list)
                and all(isinstance(arg, str) for arg in server.get("args", []))
                and isinstance(server.get("env", {}), dict)
                and all(isinstance(v, str) for v in server.get("env", {}).values())
                and server.get("type", "stdio") == "stdio"
            )
        else:
            allowed = {"type", "url"}
            valid = server.get("type") == "http" and isinstance(server.get("url"), str)
            valid = valid and server["url"].startswith("https://")
        if not valid or set(server) - allowed:
            raise ConfigError(f"MCP {name}: unsupported portable shape; add an adapter before new fields")
    return servers


def skill_inventory(roots: list[Path]) -> dict[str, Path]:
    inventory = {}
    for root in roots:
        paths = sorted(path for path in root.iterdir() if path.is_dir() and not path.name.startswith("."))
        if not paths:
            raise ConfigError(f"{root}: no skills to validate")
        for path in paths:
            content = (path / "SKILL.md").read_text()
            match = re.match(r"\A---\r?\n(.*?)\r?\n---(?:\r?\n|$)", content, re.S)
            if not match:
                raise ConfigError(f"{path}: missing YAML frontmatter")
            header = yaml.safe_load(match[1])
            if not isinstance(header, dict) or header.get("name") != path.name:
                raise ConfigError(f"{path}: skill name must match its directory")
            if not isinstance(header.get("description"), str) or not header["description"].strip():
                raise ConfigError(f"{path}: missing skill description")
            if path.name in inventory:
                raise ConfigError(f"skill collision: {path.name}")
            inventory[path.name] = path
    return inventory


@dataclass(frozen=True)
class Layout:
    agent: Path
    destination: Path
    playbook: Path

    @property
    def local(self) -> Path:
        return self.agent / "local"

    @property
    def manifest(self) -> Path:
        return self.local / "managed-state.local.json"

    def inventory(self) -> dict[str, Path]:
        roots = [self.agent / "skills"]
        if (self.playbook / "skills").is_dir():
            roots.append(self.playbook / "skills")
        else:
            print(f"  [note] external playbook not checked: {self.playbook}")
        return skill_inventory(roots)

    def links(self, inventory: dict[str, Path]) -> dict[Path, Path]:
        a, d = self.agent, self.destination
        global_policy = a / "policy/global.md"
        links = {
            d / ".claude/AGENTS.md": global_policy,
            d / ".claude/CLAUDE.md": a / "claude/CLAUDE.md",
            d / ".claude/statusline-command.sh": a / "claude/statusline-command.sh",
            d / ".pi/agent/AGENTS.md": global_policy,
            d / ".codex/AGENTS.md": global_policy,
            d / ".agents/mcp.json": a / "mcps/mcp-servers.json",
            d / ".config/herdr/config.toml": a / "herdr/config.toml",
        }
        optional_claude_templates = a / "claude/templates"
        if optional_claude_templates.exists():
            links[d / ".claude/templates"] = optional_claude_templates
        for name in ("extensions", "agents", "prompts"):
            source = a / "pi" / name
            if source.exists():
                links[d / ".pi/agent" / name] = source
        for name, source in inventory.items():
            links[d / ".agents/skills" / name] = source
            links[d / ".claude/skills" / name] = source
        return links

    def policies(self) -> dict[str, tuple[dict, Path, Path]]:
        a, d = self.agent, self.destination
        mcp = check_mcp(read_config(a / "mcps/mcp-servers.json"))
        codex = read_config(a / "codex/config.toml")
        overrides = codex.get("mcp_servers", {})
        for name, entry in overrides.items():
            if name not in mcp or set(entry) - {"tools"}:
                raise ConfigError("Codex source may contain only tool overrides for canonical MCP servers")
        codex_servers = {
            name: {key: value for key, value in server.items() if key != "type"}
            for name, server in mcp.items()
        }
        codex["mcp_servers"] = merge(overrides, codex_servers)
        return {
            "claude": (read_config(a / "claude/settings.json"), d / ".claude/settings.json",
                       self.local / "claude-settings.local.json"),
            "pi": (read_config(a / "pi/settings.json"), d / ".pi/agent/settings.json",
                   self.local / "pi-settings.local.json"),
            "codex": (codex, d / ".codex/config.toml", self.local / "codex-config.local.toml"),
            "gnhf": (read_config(a / "gnhf/config.yml"), d / ".gnhf/config.yml",
                     self.local / "gnhf-config.local.yml"),
        }


def validate(layout: Layout) -> None:
    inventory = layout.inventory()
    for source in set(layout.links(inventory).values()):
        if not source.exists():
            raise ConfigError(f"missing source: {source}")
    policies = layout.policies()
    if policies["claude"][0].get("enabledPlugins", {}).get("agentic-rules@agentic-rules") is not False:
        raise ConfigError("Claude's duplicate agentic-rules plugin must be disabled; shared links own discovery")
    for name, fields in {
        "claude": {"theme", "autoMode"},
        "pi": {"theme", "lastChangelogVersion"},
        "codex": {"projects", "marketplaces", "notice"},
    }.items():
        if set(policies[name][0]) & fields:
            raise ConfigError(f"{name}: runtime state remains in tracked policy")
    read_config(layout.agent / "herdr/config.toml")
    for _, _, overlay in policies.values():
        if overlay.exists():
            read_config(overlay)
    if (layout.agent / "claude/CLAUDE.md").read_text().strip() != "@AGENTS.md":
        raise ConfigError("Claude global instructions must import AGENTS.md")
    print(f"  [ok] canonical configuration; {len(inventory)} distinct skills validated")


def previous_state(layout: Layout) -> dict:
    return read_config(layout.manifest) if layout.manifest.exists() else {}


def without_managed_servers(value: dict, names: set[str]) -> dict:
    result = deepcopy(value)
    servers = result.get("mcp_servers", {})
    if isinstance(servers, dict):
        for name in names:
            servers.pop(name, None)
    return result


def sync(layout: Layout) -> None:
    validate(layout)
    inventory = layout.inventory()
    mcp = check_mcp(read_config(layout.agent / "mcps/mcp-servers.json"))
    prior = previous_state(layout)
    managed = set(mcp) | set(prior.get("mcp_servers", []))
    # Parse every mutable destination before any writes. A late malformed file must not leave a
    # partially activated configuration. Filesystem failures remain individually atomic, not a transaction.
    renders = []
    for name, (policy, destination, overlay) in layout.policies().items():
        saved = read_config(overlay) if overlay.exists() else {}
        live = read_config(destination) if destination.exists() else {}
        if name == "codex":
            saved = without_managed_servers(saved, managed)
            live = without_managed_servers(live, managed)
        state = unowned(policy, merge(saved, live))
        renders.append((name, overlay, state, destination, merge(state, policy)))

    # Claude user scope is ~/.claude.json, not ~/.mcp.json. Preserve auth/app state in place.
    claude_path = layout.destination / ".claude.json"
    claude = read_config(claude_path) if claude_path.exists() else {}
    user_servers = claude.setdefault("mcpServers", {})
    if not isinstance(user_servers, dict):
        raise ConfigError("Claude user mcpServers must be an object")
    for name in managed:
        user_servers.pop(name, None)
    user_servers.update(mcp)

    for name, overlay, state, destination, effective in renders:
        dump_config(overlay, state)
        dump_config(destination, effective)
        print(f"  [ok] rendered {name}; canonical fields own their values")
    dump_config(claude_path, claude)

    links = layout.links(inventory)
    for directory in (".agents/skills", ".claude/skills"):
        generated = layout.destination / directory
        if generated.is_symlink():
            generated.unlink()
        generated.mkdir(parents=True, exist_ok=True)
        for name in prior.get("skills", []):
            stale = generated / name
            if name not in inventory and stale.is_symlink():
                stale.unlink()
    for target, source in links.items():
        link(source, target)

    # Retire only recognizable legacy links. Never remove provider-bundled or user-authored skills.
    for name, source in inventory.items():
        legacy = layout.destination / ".codex/skills" / name
        if legacy.is_symlink() and legacy.resolve() == source.resolve():
            legacy.unlink()
    legacy_pi = layout.destination / ".pi/agent/skills"
    if legacy_pi.is_symlink():
        legacy_pi.unlink()
    elif legacy_pi.exists():
        backup(legacy_pi)
    for target, source in (
        (layout.destination / "AGENTS.md", layout.agent / "AGENTS.md"),
        (layout.destination / ".mcp.json", layout.agent / "mcps/mcp-servers.json"),
        (layout.destination / ".claude/templates", layout.agent / "claude/templates"),
        (layout.destination / ".pi/agent/agents", layout.agent / "pi/agents"),
    ):
        if target.is_symlink() and target.resolve() == source.resolve() and not source.exists():
            target.unlink()
        elif target.is_symlink() and target.resolve() == source.resolve() and target.name in {"AGENTS.md", ".mcp.json"}:
            target.unlink()
    link(layout.agent / "AGENTS.md", layout.agent.parent / "AGENTS.md", relative=True)

    rules_path = layout.destination / ".codex/rules/default.rules"
    rules_directory = rules_path.parent
    # Read a legacy directory link before unlinking it, so local approvals survive migration.
    effective_rules = rules_path.read_text() if rules_path.exists() else ""
    if rules_directory.is_symlink():
        rules_directory.unlink()
    policy_lines = (layout.agent / "codex/rules/default.rules").read_text().splitlines()
    saved_path = layout.local / "codex-rules.local.rules"
    saved_lines = saved_path.read_text().splitlines() if saved_path.exists() else []
    owned = set(policy_lines) | set(prior.get("codex_rule_lines", []))
    extras = list(dict.fromkeys(
        line for line in saved_lines + effective_rules.splitlines()
        if line.strip() and not line.lstrip().startswith("#") and line not in owned
    ))
    atomic_write(saved_path, "\n".join(extras) + "\n")
    atomic_write(rules_path, "\n".join(policy_lines + [""] + extras) + "\n")
    dump_config(layout.manifest, {
        "mcp_servers": sorted(mcp), "skills": sorted(inventory), "codex_rule_lines": policy_lines,
    })
    print("  [ok] installed links, shared MCP servers and local approvals")


def installed_issues(layout: Layout) -> list[str]:
    issues = []
    if not (layout.playbook / "skills").is_dir():
        issues.append("shared engineering playbook is missing; installed doctrine is incomplete")
    for directory in (".agents/skills", ".claude/skills"):
        if (layout.destination / directory).is_symlink():
            issues.append(f"{directory}: discovery root must be a generated real directory")
    inventory = layout.inventory()
    for target, source in layout.links(inventory).items():
        if not target.is_symlink() or target.resolve() != source.resolve():
            issues.append(f"link missing or stale: {target}")
    for name, (policy, destination, _) in layout.policies().items():
        if destination.is_symlink() or not destination.is_file():
            issues.append(f"{name}: expected a generated real file at {destination}")
            continue
        live = read_config(destination)
        if merge(live, policy) != live:
            issues.append(f"{name}: installed values differ from canonical policy")
        if name == "codex":
            for server in policy["mcp_servers"]:
                if live.get("mcp_servers", {}).get(server) != policy["mcp_servers"][server]:
                    issues.append(f"codex: canonical MCP server differs: {server}")
    mcp = check_mcp(read_config(layout.agent / "mcps/mcp-servers.json"))
    claude_path = layout.destination / ".claude.json"
    claude = read_config(claude_path) if claude_path.exists() else {}
    if not isinstance(claude.get("mcpServers"), dict):
        issues.append("Claude user MCP declaration is missing")
    else:
        for name, server in mcp.items():
            if claude["mcpServers"].get(name) != server:
                issues.append(f"Claude user MCP differs: {name}")
    for name, source in inventory.items():
        legacy = layout.destination / ".codex/skills" / name
        if legacy.is_symlink() and legacy.resolve() == source.resolve():
            issues.append(f"duplicate Codex skill discovery: {name}")
    if (layout.destination / ".pi/agent/skills").exists():
        issues.append("duplicate Pi skill discovery directory")
    if (layout.destination / "AGENTS.md").is_symlink():
        if (layout.destination / "AGENTS.md").resolve() == (layout.agent / "AGENTS.md").resolve():
            issues.append("dotfiles project policy leaks through home AGENTS.md")
    rules = layout.destination / ".codex/rules/default.rules"
    if not rules.is_file() or rules.is_symlink() or rules.parent.is_symlink():
        issues.append("Codex rules must be a generated real file")
    else:
        live_lines = set(rules.read_text().splitlines())
        for line in (layout.agent / "codex/rules/default.rules").read_text().splitlines():
            if line.strip() and not line.startswith("#") and line not in live_lines:
                issues.append("Codex canonical rules are missing")
                break
    return issues


def floating_dependencies(layout: Layout) -> None:
    for name, server in check_mcp(read_config(layout.agent / "mcps/mcp-servers.json")).items():
        if server.get("command") == "npx":
            packages = [arg for arg in server.get("args", []) if not arg.startswith("-")]
            for package in packages:
                if not re.search(r"@\d+\.\d+\.\d+(?:[-+].*)?$", package):
                    print(f"  [floating] MCP {name}: {package}")
    for name, enabled in read_config(layout.agent / "claude/settings.json").get("enabledPlugins", {}).items():
        if enabled:
            print(f"  [floating] Claude plugin: {name} (provider-managed snapshot)")


def check_gnhf(layout: Layout, selected: str) -> None:
    path = layout.destination / ".gnhf/config.yml"
    if not path.is_file():
        raise ConfigError("GNHF configuration is absent; run agentctl sync")
    live = read_config(path)
    agent = selected or live.get("agent")
    expected = read_config(layout.agent / "gnhf/config.yml").get("agentArgsOverride", {}).get(agent)
    if expected is None:
        raise ConfigError(f"GNHF {agent}: add a reviewed execution-mode adapter before unattended use")
    if live.get("agentArgsOverride", {}).get(agent) != expected:
        raise ConfigError(f"GNHF {agent}: execution flags differ from the reviewed adapter; run agentctl sync")
    print(f"  [ok] GNHF {agent}: explicit execution mode")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--check-installed", action="store_true")
    parser.add_argument("--inventory", action="store_true")
    parser.add_argument("--check-gnhf", metavar="AGENT")
    parser.add_argument("--agent-dir", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--destination", type=Path,
                        default=Path(os.environ.get("AGENT_CONFIG_HOME", Path.home())))
    parser.add_argument("--playbook", type=Path,
                        default=Path(os.environ.get("AGENTIC_RULES_DIR", Path.home() / "00_development/agentic-rules")))
    args = parser.parse_args(argv)
    layout = Layout(args.agent_dir.resolve(), args.destination.resolve(), args.playbook.resolve())
    try:
        if args.check_gnhf is not None:
            check_gnhf(layout, args.check_gnhf)
        elif args.inventory:
            validate(layout)
            floating_dependencies(layout)
        elif args.check_installed:
            validate(layout)
            issues = installed_issues(layout)
            for issue in issues:
                print(f"  [fail] {issue}", file=sys.stderr)
            if issues:
                return 1
            print("  [ok] installed configuration matches canonical ownership")
        elif args.check:
            validate(layout)
        else:
            sync(layout)
    except ConfigError as exc:
        print(f"agent: {exc}", file=sys.stderr)
        return 2
    except (OSError, ValueError, yaml.YAMLError):
        # Parser exceptions can contain credential values; show the operation, not the payload.
        print("agent: configuration could not be checked/rendered; inspect source shapes, "
              "required paths and parser dependencies locally", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
