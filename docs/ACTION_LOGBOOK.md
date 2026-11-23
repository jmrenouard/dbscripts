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

### ACT-051 — test(scripts): add full script coverage and container contract suite (Issue `#102`, PR 6b)
- **Date**: 2026-11-23 | **Status**: COMPLETED | **Issue**: `#102` | **Branch**: `feat/issue-102-script-coverage-howto`
- **Request**: Add `tests/test_all_scripts_coverage.py` verifying discovery, LF line endings, syntax, `utils*.sh` sourcing, `docker/script_tests` contracts, and optional live Docker execution (`PR 6b`, split ahead of PR 6c docs/portal sync to stay `< 15,000` chars).
- **Changes**: Added `tests/test_all_scripts_coverage.py` (`3` test methods covering `>= 190` scripts, `8` `utils*.sh` libraries, `Dockerfile`/`run_all_script_tests.sh`/`Makefile` contracts, and `RUN_DOCKER_SCRIPT_TESTS=1`) and logged `APP-033`.
- **Result**: `unittest` (`68/68`, `0` skipped), `RUN_DOCKER_SCRIPT_TESTS=1` live container suite (`3/3`, `0` failed), `diataxis_check.py --strict --check-ste --lang en`, `mkdocs build --strict`, and `compileall` pass; diff `< 15,000` chars.

### ACT-050 — feat(docker): add Debian container script test harness (Issue `#100`, PR 6a)
- **Date**: 2026-11-23 | **Status**: COMPLETED | **Issue**: `#100` | **Branch**: `feat/issue-100-container-script-harness`
- **Request**: Add lightweight Debian Bookworm Slim container test harness (`docker/script_tests/{Dockerfile,run_all_script_tests.sh,Makefile}`) testing all scripts under `scripts/` (`PR 6a`).
- **Changes**: Added `docker/script_tests/Dockerfile` (`debian:bookworm-slim`, `python3-yaml`, non-root `tester`), `docker/script_tests/run_all_script_tests.sh` (`225` syntax, sourcing, Python smoke, Perl, and behavioral checks), and `docker/script_tests/Makefile` (`build`, `test`, `test-one`, `clean`); logged `APP-032` and `IDEA-017`.
- **Result**: `make -C docker/script_tests build && make -C docker/script_tests test` (`225/225` checks, `0 failed`), `unittest` (`65/65`, `0` skipped), `compileall`, `diataxis_check.py`, and `mkdocs build --strict` pass; diff `< 15,000` chars.

### ACT-049 — test(docs): enforce English-only docs and ban inline base64 images (Issue `#98`, PR 5b)
- **Date**: 2026-11-23 | **Status**: COMPLETED | **Issue**: `#98` | **Branch**: `test/issue-98-english-docs-guard`
- **Request**: Add a regression test in `tests/test_diataxis_documentation.py` scanning `docs/` (excluding `ACTION_LOGBOOK.md`/`RCA_REGISTER.md`) and `documentation/` for French prose phrases and `data:image/` inline base64 dumps (PR 5b).
- **Changes**: Added `DATA_IMAGE_RE`, `FRENCH_PROSE_RE`, and `test_docs_and_guides_english_only_and_no_base64_images` to `tests/test_diataxis_documentation.py`, and logged `RCA-040`.
- **Result**: `compileall`, `unittest` (`65/65`, `0` skipped), `diataxis_check.py --strict --check-ste --lang en`, and `mkdocs build --strict` pass; diff `< 15,000` chars.

### ACT-048 — docs(postgres): translate physical backup matrix and recommendations to English (Issue `#96`, PR 5a2)
- **Date**: 2026-11-23 | **Status**: COMPLETED | **Issue**: `#96` | **Branch**: `docs/issue-96-translate-backup-matrix`
- **Request**: Complete English translation of `documentation/PostgreSQL/backup_physique.md` (comparison matrix, physical vs. logical backups, and operational recommendations) while preserving the filename (PR 5a2, Pass 2b).
- **Changes**: Translated lines 43-87 of `documentation/PostgreSQL/backup_physique.md` into structured English (stripping remaining dangling citation suffixes) and logged `RCA-039`.
- **Result**: `compileall`, `unittest` (`64/64`, `0` skipped), `diataxis_check.py --strict --check-ste --lang en`, and `mkdocs build --strict` pass; diff `< 15,000` chars.

