"""2026-09-04: project memory stays in its declared root (§4); fixtures are authored.

Run with unittest discover. Stores are temporary; no user vault or database is accessed.
"""
from pathlib import Path
import subprocess
import sys
import sqlite3
import tempfile
import unittest


class MemoryBoundaryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.project = self.root / "project"
        self.project.mkdir()
        self.command = [sys.executable, str(Path(__file__).resolve().parents[1] / "scripts/remember"),
                        "project", "--root", str(self.project), "--topic", "fixture",
                        "--message", "An authored project fact."]

    def test_project_memory_is_written_in_project(self):
        completed = subprocess.run(self.command, capture_output=True, text=True)
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertIn("An authored project fact.", (self.project / "memory/agent-memory.md").read_text())

    def test_relative_and_absolute_escape_are_rejected(self):
        for target in ("../escape.md", str(self.root / "absolute.md")):
            with self.subTest(target=target):
                completed = subprocess.run(self.command + ["--file", target], capture_output=True, text=True)
                self.assertEqual(completed.returncode, 1)
                self.assertIn("within --root", completed.stderr)
        self.assertFalse((self.root / "escape.md").exists())
        self.assertFalse((self.root / "absolute.md").exists())

    def test_symlink_escape_is_rejected(self):
        (self.project / "elsewhere").symlink_to(self.root)
        completed = subprocess.run(self.command + ["--file", "elsewhere/escape.md"], capture_output=True, text=True)
        self.assertEqual(completed.returncode, 1)
        self.assertFalse((self.root / "escape.md").exists())

    def test_all_routes_screen_every_captured_field_before_writing(self):
        command = self.command[:2]
        vault = self.root / "vault"
        (vault / "Zettelkasten").mkdir(parents=True)
        database = self.root / "events.sqlite"
        routes = [
            ["project", "--root", str(self.project)],
            ["crystal", "--vault", str(vault)],
            ["raw", "--db", str(database)],
        ]
        for route in routes:
            for field in ("topic", "message", "source"):
                values = {"topic": "fixture", "message": "Synthetic fact", "source": "test"}
                values[field] = "token=authored-not-a-real-secret"
                args = [arg for name, value in values.items() for arg in ("--" + name, value)]
                with self.subTest(route=route[0], field=field):
                    result = subprocess.run(command + route + args, text=True, capture_output=True)
                    self.assertEqual(result.returncode, 1)
        self.assertFalse(database.exists())
        self.assertEqual(list((vault / "Zettelkasten").iterdir()), [])
        self.assertEqual(list(self.project.iterdir()), [])

    def test_raw_and_crystal_write_to_independently_read_stores(self):
        command = self.command[:2]
        database = self.root / "events.sqlite"
        vault = self.root / "vault"
        (vault / "Zettelkasten").mkdir(parents=True)
        for args in (["raw", "--db", str(database)], ["crystal", "--vault", str(vault)]):
            result = subprocess.run(command + args + ["--topic", "fixture",
                                    "--message", "Authored evidence"], text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
        with sqlite3.connect(database) as con:
            self.assertEqual(con.execute("select topic,message from raw_memory").fetchall(),
                             [("fixture", "Authored evidence")])
        self.assertIn("Authored evidence", (vault / "Zettelkasten/fixture.md").read_text())

    def test_source_cannot_smuggle_a_secret_into_memory(self):
        completed = subprocess.run(self.command + ["--source", "token=fixture"], capture_output=True, text=True)
        self.assertEqual(completed.returncode, 1)
        self.assertFalse((self.project / "memory/agent-memory.md").exists())


if __name__ == "__main__":
    unittest.main()
