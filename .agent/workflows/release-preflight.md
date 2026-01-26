---
description: Perform pre-release/pre-push validation for project governance.
---

# Release Preflight Workflow

This workflow ensures that the project meets governance standards before changes are pushed or a release is finalized.

## 🛠️ Implementation

### 1. Working Directory Check

Ensure there are no uncommitted changes that might lead to a dirty release.

// turbo

```bash
git status --short
```

### 2. Governance Files Check

Verify that the mandatory files are present and properly formatted.

// turbo

```bash
ls -l VERSION Changelog
```

### 3. Changelog Accuracy

Ensure the `[Unreleased]` section has content, representing the work done since the last release.

// turbo

```bash
grep -A 5 "## \[Unreleased\]" Changelog
```

### 4. Documentation Sync (Optional but Recommended)

Ensure all TOCs and indices are up to date.

// turbo

```bash
sh documentation/genAllToC.sh
sh documentation/genReadme.sh
```

## ✅ Verification

If any of the above checks fail or show missing information, resolve them before proceeding with a commit, push, or release.
