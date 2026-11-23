"""Diataxis 4-quadrant structure, cross-linking mesh, and Docs-as-Code suite."""

from __future__ import annotations

import configparser
import json
from pathlib import Path
import re
from typing import Any
import unittest
from urllib.parse import unquote

import yaml

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
PORTAL_URL = "https://dbscripts.lightpath.fr"
QUADRANTS = ("01-tutorials", "02-how-to-guides", "03-reference", "04-explanation")
VIRTUAL_DOCS = {
    "overview.md": "README.md",
    "CHANGELOG.md": "Changelog",
    "ansible-playbooks.md": "ansible/README.md",
    "docker-mariadb-lab.md": "docker/mariadb/README.md",
}

FENCE_RE = re.compile(r"^\s*(`{3,}|~{3,})")
LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)\n]+)\)")
HEADING_RE = re.compile(r"^#{1,6}\s+(.+?)\s*$")
TBL_LIST_RE = re.compile(r"^\s*(?:\|.*\||(?:[-*+]|\d+\.)\s+\S)")
EXT_RE = re.compile(r"^(?:https?|mailto|ftp|tel|data):", re.I)
SHA40_RE = re.compile(r"^[0-9a-fA-F]{40}$")

HOWTO_VAL_RE = re.compile(r"\b(?:validat(?:e|es|ed|ing|ion)|verif(?:y|ies|ied|ication)|check)\b", re.I)
HOWTO_RB_RE = re.compile(r"\b(?:rollback|revert|backout|back-out|undo)\b", re.I)
HOWTO_TH_RE = re.compile(r"\b(?:why|architecture|theory|explanation|context|background)\b", re.I)
REF_TUT_RE = re.compile(r"(?:\bin\s+this\s+tutorial\b|\blet['’]?s\b|\blet\s+us\b|\bstep\s+1\b)", re.I)
EXPL_PROC_RE = re.compile(r"\b(?:step\s+\d+|rollback|remediation|prerequisites|procedure)\b", re.I)


class _MkDocsLoader(yaml.SafeLoader):
    """Safe YAML loader supporting PyMdownx !!python/name: tags."""


_MkDocsLoader.add_multi_constructor(
    "tag:yaml.org,2002:python/name:",
    lambda _loader, suffix, _node: f"python/name:{suffix}",
)


def _non_code_lines(text: str) -> list[tuple[int, str]]:
    """Return 1-indexed lines outside fenced code blocks with inline code masked."""
    out: list[tuple[int, str]] = []
    fence_char, fence_len = None, 0
    for lineno, line in enumerate(text.splitlines(), 1):
        if fence_char is not None:
            if re.match(rf"^\s*{re.escape(fence_char)}{{{fence_len},}}\s*$", line):
                fence_char = None
            continue
        if match := FENCE_RE.match(line):
            fence_char, fence_len = match.group(1)[0], len(match.group(1))
            continue
        out.append((lineno, re.sub(r"``[^`\n]+``|`[^`\n]+`", " ", line)))
    return out


def _relative_links(md_path: Path) -> list[tuple[int, str, Path]]:
    """Extract relative markdown link targets and resolved filesystem paths."""
    found: list[tuple[int, str, Path]] = []
    for lineno, line in _non_code_lines(md_path.read_text(encoding="utf-8")):
        for match in LINK_RE.finditer(line):
            raw = match.group(1).strip()
            target = raw[1:raw.find(">")].strip() if raw.startswith("<") and ">" in raw else (raw.split()[0] if raw else "")
            if not target or target.startswith("#") or EXT_RE.match(target) or target.startswith("//"):
                continue
            clean = unquote(target.split("#", 1)[0].split("?", 1)[0].strip())
            if clean:
                base = DOCS / clean.lstrip("/") if clean.startswith("/") else md_path.parent / clean
                found.append((lineno, clean, base.resolve()))
    return found


def _linked_quadrants(md_path: Path) -> set[str]:
    """Return sibling Diataxis quadrant names referenced from md_path."""
    return {
        resolved.relative_to(DOCS).parts[0]
        for _, _, resolved in _relative_links(md_path)
        if resolved.is_relative_to(DOCS)
        and resolved.relative_to(DOCS).parts
        and resolved.relative_to(DOCS).parts[0] in QUADRANTS
    }


def _nav_paths(node: Any) -> list[str]:
    """Flatten mkdocs.yml nav entries into file path strings."""
    if isinstance(node, str):
        return [node]
    if isinstance(node, list):
        return [item for child in node for item in _nav_paths(child)]
    if isinstance(node, dict):
        return [item for val in node.values() for item in _nav_paths(val)]
    return []


