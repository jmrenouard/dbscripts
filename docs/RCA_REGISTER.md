# RCA Register — Root Cause Analysis, Dead-Ends, Approximations & Ideas

> **Governance Rule ([`AGENTS.md`](../AGENTS.md) §4 & [`.agents/rules/project-governance.md`](../.agents/rules/project-governance.md))**:
> This living register documents all technical transparency items across 4 mandatory categories:
> 1. **Errors & Bugs Encountered (`RCA-XXX`)**: Root cause analysis and applied fixes.
> 2. **Technical Dead-Ends (`IMP-XXX`)**: Rejected technical directions with justification.
> 3. **Current Approximations (`APP-XXX`)**: Laboratory simplifications and heuristics.
> 4. **Unimplemented Ideas (`IDEA-XXX`)**: Future strategic proposals for the roadmap.

---

## 1. Errors & Bugs Encountered (`RCA-XXX`)

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

### IMP-001 — Monolithic Unversioned Script Collections Without Automated Regression
- **Abandoned Approach**: Accumulating independent bash scripts without standard syntax checks or automated test harnesses.
- **Technical & Security Justification**: Without automated test isolation and linting, scripts risk silent breakage when database versions advance (e.g. MariaDB 11.x, PostgreSQL 17/18, MySQL 9.x changes).
- **Adopted Pattern**: Modularized scripts with `set -euo pipefail`, explicit argument parsing, and structured test suites.

---

## 3. Current Approximations & Simplifying Assumptions (`APP-XXX`)

### APP-001 — Local Testing Defaults and Single-Host Simulation
- **Current Approximation**: Certain laboratory setups use default ports (e.g., `3306`, `5432`) and simulated multi-node topology on a single Docker or Vagrant host.
- **Impact & Scope**: Suitable for local automation development; production environments require distributed hosts, secrets management, and custom network routing.
- **Removal Condition**: Migration to distributed multi-node integration test harnesses.

---

## 4. Unimplemented Ideas & Strategic Roadmap (`IDEA-XXX`)

### IDEA-001 — Unified Multi-Database Automation Test Harness
- **Target Module**: `tests/` / `docker/`
- **Description**: Provide an automated multi-topology test runner executing syntax validation, container startup, data sync verification, and teardown across MariaDB, MySQL, PostgreSQL, MongoDB, and Cassandra.
- **Priority**: High
