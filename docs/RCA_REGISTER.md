# RCA Register — Root Cause Analysis, Dead-Ends, Approximations & Ideas

> **Governance Rule ([`AGENTS.md`](../AGENTS.md) §4 & [`.agents/rules/project-governance.md`](../.agents/rules/project-governance.md))**:
> This living register documents all technical transparency items across 4 mandatory categories:
> 1. **Errors & Bugs Encountered (`RCA-XXX`)**: Root cause analysis and applied fixes.
> 2. **Technical Dead-Ends (`IMP-XXX`)**: Rejected technical directions with justification.
> 3. **Current Approximations (`APP-XXX`)**: Laboratory simplifications and heuristics.
> 4. **Unimplemented Ideas (`IDEA-XXX`)**: Future strategic proposals for the roadmap.

---

## 1. Errors & Bugs Encountered (`RCA-XXX`)

### RCA-015 — RFC 5280 Serial Collision and Permissions in gen_ssl.sh
- **Observed Symptom**: Server/client certs had identical serial 01; private keys were 644; *.req missed *-req.pem.
- **Applied Fix**: Set -euo pipefail; client serial 02; rm *-req.pem; chmod 600 keys and 644 certs.
- **Non-Regression**: test_shell_scripts.py passes.


### RCA-014 — Ansible Role Naming Mismatch and Missing Handlers
- **Observed Symptom**: Playbook failed on mismatched `mysql_server`, missing `include_vars`, undefined handlers.
- **Applied Fix**: Aligned role to `mysql_servers`, moved playbook to `ansible/`, added handlers/defaults, cleaned tasks.
- **Non-Regression**: `test_ansible_structure.py` (7/7 pass).




### RCA-013 — Insecure Password Generation and Image Deletion in Docker Manager
- **Observed Symptom**: `mysql_docker.py` used non-cryptographic `random.choice`, crashed on `except e:`, and deleted base images.
- **Root Cause Analysis (5 Whys)**:
  1. *Why*: `random` is non-cryptographic; `except e:` is invalid in Python 3; base images were removed.
  2. *Why*: Script lacked `secrets` module and attempted to delete image on container teardown.
  3. *Why*: Container remove routine called `docker_client.images.remove` by default.
  4. *Why*: Subcommand `info` called `generate_bash_alias` with missing password argument.
  5. *Why*: No unit test suite existed for Python Docker management.
- **Applied Change / Fix**: Replaced with `secrets.choice`, `except Exception as e:`, removed image deletion, and passed password to alias generator.
- **Result & Non-Regression**: Verified by `test_mysql_docker_*` (4 tests pass OK).

### RCA-012 — Dump Splitter Directory Collision and High Memory Buffering
- **Observed Symptom**: mysqldump splitters collided on extensionless files and buffered multi-gigabyte dumps in memory lists causing out-of-memory errors.
- **Root Cause Analysis (5 Whys)**:
  1. *Why*: Large database dumps crashed splitter with Out Of Memory errors.
  2. *Why*: Scripts accumulated dump lines in a memory list (`db_content = []`) before writing to disk.
  3. *Why*: Memory-buffered write was used instead of streaming line-by-line to active file handles.
  4. *Why*: Output directory `os.path.splitext(file_path)[0]` stripped extension, colliding with input file on extensionless filenames.
  5. *Why*: No unit tests validated output collision safety or streaming memory contract.
- **Applied Change / Fix**: Set `output_folder = f"{file_path}_split"` and streamed lines directly to active `gzip.open` file handles.
- **Result & Non-Regression**: Verified by `test_mysqldump_splitters_output_dir_collision_prevention` and `test_mysqldump_splitters_streaming_memory_contract`.

### RCA-011 — MariaDB PITR Restore Chronological Sorting and GTID Binlog Deletion Bug
- **Observed Symptom**: `pitr-restore.sh` used `sort -n` misordering ISO directory names; `maria-pitr-restore.sh` used `sed '0,/pattern/d'` deleting starting binlog with `GTID_EXECUTED`.
- **Root Cause Analysis (5 Whys)**:
  1. *Why*: Incremental binary logs were skipped or misordered during PITR.
  2. *Why*: `sort -n` treats alphabetic prefixes as 0; `sed '0,/pattern/d'` deletes up to match.
  3. *Why*: `GTID_EXECUTED` position is in starting binlog; deleting it breaks GTID continuity.
  4. *Why*: Scripts lacked parameter guards (`${1:-}`, `${2:-}`) under `set -u`.
  5. *Why*: No unit tests validated chronological order or GTID binlog retention.