### ACT-047 — docs(postgres): translate physical backup overview and tool sections to English (Issue `#94`, PR 5a1)
- **Date**: 2026-11-23 | **Status**: COMPLETED | **Issue**: `#94` | **Branch**: `docs/issue-94-translate-backup-tools`
- **Request**: Translate the overview and physical backup tool architecture sections (`pg_basebackup`, `pgBackRest`, `WAL-G`, `pg_probackup`, `Barman`) of `documentation/PostgreSQL/backup_physique.md` into English (PR 5a1, Pass 2a).
- **Changes**: Translated lines 1-42 of `documentation/PostgreSQL/backup_physique.md` into structured English (stripping dangling citation numbers and preserving filename) and logged `RCA-038`.
- **Result**: `compileall`, `unittest` (`64/64`, `0` skipped), `diataxis_check.py --strict --check-ste --lang en`, and `mkdocs build --strict` pass; diff `< 15,000` chars.

### ACT-046 — docs(postgres): remove base64 images from physical backup guide (Issue `#92`, PR 4c)
- **Date**: 2026-11-23 | **Status**: COMPLETED | **Issue**: `#92` | **Branch**: `docs/issue-92-strip-backup-base64`
- **Request**: Replace `![][image1..4]` inline references with `RPO`, `RTO`, `PITR`, and `WAL`, and remove the 4 inline base64 PNG definitions from `documentation/PostgreSQL/backup_physique.md` (PR 4c, Pass 1b).
- **Changes**: Replaced `![][image1..4]` with plain acronyms and removed `[image1..4]: <data:image/png;base64,...>` definitions in `documentation/PostgreSQL/backup_physique.md`, and logged `RCA-037`.
- **Result**: `compileall`, `unittest` (`64/64`, `0` skipped), `diataxis_check.py --strict --check-ste --lang en`, and `mkdocs build --strict` pass; diff `< 15,000` chars.

### ACT-045 — docs(postgres): strip raw French citations from physical backup guide (Issue `#90`, PR 4b)
- **Date**: 2026-11-23 | **Status**: COMPLETED | **Issue**: `#90` | **Branch**: `docs/issue-90-strip-backup-citations`
- **Request**: Strip the 32 raw French search citation lines (`consulté le mai 6, 2026`) and `Sources des citations` heading from `documentation/PostgreSQL/backup_physique.md` (PR 4b, Pass 1a).
- **Changes**: Removed lines 89-122 from `documentation/PostgreSQL/backup_physique.md` (splitting base64 image removal into PR 4c to stay `< 15,000` chars) and logged `RCA-036`.
- **Result**: `compileall`, `unittest` (`64/64`, `0` skipped), `diataxis_check.py --strict --check-ste --lang en`, and `mkdocs build --strict` pass; diff `< 15,000` chars.

### ACT-044 — docs(postgres): rename WAL disk guide and translate to English (Issue `#88`, PR 4a)
- **Date**: 2026-11-23 | **Status**: COMPLETED | **Issue**: `#88` | **Branch**: `docs/issue-88-rename-translate-wal-disk`
- **Request**: Rename `documentation/PostgreSQL/perfromance_wal_disk.md` to `performance_wal_disk.md`, translate it to concise English, and update `documentation/README.md` line 40 (PR 4a).
- **Changes**: Renamed via `git mv`, translated `documentation/PostgreSQL/performance_wal_disk.md` into English (fixing escaped underscores inside code blocks), updated `documentation/README.md`, and logged `RCA-035`.
- **Result**: `compileall`, `unittest` (`64/64`, `0` skipped), `diataxis_check.py --strict --check-ste --lang en`, and `mkdocs build --strict` pass; diff `< 15,000` chars.

### ACT-043 — docs(postgres): rewrite PG sync guide as clean English technical spec (Issue `#86`, PR 3c)
- **Date**: 2026-11-23 | **Status**: COMPLETED | **Issue**: `#86` | **Branch**: `docs/issue-86-pg-sync-spec`
- **Request**: Rewrite `documentation/PostgreSQL/spec_sync_pg_databases.md` from a raw French AI prompt into a clean English technical specification verified against `scripts/bin/sync_pg_databases.sh` (PR 3c).
- **Changes**: Rewrote `documentation/PostgreSQL/spec_sync_pg_databases.md` documenting exact CLI flags (`-c`/`--config`, `-s`/`--source`, `-t`/`--target`, `-d`/`--database`), config variables, 6 pipeline stages, and audit behavior, and logged `RCA-034`.
- **Result**: `compileall`, `unittest` (`64/64`, `0` skipped), `diataxis_check.py --strict --check-ste --lang en`, and `mkdocs build --strict` pass; diff `< 15,000` chars.

