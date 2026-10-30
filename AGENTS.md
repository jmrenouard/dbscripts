# Database Scripts Automation Project Rules (AGENTS.md)

These rules apply **without exception** to every session and agent on **Database Scripts Automation** (`jmrenouard/dbscripts`). All project documentation, rules, governance registers, commit messages, issues, and PRs **MUST** be written in **English**.

---

## 1. Core Architecture & PR Diff Constraints

1. **Multi-Database Automation Framework**:
   - Provide robust, reproducible automation and testing solutions for multi-vendor database infrastructures (MariaDB/Galera, MySQL/InnoDB Cluster, PostgreSQL/Patroni, MongoDB, Cassandra) via Ansible, Docker, Shell, and Python.
   - Clean standards: scripts must be deterministic, idempotent, and include comprehensive error handling.
2. **Strict Pull Request Diff Limit (`< 15,000` chars)**:
   - Every PR diff (`git diff main...HEAD | wc -c`) **MUST** remain under **15,000 characters**. Split larger changes into sequential atomic PRs.
3. **Safe Shell Scripting**:
   - All Bash scripts MUST use `set -euo pipefail` and quote variables (`"$VAR"`). No silent error swallowing.

---

## 2. Mandatory GitHub Workflow (Required for Every Request)

For **every request**, the agent **MUST systematically** execute the GitHub lifecycle:
1. **GitHub Issue**: Open an issue with `gh issue create --title "<type>: <title>" --body "..."` and retrieve `#<id>`.
2. **Dedicated Branch**: Create `<type>/issue-<id>-<slug>` from `main`.
3. **Tests & Validation**: Verify test targets locally (`python3 -m unittest discover -s tests -v`).
4. **Update Registers**: Update [`docs/ACTION_LOGBOOK.md`](docs/ACTION_LOGBOOK.md) and [`docs/RCA_REGISTER.md`](docs/RCA_REGISTER.md) before committing.
5. **Commit & Push**: Atomic Conventional Commits (`feat:`, `fix:`, `docs:`, `test:`) referencing `Closes #<id>`, PR diff `< 15,000` chars, and push.
6. **Pull Request**: Open PR via `gh pr create --base main --head <branch> --title "..." --body "Closes #<id>"`.
7. **Merge**: Merge via `gh pr merge <pr-id> --merge --delete-branch` and sync `main`.
8. **Close Issue**: Detail verification in comment (`gh issue comment <id> --body "..."`) and close (`gh issue close <id>`).

---

## 3. Action Logbook (`docs/ACTION_LOGBOOK.md`)

Systematically update [`docs/ACTION_LOGBOOK.md`](docs/ACTION_LOGBOOK.md) on every request, every change, and every result:
- **Ongoing Actions (`IN PROGRESS`)**: Add entry (`ACT-XXX`, date, Issue `#<id>`, branch, **Request**).
- **Completed Actions (`COMPLETED`)**: Document **Request**, **Changes**, and **Result** (tests, PR, merge commit).

---

## 4. RCA Register (`docs/RCA_REGISTER.md`)

Systematically update [`docs/RCA_REGISTER.md`](docs/RCA_REGISTER.md) on every request, every change, and every result across 4 sections:
1. **Errors & Bugs Encountered (`RCA-XXX`)**: Observed Symptom, 5-Whys RCA, Applied Fix, Non-Regression Test.
2. **Technical Dead-Ends (`IMP-XXX`)**: Rejected technical directions with justification.
3. **Current Approximations (`APP-XXX`)**: Simplifications, heuristics, or laboratory mocks.
4. **Unimplemented Ideas (`IDEA-XXX`)**: Future strategic proposals for the roadmap.
