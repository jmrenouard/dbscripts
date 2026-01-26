---
trigger: always_on
description: Rules for maintaining and generating documentation.
category: governance
---
# 05 - Documentation Standards

## 🧠 Rationale

Consistent and bilingual documentation is critical for the `dbscripts` project. Automated generation ensures that TOCs and READMEs are always up-to-date.

## 🛠️ Implementation

### 🌍 Bilingual Parity

- Every standard procedure should have an English version (`filename.md`) and a French version (`filename_fr.md`).
- Use `genSop.sh` to scaffold these from script metadata.

### 📝 Structure

- **TOC Placeholder**: Every documentation file MUST include a `## Table of contents` (EN) or `## Table des matières` (FR) section.
- **TOC Marker**: Use the `<TOC>` marker to indicate where the automated table of contents should be injected by `genToC.sh`.

### 🚀 Automated Sync

- Never update TOCs or the root `documentation/README.md` manually.
- Use the `/doc-sync` workflow to refresh all documentation assets.

## ✅ Verification

- Ensure `genToC.sh` runs without errors on new files.
- Verify that `documentation/README.md` contains links to all existing `.md` files in both languages.