- **Applied Change / Fix**: Changed `sort -n` to lexicographical `sort`, added `|| true`, replaced `sed '0,/pattern/d'` with `sed -n "/\$(basename \"\$BINLOG_GTID_FILE\")/,\$p"`, and guarded parameters (`${1:-}`, `${TARGET_CONFIG}`).
- **Result & Non-Regression**: Verified by `test_pitr_restore_sorting_and_binlog_inclusion` and `test_unbound_variable_guarding_under_set_u`.

### RCA-004 — Silent Data Loss and Pipeline Failure Masking in Backup Encryption
- **Observed Symptom**: In `scripts/utils/utils.system.sh`, `cypher_file` piped `cat | openssl | gzip >> $outFile` and followed with `[ $? -eq 0 ] && rm -f $inFile`. When `openssl` failed (invalid key, corrupt cipher), without `pipefail`, `$?` returned the exit code of `gzip` (0), causing the unencrypted original source file to be permanently deleted with zero bytes of ciphertext written. Furthermore, repeated runs appended `>>` rather than overwrote `>`.
- **Root Cause Analysis (5 Whys)**:
  1. *Why*: The unencrypted backup was deleted even though encryption failed.
  2. *Why*: Shell pipeline exit code masking returned exit status of the final command in the pipe (`gzip`), not `openssl`.
  3. *Why*: `set -o pipefail` was not enabled inside the encryption routine.
  4. *Why*: The script did not verify that `$outFile` was created and non-empty (`[ -s "$outFile" ]`).
  5. *Why*: The routine used append `>>` and had typo `ENCRPYTED_ALGORITHM` with uninitialized `$GZIP_CMD`.
- **Applied Change / Fix**: Enabled `set -o pipefail`, changed redirect to overwrite `>`, initialized default `GZIP_CMD="${GZIP_CMD:-gzip}"`, corrected typo to `ENCRYPTED_ALGORITHM`, and required `${rc} -eq 0 && [ -s "${outFile}" ]` before removing `$inFile`.
- **Result & Non-Regression**: Verified by unit test `test_cypher_file_pipeline_safety`.

### RCA-005 — Ascending `iptables` Line Index Deletion Shifting Bug
- **Observed Symptom**: Running `scripts/bin/accept_client.sh` or `scripts/bin/accept_wsrep.sh` skipped target firewall rules and deleted unrelated rules in live iptables chains.
- **Root Cause Analysis (5 Whys)**:
  1. *Why*: Rules targeted for deletion remained in the table while other rules were deleted.
  2. *Why*: When an `iptables` rule is deleted by index (e.g. index 2), all subsequent rules shift down by 1 in the kernel table (former index 3 becomes index 2, former index 4 becomes index 3).
  3. *Why*: The loop processed rule indices in ascending numerical order (`2, 4, 6`).
  4. *Why*: Deleting index 2 shifted index 4 to index 3; the next loop iteration deleted index 4 (which was formerly index 5), skipping the intended rule and deleting an unintended rule.
  5. *Why*: The pipeline lacked reverse sorting (`sort -rn`).
- **Applied Change / Fix**: Added `| sort -rn` to rule extraction in `accept_client.sh` and `accept_wsrep.sh` so deletions occur from highest index to lowest, preserving index stability.
- **Result & Non-Regression**: Verified by unit test `test_iptables_reverse_numerical_sort`.

### RCA-002 — Committed Private SSH Keypair and Hardcoded Secrets in Git
- **Observed Symptom**: Real OpenSSH private RSA key and public key tracked in git under `MariaDB/docker/mariadb/id_rsa`, with plaintext SST and root passwords committed in shell scripts and docker-compose files.
- **Root Cause Analysis (5 Whys)**:
  1. *Why*: Lab containers required SSH connectivity for Galera SST replication.
  2. *Why*: Keys were pre-generated and checked in during initial repository setup instead of dynamically generated.
  3. *Why*: Root `.gitignore` lacked global patterns for `**/id_rsa*` and `*.key`.
  4. *Why*: Shell scripts hardcoded passwords rather than reading from environment variables.
  5. *Why*: No secret scanning gate was in place to block commits with private key signatures.
