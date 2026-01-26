---
name: documentation_engine
description: Expert system for generating Standard Operation Procedures (SOPs).
category: tool
---
# Documentation Engine Skill

## 🧠 Rationale

Generating documentation directly from script metadata ensures accuracy and maintains the bilingual standards of the `dbscripts` project.

## 🛠️ Implementation

### 📋 Prerequisites

- A target script containing `##title_en`, `##title_fr`, `##goals_en`, and `##goals_fr` metadata.
- Access to the target hosts (or laboratory environment).

### 🚀 Usage Pattern

To generate a new bilingual SOP:

1. **Format the script**: Ensure the Bash script has the required metadata comments.
2. **Execute Generator**: Run `sh documentation/genSop.sh <host> <script_path> <functional_slug>`.
    - `<functional_slug>` will be used to name the files (English: `<slug>.md`, French: `<slug_fr>.md`).
3. **Recursive Sync**: Always follow up with `/doc-sync` to integrate the new files into the global indices.

### 🧩 Script Metadata Example

```bash
##title_en: Install MariaDB
##title_fr: Installation de MariaDB
##goals_en: Update system / Install packages / Enable service
##goals_fr: Mise à jour système / Installation paquets / Activation service
```

## ✅ Verification

- Check that the generated `.md` files contain the terminal output from the script execution.
- run `/doc-sync` and verify the new documents appear in both `README.md` and `README_fr.md`.
