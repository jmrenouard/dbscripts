---
description: Pull latest changes, commit with conventional commit format, and push
---

# Git Sync with Conventional Commits

This workflow helps you synchronize your changes with the remote repository while maintaining a clean, structured commit history.

## Steps

1. **Pull latest changes**
   Ensure your local branch is up to date and resolve any conflicts if necessary.

   ```bash
   git pull origin $(git branch --show-current)
   ```

2. **Stage your changes**

   ```bash
   git add .
   ```

3. **Commit with Conventional Commit format**
   // turbo
   Use the following structure: `<type>(<scope>): <short description>`

   Types:
   - `feat`: A new feature
   - `fix`: A bug fix
   - `docs`: Documentation only changes
   - `style`: Changes that do not affect the meaning of the code (white-space, formatting, etc)
   - `refactor`: A code change that neither fixes a bug nor adds a feature
   - `perf`: A code change that improves performance
   - `test`: Adding missing tests or correcting existing tests
   - `chore`: Changes to the build process or auxiliary tools and libraries such as documentation generation

   ```bash
   git commit -m "<type>(<scope>): <description>"
   ```

4. **Push changes**

   ```bash
   git push origin $(git branch --show-current)
   ```

> [!TIP]
> Always verify your changes with `git status` and `git diff --cached` before committing.
