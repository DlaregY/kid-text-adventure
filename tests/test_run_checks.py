"""Unit checks for QA isolation. No Godot installation required."""
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import run_checks as qa

NAME = "ike-quest-qa-" + "a" * 32


class IsolationTests(unittest.TestCase):
    def test_staging_keeps_source_untouched_and_excludes_outputs(self):
        with tempfile.TemporaryDirectory() as t:
            root = Path(t)
            source, stage = root / "source", root / "stage"
            source.mkdir()
            (source / "project.godot").write_text("original")
            (source / "override.cfg").write_text("player override")
            for folder in [".git", ".godot", "exports"]:
                (source / folder).mkdir()
                (source / folder / "do-not-copy").write_text("private")
            (source / "upload.jks").write_text("not a real key")
            qa.stage_project(source, stage, NAME)
            self.assertEqual((stage / "project.godot").read_text(), "original")
            self.assertIn(NAME, (stage / "override.cfg").read_text())
            self.assertIn("config/use_custom_user_dir=true", (stage / "override.cfg").read_text())
            self.assertEqual((source / "override.cfg").read_text(), "player override")
            for path in [".git", ".godot", "exports", "upload.jks"]:
                self.assertFalse((stage / path).exists())

    def test_invalid_directory_name_is_rejected_before_copy(self):
        with tempfile.TemporaryDirectory() as t:
            with self.assertRaises(ValueError):
                qa.stage_project(Path(t), Path(t) / "stage", "../Ike Quest")

    def test_cleanup_requires_exact_name_and_marker(self):
        with tempfile.TemporaryDirectory() as t:
            root = Path(t)
            stage, data = root / "stage", root / NAME
            stage.mkdir()
            data.mkdir()
            (data / "save.json").write_text("test-save")
            (stage / ".qa-user-data-path").write_text(str(data))
            with self.assertRaises(RuntimeError):
                qa.cleanup_data(stage, NAME)
            self.assertTrue((data / "save.json").exists())
            (data / ".ike-quest-qa").write_text("wrong marker")
            with self.assertRaises(RuntimeError):
                qa.cleanup_data(stage, NAME)
            (data / ".ike-quest-qa").write_text(NAME)
            qa.cleanup_data(stage, NAME)
            self.assertFalse(data.exists())

    def test_cleanup_rejects_other_directory_and_symlink(self):
        with tempfile.TemporaryDirectory() as t:
            root = Path(t)
            stage, player = root / "stage", root / "Ike Quest"
            stage.mkdir()
            player.mkdir()
            (player / "save.json").write_text("real-save")
            (stage / ".qa-user-data-path").write_text(str(player))
            with self.assertRaises(RuntimeError):
                qa.cleanup_data(stage, NAME)
            alias = root / NAME
            alias.symlink_to(player, target_is_directory=True)
            (stage / ".qa-user-data-path").write_text(str(alias))
            with self.assertRaises(RuntimeError):
                qa.cleanup_data(stage, NAME)
            self.assertEqual((player / "save.json").read_text(), "real-save")

    def test_cleanup_without_receipt_is_noop(self):
        with tempfile.TemporaryDirectory() as t:
            qa.cleanup_data(Path(t), NAME)

    def test_logged_checks_fail_closed(self):
        with tempfile.TemporaryDirectory() as t:
            for code, text in [(1, "Game regression checks=1; failures=0"),
                               (0, "SCRIPT ERROR: bad syntax"),
                               (0, "ERROR: missing resource"),
                               (0, "Game regression checks=5; failures=1"),
                               (0, "")]:
                with self.subTest(code=code, text=text), patch.object(qa.subprocess, "run", return_value=subprocess.CompletedProcess([], code, text)):
                    with self.assertRaises(RuntimeError):
                        qa.run_logged(["fake"], {}, Path(t) / "log", "Game regression checks=")

    def test_logged_checks_accept_verified_summary(self):
        with tempfile.TemporaryDirectory() as t, patch.object(qa.subprocess, "run", return_value=subprocess.CompletedProcess([], 0, "Game regression checks=42; failures=0\n")):
            qa.run_logged(["fake"], {}, Path(t) / "log", "Game regression checks=")


if __name__ == "__main__":
    unittest.main()
