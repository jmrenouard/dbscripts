---
description: Refresh all documentation TOCs and the root README.
---
# Documentation Sync Workflow

## 🧠 Rationale

To maintain a high-quality user guide, we must ensure that all navigation elements (TOCs and index) are synchronized with the content.

## 🛠️ Implementation

### 1. Synchronization Steps

// turbo

1. **Clear old TOCs**: Navigate to `documentation/` and run `sh genAllToC.sh`.
2. **Update Index**: Run `sh genReadme.sh` to refresh the `documentation/README.md`.
3. **Verify**: Check that all `.md` files have updated links and tables of content.

### 2. Manual Update (If needed)

- If a specific file is out of sync, run `sh genToC.sh <filename>`.

## ✅ Verification

- Validate that `documentation/README.md` is updated.
- Use `git diff documentation/` to see the changes.
