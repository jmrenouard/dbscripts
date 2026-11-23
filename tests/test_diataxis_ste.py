"""ASD-STE100 Issue 9 verification suite for procedural How-To guides."""

from __future__ import annotations

from pathlib import Path
import re
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
HOWTO_DIR = ROOT / "docs" / "02-how-to-guides"

APPROVED_ING = frozenset(
    "mating missing remaining lighting opening routing servicing something during ring "
    "spring string king thing wing sing bring sting swing nothing anything everything "
    "bearing ceiling morning evening".split()
)
BANNED_MODALS = frozenset({"should", "would", "may", "might", "shall", "ought"})
NON_PARTICIPLES = frozenset(
    "bed between bleed breed citizen creed deed even exceed feed fifteen fourteen golden "
    "greed green heed hundred linen men naked need often open proceed red reed screen seed "
    "seven seventeen shed sixteen sled speed steed succeed sudden ten then thirteen wed "
    "weed when wicked women wooden".split()
)
_PARTICIPLE = (
    r"(?:[a-z]{2,}(?:ed|en)|been|done|made|gone|put|set|cut|kept|held|taken|given|"
    r"found|left|lost|meant|sent|shown|told|built|become|begun|broken|brought|come|"
    r"fallen|felt|got|gotten|grown|known|read|run|seen|spoken|thrown|worn|written|sold)"
)

CONTRACTION_RE = re.compile(
    r"\b\w+n['’]t\b|\b\w+['’](?:re|ll|ve|m|d)\b"
    r"|\b(?:it|that|there|what|let|who|here|he|she|where|when|how)['’]s\b",
    re.I,
)
HAVE_PART_RE = re.compile(rf"\b(?:has|have|had)\s+(?:(?:not|never|already|always)\s+)?{_PARTICIPLE}\b", re.I)
COMPLEX_PASSIVE_RE = re.compile(
    rf"\b(?:can|will|must|could|would|should|may|might|shall)\s+(?:not\s+)?be\s+{_PARTICIPLE}\b"
    rf"|\b(?:is|are|was|were)\s+to\s+be\s+{_PARTICIPLE}\b",
    re.I,
)
PASSIVE_BY_RE = re.compile(rf"\b(?:is|are|was|were|be|been|being)\s+(?:\w+\s+)?{_PARTICIPLE}\s+by\b", re.I)
PROGRESSIVE_RE = re.compile(r"\b(?:is|are|was|were|be|been|am)\s+[a-z]+ing\b", re.I)
LATIN_ABBR_RE = re.compile(r"(?<![A-Za-z])(?:e\.g\.|i\.e\.|etc\.)(?![A-Za-z])", re.I)
NUM_UNIT_RE = re.compile(
    r"(?<![A-Za-z0-9_])[+-]?\d+(?:[.,:]\d+)*"
    r"\s*(?:degrees?|percent|seconds?|minutes?|hours?|ms|MB|GB|KB|TB|s|m|h|%)\b"
)
SENTENCE_SPLIT_RE = re.compile(r"(?<!No\.)(?<!e\.g\.)(?<!i\.e\.)(?<!etc\.)(?<=[.!?:])\s+")
WORD_RE = re.compile(r"[A-Za-z0-9]+(?:[.'&/’-][A-Za-z0-9]+)*")
BULLET_RE = re.compile(r"^\s*(?:[-*+]|\d+[.)])\s+")

STE_RULES = (
    ("[GR-6]", LATIN_ABBR_RE, None, frozenset()),
    ("[Rule 4.2]", CONTRACTION_RE, None, frozenset()),
    ("[Rule 3.4]", HAVE_PART_RE, -1, NON_PARTICIPLES),
    ("[Rule 3.4]", COMPLEX_PASSIVE_RE, -1, NON_PARTICIPLES),
    ("[Rule 3.6]", PASSIVE_BY_RE, -2, NON_PARTICIPLES),
    ("[Rule 3.5]", PROGRESSIVE_RE, -1, APPROVED_ING),
)


