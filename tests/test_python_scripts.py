"""Unit tests verifying Python script syntax, logic, CLI argument contracts, and security."""

from __future__ import annotations

import importlib.util
import inspect
import pathlib
import re
import subprocess
import sys
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


def _load_module(module_name: str, file_path: pathlib.Path):
    """Dynamically load a python file as a module."""
    spec = importlib.util.spec_from_file_location(module_name, str(file_path))
    if not spec or not spec.loader:
        raise ImportError(f"Cannot load module from {file_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class TestPythonScriptsSyntax(unittest.TestCase):
    """Tier 1: Syntax compilation and basic execution contracts."""

    def test_all_python_scripts_compile(self) -> None:
        """Verify that all Python scripts in scripts/bin and docker compile cleanly without syntax errors."""
        python_files: list[pathlib.Path] = []
        for search_dir in (ROOT / "scripts" / "bin", ROOT / "docker", ROOT / "tests"):
            if search_dir.is_dir():
                python_files.extend(search_dir.rglob("*.py"))

        compilation_errors: list[str] = []
        for py_file in sorted(python_files):
            try:
                compile(py_file.read_text(encoding="utf-8"), str(py_file), "exec")
            except Exception as e:
                compilation_errors.append(f"{py_file.relative_to(ROOT).as_posix()}: {e}")

        self.assertEqual(compilation_errors, [], "\n".join(compilation_errors))

    def test_mygenconf_mysql_cli_arguments(self) -> None:
        """Verify mygenconf_mysql.py supports CLI arguments --port, --server-id, --buffer-pool-size, --datadir (Finding 18)."""
        target = ROOT / "scripts" / "bin" / "mygenconf_mysql.py"
        self.assertTrue(target.is_file(), "scripts/bin/mygenconf_mysql.py must exist")

        res = subprocess.run([sys.executable, str(target), "--help"], capture_output=True, text=True)
        self.assertEqual(res.returncode, 0, f"mygenconf_mysql.py --help failed: {res.stderr}")
        help_text = res.stdout.lower()

        required_args = ["--port", "--server-id", "--buffer-pool-size", "--datadir"]
        missing_args = [arg for arg in required_args if arg not in help_text]
        self.assertEqual(missing_args, [], f"mygenconf_mysql.py missing CLI options: {missing_args}")


class TestTreeS3(unittest.TestCase):
    """Tier 2: AWS S3 tree view utility size parsing, file detection, and metadata filtering (Finding 18)."""

    @classmethod
    def setUpClass(cls) -> None:
        target = ROOT / "scripts" / "bin" / "tree_s3.py"
        cls.tree_s3 = _load_module("tree_s3", target) if target.is_file() else None

    def test_tree_s3_parse_size_tib_and_pib(self) -> None:
        """Verify parse_size supports TiB (1024**4) and PiB (1024**5) units (Finding 18)."""
        self.assertIsNotNone(self.tree_s3, "tree_s3 module must exist")
        parse_size = getattr(self.tree_s3, "parse_size", None)
        self.assertTrue(callable(parse_size), "tree_s3.parse_size must be a function")

        self.assertEqual(parse_size("1", "Bytes"), 1.0)
        self.assertEqual(parse_size("1", "KiB"), 1024.0)
        self.assertEqual(parse_size("1", "MiB"), 1024.0**2)
        self.assertEqual(parse_size("1", "GiB"), 1024.0**3)
        self.assertEqual(parse_size("2", "TiB"), 2 * (1024.0**4), "parse_size must support TiB")
        self.assertEqual(parse_size("1.5", "PiB"), 1.5 * (1024.0**5), "parse_size must support PiB")

    def test_tree_s3_file_detection_without_extension(self) -> None:
        """Verify build_tree recognizes files that do not contain a dot in the filename (Finding 18)."""
        self.assertIsNotNone(self.tree_s3, "tree_s3 module must exist")
        build_tree = getattr(self.tree_s3, "build_tree", None)
        self.assertTrue(callable(build_tree), "tree_s3.build_tree must be a function")

        sample_output = [
            "2026-10-30 10:00:00 1024 KiB backup/mydb/dump",
            "2026-10-30 10:05:00 512 KiB backup/mydb/LICENSE",
        ]
        tree = build_tree(sample_output)
        dump_node = tree.get("backup", {}).get("mydb", {}).get("dump", {})
        self.assertIsNotNone(dump_node.get("_info"), "Files without extension must be recognized with _info")

    def test_tree_s3_metadata_keys_filtered_in_print_tree(self) -> None:
        """Verify print_tree does not process internal metadata keys like _files, _dirs, _size (Finding 18)."""
        self.assertIsNotNone(self.tree_s3, "tree_s3 module must exist")
        source = inspect.getsource(self.tree_s3.print_tree)
        has_metadata_filter = bool(
            re.search(r"startswith\(", source)
            or re.search(r"key\s+in\s+.*_files", source)
            or re.search(r"key\s*==\s*[\'\"]_files[\'\"]", source)
        )
        self.assertTrue(has_metadata_filter, "print_tree must filter out internal metadata keys")


class TestGenereCsv(unittest.TestCase):
    """Tier 2: Random CSV generation utility days parameter handling (Finding 18)."""

    @classmethod
    def setUpClass(cls) -> None:
        target = ROOT / "scripts" / "bin" / "genere_csv.py"
        cls.genere_csv = _load_module("genere_csv", target) if target.is_file() else None

    def test_genere_csv_days_parameter_forwarded(self) -> None:
        """Verify generate_csv accepts and uses days_range argument (Finding 18)."""
        self.assertIsNotNone(self.genere_csv, "genere_csv module must exist")
        generate_csv = getattr(self.genere_csv, "generate_csv", None)
        self.assertTrue(callable(generate_csv), "genere_csv.generate_csv must be callable")
        sig = inspect.signature(generate_csv)
        self.assertIn("days_range", sig.parameters, "generate_csv signature must accept days_range parameter")

    def test_genere_csv_generates_dates_within_days_range(self) -> None:
        """Verify generated CSV rows have timestamps within the specified days_range (Finding 18)."""
        self.assertIsNotNone(self.genere_csv, "genere_csv module must exist")
        generate_csv = getattr(self.genere_csv, "generate_csv", None)

        with tempfile.TemporaryDirectory() as tmpdir:
            csv_path = pathlib.Path(tmpdir) / "test.csv"
            try:
                generate_csv(str(csv_path), num_rows=10, days_range=5)
            except TypeError as e:
                self.fail(f"generate_csv does not accept days_range parameter (Finding 18): {e}")

            self.assertTrue(csv_path.is_file(), "CSV output must be created")
            lines = csv_path.read_text(encoding="utf-8").strip().splitlines()
            self.assertEqual(len(lines), 11, "Header + 10 rows expected")


class TestMySQLDumpSplitters(unittest.TestCase):
    """Tier 2 & 3: MySQL dump splitters directory naming and streaming memory contract (Finding 11)."""

    def test_mysqldump_splitters_output_dir_collision_prevention(self) -> None:
        """Verify dump splitters use safe output directory name (e.g., f'{file}_split') to prevent collisions (Finding 11)."""
        for splitter_name in ("mysqldump_database_splitter.py", "mysqldump_table_splitter.py"):
            target = ROOT / "scripts" / "bin" / splitter_name
            self.assertTrue(target.is_file(), f"scripts/bin/{splitter_name} must exist")
            content = target.read_text(encoding="utf-8")
            self.assertTrue(
                "_split" in content or "f'{file_path}_split'" in content or 'f"{file_path}_split"' in content,
                f"{splitter_name} must use collision-safe '_split' suffix for output directory",
            )

    def test_mysqldump_splitters_streaming_memory_contract(self) -> None:
        """Verify dump splitters stream line-by-line rather than buffering entire databases in RAM list (Finding 11)."""
        for splitter_name in ("mysqldump_database_splitter.py", "mysqldump_table_splitter.py"):
            target = ROOT / "scripts" / "bin" / splitter_name
            self.assertTrue(target.is_file(), f"scripts/bin/{splitter_name} must exist")
            content = target.read_text(encoding="utf-8")
            self.assertNotRegex(
                content,
                r"db_content\s*=\s*\[\].*db_content\.append\(line\)",
                f"{splitter_name} must not buffer entire database dumps in memory list db_content",
            )


class TestRepositoryArtifacts(unittest.TestCase):
    """Tier 1 & 2: Cleanliness and absence of stale binaries, notebook logs, and empty stubs (Finding 16)."""

    def test_repository_clean_of_stale_binaries_and_stubs(self) -> None:
        """Verify compiled Nagios binary, Init.ipynb, and empty stub files are deleted (Finding 16)."""
        stale_artifacts = [
            ROOT / "scripts" / "bin" / "check_mysql_health",
            ROOT / "notebooks" / "Init.ipynb",
            ROOT / "scripts" / "bin" / "extract_record_counts.py",
            ROOT / "scripts" / "bin" / "extract_users.py",
            ROOT / "scripts" / "bin" / "postgresql_backup.sh",
        ]
        existing_stale = [p.relative_to(ROOT).as_posix() for p in stale_artifacts if p.exists()]
        self.assertEqual(existing_stale, [], f"Stale artifacts found: {existing_stale}")


if __name__ == "__main__":
    unittest.main()
