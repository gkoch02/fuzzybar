"""Run with python3 -m unittest discover -s Tests/BuildScriptTests."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


class BuildScriptTests(unittest.TestCase):
    def run_build(self, fail):
        with tempfile.TemporaryDirectory(prefix="fuzzybar-build-test-") as directory:
            root = Path(directory)
            shutil.copy(Path(__file__).resolve().parents[2] / "build.sh", root)
            (root / ".build/release").mkdir(parents=True)
            stale = root / ".build/release/FuzzyBar"
            stale.write_text("stale")
            stale.chmod(0o755)
            (root / "fresh").mkdir()
            fresh = root / "fresh/FuzzyBar"
            fresh.write_text("fresh")
            fresh.chmod(0o755)
            (root / "Assets").mkdir()
            (root / "Assets/AppIcon.icns").write_text("fixture")
            (root / "Info.plist").write_text("fixture")
            bundle = root / "build/FuzzyBar.app"
            bundle.mkdir(parents=True)
            (bundle / "previous-build").write_text("keep on failure")
            mock = root / "mock-bin"
            mock.mkdir()
            commands = {
                "swift": 'if [ "$FAIL_BUILD" = 1 ]; then exit 42; fi\ncase "$*" in *--show-bin-path*) echo "$PWD/fresh";; esac',
                "codesign": "exit 0",
            }
            for name, body in commands.items():
                command = mock / name
                command.write_text("#!/bin/sh\n" + body + "\n")
                command.chmod(0o755)
            result = subprocess.run(
                ["/bin/zsh", str(root / "build.sh")], capture_output=True, text=True,
                env={**os.environ, "PATH": str(mock) + ":" + os.environ["PATH"],
                     "FAIL_BUILD": "1" if fail else "0", "SIGN_IDENTITY": "-"},
            )
            if fail:
                self.assertNotEqual(result.returncode, 0)
                self.assertTrue((bundle / "previous-build").exists())
                self.assertNotIn("Built build", result.stdout)
            else:
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual((bundle / "Contents/MacOS/FuzzyBar").read_text(), "fresh")

    def test_compilation_failure_preserves_existing_bundle(self):
        self.run_build(fail=True)

    def test_success_uses_reported_binary_path(self):
        self.run_build(fail=False)