### ACT-042 — docs(guides): translate Stunnel backup guide to English (Issue `#84`, PR 3b)
- **Date**: 2026-11-23 | **Status**: COMPLETED | **Issue**: `#84` | **Branch**: `docs/issue-84-translate-stunnel-guide`
- **Request**: Translate `documentation/LinuxSystem/README_STUNNEL.md` into English preserving all function names and command snippets (PR 3b).
- **Changes**: Translated `documentation/LinuxSystem/README_STUNNEL.md` into concise English and logged `RCA-033`.
- **Result**: `compileall`, `unittest` (`64/64`, `0` skipped), `diataxis_check.py --strict --check-ste --lang en`, and `mkdocs build --strict` pass; diff `< 15,000` chars.

### ACT-041 — docs(guides): translate SSHFS guide to English and remove stale docx (Issue `#82`, PR 3a)
- **Date**: 2026-11-23 | **Status**: COMPLETED | **Issue**: `#82` | **Branch**: `docs/issue-82-translate-sshfs-guide`
- **Request**: Translate `documentation/LinuxSystem/README_SSHFS.md` to English preserving all function names and command snippets, and remove stale `documentation/LinuxSystem/README_SSHFS.docx` (PR 3a).
- **Changes**: Translated `documentation/LinuxSystem/README_SSHFS.md` into concise English, deleted `documentation/LinuxSystem/README_SSHFS.docx` via `git rm`, and logged `RCA-032`.
- **Result**: `compileall`, `unittest` (`64/64`, `0` skipped), `diataxis_check.py --strict --check-ste --lang en`, and `mkdocs build --strict` pass; diff `< 15,000` chars.

### ACT-040 — chore(docs): clean .agent docs and enforce repo-wide markdown link tests (Issue `#80`, PR 2c)
- **Date**: 2026-11-23 | **Status**: COMPLETED | **Issue**: `#80` | **Branch**: `chore/issue-80-agent-docs-link-tests`
- **Request**: Clean stale `.agent/` refs and enforce repo-wide relative link, `file://` URI, and same-file anchor tests (PR 2c).
- **Changes**: Cleaned `.agent/{rules/{01_project_identity,04_best_practices},skills/documentation_engine,workflows/{doc-sync,hey-agent}}.md`, added `test_all_tracked_markdown_links_and_anchors`, and logged `RCA-031`.
- **Result**: `compileall`, `unittest` (`64/64`, `0` skipped), `diataxis_check.py --strict --check-ste --lang en`, and `mkdocs build --strict` pass; diff `< 15,000` chars.

### ACT-039 — fix(docs): harden legacy documentation shell scripts (Issue `#78`, PR 2b)
- **Date**: 2026-11-23 | **Status**: COMPLETED | **Issue**: `#78` | **Branch**: `fix/issue-78-harden-legacy-doc-scripts`
- **Request**: Harden `documentation/gen{ToC,AllToC,Readme,Sop}.sh` with LF line endings, `set -euo pipefail`, quoted variables, `mktemp` traps, GFM anchor punctuation stripping, Perl stdlib TOC replacement (no `File::Slurp`), `./` stripping, and English-only output (PR 2b).
- **Changes**: Hardened `documentation/genToC.sh`, `documentation/genAllToC.sh`, `documentation/genReadme.sh`, `documentation/genSop.sh`, and added `RCA-030`.
- **Result**: `bash -n`, LF checks, temp-dir execution of `genSop.sh`/`genAllToC.sh`/`genReadme.sh`/`genToC.sh`, `compileall`, `unittest` (`63/63`, `0` skipped), `diataxis_check.py --strict --check-ste --lang en`, and `mkdocs build --strict` pass; diff `< 15,000` chars.

### ACT-038 — docs(guides): fix broken anchors, headings, READMEs, and secret placeholders (Issue `#76`, PR 2a)
- **Date**: 2026-11-23 | **Status**: COMPLETED | **Issue**: `#76` | **Branch**: `docs/issue-76-fix-anchors-guides`
- **Request**: Fix Ansible Redis rotation vars, remove obsolete French links (`README_fr.md`, `INDEX_fr.md`), fix MariaDB README sub-headings and Galera CIDR, resolve 14 broken PostgreSQL anchors, replace weak Patroni example passwords with placeholders + warning, and update stale paths in `user_guide.md` and `generate_doc_description.md` (PR 2a).
- **Changes**: Updated `ansible/README.md`, `ansible/roles/mysql_cluster/README.md`, `docker/mariadb/README.md`, `docker/mariadb/documentation/{INDEX,architecture}.md`, `documentation/PostgreSQL/{etcd_install_ssl,patroni_config_rh,patroni_ha_tests,patroni_monitoring}.md`, `documentation/{user_guide,generate_doc_description}.md`, and `RCA-029`.
- **Result**: `compileall`, `unittest` (`63/63`, `0` skipped), `diataxis_check.py --strict --check-ste --lang en`, and `mkdocs build --strict` (`0` broken anchor warnings) pass; diff `< 15,000` chars.

