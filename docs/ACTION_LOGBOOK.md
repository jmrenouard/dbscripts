# Action Logbook & Strategic Roadmap — Database Scripts Automation

> **Governance Rule ([`AGENTS.md`](../AGENTS.md) §3 & [`.agents/rules/project-governance.md`](../.agents/rules/project-governance.md))**:
> This Action Logbook **MUST be systematically updated on every request, every change, and every result**:
> - New requests are logged under **"1. Ongoing Actions (`IN PROGRESS`)"** as soon as a GitHub Issue is opened.
> - Once validated by unit tests and merged via Pull Request, entries are completed with **Changes** and **Result** under **"2. Completed Actions (`COMPLETED`)"**.

---

## 🗺️ Strategic Roadmap & Milestones

### Phase 1 — Governance, Quality Standards & Rule Framework (Status: `In Progress 🔄`)
- [x] Inscribe English governance framework, PR diff ceiling (< 15K chars), and mandatory GitHub workflow in `AGENTS.md` and `.agents/rules/`.
- [x] Consolidate `ROADMAP.md` and `PLANNING.md` into this Action Logbook.
- [x] Consolidate `POTENTIAL_ISSUES.md` into unified RCA Register at `docs/RCA_REGISTER.md`.
- [x] Establish automated unit tests for governance rules and registers (`tests/test_project_governance_rules.py`).

### Phase 2 — Multi-Database Script Harmonization (Status: `Planned 📋`)
- [ ] Audit and standardize error handling (`set -euo pipefail`) across all shell scripts in `scripts/`.
- [ ] Modernize and validate Ansible playbooks for PostgreSQL, MySQL, and MariaDB.
- [ ] Add idempotency checks and syntax validation in pre-commit/CI pipelines.

### Phase 3 — Automated Laboratory & E2E Testing (Status: `Planned 📋`)
- [ ] Implement Docker-based test environments for multi-node database validation.
- [ ] Set up GitHub Actions CI workflow to run test suites on PRs.
- [ ] Add HTML reporting and execution summaries.

---

## 1. Ongoing Actions (`IN PROGRESS`)

*None currently in progress.*

---

## 2. Completed Actions (`COMPLETED`)

### ACT-009 — feat: dump splitters collision prevention and streaming contract (Issue `#20`)
- **Date**: `2026-10-31` | **Status**: `COMPLETED` | **Issue**: `#20`
- **Request**: M4 Splitters: collision-safe directory names and O(1) streaming in mysqldump splitters.
- **Changes**: Updated mysqldump_database_splitter.py and mysqldump_table_splitter.py to stream to gzip.
- **Result**: test_mysqldump_splitters_* pass, PR diff < 15,000 chars.

### ACT-008 — feat: shell pitr restore engine and parameter guards (Issue `#18`)
- **Date**: `2026-10-31` | **Status**: `COMPLETED` | **Issue**: `#18`
- **Request**: M4 Shell fixes: PITR chronological sort, binlog inclusion; parameter guards under `set -u`.
- **Changes**: Parameter guards (`${1:-}`, `${TARGET_CONFIG}`, `${doit:-0}`), `sort` order, `sed -n "/pattern/,\$p"`, `cut` vs `awk`.
- **Result**: `test_shell_scripts.py` passes 23/23 tests, PR diff < 15,000 chars.

### ACT-007 — fix: errexit in shell utils and parameter guarding (M3 Remediation) (Issue `#16`)
- **Date**: `2026-10-31T04:10+01:00` | **Status**: `COMPLETED` | **Issue**: `#16`
- **Request**: M3 Remediation: fix errexit in `utils.sh` separators; guard `SSH_CMD` and `$2` in `utils.mysql.sh`; bind `TARGET_CONFIG` in `mbbackup.sh`/`mbrestore.sh`; guard options in `ssh_xtrabackup_tar_replication_setup.sh`; add 3 tests.
- **Changes**: Updated `utils.sh`, `utils.mysql.sh`, 5 `scripts/bin` scripts, and `tests/test_shell_scripts.py`.
- **Result**: Regression tests pass, governance rules pass, PR diff strictly < 15,000 chars.

### ACT-006 — feat: shell script mass sourcing and variable guarding (M3.1 Batch 2) (Issue `#14`)
- **Date**: `2026-10-31T03:22+01:00` | **Status**: `COMPLETED` | **Issue**: `#14`
- **Request**: M3.1 Batch 2: standardize canonical sourcing (`_DIR=...; source .../utils.sh`) in `mbbackup.sh`, `mbrestore.sh`, `lgbackup.sh`, `lgrestore.sh`; resolve typo `[-f` in `mbbackup.sh:83`; guard unbound variables under `set -u` (`${1:-}`, `${TARGET_CONFIG:-}`, `${2:-}`).
- **Changes**: Refactored `scripts/bin/mbbackup.sh`, `scripts/bin/mbrestore.sh`, `scripts/bin/lgbackup.sh`, `scripts/bin/lgrestore.sh` to remove 30-line boilerplate and use canonical utils with guarded parameters.
- **Result**: `test_mbbackup_typo_bracket_spacing` PASS, syntax check PASS across all 193 scripts, PR diff < 15,000 chars.