- **Applied Change / Fix**: Untracked `id_rsa` and `id_rsa.pub` via `git rm --cached`, added `**/id_rsa*`, `*.key`, and `*.pem` to `.gitignore`, added SSH key generation helper to `gen_ssl.sh`, and parameterized all script secrets via environment variable fallbacks (`${SST_PASSWORD:-...}`, `${MYSQL_PWD:-...}`).
- **Result & Non-Regression**: Private keys untracked from git index, ignored by `git check-ignore`, and verified by unit test `test_ssh_keys_untracked_and_gitignored`.

### RCA-003 — Root Makefile Syntax Failure (Missing Separator & Subdir Recurse)
- **Observed Symptom**: Executing `make` failed immediately with `Makefile:7: *** missing separator. Stop.` and attempted to recurse into folders without Makefiles.
- **Root Cause Analysis (5 Whys)**:
  1. *Why*: Line 7 in `Makefile` used 8 spaces instead of a tab character for the rule recipe.
  2. *Why*: The root Makefile used `$(wildcard */.)` which recursed into documentation, tests, and scripts that lack Makefiles.
  3. *Why*: No standard targets (`test`, `lint`, `clean`) existed at the repository root.
- **Applied Change / Fix**: Replaced spaces with tabs, removed broken recursive wildcard, and added standard root targets `all`, `test`, `lint`, and `clean` powered by cross-platform Python commands.
- **Result & Non-Regression**: Root Makefile has proper tab indentation and executes test suite cleanly.

### RCA-001 — Missing Governance Framework and Standardized Registers
- **Observed Symptom**: Repository lacked living action tracking, standardized error registers, and PR diff size limits, leading to potential inconsistency with modern repository governance standards.
- **Root Cause Analysis (5 Whys)**:
  1. *Why*: The repository was created before the standardized English governance framework was adopted across the ecosystem.
  2. *Why*: Individual feature scripts were developed without centralized rule hooks.
  3. *Why*: No unified agent guidelines existed to enforce PR diff ceilings and living registers.
- **Applied Change / Fix**: Integrated `AGENTS.md`, `.agents/rules/project-governance.md`, `docs/ACTION_LOGBOOK.md`, and `docs/RCA_REGISTER.md` with redirection pointers in `ROADMAP.md`, `POTENTIAL_ISSUES.md`, and `PLANNING.md`.
- **Result & Non-Regression**: Automated unit tests in `tests/test_project_governance_rules.py` validate rule files and living registers.

### RCA-006 — Fatal Shell Exit Sourcing Utilities
- **Observed Symptom**: `source utils.sh` exited with 127 (`is: not found`).
- **5 Whys RCA**: `utils.pgsql.sh:2732` called `exit $?` on missing `is`.
- **Applied Fix**: Removed exit block, converted `is` to POSIX tests.
- **Non-Regression**: `test_canonical_utils_sourcing_runtime_execution`.

### RCA-007 — Plaintext Deletion Decrypting 0-Byte Files
- **Observed Symptom**: Decrypting valid 0-byte ciphertext exited 1.
- **5 Whys RCA**: `decypher_file` checked `[ -s ]`, purging 0-byte output.
- **Applied Fix**: Changed `[ -s ]` to `[ -f ]`, added collision guards.
- **Non-Regression**: `test_decypher_file_empty_zero_byte_safety`.

### RCA-008 — Shell Script Sourcing Failures and Syntax Interrupts
- **Observed Symptom**: Sourcing `scripts/utils.sh` aborted on environments where `/etc` does not exist due to unguarded `readlink -f`. In addition, 5 shell scripts failed `bash -n` compilation due to truncated while loops and unescaped quotes.
- **5 Whys RCA**: `utils.sh` called `readlink -f` without checking file existence; scripts in `1_system`, `4_sandbox`, `7_postgres`, and `bin/mbrestore.sh` had syntax truncation.
- **Applied Fix**: Added `[ -f "$_CONF_FILE" ]` guard in `utils.sh`; closed truncated loops in `reboot_and_wait.sh` and `update_and_reboot.sh`; fixed quotes in `8_redis.sh` and `3_install_agent_filebeat.sh`; cleaned duplicate `case` in `ssh_xtrabackup_tar_replication_setup.sh`; removed orphaned `fi` in `mbrestore.sh`.
- **Non-Regression**: `test_all_shell_scripts_pass_bash_syntax_check` (193/193 pass).

