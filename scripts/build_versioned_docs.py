"""Build a multi-version MkDocs Material site bundle for IONOS Apache hosting."""

from __future__ import annotations

import argparse
import html
import json
import os
from pathlib import Path
import re
import shutil
import subprocess  # nosec B404
import sys
import tempfile
import zipfile

_SEMVER_RE = re.compile(r"^v?(\d+)\.(\d+)\.(\d+)$")
_SAFE_REF_RE = re.compile(r"^[A-Za-z0-9._/\-]+$")
_EXCLUDED_TARGET_RE = re.compile(
    r"(?i)(?:(?:^|/)(?:\.env[^/]*|id_rsa[^/]*)$|\.(?:kdbx|keyx|pem|key|pid)$)"
)
ALWAYS_OVERLAY_FILES = (
    "mkdocs.yml",
    "scripts/mkdocs_hooks.py",
    "docs/stylesheets/extra.css",
    "docs/javascripts/katex.js",
)
FALLBACK_OVERLAY_FILES = (
    "docs/index.md",
    "docs/assets/logo.svg",
    "docs/assets/header-banner.svg",
)
_PROTECTED = (
    ".git", ".github", "docs", "documentation", "scripts",
    "ansible", "docker", "sql", "tests", ".agents", ".agent",
)


def parse_semver_tag(tag: str) -> tuple[int, int, int] | None:
    """Parse a semantic version tag such as `v1.0.0` into `(major, minor, patch)`."""
    m = _SEMVER_RE.fullmatch(tag.strip())
    return (int(m[1]), int(m[2]), int(m[3])) if m else None


def _sort_tags(tags: list[str]) -> list[str]:
    """Sort unique tags newest-first by semver, placing non-semver tags last."""
    uniq = dict.fromkeys(t.strip() for t in tags if t.strip())
    return sorted(
        uniq,
        key=lambda t: (1, v, t) if (v := parse_semver_tag(t)) is not None else (0, (0, 0, 0), t),
        reverse=True,
    )


def discover_release_tags(repo_root: Path) -> list[str]:
    """Discover semantic-version Git release tags sorted newest-first."""
    out = subprocess.check_output(["git", "-C", str(repo_root), "tag", "--list"], text=True)  # nosec B603, B607
    return _sort_tags([ln.strip() for ln in out.splitlines() if parse_semver_tag(ln)])


def build_versions_manifest(release_tags: list[str], include_main: bool = True) -> list[dict[str, object]]:
    """Build Material (`provider: mike`) `versions.json` entries ordered newest-first."""
    tags = _sort_tags(release_tags)
    entries: list[dict[str, object]] = [
        {"version": t, "title": t, "aliases": ["latest"] if i == 0 else []}
        for i, t in enumerate(tags)
    ]
    if include_main:
        entries.append(
            {"version": "main", "title": "main (dev)", "aliases": ["dev"] if tags else ["latest", "dev"]}
        )
    return entries


def render_redirect_html(target_url: str, title: str = "dbscripts Documentation") -> str:
    """Render a minimal HTML redirect fallback page for static hosting."""
    et, ti = html.escape(target_url, quote=True), html.escape(title, quote=True)
    return (
        f'<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="utf-8">\n  <title>{ti}</title>\n'
        f'  <meta http-equiv="refresh" content="0; url={et}">\n  <link rel="canonical" href="{et}">\n'
        f'  <script>window.location.replace({json.dumps(target_url)});</script>\n</head>\n'
        f'<body>\n  <p>Redirecting to <a href="{et}">{et}</a>...</p>\n</body>\n</html>\n'
    )


