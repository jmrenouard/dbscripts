# RCA Register — Root Cause Analysis, Dead-Ends, Approximations & Ideas

> **Governance Rule ([`AGENTS.md`](../AGENTS.md) §4 & [`.agents/rules/project-governance.md`](../.agents/rules/project-governance.md))**:
> This living register documents all technical transparency items across 4 mandatory categories:
> 1. **Errors & Bugs Encountered (`RCA-XXX`)**: Root cause analysis and applied fixes.
> 2. **Technical Dead-Ends (`IMP-XXX`)**: Rejected technical directions with justification.
> 3. **Current Approximations (`APP-XXX`)**: Laboratory simplifications and heuristics.
> 4. **Unimplemented Ideas (`IDEA-XXX`)**: Future strategic proposals for the roadmap.

---

## 1. Errors & Bugs Encountered (`RCA-XXX`)

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

---

## 2. Technical Dead-Ends & Abandoned Leads (`IMP-XXX`)

### IMP-002 — Committing Static Credentials and Keys into Repository for Lab Convenience
- **Abandoned Approach**: Hardcoding static SSH keys, tokens, and passwords inside test docker-compose setups and cluster scripts.
- **Technical & Security Justification**: Static committed keys violate NIST SP 800-63 guidelines and create severe security exposure. Anyone cloning the repository gains access to instances using those keys.
- **Adopted Pattern**: On-demand dynamic key generation at runtime (`gen_ssl.sh`) and environment variable parameterization (`${VAR:-default}`) for local laboratories.

### IMP-001 — Monolithic Unversioned Script Collections Without Automated Regression
- **Abandoned Approach**: Accumulating independent bash scripts without standard syntax checks or automated test harnesses.
- **Technical & Security Justification**: Without automated test isolation and linting, scripts risk silent breakage when database versions advance (e.g. MariaDB 11.x, PostgreSQL 17/18, MySQL 9.x changes).
- **Adopted Pattern**: Modularized scripts with `set -euo pipefail`, explicit argument parsing, and structured test suites.

---

## 3. Current Approximations & Simplifying Assumptions (`APP-XXX`)

### APP-002 — Fallback Default Passwords for Non-Interactive Testing
- **Current Approximation**: Shell scripts provide fallback defaults when environment variables are unset (e.g., `${SEMAPHORE_ADMIN_PASSWORD:-changeme}`, `${SST_PASSWORD:-...}`).
- **Impact & Scope**: Prevents immediate script failure in automated local lab tests; production deployments must explicitly set strong environment variables or pass Vault secrets.
- **Removal Condition**: Transition to required secret injection via HashiCorp Vault or environment files across all deployment environments.

### APP-001 — Local Testing Defaults and Single-Host Simulation
- **Current Approximation**: Certain laboratory setups use default ports (e.g., `3306`, `5432`) and simulated multi-node topology on a single Docker or Vagrant host.
- **Impact & Scope**: Suitable for local automation development; production environments require distributed hosts, secrets management, and custom network routing.
- **Removal Condition**: Migration to distributed multi-node integration test harnesses.

---

## 4. Unimplemented Ideas & Strategic Roadmap (`IDEA-XXX`)

### IDEA-002 — Pre-Commit Secret Scanning Hook (Gitleaks / TruffleHog)
- **Target Module**: `.githooks/` / `.github/workflows/`
- **Description**: Add automated pre-commit hook and CI action scanning for private keys, high-entropy tokens, and passwords to prevent credential leakage before commits reach the remote repository.
- **Priority**: High

### IDEA-001 — Unified Multi-Database Automation Test Harness
- **Target Module**: `tests/` / `docker/`
- **Description**: Provide an automated multi-topology test runner executing syntax validation, container startup, data sync verification, and teardown across MariaDB, MySQL, PostgreSQL, MongoDB, and Cassandra.
- **Priority**: High
