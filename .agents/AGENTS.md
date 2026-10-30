# Workspace Rules for Database Scripts Automation

> See root [`AGENTS.md`](../AGENTS.md) and `.agents/rules/` (`git-workflow.md`, `github-workflow.md`, `project-governance.md`). All project files, rules, and registers **MUST** be in **English**.

## 1. Core Architecture & PR Diff Limit

> [!IMPORTANT]
> - **Multi-DB Automation**: Scripts and playbooks for MariaDB/Galera, MySQL, PostgreSQL, MongoDB, Cassandra.
> - **Strict PR Diff Limit (`< 15,000` chars)**: Run `git diff main...HEAD | wc -c` before opening any PR. Split larger changes into atomic PRs.

## 2. Mandatory Git, Registers & Release Lifecycle

For **every modification** (code, configuration, scripts, CI/CD, refactoring, documentation):
1. **GitHub Issue**: Open an issue via `gh issue create`.
2. **Dedicated Branch**: Create `<type>/issue-<id>-<slug>` from `main` (or `git worktree`).
3. **Implementation, Registers & Validation**:
   - Update [`docs/ACTION_LOGBOOK.md`](../docs/ACTION_LOGBOOK.md) and [`docs/RCA_REGISTER.md`](../docs/RCA_REGISTER.md) on every request, change, and result.
   - Run unit tests and syntax checks.
4. **PR, Merge & Issue Closure**: Push branch, verify diff `< 15,000` chars, open PR (`gh pr create`), merge (`gh pr merge --merge --delete-branch`), sync `main`, and close the issue with an explicit completion comment (`gh issue comment <id> --body "..."` followed by `gh issue close <id>`).
