---
trigger: always_on
description: Rules for maintaining and generating documentation in English.
category: governance
---
# 05 - Documentation Standards

## 🧠 Rationale

Consistent and high-quality documentation is critical for the `dbscripts` project. In accordance with [`AGENTS.md`](../../AGENTS.md), all project documentation, specifications, governance registers, and code comments **MUST be written in English**. Automated generation ensures that Tables of Contents (TOCs) and README indices remain consistently synchronized across the entire hierarchy.

## 🛠️ Implementation

### 🌍 Language Standards

- All canonical procedures, guides, and architectural references MUST be written in **English**: `technical_slug.md` (e.g., `mariadb_config.md`).
- Existing French files (`*_fr.md`) are retained strictly for backward compatibility, but all new documentation and updates must be authored in English.
- All governance registers (`docs/ACTION_LOGBOOK.md`, `docs/RCA_REGISTER.md`) must be maintained in English without exception.

### 📝 Structure

- **TOC Placeholder**: Every major documentation file MUST include a `## Table of contents` section.
- **TOC Marker**: Use the `<TOC>` marker to indicate where the automated table of contents should be injected by `genToC.sh`.
- **Naming**: Use clear, lowercase kebab-case or snake_case slugs for English documentation files.

### 🚀 Automated Sync

- Never update TOCs or the `README.md` indices manually.
- **Recursive Sync**: The synchronization process scans all subdirectories in `documentation/`.
- **Index Generation**: An index is generated at the root of the documentation folder:
  - `documentation/README.md`: English index grouping documents by chapter.
- Use the `/doc-sync` workflow to refresh documentation assets.

## ✅ Verification

- Ensure `genToC.sh` runs without errors on new markdown files.
- Verify that `documentation/README.md` correctly lists all documentation files.
- Validate that all subdirectories are covered by the recursive scan.
