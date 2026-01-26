---
trigger: always_on
description: Mandatory constraints and execution protocols.
category: governance
---
# 03 - Execution Rules (Constraints)

## 🧠 Rationale

To prevent regressions and security incidents, certain operational constraints are non-negotiable. This document codifies these barriers.

## 🛠️ Implementation

### 🛡️ Credential Hygiene

- **Zero Hardcoding**: NEVER commit passwords, API keys, or SSH private keys. Use environment variables or vaulted files.
- **Metadata Sanitization**: Ensure that generated reports (HTML/Log) do not leak sensitive infrastructure metadata (e.g., public IPs, private keys).

### ☢️ The "Nuclear" Option (State Recovery)

- When a file or state becomes fragmented (e.g., partially failed Ansible play or corrupted Docker state), do not attempt minor patch-ups.
- **Protocol**: Perform a Full Block Reset or Environment Re-injection to ensure 100% consistency.

### 📜 Command Safety

- **No Path Guessing**: Always use absolute paths for file operations.
- **Delimiter Check**: When processing SQL or CSV, always verify delimiters to avoid data misalignment.
- **Shell Fail-Safe**: Every shell command executed by the agent must be monitored for `exit code 0`. Any non-zero exit must trigger an immediate diagnostic.

### 📦 Artifact Rotation

- Keep the `brain/` directory lean. Rotate or ARCHIVE old implementation plans and walkthroughs once a task is fully integrated.

## ✅ Verification

- Validate that `.gitignore` prevents accidental credential commits.
- Conduct regular audits of scripts to ensure `set -e` is present.
