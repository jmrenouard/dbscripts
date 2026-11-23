"""MkDocs Material build hooks for dbscripts documentation publishing."""

from __future__ import annotations

import os
from pathlib import Path
import posixpath
import re
from typing import TYPE_CHECKING, Any, Callable, Iterable

if TYPE_CHECKING:
    from mkdocs.structure.files import Files

DEFAULT_REPO_URL = "https://github.com/jmrenouard/dbscripts"
VIRTUAL_DOCS: dict[str, tuple[str, str]] = {
    "overview.md": ("README.md", ""), "CHANGELOG.md": ("Changelog", ""),
    "ansible-playbooks.md": ("ansible/README.md", "ansible"),
    "docker-mariadb-lab.md": ("docker/mariadb/README.md", "docker/mariadb"),
}
_DOC_TO_V = {s: u for u, (s, _) in VIRTUAL_DOCS.items()}
_GUIDE_EXTS = frozenset({".md", ".svg", ".png", ".jpg", ".webp"})
QUADRANT_HISTORICAL_FALLBACKS: dict[str, str] = {
    "01-tutorials": "guides/user_guide.md", "02-how-to-guides": "guides/README.md",
    "03-reference": "ansible-playbooks.md", "04-explanation": "overview.md",
}
ALERT_MAP = {"NOTE": "note", "TIP": "tip", "IMPORTANT": "info", "WARNING": "warning", "CAUTION": "danger"}

_FENCE_RE = re.compile(r"^([ \t]*)(`{3,}|~{3,})(.*)$")
_ALERT_RE = re.compile(r"(?m)^([ \t]*)>[ \t]*\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\][ \t]*([^\r\n]*)\r?\n((?:[ \t]*>.*(?:\r?\n|$))*)")
_REL_RE = re.compile(r"^RELEASE_NOTES_v?(\d+)\.(\d+)\.(\d+)\.md$")
_SCHEME_RE = re.compile(r"^[a-zA-Z][a-zA-Z0-9+.-]*:")
_EXCLUDED_TARGET_RE = re.compile(r"(?i)(?:(?:^|/)(?:\.env[^/]*|id_rsa[^/]*)$|\.(?:kdbx|keyx|pem|key|pid)$)")
_HTML_ATTR_RE = re.compile(r"""(<(?:img|a|source)\b[^>]*?\b(?:src|href)\s*=\s*)(["'])([^"']+)\2""", re.I)
_CODE_SPAN_RE = re.compile(r"(`+)(?:(?!\1).)+?\1", re.S)
_MD_LINK_RE = re.compile(r"(!?)\[((?:[^\[\]]|\[[^\[\]]*\])*)\]\(((?:[^()\n]|\([^()\n]*\))+)\)")


def gfm_slugify(value: str, separator: str = "-") -> str:
    """Slugify headings using GitHub Flavored Markdown rules."""
    return "".join(separator if c == " " else c for c in value.strip().lower() if c.isalnum() or c in " -_")


def _ref(raw: str | None = None) -> str:
    r = (os.environ.get("DBSCRIPTS_DOCS_REF", "main") if raw is None else raw).strip()
    return "main" if not r or r in {"WORKTREE", "HEAD", "origin/main"} else r


def _outside_fences(md: str, fn: Callable[[str], str]) -> str:
    out, buf, fc, fl = [], [], "", 0
    for ln in md.splitlines(keepends=True):
        s = ln.rstrip("\r\n")
        if not fc and (m := _FENCE_RE.match(s)):
            if buf:
                out.append(fn("".join(buf)))
                buf.clear()
            fc, fl = m[2][0], len(m[2])
            out.append(ln)
        elif fc:
            out.append(ln)
            if (ld := s.lstrip(" \t")).startswith(fc) and len(ld) - len(tl := ld.lstrip(fc)) >= fl and not tl.strip():
                fc, fl = "", 0
        else:
            buf.append(ln)
    return "".join(out) + (fn("".join(buf)) if buf else "")


