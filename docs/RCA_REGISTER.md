# RCA Register — Root Cause Analysis, Dead-Ends, Approximations & Ideas

> **Governance Rule ([`AGENTS.md`](../AGENTS.md) §4 & [`.agents/rules/project-governance.md`](../.agents/rules/project-governance.md))**:
> This living register documents all technical transparency items across 4 mandatory categories:
> 1. **Errors & Bugs Encountered (`RCA-XXX`)**: Root cause analysis and applied fixes.
> 2. **Technical Dead-Ends (`IMP-XXX`)**: Rejected technical directions with justification.
> 3. **Current Approximations (`APP-XXX`)**: Laboratory simplifications and heuristics.
> 4. **Unimplemented Ideas (`IDEA-XXX`)**: Future strategic proposals for the roadmap.

---

## 1. Errors & Bugs Encountered (`RCA-XXX`)

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
