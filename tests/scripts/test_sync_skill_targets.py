"""Tests for scripts/sync-skill.sh — target discovery, naming, and the checkout guard.

These are hermetic: every case builds a throwaway HOME and (where needed) a throwaway
git checkout in a temp directory, then runs the real script. Nothing touches the
developer's own installs.

Run:  python -m pytest tests/ -v
      python tests/scripts/test_sync_skill_targets.py -v

Why these tests exist (2026-10-13): the script's default Hermes target was a hardcoded
flat path (`.hermes/skills/surgical-investigation`) while the real install is nested
under a category directory (`.hermes/skills/DOCTOR/surgical-investigation`). With the
defaults, the PRIMARY install was printed as "[SKIP] not installed" and silently left
unsynced. It also derived the skill name from the checkout's directory name, so a
checkout named `surgical-inv-src` targeted the wrong directory, and running it outside
a checkout reported an unrelated parent repo's HEAD as the commit. Those three are the
drift class these tests pin down.
"""

from __future__ import annotations

import os
import pathlib
import shutil
import subprocess
import sys
import tempfile
import unittest

REPO = pathlib.Path(__file__).resolve().parents[2]
SCRIPT = REPO / "scripts" / "sync-skill.sh"
SKILL_NAME = "surgical-investigation"


def run_script(mode: str, home: pathlib.Path, script: pathlib.Path = SCRIPT):
    """Run the sync script with HOME redirected. Returns CompletedProcess."""
    env = dict(os.environ)
    env["HOME"] = str(home)
    env.pop("SKILL_TARGETS", None)
    return subprocess.run(
        ["bash", str(script), mode],
        capture_output=True, text=True, env=env, cwd=str(script.parent.parent),
    )


class SyncScriptTestBase(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = pathlib.Path(tempfile.mkdtemp(prefix="sync-skill-test-"))
        self.addCleanup(shutil.rmtree, self.tmp, ignore_errors=True)
        self.home = self.tmp / "home"
        self.home.mkdir()

    # --- fixture helpers -----------------------------------------------------
    def make_install(self, rel: str) -> pathlib.Path:
        """Create a fake install directory (relative to HOME) with one file."""
        d = self.home / rel
        d.mkdir(parents=True)
        (d / "SKILL.md").write_text("---\nname: %s\n---\n" % SKILL_NAME)
        return d

    def make_checkout(self, dirname: str = "checkout") -> pathlib.Path:
        """Copy SKILL.md + scripts/ into a temp dir and make it a real git checkout."""
        repo = self.tmp / dirname
        (repo / "scripts").mkdir(parents=True)
        shutil.copy2(REPO / "SKILL.md", repo / "SKILL.md")
        shutil.copy2(SCRIPT, repo / "scripts" / SCRIPT.name)
        (repo / "scripts" / SCRIPT.name).chmod(0o755)
        subprocess.run(["git", "init", "-q"], cwd=repo, check=True,
                       capture_output=True)
        return repo

    def targets_in(self, out: str) -> list[str]:
        """Extract the target paths the script reported, in order."""
        found = []
        for line in out.splitlines():
            line = line.strip()
            for tag in ("[OK  ]", "[SKIP]", "[NEW ]", "[STALE]", "[FAIL]"):
                if line.startswith(tag):
                    found.append(line[len(tag):].strip().split(" — ")[0].split(" ")[0])
                    break
        return found


class TestTargetDiscovery(SyncScriptTestBase):
    def test_discovers_nested_hermes_install(self):
        """The primary install lives under a category dir — it must be found."""
        self.make_install(f".hermes/skills/DOCTOR/{SKILL_NAME}")
        r = run_script("list", self.home)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn(f".hermes/skills/DOCTOR/{SKILL_NAME}", r.stdout)
        self.assertNotIn("[SKIP] .hermes/skills/%s" % SKILL_NAME, r.stdout,
                         "the flat path must not be probed as a separate target "
                         "when a nested install exists")

    def test_discovers_flat_hermes_install(self):
        self.make_install(f".hermes/skills/{SKILL_NAME}")
        r = run_script("list", self.home)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn(f".hermes/skills/{SKILL_NAME}", r.stdout)

    def test_discovers_both_layouts_when_both_exist(self):
        self.make_install(f".hermes/skills/{SKILL_NAME}")
        self.make_install(f".hermes/skills/DOCTOR/{SKILL_NAME}")
        r = run_script("list", self.home)
        targets = self.targets_in(r.stdout)
        self.assertIn(f".hermes/skills/{SKILL_NAME}", targets)
        self.assertIn(f".hermes/skills/DOCTOR/{SKILL_NAME}", targets)

    def test_falls_back_to_flat_path_when_nothing_installed(self):
        """`sync` must still be able to create the primary install."""
        r = run_script("list", self.home)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn(f"[SKIP] .hermes/skills/{SKILL_NAME}", r.stdout)

    def test_skill_name_comes_from_frontmatter_not_directory_name(self):
        """A checkout named something else must still target the skill's install."""
        repo = self.make_checkout(dirname="surgical-inv-src")  # not the skill name
        self.make_install(f".hermes/skills/DOCTOR/{SKILL_NAME}")
        r = run_script("list", self.home, script=repo / "scripts" / SCRIPT.name)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn(f"skill  : {SKILL_NAME}", r.stdout)
        self.assertIn(f".hermes/skills/DOCTOR/{SKILL_NAME}", r.stdout)


class TestCheckoutGuard(SyncScriptTestBase):
    def test_refuses_to_run_outside_a_checkout(self):
        """Without this, `git -C` reports an unrelated parent repo's commit."""
        stray = self.tmp / "stray" / "scripts"
        stray.mkdir(parents=True)
        shutil.copy2(SCRIPT, stray / SCRIPT.name)
        (stray / SCRIPT.name).chmod(0o755)
        r = run_script("list", self.home, script=stray / SCRIPT.name)
        self.assertEqual(r.returncode, 2, f"stdout={r.stdout} stderr={r.stderr}")
        self.assertIn("not a git checkout", r.stderr)

    def test_reports_its_own_commit_from_inside_a_checkout(self):
        repo = self.make_checkout()
        r = run_script("list", self.home, script=repo / "scripts" / SCRIPT.name)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertNotIn("not a git repo", r.stdout)
        # a fresh git init has no commits, so HEAD resolves short-but-empty; the
        # contract under test is that the script did NOT fall back to a parent repo.
        self.assertIn("commit :", r.stdout)


class TestScriptSurface(SyncScriptTestBase):
    def test_help_lists_every_mode(self):
        r = run_script("--help", self.home)
        self.assertEqual(r.returncode, 0, r.stderr)
        for mode in ("check", "sync", "verify", "list"):
            self.assertIn(mode, r.stdout)

    def test_bash_syntax_is_valid(self):
        r = subprocess.run(["bash", "-n", str(SCRIPT)], capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stderr)

    def test_script_is_executable(self):
        self.assertTrue(os.access(SCRIPT, os.X_OK), "scripts/sync-skill.sh must be executable")

    def test_unknown_mode_exits_2(self):
        r = run_script("frobnicate", self.home)
        self.assertEqual(r.returncode, 2)


if __name__ == "__main__":
    unittest.main(verbosity=2)