class TestDiataxisDocumentation(unittest.TestCase):
    """Validate Diataxis 4-quadrant docs, links, and Docs-as-Code configs."""

    def test_quadrant_structure_and_links(self) -> None:
        self.assertTrue((DOCS / "index.md").is_file())
        for quadrant in QUADRANTS:
            self.assertTrue((DOCS / quadrant / "index.md").is_file(), f"Missing docs/{quadrant}/index.md")
            self.assertTrue(any(p.name.lower() != "index.md" for p in (DOCS / quadrant).rglob("*.md")))
        broken = [
            f"{md.relative_to(ROOT)}:{ln}: {tgt}"
            for md in sorted(DOCS.rglob("*.md"))
            for ln, tgt, resolved in _relative_links(md)
            if not (resolved.is_file() or (resolved.is_dir() and (resolved / "index.md").is_file()))
        ]
        self.assertEqual(broken, [], "\n".join(broken))

    def test_genre_guardrails_and_cross_linking_mesh(self) -> None:
        for quadrant in QUADRANTS:
            for md in sorted((DOCS / quadrant).rglob("*.md")):
                if md.name.lower() == "index.md":
                    continue
                nc = _non_code_lines(md.read_text(encoding="utf-8"))
                heads = [m.group(1) for _, ln in nc if (m := HEADING_RE.match(ln))]
                full = "\n".join(ln for _, ln in nc)
                if quadrant == "01-tutorials":
                    self.assertLessEqual({"02-how-to-guides", "03-reference", "04-explanation"}, _linked_quadrants(md))
                elif quadrant == "02-how-to-guides":
                    self.assertRegex(full, HOWTO_VAL_RE)
                    self.assertRegex(full, HOWTO_RB_RE)
                    for h in heads:
                        self.assertNotRegex(h, HOWTO_TH_RE)
                    self.assertLessEqual({"03-reference", "04-explanation"}, _linked_quadrants(md))
                elif quadrant == "03-reference":
                    self.assertTrue(any(TBL_LIST_RE.match(ln) for _, ln in nc))
                    for _, ln in nc:
                        self.assertNotRegex(ln, REF_TUT_RE)
                elif quadrant == "04-explanation":
                    for h in heads:
                        self.assertNotRegex(h, EXPL_PROC_RE)
        alert_ref = DOCS / "03-reference" / "troubleshooting-codes" / "database-alert-and-error-matrix.md"
        self.assertIn("02-how-to-guides", _linked_quadrants(alert_ref))
        for adr in (DOCS / "04-explanation" / "design-decisions").glob("adr-*.md"):
            self.assertLessEqual({"03-reference", "02-how-to-guides"}, _linked_quadrants(adr))

    def test_docs_as_code_configs_and_portal_exposure(self) -> None:
        loader = _MkDocsLoader((ROOT / "mkdocs.yml").read_text(encoding="utf-8"))
        try:
            cfg = loader.get_single_data()
        finally:
            loader.dispose()
        tabs = [next(iter(e)) for e in cfg["nav"] if isinstance(e, dict)]
        self.assertEqual(tabs, ["Home", "Tutorials", "How-To Guides", "Reference", "Explanation", "Releases & Governance"])
        for path in _nav_paths(cfg["nav"]):
            target = (
                ROOT / VIRTUAL_DOCS[path]
                if path in VIRTUAL_DOCS
                else (ROOT / "documentation" / path[7:] if path.startswith("guides/") else DOCS / path)
            )
            self.assertTrue(target.is_file(), f"Missing nav target: {target}")
        cp = configparser.ConfigParser()
        cp.read_string("[__root__]\n" + (ROOT / ".vale.ini").read_text(encoding="utf-8"))
        self.assertEqual(cp["docs/02-how-to-guides/**/*.md"]["MinAlertLevel"], "error")
        self.assertTrue(json.loads((ROOT / ".markdownlint.json").read_text(encoding="utf-8")).get("default"))
        wf = yaml.safe_load((ROOT / ".github" / "workflows" / "docs-ci.yml").read_text(encoding="utf-8"))
        self.assertEqual(wf.get("permissions"), {"contents": "read"})
        self.assertIn("docs-ci-", str(wf.get("concurrency", {}).get("group", "")))
        job = wf["jobs"]["docs-quality"]
        self.assertLessEqual(job["timeout-minutes"], 15)
        for step in job["steps"]:
            if "uses" in step:
                self.assertRegex(step["uses"].split("@", 1)[1], SHA40_RE)
            if "run" in step:
                self.assertNotIn("${{", step["run"])
        run_all = "\n".join(str(s.get("run", "")) for s in job["steps"])
        self.assertIn("tests/test_diataxis_documentation.py", run_all)
        self.assertIn("tests/test_diataxis_ste.py", run_all)
        self.assertIn("mkdocs build --strict", run_all)
        portal = (DOCS / "index.md").read_text(encoding="utf-8")
        readme = (ROOT / "README.md").read_text(encoding="utf-8")
        for tok in [f"{q}/index.md" for q in QUADRANTS] + ["ACTION_LOGBOOK.md", "RCA_REGISTER.md", PORTAL_URL]:
            self.assertIn(tok, portal)
        for tok in ["docs/index.md", PORTAL_URL] + [f"docs/{q}/index.md" for q in QUADRANTS]:
            self.assertIn(tok, readme)


if __name__ == "__main__":
    unittest.main()