### ACT-005 — feat: shell script mass sourcing and syntax fixes (M3.1 Batch 1) (Issue `#12`)
- **Date**: `2026-10-31T03:10+01:00` | **Status**: `COMPLETED` | **Issue**: `#12`
- **Request**: M3.1 Batch 1: safe config check in `scripts/utils.sh`, repo-wide syntax fixes in `reboot_and_wait.sh`, `update_and_reboot.sh`, `8_redis.sh`, `3_install_agent_filebeat.sh`, `mbrestore.sh`, remove dangling continuations in `dockerrestore.sh` & `ssh_lgbackup.sh`, safe Vault token grep in `synchro_repli_mariabackup_stream.sh`, duplicate case cleanup in `ssh_xtrabackup_tar_replication_setup.sh`.
- **Changes**: Updated `scripts/utils.sh`, 4 system/sandbox/postgres scripts, 5 bin scripts (`dockerrestore.sh`, `ssh_lgbackup.sh`, `synchro_repli_mariabackup_stream.sh`, `ssh_xtrabackup_tar_replication_setup.sh`, `mbrestore.sh`).
- **Result**: `test_all_shell_scripts_pass_bash_syntax_check` passes 193/193 scripts (100% OK), targeted safety/integration tests pass, PR diff < 15,000 chars.

### ACT-004 — fix: canonical utils sourcing and decryption edge cases (Issue `#10`)
- **Date**: `2026-10-31T01:45+01:00` | **Status**: `COMPLETED` | **Issue**: `#10`
- **Request**: M2 Remediation: resolve sourcing abort in `utils.pgsql.sh`, replace `is`, fix 0-byte decryption, add collision guards, scope `accept_client.sh:36`.
- **Changes**: Fixed `utils.pgsql.sh` (deleted lines 2732-2737, 2754, 2756-2761); updated `utils.system.sh` (collision guards, `[ -f ]`, `is()` shim); scoped `accept_client.sh:36`; replaced `is` in `dockerrestore.sh`; added tests.
- **Result**: 16 M2 tests pass (100% OK), PR diff < 15,000 chars.

### ACT-003 — fix: canonical shell utilities consolidation, encryption pipeline safety and system scripts repair (Issue `#8`)
- **Date**: `2026-10-31T00:50+01:00` | **Status**: `COMPLETED` | **Issue**: `#8`
- **Request**: Milestone M2 remediation covering:
  - Finding 13: Purge redundant `output/` directory, remove root utility duplicates (`git.sh`, `network.sh`, `timer.sh`, `is.sh`, `ansible.sh`, `jupyter.sh`), replace root `utils.sh` with a thin 2-line wrapper sourcing `scripts/utils.sh`, deduplicate `dump_timer()` in `scripts/utils/utils.timer.sh`, enrich `scripts/utils.sh` with `warning()`, `sep2()`, and `title2()`.
  - Finding 3: Secure `cypher_file` and `decypher_file` in `scripts/utils/utils.system.sh` (enable `set -o pipefail`, overwrite `>` instead of append `>>`, check non-empty output `[ -s "$outFile" ]` before deleting input file, fix algorithm typo `ENCRPYTED_ALGORITHM`, initialize `GZIP_CMD` fallback).
  - Finding 10: Invert `-L` and `-l` flags in `createLogicalVolume` (`-l` for extents/percentage, `-L` for fixed sizes), default initialize mount `option`, remove recursive sourcing in `scripts/utils/utils.pgsql.sh` and `scripts/utils/utils.mongodb.sh`, convert `utils.pgsql.sh` CRLF to LF, and remove noisy greeting in `utils.mongodb.sh`.
  - Finding 9: Reverse numerical sort `rule_id` (`sort -rn`) in `scripts/bin/accept_client.sh` and `scripts/bin/accept_wsrep.sh` to prevent iptables index shifting bug.
- **Changes**:
  - Deleted `output/` directory and root utility files `git.sh`, `network.sh`, `timer.sh`, `is.sh`, `ansible.sh`, `jupyter.sh`.
  - Replaced root `utils.sh` with a thin wrapper sourcing `scripts/utils.sh`.
  - Deduplicated `dump_timer()` in `scripts/utils/utils.timer.sh`.
  - Enriched `scripts/utils.sh` with `warning()`, `sep2()`, `title2()`.
  - Secured `cypher_file` and `decypher_file` in `scripts/utils/utils.system.sh`.
  - Fixed LVM flag assignment (`-l` vs `-L`) and mount options in `createLogicalVolume`.
  - Removed recursive sourcing in `scripts/utils/utils.pgsql.sh` and `scripts/utils/utils.mongodb.sh`, normalized `utils.pgsql.sh` to LF, and removed noisy load messages from `utils.mongodb.sh`.
  - Added `sort -rn` in `scripts/bin/accept_client.sh` and `scripts/bin/accept_wsrep.sh`.
  - Extended unit tests in `tests/test_shell_scripts.py` covering all Milestone M2 features.
