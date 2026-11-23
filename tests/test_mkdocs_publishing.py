"""Unit and E2E tests for versioned MkDocs Material documentation publishing."""

from __future__ import annotations

import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from types import ModuleType, SimpleNamespace
from typing import Any
import unittest
from unittest import mock
import zipfile

import yaml

REPO_ROOT = Path(__file__).resolve().parents[1]
HOOKS_PATH = REPO_ROOT / "scripts" / "mkdocs_hooks.py"
BUILDER_PATH = REPO_ROOT / "scripts" / "build_versioned_docs.py"


class _MkDocsLoader(yaml.SafeLoader):
    """Safe YAML loader supporting PyMdownx `!!python/name:` tags."""


_MkDocsLoader.add_multi_constructor(
    "tag:yaml.org,2002:python/name:",
    lambda _l, suffix, _n: f"python/name:{suffix}",
)


class _AttrDict(dict[str, Any]):
    """Dictionary exposing keys as attributes to mimic MkDocsConfig."""

    def __getattr__(self, key: str) -> Any:
        try:
            return self[key]
        except KeyError as exc:
            raise AttributeError(key) from exc

    __setattr__ = dict.__setitem__


def _load(name: str, path: Path) -> ModuleType:
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec is not None and spec.loader is not None
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


class TestMkDocsPublishing(unittest.TestCase):
    """Verify MkDocs Material config, hooks, and versioned site builder."""

    def test_mkdocs_yml_and_packaging_assets(self) -> None:
        loader = _MkDocsLoader((REPO_ROOT / "mkdocs.yml").read_text(encoding="utf-8"))
        try:
            cfg = loader.get_single_data()
        finally:
            loader.dispose()
        self.assertEqual(cfg["site_url"], "https://dbscripts.lightpath.fr/")
        self.assertEqual(cfg["repo_name"], "jmrenouard/dbscripts")
        self.assertEqual(cfg["repo_url"], "https://github.com/jmrenouard/dbscripts")
        self.assertIn("scripts/mkdocs_hooks.py", cfg["hooks"])
        self.assertEqual((cfg["theme"]["name"], cfg["theme"]["language"]), ("material", "en"))
        self.assertIn("navigation.tabs", cfg["theme"]["features"])
        self.assertEqual(cfg["extra"]["version"], {"provider": "mike", "default": "latest"})
        self.assertTrue("stylesheets/extra.css" in cfg["extra_css"] and "javascripts/katex.js" in cfg["extra_javascript"])
        exts = {e if isinstance(e, str) else next(iter(e)) for e in cfg["markdown_extensions"]}
        self.assertLessEqual({"admonition", "pymdownx.arithmatex", "pymdownx.superfences"}, exts)
        sf = next(e["pymdownx.superfences"] for e in cfg["markdown_extensions"] if isinstance(e, dict) and "pymdownx.superfences" in e)
        self.assertTrue(any(f.get("name") == "mermaid" and f.get("class") == "mermaid" for f in sf["custom_fences"]))
        for pat in ("*.kdbx", "*.keyx", "*.pid", ".env", "*.pem", "*.key"):
            self.assertIn(pat, str(cfg.get("exclude_docs", "")))
        self.assertEqual([next(iter(x)) for x in cfg["nav"] if isinstance(x, dict)], ["Home", "Tutorials", "How-To Guides", "Reference", "Explanation", "Releases & Governance"])
        self.assertTrue((REPO_ROOT / "docs" / "stylesheets" / "extra.css").is_file())
        katex = (REPO_ROOT / "docs" / "javascripts" / "katex.js").read_text(encoding="utf-8")
        self.assertTrue("document$.subscribe" in katex and "renderMathInElement" in katex)
        gi = (REPO_ROOT / ".gitignore").read_text(encoding="utf-8")
        self.assertTrue("site/" in gi and "site_dist/" in gi)
        reqs = (REPO_ROOT / "requirements-docs.txt").read_text(encoding="utf-8")
        self.assertTrue("mkdocs>=" in reqs and "mkdocs-material>=" in reqs)
        self.assertIn("https://dbscripts.lightpath.fr", (REPO_ROOT / "README.md").read_text(encoding="utf-8"))

    def test_mkdocs_hooks_alerts_slugify_and_lazy_import(self) -> None:
        with mock.patch.dict(sys.modules, {"mkdocs": None, "mkdocs.structure": None, "mkdocs.structure.files": None}):
            h = _load("mkdocs_hooks_no_deps", HOOKS_PATH)
            self.assertEqual(h.gfm_slugify("Documentation & Governance Hub"), "documentation--governance-hub")
            self.assertEqual(h.gfm_slugify("cli_flags"), "cli_flags")
            sample = "> [!NOTE]\n> N\n\n> [!TIP] T\n> F\n\n> [!IMPORTANT]\n> I\n\n> [!WARNING]\n> W\n\n> [!CAUTION]\n> C\n\n```md\n> [!NOTE]\n> Lit\n```\n"
            conv = h.convert_github_alerts(sample)
            for tag in ("!!! note", '!!! tip "T"', "!!! info", "!!! warning", "!!! danger"):
                self.assertIn(tag, conv)
            self.assertIn("> [!NOTE]\n> Lit", conv.split("```md", 1)[1])
            self.assertIn("](overview.md)", h.rewrite_relative_links("[Root](../README.md)", "index.md"))
            cfg = _AttrDict({"docs_dir": str(REPO_ROOT / "docs"), "mdx_configs": {"toc": {"slugify": None}}, "nav": []})
            with mock.patch.dict(os.environ, {"DBSCRIPTS_DOCS_REF": "WORKTREE", "DBSCRIPTS_DOCS_SITE_URL": "https://dbscripts.lightpath.fr/main"}):
                h.on_config(cfg)
            self.assertEqual((cfg["edit_uri"], cfg["site_url"]), ("edit/main/docs/", "https://dbscripts.lightpath.fr/main/"))
            self.assertIs(cfg["mdx_configs"]["toc"]["slugify"], h.gfm_slugify)

    def test_mkdocs_hooks_links_guides_v100_fallbacks_and_nav(self) -> None:
        h = _load("mkdocs_hooks_test", HOOKS_PATH)
        sample = (
            '[![Gov](badge.svg)](docs/ACTION_LOGBOOK.md)\n<img src="docs/assets/logo.svg" />\n'
            "- [C](Changelog) [A](ansible/README.md) [D](docker/mariadb/README.md)\n"
            "- [G](documentation/README.md) [S](documentation/MariaDB/images/request_flow.svg)\n"
            "- [H](documentation/MariaDB/1_update.html) [SH](documentation/genToC.sh)\n"
            "- [K](db.kdbx) [P](ca.pem) [R](keys/id_rsa.pub) [E](.env)\n"
            "`` `inline [x](README.md)` ``\n```bash\n[keep](Changelog)\n```\n"
        )
        rw = h.rewrite_relative_links(sample, "overview.md", ref="v1.0.0", use_directory_urls=True)
        for exp in ("](ACTION_LOGBOOK.md)", '<img src="../assets/logo.svg"', "](CHANGELOG.md)", "](ansible-playbooks.md)", "](docker-mariadb-lab.md)", "](guides/README.md)", "](guides/MariaDB/images/request_flow.svg)", "/blob/v1.0.0/documentation/MariaDB/1_update.html", "/blob/v1.0.0/documentation/genToC.sh"):
            self.assertIn(exp, rw)
        for sec in ("db.kdbx", "ca.pem", "id_rsa.pub", "(.env)"):
            self.assertNotIn(sec, rw)
        self.assertTrue("`inline [x](README.md)`" in rw and "[keep](Changelog)" in rw.split("```bash", 1)[1])
        self.assertEqual(h.rewrite_relative_links(r"a\[x](y) [a ![img](../../README.md)](../../Changelog)", "01-tutorials/01.md"), r"a\[x](y) [a ![img](../overview.md)](../CHANGELOG.md)")
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            (docs := root / "docs").mkdir()
            (gd := root / "documentation").mkdir()
            (root / "ansible").mkdir()
            for p, txt in ((root / "README.md", "# R"), (root / "Changelog", "# C"), (root / "ansible" / "README.md", "# A"), (gd / "README.md", "# G"), (gd / "user_guide.md", "# U"), (docs / "ACTION_LOGBOOK.md", "# L"), (docs / "RELEASE_NOTES_v1.0.0.md", "# 1"), (docs / "RELEASE_NOTES_v1.10.0.md", "# 10")):
                p.write_text(txt, encoding="utf-8")
            portal = "[T](01-tutorials/index.md) [H](02-how-to-guides/index.md) [R](03-reference/index.md) [E](04-explanation/index.md) [M](missing.md)"
            self.assertEqual(h.rewrite_relative_links(portal, "index.md", ref="v1.0.0", docs_dir=docs), "[T](guides/user_guide.md) [H](guides/README.md) [R](ansible-playbooks.md) [E](overview.md) [M](overview.md)")
            pruned = h.prune_nav_for_existing_files([{"Guides": ["guides/README.md", "guides/genToC.sh"]}, {"Releases & Governance": [{"Changelog": "CHANGELOG.md"}]}], docs, root)
            self.assertEqual(pruned[0], {"Guides": ["guides/README.md"]})
            self.assertEqual([next(iter(x.values())) for x in pruned[1]["Releases & Governance"]], ["CHANGELOG.md", "RELEASE_NOTES_v1.10.0.md", "RELEASE_NOTES_v1.0.0.md"])
        page = SimpleNamespace(file=SimpleNamespace(src_uri="guides/README.md", src_path="guides/README.md"), edit_url="")
        with mock.patch.dict(os.environ, {"DBSCRIPTS_DOCS_REF": "main"}):
            h.on_page_markdown("# G", page, _AttrDict({"docs_dir": str(REPO_ROOT / "docs")}), None)
        self.assertEqual(page.edit_url, "https://github.com/jmrenouard/dbscripts/edit/main/documentation/README.md")

    def test_build_versioned_docs_unit_and_guards(self) -> None:
        b = _load("build_versioned_docs_test", BUILDER_PATH)
        self.assertEqual(b.parse_semver_tag("v1.0.0"), (1, 0, 0))
        self.assertIsNone(b.parse_semver_tag("main"))
        with mock.patch.object(b.subprocess, "check_output", return_value="v1.0.0\nbad\nv1.10.0\n"):
            self.assertEqual(b.discover_release_tags(REPO_ROOT), ["v1.10.0", "v1.0.0"])
        man = b.build_versions_manifest(["v1.0.0", "v1.2.0", "v1.10.0"], include_main=True)
        self.assertEqual([e["version"] for e in man], ["v1.10.0", "v1.2.0", "v1.0.0", "main"])
        self.assertEqual((man[0]["aliases"], man[-1]["aliases"]), (["latest"], ["dev"]))
        self.assertEqual(b.build_versions_manifest([], True)[0]["aliases"], ["latest", "dev"])
        ht = b.render_htaccess("v1.0.0", "main")
        for tok in ("Options -Indexes", "ErrorDocument 404 /v1.0.0/404.html", "R=301", "R=302", "^latest(?:/(.*))?$", "^dev(?:/(.*))?$", "X-Content-Type-Options"):
            self.assertIn(tok, ht)
        self.assertIn('http-equiv="refresh"', b.render_redirect_html("./v1.0.0/"))
        with tempfile.TemporaryDirectory() as td:
            tp = Path(td)
            with zipfile.ZipFile(zp := tp / "bad.zip", "w") as zf:
                zf.writestr("../evil.txt", "x")
            with self.assertRaises(ValueError):
                b._safe_extract_zip(zp, tp / "out")
            (priv := tp / "priv").mkdir()
            (priv / "id_rsa").write_text("k", encoding="utf-8")
            with self.assertRaises(RuntimeError):
                b.assert_no_private_files(priv)
            repo = tp / "repo"
            protected = (".git", ".github", "docs", "documentation", "scripts", "ansible", "docker", "sql", "tests", ".agents", ".agent")
            for name in protected:
                (repo / name).mkdir(parents=True, exist_ok=True)
            for bad in [repo, tp] + [repo / n for n in protected]:
                with self.assertRaises(ValueError):
                    b.build_versioned_site(repo, bad, skip_tags=True)

    def test_build_versioned_docs_end_to_end_worktree_and_v100(self) -> None:
        if importlib.util.find_spec("mkdocs") is None:
            self.skipTest("mkdocs not installed in current Python environment")
        if not (REPO_ROOT / ".git").exists() or shutil.which("git") is None:
            self.skipTest("Git repository metadata required")
        with tempfile.TemporaryDirectory() as td:
            out = Path(td) / "site_dist"
            proc = subprocess.run([sys.executable, str(BUILDER_PATH), "--output", str(out), "--base-url", "https://dbscripts.lightpath.fr", "--main-ref", "WORKTREE", "--tags", "v1.0.0"], cwd=str(REPO_ROOT), capture_output=True, text=True, check=False)
            self.assertEqual(proc.returncode, 0, proc.stdout + "\n" + proc.stderr)
            for rel in ("versions.json", "index.html", ".htaccess", "latest/index.html", "dev/index.html", "main/index.html", "main/guides/index.html", "main/guides/MariaDB/images/request_flow.svg", "main/overview/index.html", "main/CHANGELOG/index.html", "v1.0.0/index.html", "v1.0.0/guides/index.html", "v1.0.0/guides/user_guide/index.html"):
                self.assertTrue((out / rel).is_file(), f"Missing built file: {rel}")
            self.assertEqual([e["version"] for e in json.loads((out / "versions.json").read_text(encoding="utf-8"))], ["v1.0.0", "main"])
            _load("bvd_e2e", BUILDER_PATH).assert_no_private_files(out)


if __name__ == "__main__":
    unittest.main()
