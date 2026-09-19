"""Run with python3 -m unittest discover -s Tests/BuildScriptTests."""
import json
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


class XcodeProjectTests(unittest.TestCase):
    """FuzzyBar.xcodeproj lists source files explicitly. It is generated from
    project.yml by `xcodegen generate` and committed, so a Swift file added
    on the SwiftPM side is silently missing from App Store archives until the
    project is regenerated. The check walks the project's group tree and each
    target's Sources build phase, so a file that merely shares a basename
    with a compiled one, or has a file reference but no build-phase entry,
    still counts as missing."""

    EXPECTED = {"FuzzyBar": "Sources/FuzzyBar", "FuzzyBarTests": "Tests/FuzzyBarTests"}

    @staticmethod
    def compiled_sources(pbxproj):
        objects = json.loads(subprocess.run(
            ["plutil", "-convert", "json", "-o", "-", str(pbxproj)],
            capture_output=True, text=True, check=True,
        ).stdout)["objects"]
        project = next(o for o in objects.values() if o["isa"] == "PBXProject")

        paths = {}

        def walk(ref, prefix):
            obj = objects[ref]
            here = prefix / obj["path"] if obj.get("path") else prefix
            if obj["isa"] == "PBXFileReference":
                paths[ref] = here
            else:
                for child in obj.get("children", []):
                    walk(child, here)

        walk(project["mainGroup"], Path())

        result = {}
        for ref in project["targets"]:
            target = objects[ref]
            files = set()
            for phase in target["buildPhases"]:
                if objects[phase]["isa"] == "PBXSourcesBuildPhase":
                    for build_file in objects[phase]["files"]:
                        files.add(str(paths[objects[build_file]["fileRef"]]))
            result[target["name"]] = files
        return result

    def test_every_swift_file_is_compiled_by_its_target(self):
        root = Path(__file__).resolve().parents[2]
        compiled = self.compiled_sources(root / "FuzzyBar.xcodeproj/project.pbxproj")
        for target, folder in self.EXPECTED.items():
            on_disk = {str(p.relative_to(root)) for p in (root / folder).rglob("*.swift")}
            self.assertEqual(
                compiled.get(target), on_disk,
                f"{target}: run `xcodegen generate` and commit the project",
            )
