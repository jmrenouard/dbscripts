"""Unit tests verifying shell script syntax, safety, sourcing contracts, and operational logic."""

from __future__ import annotations

import os
import pathlib
import re
import shutil
import subprocess
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


class TestShellScriptsSyntax(unittest.TestCase):
    """Tier 1: Shell script syntax validation and compilation."""

    @classmethod
    def setUpClass(cls) -> None:
        cls.bash_path = "C:/Program Files/Git/bin/bash.exe" if os.path.isfile("C:/Program Files/Git/bin/bash.exe") else shutil.which("bash")

    def _collect_shell_scripts(self) -> list[pathlib.Path]:
        scripts: list[pathlib.Path] = []
        for search_dir in (ROOT / "scripts", ROOT / "MariaDB" / "scripts"):
            if search_dir.is_dir():
                scripts.extend(search_dir.rglob("*.sh"))
        return sorted(scripts)

    def test_all_shell_scripts_pass_bash_syntax_check(self) -> None:
        """Verify that every .sh script in the repository passes bash -n without syntax errors (Finding 1)."""
        if not self.bash_path:
            self.skipTest("bash binary not found in environment")

        scripts = self._collect_shell_scripts()
        self.assertGreater(len(scripts), 0, "Expected to find .sh scripts in repository")

        syntax_errors: list[str] = []
        for script in scripts:
            rel_path = script.relative_to(ROOT).as_posix()
            res = subprocess.run(
                [self.bash_path, "-n", rel_path],
                cwd=ROOT,
                capture_output=True,
                text=True,
            )
            if res.returncode != 0:
                syntax_errors.append(f"{rel_path}: {res.stderr.strip()}")

        self.assertEqual(
            syntax_errors,
            [],
            f"Shell syntax compilation failed on {len(syntax_errors)} scripts:\n"
            + "\n".join(syntax_errors),
        )

    def test_mbbackup_typo_bracket_spacing(self) -> None:
        """Verify mbbackup.sh line 83 does not contain invalid command typo '[-f' (Finding 1)."""
        mbbackup = ROOT / "scripts" / "bin" / "mbbackup.sh"
        self.assertTrue(mbbackup.is_file(), "scripts/bin/mbbackup.sh must exist")
        content = mbbackup.read_text(encoding="utf-8", errors="ignore")
        self.assertNotRegex(
            content,
            r"\[-f\s+",
            "mbbackup.sh contains typo '[-f' missing space after '['",
        )

    def test_makefile_targets_and_tab_indentation(self) -> None:
        """Verify root Makefile has valid tab indentation and defines test, lint, clean targets (Finding 12)."""
        makefile = ROOT / "Makefile"
        self.assertTrue(makefile.is_file(), "Root Makefile must exist")
        content = makefile.read_text(encoding="utf-8")

        for target in ("test:", "lint:", "clean:"):
            self.assertIn(target, content, f"Makefile must define target {target}")

        lines = content.splitlines()
        for i, line in enumerate(lines, start=1):
            # Recipe lines following target headers must start with a tab \t, not spaces
            if line.startswith("    ") and not line.strip().startswith("#"):
                self.fail(f"Makefile line {i} is indented with spaces instead of a tab: {line!r}")


