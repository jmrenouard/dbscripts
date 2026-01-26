---
trigger: always_on
description: Rules for maintaining and generating documentation.
category: governance
---
# 05 - Documentation Standards

## 🧠 Rationale

Consistent and bilingual documentation is critical for the `dbscripts` project. Automated generation ensures that TOCs and READMEs are always up-to-date across the entire hierarchy.

## 🛠️ Implementation

### 🌍 Bilingual Parity

- Every standard procedure must have two versions:
  - **English**: `technical_slug.md` (e.g., `mariadb_config.md`). Contains the technical reference in English.
  - **French**: `nom_fonctionnel_fr.md` (e.g., `configuration_mariadb_fr.md`). Contains the same reference in French.
- Use `genSop.sh` to scaffold these from script metadata. It maintains link parity between versions.

### 📝 Structure

- **TOC Placeholder**: Every documentation file MUST include a `## Table of contents` section.
- **TOC Marker**: Use the `<TOC>` marker to indicate where the automated table of contents should be injected by `genToC.sh`.
- **Naming**: French files MUST have the `_fr.md` suffix and use French functional names (slugs).

### 🚀 Automated Sync

- Never update TOCs or the `README.md` indices manually.
- **Recursive Sync**: The synchronization process is recursive. It scans all subdirectories in `documentation/`.
- **Double Index**: Two separate indices are generated at the root of the documentation folder:
  - [README.md](file:///home/jmren/GIT_REPOS/dbscripts/documentation/README.md): English index grouping documents by chapter.
  - [README_fr.md](file:///home/jmren/GIT_REPOS/dbscripts/documentation/README_fr.md): French index grouping documents by chapter.
- Use the `/doc-sync` workflow to refresh all documentation assets.

## ✅ Verification

- Ensure `genToC.sh` runs without errors on new files.
- Verify that both `README.md` and `README_fr.md` correctly list files in their respective languages.
- Validate that all subdirectories are covered by the recursive scan.