### RCA-009 — Shell Parameter Expansion Unbound Crash & Bracket Typo
- **Observed Symptom**: `mbbackup.sh:83` crashed with `[-f: command not found`; backup/restore scripts aborted on unguarded `$1` under `set -u`.
- **5 Whys RCA**: Missing space between `[` and `-f`; positional and environment parameters referenced bare instead of default expansion.
- **Applied Fix**: Fixed `[ -f` space in `mbbackup.sh`; guarded `${1:-}`, `${TARGET_CONFIG:-}`, `${2:-}` across `mbbackup.sh`, `mbrestore.sh`, `lgbackup.sh`, `lgrestore.sh`.
- **Non-Regression**: `test_mbbackup_typo_bracket_spacing`.

### RCA-010 — Errexit in Shell Utils and Unbound Module Variables
- **Observed Symptom**: `banner` aborted under `set -e` when `TEE_LOG_FILE` was unset; `my_status` and `galera_is_enabled` crashed with unbound variable errors under `set -u`.
- **5 Whys RCA**: `sep1()` evaluated `[ -n "${TEE_LOG_FILE:-}" ]` as last command, returning 1; `SSH_CMD` was referenced bare; ping pipelines lacked error tolerance.
- **Applied Fix**: Appended `return 0` to separators; initialized default `SSH_CMD`; guarded `${SSH_CMD:-}` and `${2:-}`; captured ping `|| true`; bound `TARGET_CONFIG=$(to_lower "${1:-}")`.
- **Non-Regression**: Verified by 3 regression tests in `tests/test_shell_scripts.py`.

---

## 2. Technical Dead-Ends & Abandoned Leads (`IMP-XXX`)

### IMP-003 — Duplicate Stale Output Trees and Inverted LVM Allocation Syntax
- **Abandoned Approach**: Maintaining duplicate utility scripts under `output/` alongside root utility stubs and using inverted `-L` for percentage sizing in LVM allocation.
- **Technical & Security Justification**: In LVM, `-l` requires logical extents (e.g. `100%FREE`), while `-L` expects byte sizes (`10G`). Inverting these options causes `lvcreate` to fail immediately on volume provisioning. Furthermore, keeping unmaintained copies of libraries in `output/` and root leads to version drift, circular dependencies, and debugging overhead.
- **Adopted Pattern**: Canonical modular hierarchy under `scripts/utils/` with a thin 2-line wrapper at root `utils.sh`, and explicit regex matching to route `%` to `-l` and byte sizes to `-L`.

### IMP-002 — Committing Static Credentials and Keys into Repository for Lab Convenience
- **Abandoned Approach**: Hardcoding static SSH keys, tokens, and passwords inside test docker-compose setups and cluster scripts.
- **Technical & Security Justification**: Static committed keys violate NIST SP 800-63 guidelines and create severe security exposure. Anyone cloning the repository gains access to instances using those keys.
- **Adopted Pattern**: On-demand dynamic key generation at runtime (`gen_ssl.sh`) and environment variable parameterization (`${VAR:-default}`) for local laboratories.

### IMP-001 — Monolithic Unversioned Script Collections Without Automated Regression
- **Abandoned Approach**: Accumulating independent bash scripts without standard syntax checks or automated test harnesses.
- **Technical & Security Justification**: Without automated test isolation and linting, scripts risk silent breakage when database versions advance (e.g. MariaDB 11.x, PostgreSQL 17/18, MySQL 9.x changes).
- **Adopted Pattern**: Modularized scripts with `set -euo pipefail`, explicit argument parsing, and structured test suites.

### IMP-004 — Static String Tests for Sourced Libraries
- **Abandoned**: Testing sourcing via regex / `bash -n` only.
- **Justification**: Misses runtime exit aborts during shell sourcing.
- **Adopted Pattern**: Subshell runtime tests via `subprocess.run([bash, "-c", ...])`.

### IMP-005 — Monolithic Single-PR Shell Mass Refactoring
- **Abandoned**: Refactoring all 166 shell scripts in a single pull request.
- **Justification**: Exceeds the 15,000 character PR diff ceiling mandated by governance rules (`AGENTS.md`).
- **Adopted Pattern**: Staged sub-batches with targeted unit test coverage per batch.

### IMP-006 — Inlined Fallback Functions Instead of Canonical Return Codes
- **Abandoned**: Duplicating safe function stubs locally inside each binary.
- **Justification**: Reintroduces duplicate boilerplate and leads to library drift.
- **Adopted Pattern**: Canonical modular utilities with explicit `return 0` and default variable expansions (`${VAR:-}`).

