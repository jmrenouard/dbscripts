"""Executable validation tests for Diataxis tutorials, how-tos, and diagrams."""

from __future__ import annotations

import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import unittest

import yaml

REPO_ROOT = Path(__file__).resolve().parents[1]
_GIT_BASH = "C:/Program Files/Git/bin/bash.exe"
_ASCII_RE = re.compile(r"[┌┐└┘├┤┬┴┼═║╔╗╚╝╠╣╦╩╬]|\+[=-]{3,}\+")
_INDENTED_MERMAID_RE = re.compile(r"^[ \t]+```mermaid\b", re.MULTILINE)
_COL0_MERMAID_RE = re.compile(r"^```mermaid\b", re.MULTILINE)
_MAKE_DEF_RE = re.compile(r"^([A-Za-z0-9_.-]+)\s*:(?!=)", re.MULTILINE)
_CITED_RE = re.compile(r"\b(?:scripts|docker|ansible)/[A-Za-z0-9_./-]+\.(?:sh|py|ya?ml|example)\b")
_CODE_SEG_RE = re.compile(r"```[^\n]*\n(.*?)```|`([^`\n]+)`", re.DOTALL)
_MAKE_CMD_RE = re.compile(r"^\s*make\b(?:[ \t]+-C[ \t]+([A-Za-z0-9_./-]+))?((?:[ \t]+[A-Za-z0-9_.=-]+)+)")
_CLI_RUNNER = (
    "import runpy,sys,types\n"
    "try:\n"
    "    from docker import from_env\n"
    "except ImportError:\n"
    "    sys.modules['docker'] = types.SimpleNamespace(from_env=lambda: None)\n"
    "sys.argv = sys.argv[1:]\n"
    "runpy.run_path(sys.argv[0], run_name='__main__')\n"
)
_MERMAID_REQUIRED = (
    "docs/01-tutorials/01-mariadb-galera-docker-lab.md",
    "docs/01-tutorials/02-mysql-docker-cli-sandbox.md",
    "ansible/README.md",
    "ansible/roles/mysql_cluster/README.md",
)


def find_diagram_hygiene_violations(repo_root: Path = REPO_ROOT) -> list[str]:
    """Return violations for ASCII boxes, indented Mermaid, or missing Mermaid."""
    issues: list[str] = []
    for rel in _MERMAID_REQUIRED:
        if not _COL0_MERMAID_RE.search((repo_root / rel).read_text(encoding="utf-8")):
            issues.append(f"{rel}: missing column-0 ```mermaid diagram")
    md_files = [repo_root / "README.md", *(p for d in ("docs", "ansible", "docker") for p in sorted((repo_root / d).rglob("*.md")))]
    for md in md_files:
        rel, text = md.relative_to(repo_root).as_posix(), md.read_text(encoding="utf-8")
        if _INDENTED_MERMAID_RE.search(text):
            issues.append(f"{rel}: indented ```mermaid fence")
        if _ASCII_RE.search(text):
            issues.append(f"{rel}: ASCII box/tree diagram found")
        in_mermaid = False
        for line in text.splitlines():
            s = line.rstrip()
            if not in_mermaid and s.startswith("```mermaid"):
                in_mermaid = True
            elif in_mermaid and s == "```":
                in_mermaid = False
        if in_mermaid:
            issues.append(f"{rel}: unclosed ```mermaid fence")
    return issues


def _tutorial_howto_docs() -> list[Path]:
    return sorted([*(REPO_ROOT / "docs/01-tutorials").rglob("*.md"), *(REPO_ROOT / "docs/02-how-to-guides").rglob("*.md")])


class TestTutorialsAndHowTos(unittest.TestCase):
    """Validate Mermaid hygiene, Make targets, script syntax, and CLI help."""

    def test_tutorial_and_ansible_diagram_hygiene(self) -> None:
        self.assertEqual(find_diagram_hygiene_violations(REPO_ROOT), [])

    def test_referenced_files_and_make_targets_exist(self) -> None:
        make_dirs = (".", "docker/mariadb", "docker/script_tests")
        makefiles = {d: set(_MAKE_DEF_RE.findall((REPO_ROOT / d / "Makefile").read_text(encoding="utf-8"))) - {".PHONY"} for d in make_dirs}
        cited: set[str] = set()
        for md in _tutorial_howto_docs():
            text = md.read_text(encoding="utf-8")
            cited.update(_CITED_RE.findall(text))
            default_dir = "docker/mariadb" if "docker/mariadb" in text else "."
            for blk, inline in _CODE_SEG_RE.findall(text):
                for line in (blk or inline).splitlines():
                    if m := _MAKE_CMD_RE.match(line):
                        targets = makefiles[m.group(1) or default_dir]
                        for tok in m.group(2).split():
                            if not tok.startswith("-") and "=" not in tok:
                                self.assertIn(tok, targets, f"{md.name}: unknown target {tok}")
        self.assertGreaterEqual(len(cited), 10)
        for rel in sorted(cited):
            self.assertTrue((REPO_ROOT / rel).is_file(), f"Missing file: {rel}")

    def test_mysql_docker_cli_help_and_cited_scripts_syntax(self) -> None:
        cli = str(REPO_ROOT / "docker/mysql_docker.py")
        for sub in ([], ["start"], ["list"], ["stop"], ["rm"]):
            proc = subprocess.run([sys.executable, "-c", _CLI_RUNNER, cli, *sub, "--help"], cwd=REPO_ROOT, capture_output=True, text=True)
            self.assertEqual(proc.returncode, 0, proc.stderr)
            self.assertIn("usage:", proc.stdout.lower())
        bash_bin = _GIT_BASH if os.path.isfile(_GIT_BASH) else shutil.which("bash")
        self.assertIsNotNone(bash_bin)
        cited = sorted({r for md in _tutorial_howto_docs() for r in _CITED_RE.findall(md.read_text(encoding="utf-8"))})
        sh_files = [r for r in cited if r.endswith(".sh")]
        yml_files = [r for r in cited if r.endswith((".yml", ".yaml"))]
        self.assertGreaterEqual(len(sh_files), 6)
        self.assertGreaterEqual(len(yml_files), 3)
        for rel in sh_files:
            res = subprocess.run([bash_bin, "-n"], input=(REPO_ROOT / rel).read_bytes().replace(b"\r\n", b"\n"), cwd=REPO_ROOT, capture_output=True)
            self.assertEqual(res.returncode, 0, f"{rel}: {res.stderr.decode(errors='replace')}")
        for rel in yml_files:
            data = yaml.safe_load((REPO_ROOT / rel).read_text(encoding="utf-8"))
            self.assertIsInstance(data, list)
            self.assertTrue(data, rel)


if __name__ == "__main__":
    unittest.main()