def _check_sentence(sentence: str, loc: str, violations: list[str]) -> None:
    """Append ASD-STE100 Issue 9 violations found in a single sentence."""
    masked = NUM_UNIT_RE.sub(" N ", re.sub(r"\([^()]*\)", " P ", sentence))
    word_count = len(WORD_RE.findall(re.sub(r"\*\*|__|#+|\*", " ", masked)))
    if word_count > 20:
        violations.append(f"{loc} [Rule 5.1]: {word_count} words (> 20)")
    if ";" in sentence:
        violations.append(f"{loc} [Rule 8.1]: semicolon not allowed")
    plain = re.sub(r"\*\*|__|(?<!\w)_|_(?!\w)|\*", "", sentence)
    for tag, pattern, word_idx, exceptions in STE_RULES:
        match = pattern.search(plain)
        if match and (word_idx is None or match.group(0).split()[word_idx].lower() not in exceptions):
            violations.append(f"{loc} {tag}: '{match.group(0)}'")
    for token in re.findall(r"[A-Za-z-]+", plain):
        if token.lower() in BANNED_MODALS:
            violations.append(f"{loc} [Rule 3.2]: modal '{token}' not allowed")


def collect_ste_violations(md_path: Path) -> list[str]:
    """Validate procedural Markdown against ASD-STE100 Issue 9 structural rules."""
    raw = md_path.read_text(encoding="utf-8").replace("\r\n", "\n")
    text = re.sub(r"\A---\n.*?\n---(?:\n|\Z)|```.*?```|~~~.*?~~~", " ", raw, flags=re.DOTALL)
    text = re.sub(r"`[^`\n]+`|\"[^\"\n]*\"", " CODE ", text)
    text = re.sub(r"!?\[([^\]]*)\]\((?:[^()]|\([^)]*\))*\)", r"\1", text)
    text = re.sub(r"(?m)^[ \t]*(?:#.*|\|.*|---+|>.*)[ \t]*$", "", text)

    violations: list[str] = []
    rel = md_path.relative_to(ROOT).as_posix() if md_path.is_relative_to(ROOT) else md_path.name
    for idx, block in enumerate(re.split(r"\n\s*\n", text), 1):
        if not block.strip() or not WORD_RE.search(block):
            continue
        items: list[str] = []
        prose: list[str] = []
        for line in block.strip().splitlines():
            if BULLET_RE.match(line):
                items.append(line)
            elif items and re.match(r"^(?:  |\t)\S", line):
                items[-1] += " " + line.strip()
            else:
                prose.append(line)
        for item in items:
            for sent in SENTENCE_SPLIT_RE.split(BULLET_RE.sub("", item, 1)):
                if sent.strip() and WORD_RE.search(sent):
                    _check_sentence(sent.strip(), f"{rel}:list", violations)
        if prose:
            sents = [s.strip() for s in SENTENCE_SPLIT_RE.split("\n".join(prose)) if s.strip() and WORD_RE.search(s)]
            if len(sents) > 6:
                violations.append(f"{rel}:par{idx} [Rule 6.6]: {len(sents)} sentences (> 6)")
            for sent in sents:
                _check_sentence(sent, f"{rel}:par{idx}", violations)
    return violations


class TestDiataxisSte(unittest.TestCase):
    """Verify ASD-STE100 Issue 9 procedural compliance across How-To guides."""

    def test_all_howto_guides_comply_with_ste(self) -> None:
        guides = sorted(p for p in HOWTO_DIR.rglob("*.md") if p.name.lower() != "index.md")
        self.assertGreaterEqual(len(guides), 4)
        for guide in guides:
            self.assertEqual(collect_ste_violations(guide), [], f"STE violations in {guide.name}")

    def test_ste_checker_accepts_compliant_procedure(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            ok_doc = Path(tmp) / "ok.md"
            ok_doc.write_text("# Backup\n\n1. Stop MariaDB.\n2. Run the backup script.\n", encoding="utf-8")
            self.assertEqual(collect_ste_violations(ok_doc), [])

    def test_ste_checker_flags_banned_constructions(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            bad_doc = Path(tmp) / "bad.md"
            bad_doc.write_text(
                "# Bad\n\n"
                "1. You should restart; don't skip this, e.g. node one.\n"
                "2. Node one has stopped while the server is running now.\n"
                "3. The backup file was wiped by the script after twenty seconds "
                "of continuous polling across every active host inside this test cluster.\n\n"
                "One. Two. Three. Four. Five. Six. Seven.\n",
                encoding="utf-8",
            )
            joined = "\n".join(collect_ste_violations(bad_doc))
            for rule in ("[Rule 3.2]", "[Rule 8.1]", "[Rule 4.2]", "[GR-6]", "[Rule 3.4]", "[Rule 3.5]", "[Rule 3.6]", "[Rule 5.1]", "[Rule 6.6]"):
                self.assertIn(rule, joined)


if __name__ == "__main__":
    unittest.main()