### ACT-037 — fix(docs): fix Redis ACL vars, Reference ports/Makefile, banner, Changelog, and test counts (Issue `#74`, PR 1b)
- **Date**: 2026-11-23 | **Status**: COMPLETED | **Issue**: `#74` | **Branch**: `fix/issue-74-docs-accuracy-counts`
- **Request**: Fix Redis ACL password rotation vars, clarify HAProxy ports and `docker/mysql_replication/Makefile` targets, drop stale count from `header-banner.svg`, update `Changelog`, and sync `63` test count across portal docs (PR 1b).
- **Changes**: Updated `harden-firewall-tls-and-redis-acl.md`, `automation-parameters-and-ports.md`, `scripts-and-cli-reference.md`, `header-banner.svg`, `Changelog`, `README.md`, `docs/index.md`, `multi-db-automation-architecture.md`, and `RCA-028`.
- **Result**: `compileall`, `unittest` (`63/63`, `0` skipped), `ste_check.py --mode procedural`, `diataxis_check.py --strict --check-ste --lang en`, and `mkdocs build --strict` pass; diff `< 15,000` chars.

### ACT-036 — fix(docs): enable Material icons, CI triggers, and HTML rendering checks (Issue `#72`, PR 1a)
- **Date**: 2026-11-23 | **Status**: COMPLETED | **Issue**: `#72` | **Branch**: `fix/issue-72-docs-icons-ci`
- **Request**: Enable `pymdownx.emoji` Material icons in `mkdocs.yml`, add virtual README triggers to Docs CI/publish workflows, and enforce HTML SVG/shortcode/alert rendering checks in tests (PR 1a).
- **Changes**: Updated `mkdocs.yml` (`pymdownx.emoji` with `twemoji` and `to_svg`), `.github/workflows/{docs-ci,docs-publish}.yml` (`ansible/README.md`, `docker/mariadb/README.md` paths), `tests/test_mkdocs_publishing.py`, `tests/test_docs_publish_workflow.py`, and `RCA-027`.
- **Result**: `compileall`, `unittest` (`63/63`, `0` skipped), `mkdocs build --strict`, and `diataxis_check.py docs --strict --check-ste --lang en` pass; diff `< 15,000` chars.

### ACT-035 — ci(docs): add IONOS versioned MkDocs deployment workflow (Issue `#70`, PR 6b)
- **Date**: 2026-11-23 | **Status**: COMPLETED | **Issue**: `#70`
- **Request**: Add `.github/workflows/docs-publish.yml` (`verify-and-build` + `deploy-ionos` via SFTP) and `tests/test_docs_publish_workflow.py` (PR 6b).
- **Changes**: Added `.github/workflows/docs-publish.yml` (SHA-40 pinned actions, `sftp_only: true`, explicit `.htaccess` upload, live `curl` checks) and `tests/test_docs_publish_workflow.py` (3 `unittest` contract/security checks); updated `.github/workflows/docs-ci.yml` and `APP-031`.
- **Result**: `compileall`, bare `unittest` (`63/63`), and MkDocs venv `unittest` (`63/63`, `0` skipped) pass; diff `< 15,000` chars.

### ACT-034 — test(docs): add MkDocs publishing unit and E2E test suite (Issue `#68`, PR 6a)
- **Date**: 2026-11-23 | **Status**: COMPLETED | **Issue**: `#68`
- **Request**: Add `tests/test_mkdocs_publishing.py` and run it in `docs-ci.yml` (PR 6a).
- **Changes**: Added `tests/test_mkdocs_publishing.py` (5 `unittest` tests: `mkdocs.yml`, hooks, builder, `WORKTREE`+`v1.0.0` E2E); updated `docs-ci.yml` and `APP-030`.
- **Result**: `make lint`, bare `make test`, and MkDocs venv `unittest` (`60/60`, `0` skipped) pass; diff `< 15,000` chars.

