---
name: documentation_engine
description: Expert system for generating Standard Operation Procedures (SOPs).
category: tool
---
# Documentation Engine Skill

## 🧠 Rationale

Generating documentation directly from script execution ensures that the documentation is accurate and reflects the actual behavior of the automation.

## 🛠️ Implementation

### 📋 Prerequisites

- A target script containing `##title_en`, `##title_fr`, `##goals_en`, and `##goals_fr` metadata.
- Access to the target hosts (or laboratory environment).

### 🚀 Usage Pattern

To generate a new SOP:

1. **Format the script**: Ensure the Bash script has the required metadata comments.
2. **Execute Generator**: Run `sh documentation/genSop.sh <host> <script_path>`.
3. **Result**: This will create `filename.md` and `filename_fr.md` with captured terminal output.

### 🧩 Script Metadata Example

```bash
##title_en: Install MariaDB
##title_fr: Installation de MariaDB
##goals_en: Update system / Install packages / Enable service
##goals_fr: Mise à jour système / Installation paquets / Activation service
```

## ✅ Verification

- Check that the generated `.md` files contain the terminal output from the script execution.
- Ensure TOCs are correctly injected at the end of the process.
