---
trigger: always_on
description: Core execution rules and constraints for the Database Scripts Automation project.
category: governance
---
# 03_execution_rules.md

## 🧠 Rationale
To ensure consistency, reliability, security, and smooth code review across all database scripts, Ansible automation playbooks, and Docker test environments. Strict adherence to these rules prevents broken deployments, inconsistent naming, environment dependencies, and rejected Pull Requests.

## 🛠️ Implementation

### 1. Mandatory Testing
- Any new or modified database script, role, or topology MUST be tested locally before committing.
- Scripts must have syntax verification (`bash -n`, `ansible-lint`, or `python3 -m unittest`).

### 2. Naming Conventions & Organization
- Scripts: `scripts/<category>/<script_name>.sh`
- Playbooks: `ansible/playbooks/` and roles in `ansible/roles/`
- Documentation: English ONLY across all technical documents, comments, issues, and PRs.

### 3. Bash & Script Portability
- All bash scripts MUST use `set -euo pipefail`.
- Variables must always be quoted (`"$VAR"`).
- Explicit error handling: no silent masking of errors or swallowed failures.

### 4. Pull Request Size & Atomic Splitting
- Maximum PR diff size is strictly **15,000 characters** (`git diff main...HEAD | wc -c` < 15000).
- Large features or multi-database extensions must be split into atomic, sub-15K-character Pull Requests to pass review bots (Sourcery AI limit) and human review.

## ✅ Verification
- Run local unit and syntax test suites.
- Verify bash scripts adhere to `set -euo pipefail`.
- Run `git diff main...HEAD | wc -c` to confirm PR diff size < 15,000 characters before submitting PR.