### ACT-033 — ci(docs): add documentation CI workflow and Diataxis/Docs-as-Code test suite (Issue `#66`, PR 5b)
- **Date**: 2026-11-23 | **Status**: COMPLETED | **Issue**: `#66`
- **Request**: Add `.github/workflows/docs-ci.yml` and `tests/test_diataxis_documentation.py` validating quadrants, links, genre guardrails, and configs (PR 5b).
- **Changes**: Added `.github/workflows/docs-ci.yml` and `tests/test_diataxis_documentation.py` (`3` test methods); updated `ACTION_LOGBOOK.md` and `RCA_REGISTER.md`.
- **Result**: `mkdocs build --strict`, `diataxis_check.py --strict --check-ste --lang en`, `make lint`, and `make test` (`55/55` pass) succeed; diff `< 15,000` chars.

### ACT-032 — test(docs): add ASD-STE100 Issue 9 verifier and procedural test suite (Issue `#64`, PR 5a)
- **Date**: 2026-11-23 | **Status**: COMPLETED | **Issue**: `#64`
- **Request**: Add automated stdlib `unittest` verification for ASD-STE100 Issue 9 compliance across all How-To guides (PR 5a).
- **Changes**: Added `tests/test_diataxis_ste.py` (rule checks + positive/negative unit cases); updated `ACTION_LOGBOOK.md` and `RCA_REGISTER.md`.
- **Result**: `make lint` and `make test` (`52/52` pass) succeed; diff `< 15,000` chars.

### ACT-031 — docs(mkdocs): add mkdocs.yml navigation and README documentation portal links (Issue `#62`, PR 4b)
- **Date**: 2026-11-23 | **Status**: COMPLETED | **Issue**: `#62`
- **Request**: Configure `mkdocs.yml` Material navigation and add Documentation Portal badge/links to root `README.md` (PR 4b).
- **Changes**: Added `mkdocs.yml` (6 top nav tabs + virtual docs + `scripts/mkdocs_hooks.py`), updated `README.md`, `ACTION_LOGBOOK.md`, and `RCA_REGISTER.md`.
- **Result**: `mkdocs build --strict` (`1.75s`), `build_versioned_docs.py --main-ref WORKTREE --tags v1.0.0`, `diataxis_check.py --strict --check-ste --lang en`, `make lint`, and `make test` (49/49) pass; diff `< 15,000` chars.

### ACT-030 — docs(portal): add portal index, assets, styles, and Docs-as-Code configs (Issue `#60`, PR 4a)
- **Date**: 2026-11-23 | **Status**: COMPLETED | **Issue**: `#60`
- **Request**: Add `docs/index.md`, SVG branding, CSS/KaTeX assets, Docs-as-Code toolchain configs, and `.gitignore` updates (PR 4a).
- **Changes**: Added `docs/index.md`, `docs/assets/{logo,header-banner}.svg`, `docs/stylesheets/extra.css`, `docs/javascripts/katex.js`, `requirements-docs.txt`, `.vale.ini`, `.markdownlint.json`; updated `.gitignore`, `ACTION_LOGBOOK.md`, and `RCA_REGISTER.md`.
- **Result**: `diataxis_check.py docs --strict --check-ste --lang en` (`0` errors, `0` warnings across 18 files), `make lint`, and `make test` (49/49) pass; diff `< 15,000` chars.

### ACT-029 — docs(how-to): add ASD-STE100 How-To guides and database alert matrix (Issue `#58`, PR 3b)
- **Date**: 2026-11-23 | **Status**: COMPLETED | **Issue**: `#58`
- **Request**: Add 4 procedural STE How-To guides, database troubleshooting error matrix, and quadrant index updates (PR 3b).
- **Changes**: Created 4 `02-how-to-guides/` runbooks, `database-alert-and-error-matrix.md`, updated `02-how-to-guides/index.md`, `03-reference/index.md`, `ACTION_LOGBOOK.md`, and `RCA_REGISTER.md`.
- **Result**: `ste_check.py --mode procedural --lang en` (`0` errors, `0` warnings), `diataxis_check.py` (`0` broken links), `make lint`, and `make test` (49/49) pass; diff `< 15,000` chars.

### ACT-028 — docs(tutorials): add MariaDB Galera and MySQL Docker lab tutorials (Issue `#56`, PR 3a)
- **Date**: 2026-11-23 | **Status**: COMPLETED | **Issue**: `#56`
- **Request**: Add hands-on Diataxis tutorials for MariaDB Galera and MySQL Docker CLI sandboxes (PR 3a).
- **Changes**: Added `docs/01-tutorials/01-mariadb-galera-docker-lab.md`, `docs/01-tutorials/02-mysql-docker-cli-sandbox.md`, updated `docs/01-tutorials/index.md`, `ACTION_LOGBOOK.md`, and `RCA_REGISTER.md`.
- **Result**: `make lint`, `make test` (49/49), and `diataxis_check.py` (0 broken links) pass; diff `< 15,000` chars.