def convert_github_alerts(markdown: str) -> str:
    """Convert GitHub alerts to Material admonitions outside fences."""

    def _fmt(m: re.Match[str]) -> str:
        ws, kind, title = m[1], ALERT_MAP[m[2].upper()], m[3].strip()
        head = f'{ws}!!! {kind} "{title}"\n' if title else f"{ws}!!! {kind}\n"
        return head + "".join((r[len(st):] or "\n") if not (in_ := re.sub(r"^[ \t]*>[ \t]?", "", (st := r.rstrip("\r\n")))).strip() else f"{ws}    {in_}{r[len(st):] or chr(10)}" for r in m[4].splitlines(keepends=True))

    return _outside_fences(markdown, lambda s: _ALERT_RE.sub(_fmt, s))


def _nav_doc_exists(rel: str, dd: Path, root: Path | None, avail: frozenset[str] | None = None) -> bool:
    """Return True if target exists in `docs_dir`, `VIRTUAL_DOCS`, or `documentation/`."""
    if (dd / rel).is_file():
        return True
    if rel in VIRTUAL_DOCS:
        return (avail is None or rel in avail) and (root is None or (root / VIRTUAL_DOCS[rel][0]).is_file())
    return rel.startswith("guides/") and Path(rel[7:]).suffix.lower() in _GUIDE_EXTS and (root is None or (root / "documentation" / rel[7:]).is_file())