class TestShellScriptsSafety(unittest.TestCase):
    """Tier 2: Boundary conditions, variable guarding under set -u, and error handling."""

    def test_unbound_variable_guarding_under_set_u(self) -> None:
        """Verify scripts declaring set -euo pipefail guard positional arguments as ${1:-}, ${2:-} (Finding 1)."""
        critical_scripts = [
            ROOT / "scripts" / "bin" / "create_database.sh",
            ROOT / "scripts" / "bin" / "drop_database.sh",
            ROOT / "scripts" / "bin" / "lgbackup.sh",
            ROOT / "scripts" / "bin" / "lgrestore.sh",
            ROOT / "scripts" / "bin" / "mbrestore.sh",
            ROOT / "scripts" / "bin" / "mbbackup.sh",
            ROOT / "scripts" / "bin" / "maria-pitr-restore.sh",
            ROOT / "scripts" / "bin" / "pitr-restore.sh",
            ROOT / "scripts" / "bin" / "ssh_lgrestore.sh",
        ]

        unprotected: list[str] = []
        for script in critical_scripts:
            if not script.is_file():
                continue
            content = script.read_text(encoding="utf-8", errors="ignore")
            # If script declares set -u or set -euo pipefail
            if re.search(r"set\s+-[^\n]*u", content):
                # Search for unguarding of $1, $2, $3 outside of default expansion ${1:-
                # Flag bare references like `if [ "$1" =` or `for srv in $1 $2`
                lines = content.splitlines()
                for line_no, line in enumerate(lines, start=1):
                    stripped = line.strip()
                    if stripped.startswith("#"):
                        continue
                    # Match bare $1, $2, $3 not followed by : or -
                    if re.search(r'(?<!\$\{)(?<!\$)(\$([1-9]|doit|TARGET_CONFIG)\b)(?![:\-])', stripped):
                        rel = script.relative_to(ROOT).as_posix()
                        unprotected.append(f"{rel}:{line_no} -> {stripped}")

        self.assertEqual(
            unprotected,
            [],
            f"Found {len(unprotected)} unguarded variables in scripts with set -u:\n"
            + "\n".join(unprotected[:10]),
        )

    def test_synchro_repli_vault_token_non_fatal_extraction(self) -> None:
        """Verify synchro_repli_mariabackup_stream.sh does not fail if database is unencrypted (Finding 6)."""
        target = ROOT / "scripts" / "bin" / "synchro_repli_mariabackup_stream.sh"
        self.assertTrue(target.is_file(), "synchro_repli_mariabackup_stream.sh must exist")
        content = target.read_text(encoding="utf-8", errors="ignore")

        # Must not have bare fatal grep command under set -euo pipefail
        self.assertTrue(
            "|| true" in content or "|| :" in content or "${TOKEN:-}" in content or "2>/dev/null" in content,
            "synchro_repli_mariabackup_stream.sh must safely guard Vault token extraction for unencrypted databases",
        )

    def test_ssh_keys_untracked_and_gitignored(self) -> None:
        """Verify no private SSH keys are tracked in git and .gitignore ignores id_rsa (Finding 2)."""
        gitignore_path = ROOT / ".gitignore"
        self.assertTrue(gitignore_path.is_file(), ".gitignore must exist")
        gitignore_content = gitignore_path.read_text(encoding="utf-8")
        self.assertTrue(
            any(pat in gitignore_content for pat in ("**/id_rsa*", "id_rsa", "id_rsa*")),
            ".gitignore must ignore id_rsa key files",
        )

        tracked_key = ROOT / "MariaDB" / "docker" / "mariadb" / "id_rsa"
        if tracked_key.exists():
            # Check git tracking via git ls-files
            git_path = shutil.which("git")
            if git_path:
                res = subprocess.run(
                    [git_path, "ls-files", "MariaDB/docker/mariadb/id_rsa"],
                    cwd=ROOT,
                    capture_output=True,
                    text=True,
                )
                self.assertEqual(
                    res.stdout.strip(),
                    "",
                    "MariaDB/docker/mariadb/id_rsa must not be tracked in git",
                )

    def test_docker_tree_consolidation_and_gen_ssl(self) -> None:
        """Verify MariaDB/ removal and gen_ssl security polish (Finding 14)."""
        self.assertFalse((ROOT / "MariaDB").exists(), "MariaDB/ directory must be pruned")
        self.assertTrue((ROOT / "docker" / "mariadb" / "Dockerfile").is_file())
        gen_ssl = (ROOT / "docker" / "mariadb" / "gen_ssl.sh").read_text(encoding="utf-8")
        self.assertIn("set -euo pipefail", gen_ssl)
        self.assertIn("-set_serial 02", gen_ssl)
        self.assertIn('rm -f "$SSL_DIR/"*-req.pem', gen_ssl)
        self.assertIn('chmod 600 "$SSL_DIR/"*key*.pem', gen_ssl)
        self.assertIn('chmod 644 "$SSL_DIR/"*cert*.pem', gen_ssl)

    def test_mysql_utils_guarding_under_set_u(self) -> None:
        """Verify my_status and galera_is_enabled execute under set -u without crashes (Finding 1)."""
        if not BASH: self.skipTest("no bash")
        cmd = 'set -euo pipefail; unset SSH_CMD; source scripts/utils.sh; my_status >/dev/null 2>&1 || true; res=$(galera_is_enabled 2>&1); echo "GALERA_RES=$res"'
        res = subprocess.run([BASH, "-c", cmd], cwd=ROOT, capture_output=True, text=True)
        self.assertEqual(res.returncode, 0, f"MySQL utils failed under set -u: {res.stderr}")
        for v in ("unbound variable", "SSH_CMD", "$2"): self.assertNotIn(v, res.stderr)
        self.assertIn("GALERA_RES=0", res.stdout)


