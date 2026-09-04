"""2026-09-04: frozen-interface and map guards (§§6–7), authored red fixtures.

The guard reads source from disk. Test commands: unittest discovery or agent/tests/run.sh.
Model-level skill activation and live provider behavior are deliberately separate.
"""
from contextlib import redirect_stdout, redirect_stderr
import io
import os
import subprocess
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from check_coherence import CONTRACT, DECISIONS, commit_paths, diff_issues, frozen_paths, main, map_issues, source_issues


class GuardTests(unittest.TestCase):
    def test_frozen_change_without_documents_fails(self):
        self.assertTrue(diff_issues({"api"}, {"api"}))

    def test_half_document_pair_still_fails(self):
        self.assertTrue(diff_issues({"api", CONTRACT}, {"api"}))
        self.assertTrue(diff_issues({"api", DECISIONS}, {"api"}))

    def test_documented_change_and_unrelated_change_pass(self):
        self.assertEqual(diff_issues({"api", CONTRACT, DECISIONS}, {"api"}), [])
        self.assertEqual(diff_issues({"implementation"}, {"api"}), [])

    def test_empty_inputs_cannot_pass_vacuously(self):
        self.assertTrue(diff_issues(set(), {"api"}))
        with self.assertRaises(ValueError):
            frozen_paths("# no contract section")

    def test_frozen_paths_come_from_the_contract(self):
        root = Path(__file__).resolve().parents[2]
        paths = frozen_paths((root / CONTRACT).read_text())
        self.assertIn("agent/scripts/agentctl", paths)
        self.assertIn("agent/scripts/agent_config.py", paths)
        for path in paths:
            self.assertTrue((root / path).is_file(), path)

    def test_absolute_map_and_claude_copy_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "agent").mkdir()
            (root / "agent/AGENTS.md").write_text("Read agent/docs/ARCHITECTURE.md")
            (root / "AGENTS.md").symlink_to(root / "agent/AGENTS.md")
            (root / "CLAUDE.md").write_text("Duplicated rules")
            issues = map_issues(root)
            self.assertTrue(any("relative" in issue for issue in issues))
            self.assertTrue(any("import" in issue for issue in issues))

    def test_guard_cli_rejects_real_frozen_violation(self):
        with redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
            result = main(["--files", "agent/scripts/agentctl"])
        self.assertEqual(result, 1)

    def test_source_rules_reject_each_paid_conflict(self):
        fixtures = {
            "agent/skills/manuscript-review/SKILL.md": "43 = 32 active + 11 sham",
            "agent/skills/manuscript-review/checklists/consistency.md": "must be the **left insula**",
            "agent/skills/mne-python/SKILL.md": "CLAUDE_SKILL_DIR",
            "agent/skills/mcp-authoring/SKILL.md": "~/.dotfiles/agent/mcps/mcp-servers.json",
            "agent/skills/telemetry-triage/SKILL.md": "v2.3.1",
            "agent/scripts/agentctl": 'GNHF_VERSION="0.0.0"',
            "agent/scripts/install-agent-tools.sh": "no shared pins",
            "agent/skills/git-collaboration/SKILL.md": "Co-authored-by:",
            "agent/skills/write-skill/SKILL.md": "Facts about the codebase belong in CLAUDE.md",
            "agent/skills/orchestrator/SKILL.md": "Subagents inherit none of the conversation.",
            "agent/IMPLEMENTATION-PLAN.md": "Current plan",
            "agent/MULTI-HARNESS-PLAN.md": "Current plan",
        }
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            valid = {path: 'source "$AGENT_DIR/tools.env"\nHistorical' for path in fixtures}
            valid["agent/AGENTS.md"] = "Read agent/docs/ARCHITECTURE.md"
            valid["CLAUDE.md"] = "@AGENTS.md"
            for path, content in valid.items():
                target = root / path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(content)
            (root / "AGENTS.md").symlink_to("agent/AGENTS.md")
            self.assertEqual(source_issues(root), [])
            for path, content in fixtures.items():
                with self.subTest(path=path):
                    (root / path).write_text(content)
                    self.assertTrue(source_issues(root))
                    (root / path).write_text(valid[path])

    def test_merge_commit_cannot_hide_a_frozen_patch(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            env = dict(os.environ, GIT_CONFIG_GLOBAL="/dev/null", GIT_CONFIG_NOSYSTEM="1",
                       GIT_AUTHOR_NAME="Fixture", GIT_AUTHOR_EMAIL="fixture@example.invalid",
                       GIT_COMMITTER_NAME="Fixture", GIT_COMMITTER_EMAIL="fixture@example.invalid")
            def git(*args):
                return subprocess.run(["git", "-C", str(root), *args], env=env, check=True,
                                      text=True, capture_output=True)
            git("init", "-b", "main")
            (root / "api").write_text("original")
            git("add", "api")
            git("commit", "-m", "fixture base")
            git("checkout", "-b", "topic")
            (root / "api").write_text("undocumented change")
            git("commit", "-am", "fixture API change")
            git("checkout", "main")
            (root / "other").write_text("independent")
            git("add", "other")
            git("commit", "-m", "fixture independent change")
            git("merge", "--no-ff", "topic", "-m", "fixture merge")
            changed = commit_paths(root, "HEAD")
            self.assertEqual(changed, {"api"})
            self.assertTrue(diff_issues(changed, {"api"}))

    def test_unavailable_base_is_not_green(self):
        with redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
            result = main(["--base", "refs/nonexistent-coherence-fixture"])
        self.assertEqual(result, 2)


if __name__ == "__main__":
    unittest.main()
