---
trigger: explicit_call
description: Commit and synchronize changes using Conventional Commits standards.
category: tool
---

# Git Conventional Sync

## 🧠 Rationale

Maintaining a clean and structured commit history is essential for high-density agentic development. Conventional Commits allow for automated changelog generation and easier traceability. This workflow ensures that all changes are synchronized with the remote while adhering to these standards.

## 🛠️ Implementation

### 1. Pull Latest Changes

Ensure your local environment is up to date before committing.

// turbo

```bash
git pull origin $(git branch --show-current) --rebase
```

### 2. Stage Changes

Selectively stage your changes or add all modified files.

```bash
git add .
```

### 3. Commit with Conventional Format

Compose your commit message following the structure: `<type>(<scope>): <description>`

**Common Types:**

- `feat`: ✨ A new feature
- `fix`: 🐛 A bug fix
- `docs`: 📚 Documentation only changes
- `style`: 💎 Changes that do not affect the meaning of the code
- `refactor`: ♻️ A code change that neither fixes a bug nor adds a feature
- `perf`: 🚀 A code change that improves performance
- `test`: 🧪 Adding missing tests or correcting existing tests
- `ci`: ⚙️ Changes to CI configuration scripts and tools
- `chore`: 🔧 Changes to the build process or auxiliary tools

```bash
git commit -m "<type>(<scope>): <description>"
```

### 4. Push Changes

Deploy your committed changes to the remote repository.

// turbo

```bash
git push origin $(git branch --show-current)
```

## ✅ Verification

- Check `git log -n 5` to ensure the commit message follows the pattern.
- Verify that `git status` shows a clean working directory.
- Confirm changes are visible on the remote repository.