def render_htaccess(latest_version: str, main_version: str = "main") -> str:
    """Render Apache `.htaccess` for IONOS with HTTPS enforcement, headers, and redirects."""
    lat, main = latest_version.strip("/"), main_version.strip("/")
    if not _SAFE_REF_RE.fullmatch(lat) or not _SAFE_REF_RE.fullmatch(main):
        raise ValueError(f"Unsafe version slug for .htaccess: {latest_version!r}, {main_version!r}")
    return (
        "# dbscripts Versioned Documentation Apache Configuration (IONOS)\n"
        f"Options -Indexes -MultiViews\nDirectoryIndex index.html\nErrorDocument 404 /{lat}/404.html\n\n"
        "<IfModule mod_deflate.c>\n"
        "  AddOutputFilterByType DEFLATE text/html text/plain text/css text/xml application/javascript application/json image/svg+xml\n"
        "</IfModule>\n\n"
        '<IfModule mod_headers.c>\n  Header always set X-Content-Type-Options "nosniff"\n'
        '  Header always set Referrer-Policy "strict-origin-when-cross-origin"\n'
        '  Header always set Permissions-Policy "geolocation=(), microphone=(), camera=()"\n'
        '  Header always set X-Frame-Options "SAMEORIGIN"\n'
        '  <FilesMatch "versions\\.json$">\n    Header set Cache-Control "public, max-age=300, must-revalidate"\n  </FilesMatch>\n'
        "</IfModule>\n\n"
        "<IfModule mod_rewrite.c>\n  RewriteEngine On\n  RewriteBase /\n"
        "  RewriteCond %{HTTPS} !=on\n  RewriteCond %{HTTP:X-Forwarded-Proto} !https [NC]\n"
        "  RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]\n"
        f"  RewriteRule ^$ /{lat}/ [R=302,L]\n  RewriteRule ^latest(?:/(.*))?$ /{lat}/$1 [R=302,L]\n"
        f"  RewriteRule ^dev(?:/(.*))?$ /{main}/$1 [R=302,L]\n</IfModule>\n"
    )


def _safe_extract_zip(archive_path: Path, dest_dir: Path) -> None:
    """Extract a ZIP archive into `dest_dir` while preventing path traversal."""
    root = dest_dir.resolve()
    with zipfile.ZipFile(archive_path, "r") as zf:
        for info in zf.infolist():
            dst = (root / info.filename).resolve()
            if not dst.is_relative_to(root):
                raise ValueError(f"Unsafe archive member path detected: {info.filename!r}")
            if info.is_dir():
                dst.mkdir(parents=True, exist_ok=True)
            else:
                dst.parent.mkdir(parents=True, exist_ok=True)
                with zf.open(info, "r") as sf, open(dst, "wb") as df:
                    shutil.copyfileobj(sf, df)


def assert_no_private_files(output_dir: Path) -> None:
    """Verify zero private vault, key, PID, or `.env*` files exist in `output_dir`."""
    bad = [
        rel for p in output_dir.rglob("*")
        if p.is_file() and _EXCLUDED_TARGET_RE.search(rel := p.relative_to(output_dir).as_posix())
    ]
    if bad:
        raise RuntimeError(f"Privacy violation in built documentation output ({output_dir}): {bad}")


def build_single_version(
    repo_root: Path, git_ref: str, version_slug: str, output_dir: Path, base_url: str, strict: bool = True
) -> Path:
    """Build a single documentation version (`WORKTREE` or Git archive snapshot)."""
    ref = git_ref.strip()
    if not ref or ref.startswith("-") or not _SAFE_REF_RE.fullmatch(ref):
        raise ValueError(f"Invalid git ref: {git_ref!r}")
    base_out = output_dir.resolve()
    out = (base_out / version_slug).resolve()
    if not out.is_relative_to(base_out) or out == base_out:
        raise ValueError(f"Invalid version output slug: {version_slug!r}")
    out.parent.mkdir(parents=True, exist_ok=True)

    def _run_mkdocs(proj: Path) -> None:
        env = {
            **os.environ,
            "PYTHONUTF8": "1",
            "DBSCRIPTS_DOCS_REF": "main" if ref in {"WORKTREE", "origin/main", "main", "HEAD"} else ref,
            "DBSCRIPTS_DOCS_SITE_URL": f"{base_url.rstrip('/')}/{version_slug}/",
        }
        cmd = [sys.executable, "-m", "mkdocs", "build", "-f", str(proj / "mkdocs.yml"), "-d", str(out)]
        if strict:
            cmd.append("--strict")
        subprocess.run(cmd, cwd=str(proj), env=env, check=True)  # nosec B603

    if ref == "WORKTREE":
        _run_mkdocs(repo_root)
    else:
        with tempfile.TemporaryDirectory(prefix=f"dbscripts-docs-{version_slug}-") as tmp:
            arc, snap = Path(tmp) / "snapshot.zip", Path(tmp) / "src"
            snap.mkdir(parents=True, exist_ok=True)
            subprocess.run(  # nosec B603, B607
                ["git", "-C", str(repo_root), "archive", "--format=zip", "-o", str(arc), ref],
                check=True,
            )
            _safe_extract_zip(arc, snap)
            overlays = [(r, True) for r in ALWAYS_OVERLAY_FILES] + [(r, False) for r in FALLBACK_OVERLAY_FILES]
            for rel, always in overlays:
                src_f, dst_f = repo_root / rel, snap / rel
                if src_f.is_file() and (always or not dst_f.is_file()):
                    dst_f.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(src_f, dst_f)
            _run_mkdocs(snap)
    assert_no_private_files(out)
    return out


