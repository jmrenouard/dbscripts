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
0. **GitHub Issue (`gh issue create`)**: Open an issue with `gh issue create --title "<type>: <title>" --body "..."` (strictly in English) and retrieve `#<id>`.
1. **Dedicated Branch**: Create `<type>/issue-<id>-<slug>` from `main`.
2. **Tests & Validation**: Verify test targets locally (`python3 -m unittest discover -s tests -v`). All code and SQL comments must strictly be in English. Update [`docs/ACTION_LOGBOOK.md`](docs/ACTION_LOGBOOK.md) and [`docs/RCA_REGISTER.md`](docs/RCA_REGISTER.md) before committing.
3. **Rigorous Staging (`git add`)**: Stage only tracked files (`git add`); exclude temporary dumps and artifacts.
4. **Structured Commit (`git commit`)**: Atomic Conventional Commits (`feat:`, `fix:`, `docs:`, `test:`) in English referencing `Closes #<id>`, keeping PR diff `< 15,000` chars.
5. **Branch Push (`git push`)**: Push branch to remote (`git push -u origin <branch>`).
6. **Pull Request (`gh pr create`)**: Open PR via `gh pr create --base main --head <branch> --title "..." --body "Closes #<id>"` (strictly in English).
7. **Merge (`gh pr merge`)**: Merge via `gh pr merge <pr-id> --merge --delete-branch` with a merge commit message strictly in English, and sync `main`.
8. **Close Issue (`gh issue close`)**: Detail verification in comment strictly in English (`gh issue comment <id> --body "..."`) and close (`gh issue close <id>`).

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

---

## 5. Mandatory English-Only Policy for GitHub and Code

All GitHub artifacts, messages, and source code across the Database Scripts Automation repository MUST be strictly in English:
1. **GitHub Issues**: Every issue title, description, and discussion comment (`gh issue create`) MUST be strictly in English.
2. **Pull Requests (PRs)**: Every PR title, description, and review comment (`gh pr create`) MUST be strictly in English.
3. **PR Merges & Issue Comments**: Every PR merge commit message (`gh pr merge`) and issue closing comment (`gh issue close --comment "..."` or `gh issue comment`) MUST be strictly in English.
4. **Git Commit Messages**: All commit messages (Conventional Commits) MUST be strictly in English.
5. **Source Code & SQL Comments**: All comments in Python, Bash, SQL, Ansible playbooks, and Dockerfiles MUST be strictly written in English. French code and script comments are strictly forbidden.
6. **Zero French on GitHub**: Zero French is allowed in any GitHub interactions, issue discussions, PR reviews, merge messages, or issue closing comments.