### ACT-027 — docs(diataxis): add quadrant indexes, reference matrices, and explanations (Issue `#54`, PR 2)
- **Date**: 2026-11-23 | **Status**: COMPLETED | **Issue**: `#54`
- **Request**: Add Diataxis quadrant indexes, Reference CLI/config tables, Architecture overview, and ADR-001 (PR 2).
- **Changes**: Created 8 Markdown files under `docs/01-tutorials/`..`docs/04-explanation/`; updated `ACTION_LOGBOOK.md` and `RCA_REGISTER.md`.
- **Result**: `make lint`, `make test` (49/49), and `diataxis_check.py` (0 broken links) pass; diff `< 15,000` chars.

### ACT-026 — feat(docs): add versioned MkDocs Material site builder (Issue `#52`, PR 1b)
- **Date**: 2026-11-23 | **Status**: COMPLETED | **Issue**: `#52`
- **Request**: Implement `scripts/build_versioned_docs.py` for multi-version IONOS Apache publishing (PR 1b).
- **Changes**: Added `scripts/build_versioned_docs.py` (`versions.json`, `.htaccess`, HTML redirects, safe zip extraction, private-file & protected-dir guards, snapshot overlays); added `APP-022`.
- **Result**: `make lint` and `make test` (49/49) pass; builder unit tests pass; diff `< 15,000` chars.

### ACT-025 — feat(docs): add MkDocs Material build hooks (Issue `#50`, PR 1a)
- **Date**: 2026-11-23 | **Status**: COMPLETED | **Issue**: `#50`
- **Request**: Provision IONOS secrets (`Step 0`) and add `scripts/mkdocs_hooks.py` (PR 1a).
- **Changes**: Set 5 IONOS secrets; added `scripts/mkdocs_hooks.py`; logged `APP-021`.
- **Result**: `make lint` and `make test` (49/49) pass; hook tests pass; diff `< 15,000` chars.

### ACT-024 — ci(release): add CI and release workflows, README badges, and tag v1.0.0
- **Date**: 2026-11-10 | **Status**: COMPLETED
- **Request**: Milestone 4: Add GitHub Actions CI workflow, release workflow bundling tarball with SHA256SUMS.txt, update README badges, and tag v1.0.0.
- **Changes**: Added `.github/workflows/ci.yml` and `.github/workflows/release.yml`; updated `README.md` with Release and CI badges; tagged initial release `v1.0.0`.
- **Result**: All 49 unit tests pass (100% green); verify_release_system.py passes 100% of M4 checks.

### ACT-023 — docs(cleanup): unify documentation in English and remove French duplicates (Issue #48)
- **Date**: 2026-11-01 | **Status**: COMPLETED | **Issue**: #48
- **Request**: Milestone C5 / R5: Purge 51 French docs, 2 obsolete assets, unify English index.
- **Changes**: Removed 51 *_fr.md files, 2 obsolete assets with git rm; added .gitattributes -diff rules; rewrote documentation/README.md; updated registers.
- **Result**: All 49 unit tests pass; compilation clean; PR diff < 15,000 chars; closes #48.


### ACT-022 — docs(ansible): consolidate playbook documentation into single README matrix (Issue `#46`)
- **Date**: `2026-11-01` | **Status**: `COMPLETED` | **Issue**: `#46`
- **Request**: Milestone C4 / Requirement R4: Consolidate 24 fragmented doc files (`ansible/doc_*.md` and `*_fr.md`) into a single English `ansible/README.md` matrix and usage guide, configure `.gitattributes` diff bounding, and remove doc files.
- **Changes**: Created `ansible/README.md` (15-playbook inventory matrix, layout, 4 workflow guides, test commands); removed 24 `ansible/doc_*.md` files via `git rm`; appended `ansible/doc_*.md -diff` to `.gitattributes`; updated `docs/ACTION_LOGBOOK.md` and `docs/RCA_REGISTER.md` (RCA-024, APP-019).
- **Result**: All 49 unit tests pass (100% green); compilation clean; PR diff < 15,000 characters; closes `#46`.


