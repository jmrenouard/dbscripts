# TEST_INFRA.md — Testing Infrastructure & Quality Gate Framework

## 1. Architecture & Scope
The `dbscripts` project provides multi-vendor database automation across MariaDB/Galera, MySQL/InnoDB Cluster, PostgreSQL, MongoDB, and Cassandra via Bash, Python, Docker, and Ansible.
This document defines the authoritative E2E and unit testing infrastructure, testing philosophy, 4-tier methodology, feature coverage mapping, and quality gates for the project.

---

## 2. Testing Philosophy
1. **Opaque-Box (Requirement-Driven) Verification**:
   - Tests assert observable external behavior, interface contracts, CLI parameter handling, output artifacts, pipeline exit codes, and error semantics rather than private internal implementation details.
   - Requirements and expected values derive authoritatively from `PROJECT.md`, `ORIGINAL_REQUEST.md`, and the 18 Ponytail Audit findings.
2. **Zero Facade Policy**:
   - Tests must exercise genuine logic, real syntax parsing, actual AST analysis, and isolated command executions.
   - Tests must never pass unconditionally or mock away the core behavior being evaluated.
3. **Strict Isolation & Idempotence**:
   - Tests execute in isolated temporary sandboxes (`tempfile.TemporaryDirectory`), leaving zero residual files or side effects on the host.
   - Tests must be independent of execution order.
4. **Multi-Environment Portability**:
   - All automated test suites use the Python standard library `unittest` framework to ensure native execution on Windows, Linux (EL9, Debian/Ubuntu), and containerized CI environments without third-party test framework dependencies.
   - Runner command: `python -m unittest discover -s tests -v`.

---

## 3. Four-Tier Testing Methodology

- **Tier 4: Real-World Scenarios & Workflows** (Firewall Reordering, LVM Mounts, PITR Binlog Chains, Governance)
- **Tier 3: Cross-Feature Integration Contracts** (Canonical Utils Sourcing, Playbook Handlers, Streaming)
- **Tier 2: Boundary, Corner Cases & Error Safety** (Guarded set -u, Collision-Proof Dirs, Pipeline Safety)
- **Tier 1: Feature Coverage & Syntax Compilation** (bash -n, py_compile, PyYAML Safe Load, CLI Parsing)


### Tier 1 — Feature Coverage & Syntax Compilation
- **Objective**: Ensure every source file, playbook, and script is syntactically valid and compiles cleanly before runtime.
- **Coverage**:
  - Shell scripts syntax compilation via `bash -n`.
  - Python scripts syntax compilation via `py_compile.compile(doraise=True)`.
  - Ansible playbooks and task files parsed via `yaml.safe_load`.
  - CLI argument definitions present in `argparse` for helper utilities (`mygenconf_mysql.py`, `tree_s3.py`, `genere_csv.py`, `mysql_docker.py`).

### Tier 2 — Boundary, Corner Cases & Error Handling Safety
- **Objective**: Validate system behavior at boundary limits, unexpected inputs, empty configurations, and failure conditions.
- **Coverage**:
  - Missing positional arguments under `set -u` (ensuring `${1:-}`, `${2:-}`, etc. are guarded).
  - Exception handling correctness (eliminating `except e:` syntax bugs and `UnboundLocalError` in container managers).
  - Directory collision avoidance in dump splitters (guaranteeing output directory does not collide with input dump file).
  - Size unit parsing at boundaries (`TiB`, `PiB`, `GiB`, `MiB`, `KiB`, `Bytes` in `tree_s3.py`).
  - Safe error masking prevention in backup encryption pipelines (`cypher_file`).
  - Non-fatal replication token extraction for unencrypted MariaDB deployments.

### Tier 3 — Cross-Feature Integration Contracts
- **Objective**: Verify that interconnected components adhere to shared interface contracts defined in `PROJECT.md`.
- **Coverage**:
  - Canonical utility library sourcing: all domain scripts source `scripts/utils.sh` rather than maintaining copy-pasted blocks.
  - Elimination of recursive utility sourcing (`utils.pgsql.sh`, `utils.mongodb.sh`).
  - Elimination of dangling multiline line continuations (`dockerrestore.sh`, `ssh_lgbackup.sh`).
  - Ansible role integration: playbook role references match actual role directories (`mysql_servers`), and all task notifications resolve to defined handlers.
  - Memory consumption contract: MySQL dump splitters stream line-by-line rather than buffering entire databases in RAM.

### Tier 4 — Real-World Operational Workflows
- **Objective**: Verify end-to-end operational procedures against production failure modes.
- **Coverage**:
  - Firewall rule deletion order: rules deleted in reverse numerical order (`sort -rn`) to prevent index shifting.
  - LVM volume provisioning: percentage allocations use `-l` and byte/size allocations use `-L`, with default mount options assigned.
  - PITR restore sequence: incremental backups sorted chronologically, and starting binlog files preserved during transaction replay.
  - Container environment cleanup: container removal does not delete shared base images or clobber unrelated aliases.
  - Project governance: Action Logbook, RCA Register, PR diff size limits, and bilingual documentation standards.

---

## 4. Feature Inventory & Test Coverage Matrix

