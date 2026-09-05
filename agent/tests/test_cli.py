"""2026-09-04: subprocess argv and failure contracts (§5), authored fake executables.

No real GUI, Docker daemon, home config or remote is used. The output reader is JSON,
so space/quote preservation is checked as argv values, not reconstructed shell text.
"""
import json
import os
import shlex
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
CLI = ROOT / "agent/scripts/agentctl"


class ExecutionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.project = self.root / "project with spaces"
        self.project.mkdir()
        subprocess.run(["git", "-C", str(self.project), "init", "-q"], check=True)
        subprocess.run(["git", "-C", str(self.project), "checkout", "-q", "-b", "feature"], check=True)
        subprocess.run(["git", "-C", str(self.project), "-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", "commit", "-q", "--allow-empty", "-m", "fixture: base"], check=True)
        (self.project / ".no-mistakes.yaml").touch()
        subprocess.run(["git", "-C", str(self.project), "add", ".no-mistakes.yaml"], check=True)
        subprocess.run(["git", "-C", str(self.project), "-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", "commit", "-q", "-m", "fixture: delivery gate"], check=True)
        self.registry = self.root / "projects.json"
        self.arguments = ["contains spaces", 'quote"literal', "--leading-hyphen",
                          "$(touch should-not-exist)", "backtick" + chr(96)]
        self.set_registry(self.arguments)
        self.env = dict(os.environ, PATH=str(self.bin) + os.pathsep + os.environ["PATH"],
                        AGENTCTL_PROJECTS_FILE=str(self.registry), AGENT_PYTHON=sys.executable, HERDR_ENV="0",
                        AGENT_CONFIG_HOME=str(self.root / "config-home"),
                        AGENTIC_RULES_DIR=str(self.root / "missing-playbook"),
                        AGENTCTL_FIRSTMATE_DIR=str(self.root / "firstmate"),
                        FIXTURE_ARGV=str(self.root / "argv.json"))
        (self.root / "firstmate/.git").mkdir(parents=True)

    def set_registry(self, arguments):
        self.registry.write_text(json.dumps({"schema_version": 1, "projects": {"fixture": {
            "path": str(self.project), "label": "Fixture",
            "visualizations": {"view": ["fixture-view", *arguments]},
        }}}))

    def executable(self, name, source):
        path = self.bin / name
        path.write_text("#!/bin/sh\n" + source)
        path.chmod(0o755)

    def invoke(self, *arguments):
        return subprocess.run([str(CLI), *arguments], env=self.env, cwd=self.root,
                              text=True, capture_output=True)

    def test_visualization_preserves_exact_argument_values(self):
        path = self.bin / "fixture-view"
        path.write_text("#!" + sys.executable + "\nimport json,os,sys\n"
                        "from pathlib import Path\n"
                        "Path(os.environ['FIXTURE_ARGV']).write_text(json.dumps(sys.argv[1:]))\n")
        path.chmod(0o755)
        result = self.invoke("project", "fixture", "--visualization", "view")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads((self.root / "argv.json").read_text()), self.arguments)
        self.assertFalse((self.project / "should-not-exist").exists())

    def test_newline_argument_is_rejected_before_execution(self):
        self.set_registry(["one\ntwo"])
        self.executable("fixture-view", "exit 99\n")
        result = self.invoke("project", "fixture", "--visualization", "view")
        self.assertEqual(result.returncode, 2)
        self.assertIn("control characters", result.stderr)

    def test_upstream_failures_map_to_one_for_each_execution_path(self):
        for tool in ("herdr", "gh-axi", "pi", "no-mistakes", "fixture-view"):
            self.executable(tool, "exit 23\n")
        for arguments in (["start"], ["fleet", "--harness", "pi"], ["ship", "fixture", "--intent", "fixture goal"],
                          ["project", "fixture"], ["project", "fixture", "--visualization", "view"]):
            with self.subTest(command=arguments):
                result = self.invoke(*arguments)
                self.assertEqual(result.returncode, 1, result.stdout + result.stderr)

    def test_fleet_launch_writes_firstmate_dispatch_config(self):
        self.executable("herdr", "if [ \"$1 $2 $3\" = \"integration install pi\" ]; then exit 0; fi\n"
                                 "if [ \"$1 $2\" = \"integration status\" ]; then echo 'pi: current (v8)'; exit 0; fi\n"
                                 "exit 23\n")
        self.executable("pi", "exit 0\n")
        result = self.invoke("fleet", "--harness", "pi")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        config = self.root / "firstmate/config"
        self.assertEqual((config / "backend").read_text(), "herdr\n")
        self.assertEqual(
            (config / "crew-dispatch.json").read_text(),
            (ROOT / "agent/firstmate/crew-dispatch.json").read_text(),
        )
        projects = self.root / "firstmate/data/projects.md"
        self.assertIn("- fixture [no-mistakes +yolo]", projects.read_text())

    def test_ship_runs_no_mistakes_then_schedules_guarded_auto_merge(self):
        self.executable("no-mistakes", "case \"$1 $2\" in\n"
                                     "  'init ') exit 0 ;;\n"
                                     "  'axi run') echo 'Open the PR: https://github.com/owner/repo/pull/42'; exit 0 ;;\n"
                                     "  'axi status') echo 'status: checks-passed https://github.com/owner/repo/pull/42'; exit 0 ;;\n"
                                     "esac\nexit 23\n")
        self.executable("gh-axi", "printf '%s\\n' \"$0 $*\" > \"$FIXTURE_ARGV\"\n")
        result = self.invoke("ship", "fixture", "--intent", "fixture goal")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual((self.root / "argv.json").read_text().strip(),
                         str(self.bin / "gh-axi") + " pr merge 42 --squash --delete-branch --auto")

    def test_doctor_rejects_a_version_probe_that_prints_then_fails(self):
        for tool in ("herdr", "treehouse", "gnhf", "no-mistakes", "pi", "claude", "codex", "jq"):
            self.executable(tool, "echo 'fixture version'; exit 23\n")
        self.executable("fixture-sync", "exit 0\n")
        self.env["AGENTCTL_SYNC_SCRIPT"] = str(self.bin / "fixture-sync")
        result = self.invoke("doctor")
        self.assertEqual(result.returncode, 1)
        self.assertIn("version probe failed", result.stdout)

    def test_retired_publisher_cannot_evaluate_a_description_or_call_git(self):
        marker = self.root / "unexpected"
        self.executable("gh", "exit 99\n")
        self.executable("git", "exit 99\n")
        result = subprocess.run([str(ROOT / "zsh/init_github_repo.sh"), "fixture",
                                 "$(touch " + str(marker) + ")"], env=self.env, cwd=self.root,
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 2)
        self.assertIn("retired", result.stderr)
        self.assertFalse(marker.exists())

    def test_pi_probe_rejects_empty_success_and_native_failure(self):
        probe = ROOT / "agent/scripts/pi-resources.mjs"
        payload = {"id": "agent-platform-resource-probe", "command": "get_commands",
                   "success": True, "data": {"commands": []}}
        self.executable("pi", "printf '%s\\n' " + shlex.quote(json.dumps(payload)) + "\n")
        result = subprocess.run(["node", str(probe)], env=self.env, cwd=self.root,
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 1)
        self.assertIn("empty", result.stderr)
        self.executable("pi", "exit 23\n")
        result = subprocess.run(["node", str(probe)], env=self.env, cwd=self.root,
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 1)
        self.assertIn("exited 23", result.stderr)

    def test_pi_probe_reads_native_skill_identity_without_a_model_prompt(self):
        skill = self.root / "SKILL.md"
        skill.write_text("synthetic skill")
        payload = {"id": "agent-platform-resource-probe", "command": "get_commands",
                   "success": True, "data": {"commands": [{
                       "name": "skill:fixture", "source": "skill", "sourceInfo": {"path": str(skill)}
                   }]}}
        path = self.bin / "pi"
        path.write_text("#!" + sys.executable + "\nimport json,sys\n"
                        "request=json.loads(sys.stdin.readline())\n"
                        "assert request['type']=='get_commands'\n"
                        "assert '--no-tools' in sys.argv and '--offline' in sys.argv\n"
                        "print(" + repr(json.dumps(payload)) + ")\n")
        path.chmod(0o755)
        result = subprocess.run(["node", str(ROOT / "agent/scripts/pi-resources.mjs"), "--json"],
                                env=self.env, cwd=self.root, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        value = json.loads(result.stdout)
        self.assertEqual(value["skills"], [{"name": "fixture", "path": str(skill),
                                          "resolvedPath": str(skill.resolve())}])

    def test_docker_failure_cannot_print_a_successful_smoke_result(self):
        self.executable("docker", "exit 23\n")
        for script in ("test_docker.sh", "quick_test.sh"):
            result = subprocess.run([str(ROOT / "testing" / script), "test"], env=self.env,
                                    cwd=self.root, text=True, capture_output=True)
            self.assertEqual(result.returncode, 23)
            self.assertNotIn("checked", result.stdout)


if __name__ == "__main__":
    unittest.main()