def rewrite_relative_links(
    markdown: str, page_src_path: str, ref: str = "main", repo_url: str = DEFAULT_REPO_URL,
    docs_dir: Path | None = None, use_directory_urls: bool = True, available_root_docs: Iterable[str] | None = None,
) -> str:
    """Rewrite relative Markdown and HTML links outside code blocks."""
    norm = page_src_path.replace("\\", "/").lstrip("/")
    md_d = norm.count("/")
    hp = "../" * (md_d + (0 if not use_directory_urls or norm == "index.md" or norm.endswith("/index.md") else 1))
    mp, rf, repo = "../" * md_d, _ref(ref), repo_url.rstrip("/")
    dd = Path(docs_dir) if docs_dir is not None else None
    root = dd.parent if dd is not None else None
    avail = frozenset(VIRTUAL_DOCS if available_root_docs is None else available_root_docs)
    sdir = VIRTUAL_DOCS[norm][1] if norm in VIRTUAL_DOCS else posixpath.dirname(("documentation/" + norm[7:]) if norm.startswith("guides/") else ("docs/" + norm))

    def _resolve(raw: str, pfx: str) -> tuple[str | None, bool]:
        if not raw or raw[0] in "#/\\" or _SCHEME_RE.match(raw):
            return raw, False
        part, sep, frag = raw.partition("#")
        if not part:
            return raw, False
        anc, slash = sep + frag, part.endswith("/")
        rel = posixpath.normpath(posixpath.join(sdir, part) if sdir else part)
        if _EXCLUDED_TARGET_RE.search(rel) or _EXCLUDED_TARGET_RE.search(part):
            return None, True
        if rel.startswith("docs/guides/"):
            rel = f"documentation/{rel[12:]}"
        elif rel.startswith("docs/") and (v := rel[5:]) in VIRTUAL_DOCS and (dd is None or not (dd / v).is_file()):
            rel = VIRTUAL_DOCS[v][0]
        if rel in _DOC_TO_V:
            vu = _DOC_TO_V[rel]
            return (f"{pfx}{vu}{anc}" if vu in avail else f"{repo}/blob/{rf}/{rel}{anc}"), False
        if rel == "docs/index.md":
            return f"{pfx}index.md{anc}", False
        if rel.startswith("documentation/") and Path(rel[14:]).suffix.lower() in _GUIDE_EXTS and (root is None or (root / rel).is_file()):
            return f"{pfx}guides/{rel[14:]}{anc}", False
        if not rel.startswith("docs/"):
            if rel in (".", "..") or rel.startswith("../"):
                return repo, False
            kind = "tree" if slash or (root is not None and (root / rel).is_dir()) else "blob"
            return f"{repo}/{kind}/{rf}/{rel}{'/' if slash and not rel.endswith('/') else ''}{anc}", False
        sub = rel[5:]
        if dd is not None:
            ov = f"{pfx}overview.md" if "overview.md" in avail else f"{repo}/blob/{rf}/README.md"
            if (top := sub.split("/", 1)[0]) in QUADRANT_HISTORICAL_FALLBACKS and not (dd / top).is_dir():
                fb = QUADRANT_HISTORICAL_FALLBACKS[top]
                return (f"{pfx}{fb}" if _nav_doc_exists(fb, dd, root, avail) else ov), False
            if norm == "index.md" and not (dd / "01-tutorials").is_dir() and not (dd / sub).exists() and sub not in avail:
                return (f"{pfx}CHANGELOG.md" if sub.startswith("RELEASE_NOTES_") and "CHANGELOG.md" in avail else ov), False
            if (dd / sub).is_dir() and (dd / sub / "index.md").is_file():
                return f"{pfx}{posixpath.join(sub.rstrip('/'), 'index.md')}{anc}", False
        return f"{pfx}{sub}{'/' if slash and sub and not sub.endswith('/') else ''}{anc}", False

    def _rw(seg: str) -> str:
        spans: list[str] = []
        mk = _CODE_SPAN_RE.sub(lambda m: (spans.append(m[0]), f"\x00IC{len(spans) - 1}\x00")[1], seg)

        def _md(m: re.Match[str]) -> str:
            pre = m.string[: m.start()]
            if (len(pre) - len(pre.rstrip("\\"))) & 1:
                return m[0]
            b, lbl, raw = m[1], _MD_LINK_RE.sub(_md, m[2]), m[3].strip()
            ang = raw.startswith("<") and ">" in raw
            up, sfx = (raw[1:(ae := raw.find(">"))].strip(), raw[ae + 1:]) if ang else (raw[:(sp := next((k for k, c in enumerate(raw) if c.isspace()), len(raw)))], raw[sp:])
            res, neu = _resolve(up, mp)
            return ("" if b else lbl) if neu else f"{b}[{lbl}]({f'<{res}>' if ang else res}{sfx})"

        out = _HTML_ATTR_RE.sub(lambda m: (lambda u, n: f"{m[1]}{m[2]}{'#' if n else u}{m[2]}")(*_resolve(m[3], hp)), _MD_LINK_RE.sub(_md, mk))
        return re.sub(r"\x00IC(\d+)\x00", lambda m: spans[int(m[1])], out)

    return _outside_fences(markdown, _rw)


def prune_nav_for_existing_files(nav: list[Any] | None, docs_dir: Path, repo_root: Path) -> list[Any]:
    """Prune missing pages and empty sections while discovering release notes."""
    if not nav:
        return []
    dd, rr = Path(docs_dir), Path(repo_root)

    def _rn(p: Path) -> tuple[int, tuple[int, int, int], str, str]:
        if m := _REL_RE.match(p.name):
            return (1, (int(m[1]), int(m[2]), int(m[3])), f"Release Notes v{int(m[1])}.{int(m[2])}.{int(m[3])}", p.name)
        return (0, (0, 0, 0), f"Release Notes {p.stem[14:]}", p.name)

    notes = [{lbl: fn} for _, _, lbl, fn in sorted((_rn(p) for p in (dd.glob("RELEASE_NOTES_*.md") if dd.is_dir() else ()) if p.is_file()), reverse=True)]

    def _walk(items: list[Any], in_rel: bool = False) -> list[Any]:
        out, ins = [], False
        for e in items:
            if not isinstance(e, (str, dict)) or (isinstance(e, dict) and not e):
                continue
            k, v = (None, e) if isinstance(e, str) else next(iter(e.items()))
            if isinstance(v, str):
                if in_rel and Path(v).name.startswith("RELEASE_NOTES_"):
                    if not ins:
                        out.extend(notes)
                        ins = True
                elif _nav_doc_exists(v, dd, rr):
                    out.append(v if k is None else {k: v})
                    if in_rel and v == "CHANGELOG.md" and not ins:
                        out.extend(notes)
                        ins = True
            elif isinstance(v, list) and (nd := _walk(v, in_rel or k == "Releases & Governance")):
                out.append({k: nd})
            elif isinstance(v, dict) and (nl := _walk([v], in_rel)):
                out.append({k: nl[0]})
        if in_rel and not ins and notes:
            idx = next((i + 1 for i, it in enumerate(out) if isinstance(it, dict) and "CHANGELOG.md" in it.values()), 0)
            out[idx:idx] = notes
        return out

    return _walk(list(nav))


