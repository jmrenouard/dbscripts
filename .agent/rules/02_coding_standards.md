---
trigger: always_on
description: Unified coding standards for Ansible, Docker, Bash, and Python.
category: governance
---
# 02 - Coding Standards

## 🧠 Rationale

Consistent code is maintainable code. Given the diversity of technologies in `dbscripts`, we need strict but pragmatic standards to ensure interoperability and stability.

## 🛠️ Implementation

### 🛠️ Ansible Standard (Molecule Focus)

- **Modularity**: Use roles for discrete functions (e.g., `mariadb_galera`).
- **Target OS**: Prioritize EL9 (Rocky Linux 9) and RHEL UBI 9.4.
- **Testing**: Every major role MUST have a `molecule/` test suite.
- **Variable Scoping**: Use descriptive prefixes for role variables (e.g., `mariadb_galera_port`).
- **Idempotency**: Playbooks must be runnable multiple times without changing state unless necessary.
- **Fail-Safe**: Use `service_facts` patterns that are Docker-aware (avoiding systemd/tuned issues in non-privileged containers).

### 🐳 Docker Standard

- **Slimness**: Prefer `-slim` or Alpine-based images where appropriate, unless binary compatibility requires GLIBC.
- **Orchestration**: Standardize on `docker-compose.yml` for multi-node labs.
- **Persistence**: Database data must always be mapped to external volumes.
- **Network**: Explicitly define bridge networks for inter-container communication (e.g., Galera nodes).

### 📜 Bash / Shell Standard

- **Headers**: ALWAYS include `set -euo pipefail`.
- **Utilities**: Leverage `utils.sh` or `scripts/utils.sh` for common functions.
- **Safe Exit**: Use `trap` to clean up temporary files on exit.
- **Validation**: Validate that required binaries (e.g., `mysql`, `psql`, `ansible`) are available before proceeding.
- **Variables**: Use `${VAR}` syntax for all variables.
- **Idempotency**: Check for state before execution (e.g., `[ -f /path/to/file ] || touch /path/to/file`).

### 🐍 Python Standard

- **Version**: Target Python 3.9+ (native to EL9).
- **Isolation**: Always use `venv` or `molecule`'s internal isolation.
- **Style**: Adhere to PEP 8 standards. Use Python type hints for clarity.
- **Exception Handling**: Avoid generic `except: pass`. Log specific errors and fail gracefully.
- **Logging**: Use the `logging` module instead of `print` for structured output.

## ✅ Verification

- Run `ansible-lint` on Ansible roles.
- Run `shellcheck` on Bash scripts.
- Ensure `molecule test` passes for new infrastructure components.
