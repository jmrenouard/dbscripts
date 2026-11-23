---
description: Refresh all documentation TOCs and the English README index.
---
# Documentation Sync Workflow

## 🧠 Rationale

To maintain a high-quality English user guide, we must ensure that all navigation elements (TOCs and indices) are synchronized with the content across all directories.

## 🛠️ Implementation

### 1. Synchronization Steps

// turbo

1. **Recursive TOC Update**: Navigate to `documentation/` and run `bash genAllToC.sh`. This refreshes TOCs in all `.md` files throughout the project.
2. **Index Update**: Run `bash genReadme.sh`. This regenerates:
    - [README.md](../../documentation/README.md) (English index)
3. **Verify Generation**: Ensure `documentation/README.md` exists and is correctly populated with links to all documents.

### 2. Manual Update (If needed)

- To update a single file's TOC, run `bash genToC.sh <filename>`.

## ✅ Verification

- Use `ls -l documentation/README.md` to verify the index was created.
- Review changes with `git diff documentation/`.