def on_config(config: Any) -> Any:
    """Configure `site_url`, `edit_uri`, GFM TOC slugifier, and pruned navigation."""
    if url := os.environ.get("DBSCRIPTS_DOCS_SITE_URL", "").strip():
        config.site_url = url.rstrip("/") + "/"
    config.edit_uri = "edit/main/docs/" if _ref() == "main" else ""
    if isinstance(mdx := getattr(config, "mdx_configs", None), dict) and isinstance(toc := mdx.setdefault("toc", {}), dict) and not toc.get("slugify"):
        toc["slugify"] = gfm_slugify
    dd = Path(config.docs_dir)
    if getattr(config, "nav", None):
        config.nav = prune_nav_for_existing_files(config.nav, dd, dd.parent)
    return config


def on_files(files: Files, config: Any) -> Files:
    """Exclude private files and inject virtual root docs plus `documentation/` guides."""
    from mkdocs.structure.files import File, Files as MkDocsFiles, InclusionLevel

    kept = []
    for f in list(files):
        if _EXCLUDED_TARGET_RE.search(f.src_uri):
            f.inclusion = InclusionLevel.EXCLUDED
        else:
            kept.append(f)
    if len(kept) != len(files):
        files = MkDocsFiles(kept)
    root = Path(config.docs_dir).parent
    cands = [(u, root / rel) for u, (rel, _) in VIRTUAL_DOCS.items()]
    if (guides := root / "documentation").is_dir():
        cands.extend((f"guides/{p.relative_to(guides).as_posix()}", p) for p in sorted(guides.rglob("*")) if p.is_file() and p.suffix.lower() in _GUIDE_EXTS)
    for uri, src in cands:
        if src.is_file() and not _EXCLUDED_TARGET_RE.search(uri) and files.get_file_from_path(uri) is None:
            files.append(File.generated(config, uri, abs_src_path=str(src)))
    return files


def on_page_markdown(markdown: str, page: Any, config: Any, files: Files) -> str:
    """Convert alerts, rewrite relative links, and adjust virtual doc edit URLs."""
    src = getattr(page.file, "src_uri", None) or str(page.file.src_path).replace("\\", "/")
    rf, repo = _ref(), (getattr(config, "repo_url", None) or DEFAULT_REPO_URL).rstrip("/")
    rd = getattr(config, "docs_dir", None) or (config.get("docs_dir") if isinstance(config, dict) else None)
    if (es := VIRTUAL_DOCS[src][0] if src in VIRTUAL_DOCS else (f"documentation/{src[7:]}" if src.startswith("guides/") else None)) is not None:
        page.edit_url = f"{repo}/edit/main/{es}" if rf == "main" else None
    avail = [k for k in VIRTUAL_DOCS if files.get_file_from_path(k) is not None] if files is not None else None
    return rewrite_relative_links(convert_github_alerts(markdown), src, rf, repo, Path(rd) if rd else None, bool(getattr(config, "use_directory_urls", True)), avail)
