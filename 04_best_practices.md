---
trigger: always_on
description: Best practices for coding, testing, automation, and security in the Database Scripts Automation project.
category: governance
---
# 04_best_practices.md

## 🧠 Rationale
To maintain high code quality, standardized output formatting, clean test lifecycles, and safe execution across all supported database management scripts.

## 🛠️ Implementation

### 1. Automated vs. Manual Execution
- Prioritize automated, reproducible test scripts and playbooks over manual execution.
- Ensure robust error handling, status codes, and timeouts on remote SSH or Docker commands.

### 2. Idempotency & Clean Lifecycles
- Ensure Ansible tasks and bash scripts are idempotent.
- Clean up temporary files, dumps, and test containers after execution.

### 3. Security (Credentials & Least Privilege)
- NEVER hardcode secrets, passwords, or Personal Access Tokens (PAT) directly in repository files or scripts.
- Use environment variables or Ansible Vault for sensitive values.

### 4. Living Registers & Continuous Bot Review
- Keep `docs/ACTION_LOGBOOK.md` and `docs/RCA_REGISTER.md` continuously updated on every request, change, and result.
- Maintain redirection notices in `ROADMAP.md` and `POTENTIAL_ISSUES.md`.

## ✅ Verification
- Verify no secrets or credentials leaked in git diff.
- Run unit tests to confirm rule and governance compliance.