- **Result**: Automated unit tests pass for all M2 features (`tests.test_shell_scripts`), bash syntax checks clean across all modified scripts, PR diff character count strictly under 15,000 characters.

### ACT-002 — chore: repository hygiene, makefile repair and secret sanitization (Issue `#6`)
- **Date**: `2026-10-31T00:15+01:00` | **Status**: `COMPLETED` | **Issue**: `#6`
- **Request**: Milestone M1 remediation covering Finding 2 (untrack SSH keypair from git, update .gitignore, add on-the-fly SSH keygen in gen_ssl.sh, parameterize passwords/tokens across docker-compose and shell scripts), Finding 12 (fix root Makefile tab indentation, add working test/lint/clean targets), Finding 15 (remove orphaned AI prompt layers in .github/prompts, SPECIFICATIONS, TEST_SPECIFICATIONS, MariaDB/docker/mariadb/.agent, MEMORY.json; harmonize 05_documentation_standards.md with English standard; preserve root rules for test compliance), and Finding 16 (purge 20 dead/bloat artifacts including Nagios binary check_mysql_health, notebooks/Init.ipynb, reports, 3 zero-byte files, duplicate README_NFS.md, and 12 1-line MongoDB stubs).
- **Changes**:
  - Untracked `MariaDB/docker/mariadb/id_rsa` and `id_rsa.pub` and added `**/id_rsa*`, `*.key`, `*.pem` to `.gitignore`.
  - Added on-demand SSH keypair generator helper in `MariaDB/docker/mariadb/gen_ssl.sh`.
  - Parameterized committed secrets via environment variables in `docker/semaphore/docker-compose.yml`, `MariaDB/scripts/8_galera/6_start_new_node.sh`, `MariaDB/scripts/8_galera/5_bootstrap_node.sh` (fixed typo `//mysqetcl/` and added `warn`), `MariaDB/scripts/10_proxy/9_agent_haproxy.sh`, `scripts/bin/my_diff_schema.sh`, `scripts/4_sandbox/12_zabbix_agent_mysql.sh`, and `scripts/bin/sysbench.sh`.
  - Repaired root `Makefile` with standard tab indentation and cross-platform recipes for `test`, `lint`, and `clean`.
  - Removed orphaned AI configuration directories `.github/prompts/`, `SPECIFICATIONS/`, `TEST_SPECIFICATIONS/`, `MariaDB/docker/mariadb/.agent/`, and `MariaDB/docker/mariadb/MEMORY.json`.
  - Harmonized `.agent/rules/05_documentation_standards.md` to English documentation standards while retaining root `03_execution_rules.md` and `04_best_practices.md`.
  - Purged 20 dead/bloat artifacts: compiled Nagios binary `check_mysql_health`, `notebooks/Init.ipynb`, test reports in `MariaDB/docker/mariadb/reports/`, 3 zero-byte files (`extract_record_counts.py`, `extract_users.py`, `postgresql_backup.sh`), duplicate `README_NFS.md`, and 12 1-line MongoDB stubs.
- **Result**: Automated tests pass (`python -m unittest tests/test_project_governance_rules.py -v`), SSH key leakage resolved, Makefile functional, diff within limit (< 15,000 characters).


### ACT-001 — feat: integrate CIS Benchmarks governance framework, action logbook, and RCA register (Issue `#3`)
- **Date**: `2026-10-30T23:25+01:00` | **Status**: `COMPLETED` | **Issue**: `#3`
- **Request**: Integrate CIS Benchmarks dev rules and governance framework into `dbscripts`, harmonize roadmap and potential issues into living registers (`docs/ACTION_LOGBOOK.md` and `docs/RCA_REGISTER.md`), add redirection notices in `ROADMAP.md`, `POTENTIAL_ISSUES.md`, and `PLANNING.md`, and verify via unit tests.
- **Changes**:
  - Created `AGENTS.md` and `.agents/AGENTS.md` enforcing English governance, PR diff limit (< 15,000 chars), and systematic GitHub lifecycle.
  - Created `.agents/rules/project-governance.md`, `.agents/rules/git-workflow.md`, and `.agents/rules/github-workflow.md`.
  - Created `03_execution_rules.md` and `04_best_practices.md`.
  - Created `docs/ACTION_LOGBOOK.md` and `docs/RCA_REGISTER.md`.
  - Created `ROADMAP.md`, `POTENTIAL_ISSUES.md`, and updated `PLANNING.md` as redirection pointers.
  - Created `tests/test_project_governance_rules.py` covering all governance assertions.
- **Result**: Unit tests pass (4/4 tests), PR diff < 15,000 characters.