### ACT-021 — refactor(scripts): reorganize root scripts and purge non-DBMS sandboxes (Issue `#44`)
- **Date**: `2026-11-01` | **Status**: `COMPLETED` | **Issue**: `#44`
- **Request**: Milestone C3 / Requirement R3: Move single-file root dirs into scripts/bin/ (cassandra, oracle), purge non-DBMS applications (IA, drupal, odoo, n8n, wikijs, wordpress), configure .gitattributes diff bounding, and update README.md paths and authentic quickstart commands.
- **Changes**: Moved `cassandra/show_cql_grants.py` and `oracle/ora2mariadb.sh` to `scripts/bin/` with executable permissions and pruned empty root directories; purged non-DBMS sandboxes (`scripts/12_ia/`, Drupal, Odoo, `docker/n8n/`, `docker/wikijs/`, WordPress manifests and `web-service.yaml`) retaining only PostgreSQL in `docker/miniapps/`; added `.gitattributes` `-diff` rules for purged paths to bound PR diff size; updated `README.md` matrix paths and authentic quickstart commands (`make up-galera`, MySQL replication compose, PostgreSQL K8s manifest, `mysql_docker.py start/list/stop`); updated `docs/ACTION_LOGBOOK.md` and `docs/RCA_REGISTER.md` (RCA-023, APP-018).
- **Result**: All 49 unit tests pass (100% green); compilation passes with 0 errors; PR diff strictly under 15,000 characters.

### ACT-020 — docs(readme): rewrite README as structured English repository catalog (Issue `#42`)
- **Date**: `2026-11-01` | **Status**: `COMPLETED` | **Issue**: `#42`
- **Request**: Milestone C2 / Requirement R2: Rewrite root `README.md` as structured English repository catalog (~80–120 lines) documenting repository layout, multi-DBMS automation scripts, Docker labs, and test execution.
- **Changes**: Rewrote root `README.md` (90 lines) as structured catalog: repository architecture table (7 dirs), Multi-DBMS Automation Matrix (MariaDB/Galera, MySQL, PostgreSQL, MongoDB, Cassandra, Oracle), Docker lab quickstarts, and test commands (`make test`, `make lint`, `python -m unittest discover -s tests -v`); updated `docs/ACTION_LOGBOOK.md` and `docs/RCA_REGISTER.md` (RCA-022, IDEA-016).
- **Result**: All 49 unit tests pass (100% green); root README clean; PR diff strictly under 15,000 characters; merged to `main` via PR `#43`.

### ACT-019 — chore(root): clean root directory redundant governance files and directories (Issue `#40`)
- **Date**: `2026-10-31` | **Status**: `COMPLETED` | **Issue**: `#40`
- **Request**: Milestone C1 / Requirement R1: Clean repository root by removing 8 redundant governance and temporary files (`PROJECT.md`, `TEST_INFRA.md`, `TEST_READY.md`, `PLANNING.md`, `POTENTIAL_ISSUES.md`, `ROADMAP.md`, `03_execution_rules.md`, `04_best_practices.md`), prune empty directory `sys_result/`, preserve canonical rules in `.agent/rules/` and `utils.sh`, configure `.gitattributes` to bound deletion diff size, and update `tests/test_project_governance_rules.py`.
- **Changes**: Removed empty directory `sys_result/` from filesystem; created root `.gitattributes` with `-diff` directives for the 8 obsolete files to strictly bound PR diff size; removed 8 redundant files via `git rm`; preserved canonical `.agent/rules/03_execution_rules.md` and `04_best_practices.md`; updated `tests/test_project_governance_rules.py` to assert canonical rules and assert root `*.md` files are strictly `{"README.md", "AGENTS.md"}`; updated `docs/ACTION_LOGBOOK.md` and `docs/RCA_REGISTER.md` (RCA-021, APP-017 / APP-008).
- **Result**: All 49 unit tests pass (100% green); root directory clean; PR diff strictly under 15,000 characters; merged to `main` via PR `#41`.

### ACT-018 — docs(test): certify repository readiness and finalize project index (Issue `#38`)
- **Date**: `2026-10-31` | **Status**: `COMPLETED` | **Issue**: `#38`
- **Request**: M5.3b: Promote `TEST_READY.md` and `PROJECT.md` certifying 49/49 passing tests and completing Milestone M5.
- **Changes**: Promoted `TEST_READY.md` documenting 100% green certification across all 5 test modules; updated `PROJECT.md` marking M5 and all sub-batches DONE.
- **Result**: All 49 tests pass (100% green); zero untracked files on `main`; PR diff strictly < 15,000 characters.

### ACT-017 — docs(test): promote test infrastructure documentation (Issue `#36`)
- **Date**: `2026-10-31` | **Status**: `COMPLETED` | **Issue**: `#36`
- **Request**: M5.3a: Promote test infrastructure documentation (`TEST_INFRA.md`) to `main`.
- **Changes**: Promoted `TEST_INFRA.md` defining testing philosophy, 4-tier methodology, 18-finding coverage matrix, and CLI execution commands across all 5 test modules.
- **Result**: All 49 discovered unit tests pass (100% green); PR diff strictly < 15,000 characters.