### IMP-007 — Numerical Sorting and Address Deletion in PITR Pipelines
- **Abandoned**: Using `sort -V` or `sed '1,/pattern/d'` for binary log filtering.
- **Justification**: `sort -V` is non-POSIX. `sed '1,/pattern/d'` drops starting binlog. POSIX `sed -n '/pattern/,$p'` preserves GTID continuity.

### IMP-008 — In-Memory Buffering of Large Dumps in Splitter Utilities
- **Abandoned**: Loading entire database contents into memory lists before gzip compression.
- **Justification**: Causes out-of-memory errors on large dumps. Direct streaming to gzip handles operates in O(1) memory.

### IMP-009 — Docker Image Teardown in Local Management Scripts
- **Abandoned**: Deleting base Docker images (`docker_client.images.remove`) during environment cleanup.
- **Justification**: Base images (e.g., `mysql:8.0`) are shared across containers; deleting them forces costly re-downloads.

### IMP-010 — Monolithic MariaDB/ Tree Consolidation
- **Abandoned**: Moving 79 files in one PR. Staged into M4.2 and M4.3.

### IMP-011 — Two-Part Partitioning of Docker Tree Consolidation
- **Abandoned**: Attempting to move all 58 Docker files in a single PR (diff exceeded 16,400 chars).
- **Justification**: 58 file renames produce 13,809 characters, leaving insufficient headroom for registers. Staged into M4.3a (21 files, ~7,997 chars) and M4.3b (37 files, ~9,500 chars) ensuring both PR diffs stay strictly < 15,000 characters.







---

## 3. Current Approximations & Simplifying Assumptions (`APP-XXX`)

### APP-003 — Local Default Service Endpoints Without Credentials in Utilities
- **Current Approximation**: Modular database utilities (`utils.mongodb.sh`, `utils.pgsql.sh`, `utils.mysql.sh`) default to local loopback URIs (`mongodb://localhost:27017`, `127.0.0.1:3306`) without requiring strict authentication parameters at source time.
- **Impact & Scope**: Allows scripts to be loaded into interactive shells or test harnesses without failing or prompting for passwords during initial library loading.
- **Removal Condition**: Dedicated configuration loaders reading secrets and endpoints from environment files or Vault tokens at command execution time.

### APP-002 — Fallback Default Passwords for Non-Interactive Testing
- **Current Approximation**: Shell scripts provide fallback defaults when environment variables are unset (e.g., `${SEMAPHORE_ADMIN_PASSWORD:-changeme}`, `${SST_PASSWORD:-...}`).
- **Impact & Scope**: Prevents immediate script failure in automated local lab tests; production deployments must explicitly set strong environment variables or pass Vault secrets.
- **Removal Condition**: Transition to required secret injection via HashiCorp Vault or environment files across all deployment environments.

### APP-001 — Local Testing Defaults and Single-Host Simulation
- **Current Approximation**: Certain laboratory setups use default ports (e.g., `3306`, `5432`) and simulated multi-node topology on a single Docker or Vagrant host.
- **Impact & Scope**: Suitable for local automation development; production environments require distributed hosts, secrets management, and custom network routing.
- **Removal Condition**: Migration to distributed multi-node integration test harnesses.

### APP-004 — Network Interface Fallback
- **Approximation**: `scripts/utils/utils.network.sh` warns on missing `ip` on non-Linux hosts.
- **Impact & Scope**: Benign warning in local dev; Linux environments have `ip`.
- **Removal Condition**: Guard network discovery with `command -v ip`.

### APP-005 — Staged Utility Sourcing Migration
- **Approximation**: Phase 1 migrates critical `scripts/bin/` scripts to canonical `utils.sh`, with subsequent batches covering secondary utilities.
- **Impact & Scope**: Core backup and replication binaries use canonical sourcing; remaining scripts use isolated utilities.
- **Removal Condition**: Full migration of all shell scripts across subsequent milestones.

### APP-006 — Graceful Service Health Check Fallbacks
- **Approximation**: `my_status` and `galera_is_enabled` report stopped when mysqld is unreachable rather than failing with fatal script aborts.
- **Impact & Scope**: Prevents CLI scripts and test harnesses from crashing unexpectedly on cold nodes.
- **Removal Condition**: Formal health-check daemon reporting node state via unix socket.