def build_versioned_site(
    repo_root: Path,
    output_dir: Path,
    base_url: str = "https://dbscripts.lightpath.fr",
    main_ref: str = "WORKTREE",
    tags: list[str] | None = None,
    skip_tags: bool = False,
    strict: bool = True,
) -> dict[str, object]:
    """Build the multi-version site bundle with redirects, `.htaccess`, and `versions.json`."""
    r_repo, r_out = repo_root.resolve(), output_dir.resolve()
    if (
        r_out == r_repo
        or r_repo.is_relative_to(r_out)
        or any(r_out == (p := r_repo / n) or r_out.is_relative_to(p) for n in _PROTECTED)
    ):
        raise ValueError(f"Output directory must not overwrite repository or protected paths: {r_out}")
    if r_out.exists():
        shutil.rmtree(r_out)
    r_out.mkdir(parents=True, exist_ok=True)

    rel_tags = [] if skip_tags else (_sort_tags(tags) if tags is not None else discover_release_tags(r_repo))
    manifest = build_versions_manifest(rel_tags, include_main=True)
    (r_out / "versions.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    build_single_version(r_repo, main_ref, "main", r_out, base_url, strict)
    for t in rel_tags:
        build_single_version(r_repo, t, t, r_out, base_url, strict)

    latest = rel_tags[0] if rel_tags else "main"
    (r_out / ".htaccess").write_text(render_htaccess(latest, "main"), encoding="utf-8")
    (r_out / "index.html").write_text(
        render_redirect_html(f"./{latest}/", "dbscripts Documentation"), encoding="utf-8"
    )
    for sub, tgt, lbl in (
        ("latest", f"../{latest}/", f"dbscripts Documentation ({latest})"),
        ("dev", "../main/", "dbscripts Documentation (main / dev)"),
    ):
        (d := r_out / sub).mkdir(parents=True, exist_ok=True)
        (d / "index.html").write_text(render_redirect_html(tgt, lbl), encoding="utf-8")

    assert_no_private_files(r_out)
    return {"output_dir": str(r_out), "latest_version": latest, "versions": [e["version"] for e in manifest]}


def main(argv: list[str] | None = None) -> int:
    """CLI entrypoint for versioned MkDocs Material site generation."""
    p = argparse.ArgumentParser(description="Build versioned dbscripts MkDocs Material docs for IONOS hosting.")
    p.add_argument("--output", default="site_dist", help="Target output directory (default: site_dist).")
    p.add_argument("--base-url", default="https://dbscripts.lightpath.fr", help="Base public documentation URL.")
    p.add_argument("--main-ref", default="WORKTREE", help="Git ref for /main/ (default: WORKTREE).")
    p.add_argument("--tags", nargs="*", default=None, help="Explicit release tags (space/comma-separated).")
    p.add_argument("--skip-tags", action="store_true", help="Skip release tags and build only /main/.")
    p.add_argument("--no-strict", action="store_true", help="Disable MkDocs --strict validation.")
    p.add_argument("--repo-root", default=str(Path(__file__).resolve().parents[1]), help="Repository root.")
    a = p.parse_args(argv)
    tags = [i.strip() for r in a.tags for i in r.split(",") if i.strip()] if a.tags is not None else None
    summary = build_versioned_site(
        Path(a.repo_root), Path(a.output), a.base_url, a.main_ref, tags, a.skip_tags, not a.no_strict
    )
    print(json.dumps(summary, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
