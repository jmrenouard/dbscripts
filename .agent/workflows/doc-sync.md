---
description: Refresh all documentation TOCs and the bilingual READMEs.
---
# Documentation Sync Workflow

## 🧠 Rationale

To maintain a high-quality, bilingual user guide, we must ensure that all navigation elements (TOCs and indices) are synchronized with the content across all directories.

## 🛠️ Implementation

### 1. Synchronization Steps

// turbo

1. **Recursive TOC Update**: Navigate to `documentation/` and run `sh genAllToC.sh`. This refreshes TOCs in all `.md` files throughout the project.
2. **Bilingual Index Update**: Run `sh genReadme.sh`. This regenerates:
    - [README.md](file:///home/jmren/GIT_REPOS/dbscripts/documentation/README.md) (English version)
    - [README_fr.md](file:///home/jmren/GIT_REPOS/dbscripts/documentation/README_fr.md) (French version)
3. **Verify Generation**: Ensure both files exist and are correctly populated with links to their respective languages.

### 2. Manual Update (If needed)

- To update a single file's TOC, run `sh genToC.sh <filename>`.

## ✅ Verification

- Use `ls -l documentation/README*` to verify both indices were created.
- Review changes with `git diff documentation/`.
