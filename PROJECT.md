# Project: Ponytail Audit Remediation (`dbscripts`)

## Architecture
Multi-vendor database automation across MariaDB/Galera, MySQL, PostgreSQL, MongoDB, and Cassandra via Bash, Python, Ansible, and Docker.
- `scripts/`: Modular shell scripts by chapter (system, install, database, galera, bin, utils).
- `ansible/`: Ansible playbooks and reusable roles (`mysql_servers`, `mysql_cluster`, `mariadb_galera`).
- `docker/`: Docker Compose laboratory topologies and Python tooling (`mysql_docker.py`).
- `tests/`: Automated unit and syntax verification suites (`unittest`) enforcing code quality.
- `docs/`: Living governance registers (`ACTION_LOGBOOK.md`, `RCA_REGISTER.md`).

## Feature Inventory
| # | Feature / Finding | Description | Milestone | Status |
|---|-------------------|-------------|-----------|:------:|
| 1 | Mass Refactoring & `set -u` Fix | Sourcing canonical `utils.sh`, guarding variables under `set -u`, fixing typos | M3 | DONE |
| 2 | SSH Key & Credential Hygiene | Untrack SSH keypair, add `**/id_rsa*` to `.gitignore`, parameterize secrets | M1 | DONE |
| 3 | Safe Backup Encryption Pipeline | Fix `cypher_file` pipeline masking in `utils.system.sh`, overwrite `>`, require non-empty | M2 | DONE |
| 4 | MariaDB PITR Restore Corrections | Include starting binlog in `maria-pitr-restore.sh`, chronological `sort` in `pitr-restore.sh` | M4 | DONE |
| 5 | Dangling Utility Sourcing Lines | Fix dangling `[ -f ... ] && \` continuations in `dockerrestore.sh` and `ssh_lgbackup.sh` | M3 | DONE |
| 6 | Robust Replication Token Extraction | Make HashiCorp Vault token grep non-fatal in `synchro_repli_mariabackup_stream.sh` | M3 | DONE |
| 7 | Python Docker Manager Fixes | Fix `except e:`, alias password parameter, image preservation, `secrets.choice` | M4 | DONE |
| 8 | Ansible MySQL InnoDB Cluster Fixes | Move playbook to `ansible/`, fix role `mysql_servers`, add handlers/defaults | M4 | DONE |
| 9 | Reverse Numerical Firewall Deletion | Sort `rule_id` in reverse numerical order (`sort -rn`) in firewall deletion scripts | M2 | DONE |
| 10 | LVM Flag Inversion & Recursion | Swap `-L`/`-l` flags in `createLogicalVolume`, mount options, break recursive sourcing | M2 | DONE |
| 11 | Streaming MySQL Dump Splitters | Stream dump lines in splitters to prevent OOM; use collision-proof `_split` directory | M4 | DONE |
| 12 | Root Makefile Repair | Fix tab indentation on recipe lines, provide functional targets (`test`, `lint`, `clean`) | M1 | DONE |
| 13 | Canonical Utility Consolidation | Delete `output/`, remove root script duplicates, establish 2-line root `utils.sh` wrapper | M2 | DONE |
| 14 | Top-Level `MariaDB/` Consolidation | Move `MariaDB/` subtrees to `scripts/`, `ansible/`, `docker/`, and remove `MariaDB/` | M4 | DONE |
| 15 | AI Agent Configuration Cleanup | Delete orphaned prompts/specs/configs; harmonize rules in English | M1 | DONE |
| 16 | Repository Artifact Purge | Delete Nagios binary, `Init.ipynb`, reports, zero-byte files, duplicate docs, stubs | M1 | DONE |
| 17 | Automated Multi-Domain Test Suites | Comprehensive test suites in `tests/`: 5 modules, 49 tests (100% GREEN) | M5 | DONE |
| 18 | Helper Python Script Logic Fixes | Support `TiB`/`PiB` in `tree_s3.py`, pass `days_range` in `genere_csv.py`, add CLI arguments | M4 | DONE |

## Milestones
| Milestone | Description | Scope | Status |
|-----------|-------------|-------|:------:|
| M1 | Repo Hygiene & Secret Sanitization | Secrets, Makefile, AI prompts, artifact purge | DONE |
| M2 | Canonical Shell Utilities & System Scripts | utils consolidation, cypher_file, LVM, iptables | DONE |
| M3 | Shell Script Mass Sourcing & Variable Guards | 166 scripts sourcing, 54 set -u fixes, dangling lines | DONE |
| M4 | Python Tooling, Restore Engine & Ansible | PITR, Docker manager, Ansible cluster, splitters, tree | DONE |
| M4.1 | Batch M4.1: Python Tooling & PITR Engine | pitr-restore, splitters O(1), mysql_docker, helpers | DONE |
| M4.2 | Batch M4.2: Ansible Cluster & Scripts | Ansible InnoDB Cluster, 19 scripts to scripts/ | DONE |
| M4.3 | Batch M4.3: Docker Stacks & Pruning | Docker stacks, gen_ssl polish, MariaDB/ removal | DONE |
| M5 | Automated Test Suites & Quality Gates | Finding 17, Multi-Domain Tests, PR diffs < 15K | DONE |
| M5.1 | Batch M5.1: Ansible Structure Test Suite | test_ansible_structure.py, bash path fallback | DONE |
| M5.2 | Batch M5.2: Python Test Suites Promotion | test_python_docker.py, test_python_scripts.py | DONE |
| M5.3 | Batch M5.3: Test Infrastructure & Certification | TEST_INFRA.md, TEST_READY.md, PROJECT.md | DONE |

## Interface Contracts
- **Canonical Shell Utility** (`scripts/utils.sh`): Entry via `source scripts/utils.sh`; exports logging (`now`, `info`, `warn`, `error`, `die`), formatting (`sep1`, `sep2`, `title1`, `title2`), domain helpers (`to_lower`, `my_status`, `galera_is_enabled`), timers (`start_timer`, `dump_timer`). Scripts declare `set -euo pipefail` and guard positional parameters (`${1:-}`).
- **Encryption Pipeline** (`scripts/utils/utils.system.sh`): `cypher_file <inFile> [keyFile] [outFile]` overwrites `>` output and deletes `<inFile>` only upon pipeline RC 0 and non-empty output.
- **MySQL Splitter Streaming**: $O(1)$ memory streaming directly to gzip files without buffering lists in memory; outputs to `<file_base>_split/` avoiding directory collision.
- **Ansible MySQL InnoDB Cluster Role**: Playbook `ansible/playbook_innodb_cluster_group.yml` targets `mysql_servers` and `mysql_cluster` roles with verified handlers (`Restart mysql`) and defaults.

## Code Layout
- `scripts/`: Standalone CLI utilities (`scripts/bin/`) and canonical helpers (`scripts/utils/`, `scripts/utils.sh`).
- `ansible/`: Playbooks and reusable roles (`mysql_servers`, `mysql_cluster`).
- `docker/`: Laboratory compose stacks and `mysql_docker.py`.
- `tests/`: Automated Python `unittest` suites (`test_ansible_structure.py`, `test_project_governance_rules.py`, `test_python_docker.py`, `test_python_scripts.py`, `test_shell_scripts.py`).
- `docs/`: Living registers (`ACTION_LOGBOOK.md`, `RCA_REGISTER.md`).