### APP-007 — Incremental Directory Discovery via Find Fallback
- **Approximation**: `pitr-restore.sh` searches for incremental directories using `find ... | sort || true` to prevent `pipefail` errors when no incrementals exist.
- **Impact & Scope**: Prevents script crash when restoring full backups without incremental chains.
- **Removal Condition**: Catalog-based restore metadata verification.

### APP-008 — Line-by-Line Splitter Parsing Heuristic
- **Approximation**: Splitters identify database and table boundaries using standard SQL comment prefixes (`-- Current Database:`, `-- Table structure`).
- **Impact & Scope**: Supports standard mysqldump and mariadb-dump outputs.
- **Removal Condition**: Full SQL AST grammar parser.

### APP-009 — AST and Regex Inspection for Docker Commands
- **Approximation**: Unit tests inspect AST and source code without requiring a running Docker daemon.
- **Impact & Scope**: Ensures multi-platform test execution on local dev and CI.
- **Removal Condition**: Full Docker daemon E2E test harness.

### APP-010 — Default Node IP Fallback in Galera Bootstrap
- **Approximation**: `5_bootstrap_node.sh` falls back to `my_private_ipv4` if `private_ip` is unset.

### APP-011 — Static Inspection of gen_ssl.sh
- **Approximation**: Validates script flags/permissions without live CA generation.




---


## 4. Unimplemented Ideas & Strategic Roadmap (`IDEA-XXX`)

### IDEA-003 — Automated Shell Cryptography Pipeline and Netfilter Mutation Testing
- **Target Module**: `tests/` / `scripts/utils/`
- **Description**: Add dedicated automated integration tests that mock `openssl` failure modes (e.g. invalid password, corrupt input, missing entropy) to assert that original files are preserved and corrupt ciphertexts are cleaned up, as well as mock netfilter kernel rule tables to assert reverse index stability during flush routines.
- **Priority**: Medium

### IDEA-002 — Pre-Commit Secret Scanning Hook (Gitleaks / TruffleHog)
- **Target Module**: `.githooks/` / `.github/workflows/`
- **Description**: Add automated pre-commit hook and CI action scanning for private keys, high-entropy tokens, and passwords to prevent credential leakage before commits reach the remote repository.
- **Priority**: High

### IDEA-001 — Unified Multi-Database Automation Test Harness
- **Target Module**: `tests/` / `docker/`
- **Description**: Provide an automated multi-topology test runner executing syntax validation, container startup, data sync verification, and teardown across MariaDB, MySQL, PostgreSQL, MongoDB, and Cassandra.
- **Priority**: High

### IDEA-004 — Multi-Shell Runtime CI Matrix
- **Target Module**: `.github/workflows/`
- **Description**: Run test suite across Bash versions and dash/sh in CI.
- **Priority**: Medium

### IDEA-005 — Automated ShellCheck Linting in CI
- **Target Module**: `.github/workflows/` / `tests/`
- **Description**: Integrate ShellCheck AST analysis into GitHub Actions matrix to prevent syntax truncation and unquoted variable regressions.
- **Priority**: High

### IDEA-006 — Subshell Environment Isolation Harness
- **Target Module**: `tests/` / `scripts/`
- **Description**: Subshell tests validating all 193 shell scripts under strict `set -euo pipefail`.
- **Priority**: High

### IDEA-007 — Automated PITR Multi-Node Verification Harness
- **Target Module**: `tests/` / `scripts/bin/`
- **Description**: Add Docker-based verification harness that provisions primary DB, executes transactions, creates backup, injects writes, and validates `maria-pitr-restore.sh`.
- **Priority**: High

### IDEA-008 — Parallel Multi-Core Dump Splitter Engine
- **Target Module**: `scripts/bin/`
- **Description**: Multiprocessing dump splitter to decompress, parse, and recompress tables concurrently across CPU cores.
- **Priority**: Medium

### IDEA-009 — Ephemeral Containerized Database Testing Harness
- **Target Module**: `docker/` / `tests/`
- **Description**: Add pytest fixtures running lightweight containerized MySQL/MariaDB instances with ephemeral ports.
- **Priority**: High
### IDEA-010 — Molecule Testing for MySQL and Galera Clusters
- **Description**: Molecule test scenarios for MySQL/Galera roles.

### IDEA-011 — Automated TLS Handshake Verification in Docker
- **Description**: Container mutual TLS handshake test for generated certificates.