BASH = "C:/Program Files/Git/bin/bash.exe" if os.path.isfile("C:/Program Files/Git/bin/bash.exe") else shutil.which("bash")


class TestShellScriptsIntegration(unittest.TestCase):
    """Tier 3: Cross-feature integration, canonical sourcing contracts, and dangling continuations."""

    def test_canonical_utils_sourcing_runtime_execution(self) -> None:
        if not BASH: self.skipTest("no bash")
        for t in ("utils.sh", "scripts/utils.sh"):
            self.assertEqual(subprocess.run([BASH, "-c", f'source {t} && [ "${{UTILS_IS_LOADED:-0}}" = "1" ]'], cwd=ROOT, capture_output=True, text=True).returncode, 0)

    def test_canonical_utils_exported_functions(self) -> None:
        if not BASH: self.skipTest("no bash")
        r = subprocess.run([BASH, "-c", "source utils.sh && type info warn warning sep2 title2 dump_timer"], cwd=ROOT, capture_output=True, text=True)
        self.assertEqual(r.returncode, 0)
        for f in ("info", "warn", "warning", "sep2", "title2", "dump_timer"): self.assertIn(f"{f} is a function", r.stdout)

    def test_no_dangling_sourcing_lines_in_bin_scripts(self) -> None:
        """Verify dockerrestore.sh and ssh_lgbackup.sh do not contain broken dangling '&& \\' lines (Finding 5)."""
        for script_rel in ("scripts/bin/dockerrestore.sh", "scripts/bin/ssh_lgbackup.sh"):
            script_path = ROOT / script_rel
            self.assertTrue(script_path.is_file(), f"{script_rel} must exist")
            content = script_path.read_text(encoding="utf-8", errors="ignore")

            # Must not contain dangling `[ -f .../utils.sh ] && \` without valid command continuation
            self.assertNotRegex(
                content,
                r"\[\s+-f\s+.*utils\.sh.*\]\s*&&\s*\\",
                f"{script_rel} contains broken dangling '&& \\' continuation line on utils.sh check",
            )

    def test_utils_no_recursive_sourcing(self) -> None:
        """Verify utils.pgsql.sh and utils.mongodb.sh do not recursively re-source utils.sh (Finding 10)."""
        for util_name in ("utils.pgsql.sh", "utils.mongodb.sh"):
            util_path = ROOT / "scripts" / "utils" / util_name
            if util_path.is_file():
                content = util_path.read_text(encoding="utf-8", errors="ignore")
                self.assertNotRegex(
                    content,
                    r"source\s+\$_DIR/utils\.sh",
                    f"{util_name} must not recursively source $_DIR/utils.sh",
                )

    def test_canonical_utils_consolidation(self) -> None:
        """Verify output/ directory is removed and scripts/utils.sh is canonical (Finding 13)."""
        output_dir = ROOT / "output"
        self.assertFalse(
            output_dir.exists(),
            "output/ directory must be deleted to eliminate redundant utility copies",
        )
        for root_script in ("ansible.sh", "git.sh", "is.sh", "jupyter.sh", "network.sh", "timer.sh"):
            self.assertFalse(
                (ROOT / root_script).exists(),
                f"Redundant root utility {root_script} must be deleted",
            )
        root_utils = ROOT / "utils.sh"
        self.assertTrue(root_utils.is_file(), "Root utils.sh wrapper must exist")
        root_utils_content = root_utils.read_text(encoding="utf-8")
        self.assertIn(
            "scripts/utils.sh",
            root_utils_content,
            "Root utils.sh must source scripts/utils.sh as a thin wrapper",
        )

    def test_dump_timer_deduplication(self) -> None:
        """Verify scripts/utils/utils.timer.sh has no duplicate dump_timer definitions (Finding 13)."""
        timer_script = ROOT / "scripts" / "utils" / "utils.timer.sh"
        self.assertTrue(timer_script.is_file(), "scripts/utils/utils.timer.sh must exist")
        content = timer_script.read_text(encoding="utf-8")
        matches = re.findall(r"^dump_timer\s*\(\)", content, re.MULTILINE)
        self.assertEqual(
            len(matches),
            1,
            f"dump_timer() must be defined exactly once, found {len(matches)}",
        )

    def test_scripts_utils_enriched_helpers(self) -> None:
        """Verify scripts/utils.sh defines warning(), sep2(), and title2() (Finding 13)."""
        utils_sh = ROOT / "scripts" / "utils.sh"
        self.assertTrue(utils_sh.is_file(), "scripts/utils.sh must exist")
        content = utils_sh.read_text(encoding="utf-8")
        for func in ("warning()", "sep2()", "title2()"):
            self.assertIn(
                func,
                content,
                f"scripts/utils.sh must define helper function {func}",
            )

    def test_utils_pgsql_lf_line_endings(self) -> None:
        """Verify scripts/utils/utils.pgsql.sh uses LF line endings, not CRLF (Finding 10)."""
        pgsql_script = ROOT / "scripts" / "utils" / "utils.pgsql.sh"
        self.assertTrue(pgsql_script.is_file(), "scripts/utils/utils.pgsql.sh must exist")
        raw = pgsql_script.read_bytes()
        self.assertNotIn(
            b"\r\n",
            raw,
            "scripts/utils/utils.pgsql.sh must have UNIX LF line endings without CRLF",
        )

    def test_canonical_utils_separators_and_titles_under_errexit_without_log_file(self) -> None:
        """Verify banner, sep1, sep2, title1, and title2 execute with RC 0 without TEE_LOG_FILE (Finding 1)."""
        if not BASH: self.skipTest("no bash")
        cmd = 'set -euo pipefail; unset TEE_LOG_FILE; source scripts/utils.sh; sep1; sep2; title1 "T1"; title2 "T2"; banner "TB"; echo "ALL_HELPERS_SUCCESS"'
        res = subprocess.run([BASH, "-c", cmd], cwd=ROOT, capture_output=True, text=True)
        self.assertEqual(res.returncode, 0, f"Helper failed under errexit: {res.stderr}")
        self.assertIn("ALL_HELPERS_SUCCESS", res.stdout)


