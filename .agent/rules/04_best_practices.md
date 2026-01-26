---
trigger: always_on
description: Dynamic best practices and evolutionary patterns.
category: governance
---
# 04 - Best Practices

## 🧠 Rationale

Governance is not static. This document captures the evolutionary patterns and best practices that emerge from successful laboratory experiments and production deployments.

## 🛠️ Implementation

### 🚀 Evolutionary Roadmapping

- Use `ROADMAP.md` to track long-term features.
- Every new feature should be prototyped in a dedicated branch or folder before being merged into the main `scripts/` or `ansible/` structure.

### 📊 Reporting Standards

- Prefer HTML/Jinja2 output for human-readable reports.
- Ensure all reports include a "Reproduce Test" section to allow others to verify results with a single command.

### 🧪 Laboratory Discipline

- **Atomic Injection**: When setting up a test environment, inject configuration in a single step (e.g., a single `docker-compose up` or a single Ansible playbook run).
- **Persistent Labs**: Maintain laboratory environments as long as possible to allow for deep debugging of intermittent issues.

### 📝 Documentation Sync

- Run `/doc-sync` regularly to ensure that `README.md` and other documentation files accurately reflect the current state of the code.
- Avoid duplicated documentation; link to specialized files instead.

### 🛠️ Contribution Model

- **Spec-Driven**: Changes start with a specification in `documentation/specifications/`.
- **Atomic Commits**: Follow Conventional Commits standards (see [06_version_management.md](file:///home/jmren/GIT_REPOS/dbscripts/.agent/rules/06_version_management.md)).
- **Verifiable Proof**: Every PR or change must include verification results (walkthroughs).

### ✅ Accountability

- **Maintainer**: Jean-Sébastien Renouard (@jmrenouard).
- **Rule Compliance**: All contributions must adhere to the `.agent/` rules.

## ✅ Verification

- Review this document monthly to prune outdated practices.
- Use `/ compliance-sentinel` to ensure best practices don't drift from execution rules.
