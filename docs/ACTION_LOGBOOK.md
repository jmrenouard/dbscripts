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

_None._

---

## 2. Completed Actions (`COMPLETED`)

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