### ACT-016 — feat: promote python CLI and helper scripts test suite (Issue `#34`)
- **Date**: `2026-10-31` | **Status**: `COMPLETED` | **Issue**: `#34`
- **Request**: M5.2b: Promote `tests/test_python_scripts.py` to git tracking on `main` (Findings 11, 16, 18).
- **Changes**: Promoted `tests/test_python_scripts.py` (10 tests: splitters O(1) streaming/collision, artifacts, S3 tree parsing, CSV days, mygenconf CLI args).
- **Result**: `tests/test_python_scripts.py` passes 10/10 tests; combined Python tests 14/14 pass; PR diff < 15,000 chars.

### ACT-015 — feat: promote python docker manager test suite (Issue `#32`)
- **Date**: `2026-10-31` | **Status**: `COMPLETED` | **Issue**: `#32`
- **Request**: M5.2a: Promote `tests/test_python_docker.py` into git tracking on `main` to verify Finding 7 (AST syntax validation, secrets generation, base image preservation, bash alias arguments) while keeping PR diff < 15,000 chars.
- **Changes**: Created `tests/test_python_docker.py` defining `TestPythonDockerManager` with 4 tests covering `mysql_docker.py` error handling, password generation via `secrets`, shared image preservation, and parameter passing.
- **Result**: `tests/test_python_docker.py` executes 4/4 passing tests in <0.02s; PR diff strictly < 15,000 characters.

### ACT-014 — feat: promote ansible structure test suite and portable bash detection (Issue `#30`)
- **Date**: `2026-10-31` | **Status**: `COMPLETED` | **Issue**: `#30`
- **Request**: M5.1: Promote `tests/test_ansible_structure.py` into git tracking on `main`, fix portable Git Bash detection in `tests/test_shell_scripts.py:20`.
- **Changes**: Promoted `tests/test_ansible_structure.py` (7 tests verifying Ansible playbooks, role layout, defaults, handlers, YAML validity); patched `tests/test_shell_scripts.py:20` to prefer `C:/Program Files/Git/bin/bash.exe` on Windows.
- **Result**: `tests/test_ansible_structure.py` (7/7 pass) and `tests/test_shell_scripts.py` (24/24 pass) execute cleanly; PR diff < 15,000 chars.


### ACT-013 — feat: docker mariadb stack consolidation part 2 (Issue `#28`)
- **Date**: `2026-10-31` | **Status**: `COMPLETED` | **Issue**: `#28`
- **Request**: M4.3 part 2: Move remaining 37 files to `docker/mariadb/`, polish `gen_ssl.sh`, prune `MariaDB/`.
- **Changes**: Moved 37 files to `docker/mariadb/`; pruned `MariaDB/`; hardened `gen_ssl.sh` (set -euo pipefail, serial 02, cleanup, chmod 600); added tests.
- **Result**: Unit tests pass, PR diff < 15,000 chars.


### ACT-012 — feat: docker tree consolidation part 1 (Issue `#26`)
- **Date**: `2026-10-31` | **Status**: `COMPLETED` | **Issue**: `#26`
- **Request**: M4.3 part 1: Docker stacks move (mysql_replication & documentation).
- **Changes**: Moved 21 files (`MariaDB/docker/mysql_replication/` and `documentation/` to `docker/`).
- **Result**: Tests pass, PR diff 7,997 chars (< 15,000 limit).



### ACT-011 — feat: ansible cluster architecture & scripts consolidation (Issue `#24`)
- **Date**: `2026-10-31` | **Status**: `COMPLETED` | **Issue**: `#24`
- **Request**: M4.2: Ansible Cluster & Scripts Consolidation (Findings 8 & 14).
- **Changes**: Moved playbook/doc to `ansible/`; added handlers/defaults; cleaned tasks; moved 19 scripts; guarded `private_ip`.
- **Result**: `test_ansible_structure.py` passes 7/7, PR diff < 15K chars.




### ACT-010 — feat: python docker manager security and cli helper utilities (Issue `#22`)
- **Date**: `2026-10-31` | **Status**: `COMPLETED` | **Issue**: `#22`
- **Request**: M4 Python fixes: secrets in mysql_docker, s3 TiB/PiB support, csv days_range, mygenconf args.
- **Changes**: Updated docker/mysql_docker.py, tree_s3.py, genere_csv.py, mygenconf_mysql.py.
- **Result**: test_python_scripts.py passes 14/14 tests, PR diff < 15,000 chars.

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
