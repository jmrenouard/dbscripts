---
description: Synchronize changes with remote using Conventional Commits and pre-push validation.
---

# Git Sync with Conventional Commits

This workflow synchronizes your changes with the remote repository while maintaining a clean, structured commit history and enforcing project governance.

## 🛠️ Implementation

### 1. Pull Latest Changes

Ensure your local branch is up to date.

// turbo

```bash
git pull origin $(git branch --show-current) --rebase
```

### 2. Stage and Commit

Follow the Conventional Commits format: `<type>(<scope>): <description>`.

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `ci`, `chore`.

```bash
git add .
git commit -m "<type>(<scope>): <description>"
```

### 3. Pre-flight Validation

Run the pre-flight checks before pushing.

```bash
/release-preflight
```

### 4. Push Changes

Deploy your changes once validation is complete.

// turbo

```bash
git push origin $(git branch --show-current)
```

> [!TIP]
> Use `/release-preflight` independently at any time to verify project state.
