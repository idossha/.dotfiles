"""2026-09-04: pin configuration ownership (§3) using synthetic temporary homes.

Expected policy/state values are authored fixtures; json/tomllib independently
read generated files. Live harness execution and remote service health are separate.
Run: agent/.venv/bin/python -m unittest discover -s agent/tests -p 'test_*.py'
"""
from __future__ import annotations

from contextlib import redirect_stdout
import io
import json
from pathlib import Path
import shutil
import sys
import tempfile
import tomllib
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from agent_config import Layout, check_mcp, installed_issues, skill_inventory, sync, unowned


class OwnershipTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        source = Path(__file__).resolve().parents[1]
        self.agent = self.root / "repo/agent"
        shutil.copytree(source, self.agent, ignore=shutil.ignore_patterns(".venv", "local", "__pycache__"))
        self.destination = self.root / "destination"
        playbook = self.root / "playbook"
        skill = playbook / "skills/house-fixture/SKILL.md"
        skill.parent.mkdir(parents=True)
        skill.write_text("---\nname: house-fixture\ndescription: Synthetic engineering procedure\n---\n")
        self.layout = Layout(self.agent, self.destination, playbook)

    def write_json(self, relative, value):
        path = self.destination / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(value))

    def run_sync(self):
        with redirect_stdout(io.StringIO()):
            sync(self.layout)

    def test_claude_and_shared_discovery_resolve_identical_skill_sources(self):
        self.run_sync()
        for name in ("house-fixture", "mcp-authoring"):
            claude = self.destination / ".claude/skills" / name
            shared = self.destination / ".agents/skills" / name
            self.assertEqual(claude.resolve(), shared.resolve())
        settings = json.loads((self.destination / ".claude/settings.json").read_text())
        self.assertIs(settings["enabledPlugins"]["agentic-rules@agentic-rules"], False)
        self.assertFalse((self.destination / ".claude/skills").is_symlink())

    def test_missing_playbook_cannot_pass_installed_validation(self):
        self.run_sync()
        shutil.rmtree(self.layout.playbook)
        with redirect_stdout(io.StringIO()):
            self.assertTrue(any("playbook is missing" in x for x in installed_issues(self.layout)))

    def test_malformed_late_live_input_writes_nothing(self):
        self.write_json(".claude/settings.json", {"theme": "untouched"})
        self.write_json(".claude.json", {"mcpServers": "not-an-object"})
        before = (self.destination / ".claude/settings.json").read_bytes()
        with self.assertRaisesRegex(ValueError, "mcpServers must be an object"):
            self.run_sync()
        self.assertEqual((self.destination / ".claude/settings.json").read_bytes(), before)
        self.assertFalse(self.layout.local.exists())

    def test_policy_wins_and_unknown_runtime_fields_survive(self):
        self.write_json(".pi/agent/settings.json", {
            "defaultModel": "runtime-conflict", "theme": "user-theme",
            "futureProviderState": {"revision": 7},
        })
        self.run_sync()
        actual = json.loads((self.destination / ".pi/agent/settings.json").read_text())
        expected = json.loads((self.agent / "pi/settings.json").read_text())
        self.assertEqual(actual["defaultModel"], expected["defaultModel"])
        self.assertEqual(actual["theme"], "user-theme")
        self.assertEqual(actual["futureProviderState"], {"revision": 7})
        overlay = json.loads((self.agent / "local/pi-settings.local.json").read_text())
        self.assertNotIn("defaultModel", overlay)

    def test_nested_overlays_cannot_replace_canonical_permissions(self):
        policy = {"permissions": {"allow": ["read"], "deny": ["write"]}}
        state = {"permissions": {"allow": ["everything"], "newRuntimeState": True}}
        self.assertEqual(unowned(policy, state), {"permissions": {"newRuntimeState": True}})

    def test_codex_preserves_new_tables_and_top_level_runtime_preferences(self):
        path = self.destination / ".codex/config.toml"
        path.parent.mkdir(parents=True)
        path.write_text('model = "user-model"\n[hooks]\ncustom = "local"\n'
                        '[marketplaces.local]\nlast_revision = "fixture"\n')
        self.run_sync()
        with path.open("rb") as handle:
            actual = tomllib.load(handle)
        self.assertEqual(actual["model"], "user-model")
        self.assertEqual(actual["hooks"]["custom"], "local")
        self.assertEqual(actual["marketplaces"]["local"]["last_revision"], "fixture")
        self.assertIn("context7", actual["mcp_servers"])

    def test_managed_mcp_removal_preserves_unmanaged_servers_and_claude_state(self):
        self.write_json(".claude.json", {"appState": "fixture-private", "mcpServers": {
            "personal": {"command": "personal-server"},
        }})
        self.run_sync()
        path = self.agent / "mcps/mcp-servers.json"
        declaration = json.loads(path.read_text())
        del declaration["mcpServers"]["context7"]
        path.write_text(json.dumps(declaration))
        self.run_sync()
        actual = json.loads((self.destination / ".claude.json").read_text())
        self.assertEqual(actual["appState"], "fixture-private")
        self.assertIn("personal", actual["mcpServers"])
        self.assertNotIn("context7", actual["mcpServers"])
        with (self.destination / ".codex/config.toml").open("rb") as handle:
            self.assertNotIn("context7", tomllib.load(handle)["mcp_servers"])

    def test_repeat_sync_is_byte_identical_and_does_not_modify_sources(self):
        before = {path.relative_to(self.agent): path.read_bytes()
                  for path in self.agent.rglob("*") if path.is_file()}
        self.run_sync()
        snapshot = {path: path.read_bytes() for path in self.destination.rglob("*")
                    if path.is_file() and not path.is_symlink()}
        self.run_sync()
        for path, expected in snapshot.items():
            self.assertEqual(path.read_bytes(), expected, str(path))
        for path, expected in before.items():
            self.assertEqual((self.agent / path).read_bytes(), expected, str(path))
        with redirect_stdout(io.StringIO()):
            self.assertEqual(installed_issues(self.layout), [])

    def test_installed_check_detects_missing_links_and_edited_policy(self):
        self.run_sync()
        (self.destination / ".codex/AGENTS.md").unlink()
        self.write_json(".pi/agent/settings.json", {"defaultModel": "wrong"})
        with redirect_stdout(io.StringIO()):
            issues = installed_issues(self.layout)
        self.assertTrue(any("link missing" in issue for issue in issues))
        self.assertTrue(any("pi: installed values differ" in issue for issue in issues))

    def test_old_codex_discovery_is_retired_but_system_skills_survive(self):
        legacy = self.destination / ".codex/skills"
        legacy.mkdir(parents=True)
        (legacy / "mcp-authoring").symlink_to(self.agent / "skills/mcp-authoring")
        (legacy / ".system").mkdir()
        (legacy / ".system/marker").write_text("provider-owned")
        self.run_sync()
        self.assertFalse((legacy / "mcp-authoring").is_symlink())
        self.assertEqual((legacy / ".system/marker").read_text(), "provider-owned")

    def test_removed_optional_static_links_are_retired(self):
        templates = self.destination / ".claude/templates"
        agents = self.destination / ".pi/agent/agents"
        templates.parent.mkdir(parents=True)
        agents.parent.mkdir(parents=True)
        templates.symlink_to(self.agent / "claude/templates")
        agents.symlink_to(self.agent / "pi/agents")
        self.run_sync()
        self.assertFalse(templates.exists() or templates.is_symlink())
        self.assertFalse(agents.exists() or agents.is_symlink())

    def test_global_map_cannot_leak_dotfiles_project_rules(self):
        self.destination.mkdir()
        home_map = self.destination / "AGENTS.md"
        home_map.symlink_to(self.agent / "AGENTS.md")
        self.run_sync()
        self.assertFalse(home_map.is_symlink())
        project_map = self.agent.parent / "AGENTS.md"
        self.assertEqual(project_map.readlink(), Path("agent/AGENTS.md"))
        self.assertEqual((self.destination / ".claude/CLAUDE.md").read_text().strip(), "@AGENTS.md")
        self.assertEqual((self.destination / ".claude/AGENTS.md").resolve(),
                         (self.agent / "policy/global.md").resolve())

    def test_memory_policy_has_no_local_router_overlap(self):
        self.assertTrue((self.agent / "policy/global.md").is_file())
        self.assertFalse((self.agent / "memory/global.md").exists())
        self.assertFalse((self.agent / "scripts/remember").exists())
        self.assertFalse((self.agent / "skills/remember").exists())

    def test_validation_rejects_empty_skill_set_and_colliding_names(self):
        empty = self.root / "empty"
        empty.mkdir()
        with self.assertRaisesRegex(ValueError, "no skills"):
            skill_inventory([empty])
        with self.assertRaisesRegex(ValueError, "collision"):
            skill_inventory([self.agent / "skills", self.agent / "skills"])

    def test_invalid_yaml_is_rejected(self):
        path = self.agent / "skills/mcp-authoring/SKILL.md"
        path.write_text("---\nname: [invalid\ndescription: fixture\n---\n")
        import yaml
        with self.assertRaises(yaml.YAMLError):
            skill_inventory([self.agent / "skills"])

    def test_unsupported_mcp_fields_do_not_disappear_in_adapters(self):
        with self.assertRaisesRegex(ValueError, "unsupported portable shape"):
            check_mcp({"mcpServers": {"demo": {"url": "https://example.invalid"}}})
        with self.assertRaisesRegex(ValueError, "unsupported portable shape"):
            check_mcp({"mcpServers": {"demo": {"command": "demo", "headers": {"x": "y"}}}})
        with self.assertRaisesRegex(ValueError, "non-empty"):
            check_mcp({"mcpServers": {}})


if __name__ == "__main__":
    unittest.main()