class TestShellScriptsWorkflows(unittest.TestCase):
    """Tier 4: Real-world operational workflows (firewall deletion, LVM flags, cypher_file, PITR)."""

    def test_accept_client_scopes_input_chain(self) -> None:
        self.assertRegex((ROOT / "scripts" / "bin" / "accept_client.sh").read_text(encoding="utf-8", errors="ignore"), r"iptables\s+--list\s+INPUT\s+--line-numbers")

    def test_decypher_file_empty_zero_byte_safety(self) -> None:
        if not BASH: self.skipTest("no bash")
        c = "set -e; source scripts/utils/utils.system.sh; D=$(mktemp -d); trap 'rm -rf \"$D\"' EXIT; cd \"$D\"; touch e; echo pass123 > k; cypher_file e k e.enc && [ -f e.enc ] && [ ! -f e ]; decypher_file e.enc k r && [ -f r ] && [ ! -f e.enc ] && [ ! -s r ]; ! decypher_file r k r; echo bad > b; touch f; cypher_file f k f.enc && ! decypher_file f.enc b c && [ -f f.enc ] && [ ! -f c ]"
        self.assertEqual(subprocess.run([BASH, "-c", c], cwd=ROOT, capture_output=True, text=True).returncode, 0)

    def test_iptables_reverse_numerical_sort(self) -> None:
        """Verify accept_client.sh and accept_wsrep.sh sort rule_ids in reverse numerical order (Finding 9)."""
        for script_rel in ("scripts/bin/accept_client.sh", "scripts/bin/accept_wsrep.sh"):
            script_path = ROOT / script_rel
            self.assertTrue(script_path.is_file(), f"{script_rel} must exist")
            content = script_path.read_text(encoding="utf-8", errors="ignore")

            # Must contain sort -rn or sort -r -n when extracting rule_id
            self.assertTrue(
                bool(re.search(r"sort\s+(-rn|-r\s+-n|-n\s+-r)", content)),
                f"{script_rel} must sort iptables line numbers with reverse numerical sort (sort -rn)",
            )

    def test_lvm_create_logical_volume_flag_logic(self) -> None:
        """Verify createLogicalVolume in utils.system.sh uses -l for % and -L for fixed sizes (Finding 10)."""
        target = ROOT / "scripts" / "utils" / "utils.system.sh"
        self.assertTrue(target.is_file(), "scripts/utils/utils.system.sh must exist")
        content = target.read_text(encoding="utf-8", errors="ignore")

        # When grep "%" succeeds, lvcreate must use -l, NOT -L
        # Flag the inverted construct where % branch invokes lvcreate -L
        has_inverted_flag = bool(re.search(r'grep.*%.*?\n\s*then\s*\n\s*lvcreate\s+-L', content, re.DOTALL))
        self.assertFalse(
            has_inverted_flag,
            "createLogicalVolume erroneously uses -L when size contains %; LVM requires -l for percentage extents",
        )
        self.assertIn(
            "lvcreate",
            content,
            "utils.system.sh must contain lvcreate",
        )
        self.assertIn(
            'option="${lvfstype}    defaults        0       2"',
            content,
            "createLogicalVolume must initialize default mount option",
        )

    def test_cypher_file_pipeline_safety(self) -> None:
        """Verify cypher_file in utils.system.sh overwrites output (> not >>) and checks success (Finding 3)."""
        target = ROOT / "scripts" / "utils" / "utils.system.sh"
        self.assertTrue(target.is_file(), "scripts/utils/utils.system.sh must exist")
        content = target.read_text(encoding="utf-8", errors="ignore")

        # Must not append with >> $outFile
        self.assertNotRegex(
            content,
            r"\|\s*\$GZIP_CMD\s+>>\s+\$outFile",
            "cypher_file must overwrite output file with > instead of appending >>",
        )
        # Typo check
        self.assertNotIn(
            "ENCRPYTED_ALGORITHM",
            content,
            "utils.system.sh contains typo ENCRPYTED_ALGORITHM",
        )
        self.assertIn(
            "set -o pipefail",
            content,
            "utils.system.sh must enable pipefail in encryption pipeline",
        )
        self.assertIn(
            '-s "${outFile}"',
            content,
            "utils.system.sh must verify that outFile is non-empty before deleting inFile",
        )

    def test_pitr_restore_sorting_and_binlog_inclusion(self) -> None:
        """Verify pitr-restore.sh sorts chronologically and maria-pitr-restore.sh includes starting binlog (Finding 4)."""
        pitr = ROOT / "scripts" / "bin" / "pitr-restore.sh"
        self.assertTrue(pitr.is_file(), "scripts/bin/pitr-restore.sh must exist")
        pitr_content = pitr.read_text(encoding="utf-8", errors="ignore")
        # pitr-restore must NOT use `sort -n` on directory paths like ${BACKDIR}/base
        self.assertNotRegex(
            pitr_content,
            r"find\s+\$\{?BACKDIR\}?.*\|\s*sort\s+-n\s*\|",
            "pitr-restore.sh must not use 'sort -n' on directory path strings",
        )

        maria_pitr = ROOT / "scripts" / "bin" / "maria-pitr-restore.sh"
        self.assertTrue(maria_pitr.is_file(), "scripts/bin/maria-pitr-restore.sh must exist")
        maria_content = maria_pitr.read_text(encoding="utf-8", errors="ignore")
        # Must not use `sed "0,/$(basename $BINLOG_GTID_FILE)/d"` which drops the starting binlog
        self.assertNotRegex(
            maria_content,
            r'sed\s+"0,/.*BINLOG_GTID_FILE.*/d"',
            "maria-pitr-restore.sh must not drop starting binlog using sed 0,/.../d",
        )

    def test_backup_restore_cli_list_startup_under_set_e(self) -> None:
        """Verify CLI invocations -l on backup/restore scripts execute without crashing (Finding 1)."""
        if not BASH: self.skipTest("no bash")
        for s in ("mbbackup.sh", "mbrestore.sh", "lgbackup.sh", "lgrestore.sh"):
            p = ROOT / "scripts" / "bin" / s
            self.assertTrue(p.is_file(), f"{s} must exist")
            r = subprocess.run([BASH, p.as_posix(), "-l"], cwd=ROOT, capture_output=True, text=True)
            self.assertEqual(r.returncode, 0, f"CLI '{s} -l' crashed: {r.stderr}")


if __name__ == "__main__":
    unittest.main()
