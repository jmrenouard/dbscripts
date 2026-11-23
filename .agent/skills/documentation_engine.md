---
name: documentation_engine
description: Expert system for generating Standard Operation Procedures (SOPs).
category: tool
---
# Documentation Engine Skill

## 🧠 Rationale

Generating documentation directly from script metadata ensures accuracy and maintains the English documentation standards of the `dbscripts` project.

## 🛠️ Implementation

### 📋 Prerequisites

- A target script containing `##title_en` and `##goals_en` metadata.
- Access to the target hosts (or laboratory environment).

### 🚀 Usage Pattern

To generate a new English SOP:

1. **Format the script**: Ensure the Bash script has the required metadata comments.
2. **Execute Generator**: Run `bash documentation/genSop.sh <host> <script_path> <functional_slug>`.
    - `<functional_slug>` will be used to name the generated file (`<slug>.md`).
3. **Recursive Sync**: Always follow up with `/doc-sync` to integrate the new file into the global index.

### 🧩 Script Metadata Example

```bash
##title_en: Install MariaDB
##goals_en: Update system / Install packages / Enable service
```

## ✅ Verification

- Check that the generated `.md` file contains the terminal output from the script execution.
- Run `/doc-sync` and verify the new document appears in `documentation/README.md`.
