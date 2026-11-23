"""Contract and security tests for the IONOS versioned MkDocs deploy workflow."""

from __future__ import annotations

from pathlib import Path
import re
import unittest

import yaml


ROOT = Path(__file__).resolve().parent.parent
PUB_PATH = ROOT / ".github" / "workflows" / "docs-publish.yml"
CI_PATH = ROOT / ".github" / "workflows" / "docs-ci.yml"
SHA_RE = re.compile(r"^[A-Za-z0-9_.\-/]+@[0-9a-fA-F]{40}$")
DOC_TESTS = ("tests/test_diataxis_documentation.py", "tests/test_diataxis_ste.py", "tests/test_mkdocs_publishing.py", "tests/test_docs_publish_workflow.py")


def _load(path: Path) -> dict:
    """Load a YAML mapping via yaml.safe_load."""
    data = yaml.safe_load(path.read_text(encoding="utf-8"))
    assert isinstance(data, dict)
    return data


class TestDocsPublishWorkflow(unittest.TestCase):
    """Verify triggers, security hardening, SFTP deploy, and CI parity."""

    def test_triggers_permissions_and_ci_parity(self) -> None:
        wf, ci = _load(PUB_PATH), _load(CI_PATH)
        on_p, on_ci = wf.get("on", wf.get(True, {})), ci.get("on", ci.get(True, {}))
        self.assertEqual(wf.get("permissions"), {"contents": "read"})
        self.assertTrue(str(wf.get("concurrency", {}).get("group", "")).startswith("docs-publish-"))
        self.assertEqual((on_p["push"]["branches"], on_p["pull_request"]["branches"]), (["main"], ["main"]))
        self.assertEqual(on_p["push"]["paths"], on_p["pull_request"]["paths"])
        self.assertEqual(on_p["release"], {"types": ["published"]})
        self.assertIs(on_p["workflow_dispatch"]["inputs"]["deploy"]["default"], True)
        self.assertTrue(set(on_ci["push"]["paths"]).issubset(set(on_p["push"]["paths"])))
        self.assertTrue({".github/workflows/docs-publish.yml", *DOC_TESTS}.issubset(set(on_ci["push"]["paths"])))
        ci_runs = "\n".join(str(s.get("run", "")) for j in ci["jobs"].values() for s in j["steps"])
        for tf in DOC_TESTS:
            self.assertIn(tf, ci_runs)

    def test_security_hardening_across_all_jobs(self) -> None:
        jobs = _load(PUB_PATH).get("jobs", {})
        self.assertEqual(set(jobs), {"verify-and-build", "deploy-ionos"})
        for name, job in jobs.items():
            t = job.get("timeout-minutes", 0)
            self.assertTrue(isinstance(t, int) and 0 < t <= 15, name)
            self.assertNotIn("secrets.", str(job.get("if", "")), name)
            for s in job.get("steps", []):
                if (u := s.get("uses")) is not None:
                    self.assertRegex(str(u), SHA_RE, f"{name}: unpinned {u}")
                self.assertNotIn("secrets.", str(s.get("if", "")), name)
                cmd = str(s.get("run", ""))
                self.assertNotIn("${{", cmd, name)
                for bad in ("chmod 777", "sudo ", "eval ", "| bash", "| sh"):
                    self.assertNotIn(bad, cmd, name)

    def test_verify_build_and_deploy_ionos_contracts(self) -> None:
        jobs = _load(PUB_PATH)["jobs"]
        vb = jobs["verify-and-build"]["steps"]
        self.assertEqual(next(s for s in vb if str(s.get("uses", "")).startswith("actions/checkout@"))["with"]["fetch-depth"], 0)
        py = next(s for s in vb if str(s.get("uses", "")).startswith("actions/setup-python@"))["with"]
        self.assertEqual((py["python-version"], py["cache"], py["cache-dependency-path"]), ("3.12", "pip", "requirements-docs.txt"))
        vb_runs = "\n".join(str(s.get("run", "")) for s in vb)
        for tok in (*DOC_TESTS, "scripts/build_versioned_docs.py", "--output site_dist", "--base-url https://dbscripts.lightpath.fr", "versions.json", "index.html", ".htaccess", "main/index.html", "latest/index.html", "*.kdbx", "*.keyx", "id_rsa*"):
            self.assertIn(tok, vb_runs)
        up = next(s for s in vb if str(s.get("uses", "")).startswith("actions/upload-artifact@"))["with"]
        self.assertEqual(up["name"], "mkdocs-site-dist")
        self.assertIs(up["include-hidden-files"], True)

        dep = jobs["deploy-ionos"]
        self.assertEqual(dep["needs"], "verify-and-build")
        for cond in ("github.event_name == 'release'", "github.event_name == 'push' && github.ref == 'refs/heads/main'", "github.event_name == 'workflow_dispatch' && inputs.deploy == true"):
            self.assertIn(cond, str(dep["if"]))
        ds = dep["steps"]
        self.assertFalse(any(str(s.get("uses", "")).startswith("actions/checkout@") for s in ds))
        self.assertEqual(next(s for s in ds if str(s.get("uses", "")).startswith("actions/download-artifact@"))["with"]["name"], "mkdocs-site-dist")
        sftp = [s for s in ds if str(s.get("uses", "")).startswith("wlixcc/SFTP-Deploy-Action@")]
        self.assertEqual([s["with"]["local_path"] for s in sftp], ["./", ".htaccess"])
        for st in sftp:
            self.assertIs(st["with"]["sftp_only"], True)
            for sec in ("IONOS_FTP_SERVER", "IONOS_FTP_USERNAME", "IONOS_FTP_PASSWORD", "IONOS_FTP_PORT", "IONOS_REMOTE_PATH"):
                self.assertIn(f"secrets.{sec}", str(st["with"]))
        d_runs = "\n".join(str(s.get("run", "")) for s in ds)
        for chk in (".htaccess", "versions.json", "https://dbscripts.lightpath.fr/versions.json", "/latest/", "/main/", "/v1.0.0/"):
            self.assertIn(chk, d_runs)


if __name__ == "__main__":
    unittest.main()
