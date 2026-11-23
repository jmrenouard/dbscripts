"""Coverage and container harness tests for all scripts under scripts/."""

from __future__ import annotations

import ast
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS_DIR = ROOT / "scripts"
HARNESS_DIR = ROOT / "docker" / "script_tests"


def _find_bin(win_path: str, name: str) -> str | None:
    """Resolve Git-bundled bash/perl on Windows before PATH fallback."""
    return win_path if os.path.isfile(win_path) else shutil.which(name)


def _docker_mount_root(docker_bin: str) -> str:
    """Convert REPO_ROOT for native Docker or WSL docker.cmd wrappers."""
    if sys.platform == "win32" and docker_bin.lower().endswith((".cmd", ".bat")) and ROOT.drive:
        return f"/mnt/{ROOT.drive[0].lower()}{ROOT.as_posix()[2:]}"
    return ROOT.as_posix()


class TestAllScriptsCoverage(unittest.TestCase):
    """Verify discovery, syntax, sourcing, and container harness contracts."""

    @classmethod
    def setUpClass(cls) -> None:
        cls.bash_path = _find_bin("C:/Program Files/Git/bin/bash.exe", "bash")
        cls.perl_path = _find_bin("C:/Program Files/Git/usr/bin/perl.exe", "perl")
        cls.shell_scripts = sorted(
            set(SCRIPTS_DIR.rglob("*.sh"))
            | {p for p in (SCRIPTS_DIR / "bin" / "clustercheck", SCRIPTS_DIR / "bin" / "mysqlcheck") if p.is_file()}
        )
        cls.python_scripts = sorted(SCRIPTS_DIR.rglob("*.py"))
        cls.perl_scripts = sorted(SCRIPTS_DIR.rglob("*.pl"))
        cls.util_libs = sorted([SCRIPTS_DIR / "utils.sh", *(SCRIPTS_DIR / "utils").glob("*.sh")])

    def test_all_scripts_discovered_with_lf_and_valid_syntax(self) -> None:
        """Discover >= 190 scripts and validate LF endings and syntax."""
        all_scripts = self.shell_scripts + self.python_scripts + self.perl_scripts
        self.assertGreaterEqual(len(all_scripts), 190)
        for path in all_scripts:
            raw = path.read_bytes()
            rel = path.relative_to(ROOT).as_posix()
            self.assertGreater(len(raw), 0, f"Empty script: {rel}")
            self.assertNotIn(b"\r", raw, f"CR byte found in {rel}")
        if self.bash_path:
            for path in self.shell_scripts:
                rel = path.relative_to(ROOT).as_posix()
                res = subprocess.run([self.bash_path, "-n", rel], cwd=ROOT, capture_output=True, text=True)
                self.assertEqual(res.returncode, 0, f"bash -n failed on {rel}: {res.stderr}")
        for path in self.python_scripts:
            ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
        if self.perl_path and self.perl_scripts:
            with tempfile.TemporaryDirectory() as tmp:
                inc = Path(tmp) / "Nagios" / "DBD" / "MySQL"
                inc.mkdir(parents=True, exist_ok=True)
                for mod in ("Server", "Cluster"):
                    (inc / f"{mod}.pm").write_text(f"package Nagios::DBD::MySQL::{mod}; 1;\n", encoding="utf-8")
                for path in self.perl_scripts:
                    res = subprocess.run([self.perl_path, "-I", tmp, "-c", path.relative_to(ROOT).as_posix()], cwd=ROOT, capture_output=True, text=True)
                    self.assertEqual(res.returncode, 0, f"perl -c failed on {path.name}: {res.stderr}")

    def test_all_utils_libraries_source_under_errexit(self) -> None:
        """Verify all 8 scripts/utils*.sh files source cleanly under set -e."""
        self.assertEqual(len(self.util_libs), 8)
        if self.bash_path:
            for lib in self.util_libs:
                rel = lib.relative_to(ROOT).as_posix()
                res = subprocess.run([self.bash_path, "-c", 'set -e; source "$1"', "_", rel], cwd=ROOT, capture_output=True, text=True)
                self.assertEqual(res.returncode, 0, f"source failed on {rel}: {res.stderr}")

    def test_docker_harness_contracts_and_optional_live_container(self) -> None:
        """Validate docker/script_tests contracts and optional live container tests."""
        df, runner, mk = HARNESS_DIR / "Dockerfile", HARNESS_DIR / "run_all_script_tests.sh", HARNESS_DIR / "Makefile"
        for p in (df, runner, mk):
            self.assertTrue(p.is_file(), f"Missing {p.relative_to(ROOT)}")
            self.assertNotIn(b"\r", p.read_bytes(), f"CR byte in {p.name}")
        df_txt = df.read_text(encoding="utf-8")
        for tok in ("FROM debian:bookworm-slim", "--no-install-recommends", "rm -rf /var/lib/apt/lists/*", "USER tester", "WORKDIR /workspace"):
            self.assertIn(tok, df_txt)
        run_txt = runner.read_text(encoding="utf-8")
        for tok in ("#!/usr/bin/env bash", "set -euo pipefail", "--filter", "SCRIPT_FILTER"):
            self.assertIn(tok, run_txt)
        if self.bash_path:
            res = subprocess.run([self.bash_path, "-n", runner.relative_to(ROOT).as_posix()], cwd=ROOT, capture_output=True, text=True)
            self.assertEqual(res.returncode, 0, res.stderr)
        mk_txt = mk.read_text(encoding="utf-8")
        for target in ("build:", "test:", "test-one:", "clean:"):
            self.assertIn(target, mk_txt)
        for ln_no, line in enumerate(mk_txt.splitlines(), 1):
            if line.startswith("    ") and not line.strip().startswith("#"):
                self.fail(f"Makefile line {ln_no} must use tab indentation")
        if os.environ.get("RUN_DOCKER_SCRIPT_TESTS") == "1":
            docker_bin = shutil.which("docker")
            self.assertIsNotNone(docker_bin, "docker binary required when RUN_DOCKER_SCRIPT_TESTS=1")
            assert docker_bin is not None
            bld = subprocess.run([docker_bin, "build", "-t", "dbscripts-script-tests:latest", "docker/script_tests"], cwd=ROOT, stdin=subprocess.DEVNULL, capture_output=True, text=True)
            self.assertEqual(bld.returncode, 0, bld.stdout + bld.stderr)
            run = subprocess.run([docker_bin, "run", "--rm", "-v", f"{_docker_mount_root(docker_bin)}:/workspace:ro", "dbscripts-script-tests:latest", "bash", "/workspace/docker/script_tests/run_all_script_tests.sh"], cwd=ROOT, stdin=subprocess.DEVNULL, capture_output=True, text=True)
            self.assertEqual(run.returncode, 0, run.stdout + "\n" + run.stderr)
            self.assertIn("0 failed", run.stdout)


if __name__ == "__main__":
    unittest.main()