| # | Finding / Feature | Tier | Test File | Key Test Anchor | Quality Threshold |
|---|-------------------|------|-----------|-----------------|-------------------|
| 1 | Mass Refactoring & `set -u` Guarding | Tier 1-4 | `tests/test_shell_scripts.py` | `test_unbound_variable_guarding_under_set_u` | All scripts pass `bash -n`; 0 unbound crashes under `set -u` |
| 2 | SSH Key & Credential Hygiene | Tier 2, 4 | `tests/test_shell_scripts.py` | `test_ssh_keys_untracked_and_gitignored` | 0 private keys tracked; `.gitignore` blocks `**/id_rsa*` |
| 3 | Safe Backup Encryption Pipeline | Tier 2, 4 | `tests/test_shell_scripts.py` | `test_cypher_file_pipeline_safety` | Fails safely on error; input preserved on failure; `>` overwrite |
| 4 | MariaDB PITR Restore Corrections | Tier 4 | `tests/test_shell_scripts.py` | `test_pitr_restore_sorting_and_binlog_inclusion` | Chronological incremental sort; starting binlog retained |
| 5 | Dangling Utility Sourcing Lines | Tier 3 | `tests/test_shell_scripts.py` | `test_no_dangling_sourcing_lines_in_bin_scripts` | Zero dangling `[ -f ... ] && \` continuations in bin scripts |
| 6 | Robust Replication Token Extraction | Tier 2, 3 | `tests/test_shell_scripts.py` | `test_synchro_repli_vault_token_non_fatal_extraction` | Unencrypted DB does not exit with code 1 during token grep |
| 7 | Python Docker Manager Fixes | Tier 1, 2, 4 | `tests/test_python_docker.py` | `test_mysql_docker_remove_environment_does_not_delete_shared_images` | No `except e:`; alias password passed; shared images preserved |
| 8 | Ansible MySQL InnoDB Cluster Fixes | Tier 1-3 | `tests/test_ansible_structure.py` | `test_innodb_cluster_playbook_location_and_role_name` | Valid YAML; roles aligned (`mysql_servers`); handlers present |
| 9 | Reverse Numerical Firewall Deletion | Tier 4 | `tests/test_shell_scripts.py` | `test_iptables_reverse_numerical_sort` | `accept_client.sh` and `accept_wsrep.sh` sort rule IDs `sort -rn` |
| 10 | LVM Flag Inversion & Recursion | Tier 2-4 | `tests/test_shell_scripts.py` | `test_lvm_create_logical_volume_flag_logic` | `-l` for `%` size, `-L` for fixed sizes; no recursive sourcing |
| 11 | Streaming MySQL Dump Splitters | Tier 2, 3 | `tests/test_python_scripts.py` | `test_mysqldump_splitters_streaming_memory_contract` | `<file>_split` prevents collision; streaming line-by-line |
| 12 | Root Makefile Repair | Tier 1 | `tests/test_shell_scripts.py` | `test_makefile_targets_and_tab_indentation` | Makefile recipes indented with tabs; `test`, `lint`, `clean` present |
| 13 | Canonical Utility Consolidation | Tier 3 | `tests/test_shell_scripts.py` | `test_canonical_utils_consolidation` | Single canonical `scripts/utils.sh`; no `output/`; deduplicated timer |
| 14 | Top-Level `MariaDB/` Consolidation | Tier 3 | `tests/test_shell_scripts.py` | `test_docker_tree_consolidation_and_gen_ssl` | Scripts in `scripts/`, playbooks in `ansible/`, docker in `docker/` |
| 15 | AI Agent Configuration Cleanup | Tier 1, 4 | `tests/test_project_governance_rules.py` | `test_governance_rules_inscribed_in_agents_and_rules_dir` | Harmonized English rules; orphaned prompts and specs deleted |
| 16 | Repository Artifact Purge | Tier 1, 2 | `tests/test_python_scripts.py` | `test_repository_clean_of_stale_binaries_and_stubs` | Zero 0-byte stubs, no Nagios binary, no stray notebook logs |
| 17 | Automated Multi-Domain Test Suites | Tier 1-4 | `tests/` | `test_all_ansible_yaml_files_are_valid` | Discoverable via `python -m unittest discover -s tests -v` |
| 18 | Helper Python Script Logic Fixes | Tier 1, 2 | `tests/test_python_scripts.py` | `test_tree_s3_parse_size_tib_and_pib` | `TiB`/`PiB` supported; dotless files parsed; CLI args parsed |

---

## 5. Test Execution & Quality Gates

### Test Execution Commands
```powershell
# Run the complete test suite
python -m unittest discover -s tests -v

# Run individual domain suites
python -m unittest tests/test_shell_scripts.py -v
python -m unittest tests/test_python_scripts.py -v
python -m unittest tests/test_python_docker.py -v
python -m unittest tests/test_ansible_structure.py -v
python -m unittest tests/test_project_governance_rules.py -v
```

### Quality Gate Pass Criteria
1. **Test Execution**: 100% of tests must pass for completed milestones.
2. **PR Diff Size Constraint**: PR diff size must strictly remain under 15,000 characters (`git diff main...HEAD | wc -c < 15000`).
3. **Governance Sync**: Every action, change, error, and result must be recorded in `docs/ACTION_LOGBOOK.md` and `docs/RCA_REGISTER.md`.
4. **No Regressions**: Existing `tests/test_project_governance_rules.py` must continuously pass.
