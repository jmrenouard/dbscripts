---
description: Unified management for Rules, Skills, and Workflows.
---
# Hey-Agent Workflow (The Core Orchestrator)

## 🧠 Rationale

High-density agentic development requires a unified way to manage project governance. The `hey-agent` workflow centralizes the creation, update, and auditing of all `.agent` assets.

## 🛠️ Implementation

### 1. Management Modes

- **ADD**: Insert new items (Rules/Skills/Workflows) in AFF format.
- **EDIT**: Update existing items while maintaining consistency.
- **AUDIT**: Reveal contradictions or outdated rules.
- **MERGE**: Integrate fragmented logic into unified high-level workflows.

### 2. Standardization (AFF - Agent-Friendly Format)

Every governance file MUST follow this header/structure:

```markdown
---
trigger: [always_on | explicit_call]
description: [one-line summary]
category: [governance | tool | skill]
---
# Title
## 🧠 Rationale
## 🛠️ Implementation
## ✅ Verification
```

### 3. Execution Steps (The "Nuclear" Protocol)

1. **Trigger**: Invoke `/hey-agent` for any structural change.
2. **Specify (`/specify`)**: Define requirements for new features or structural changes in `documentation/specifications/`.
3. **Plan (`/plan`)**: Draft a technical strategy for the implementation.
4. **Tasks (`/tasks`)**: Break down the plan into trackable units.
5. **Analysis**: Scan existing files for contradictions (Audit Mode).
6. **Execution**: Apply changes using `replace_file_content` or `multi_replace`.
7. **Synchronization**: Immediately update `03_execution_rules.md` (constraints) and `04_best_practices.md` if necessary.
8. **Autolearning**: Update `remembers.md` as the session-level memory buffer.
9. **Documentation Sync**: Execute `/doc-sync` to refresh the project's technical summary.

## ✅ Verification

- Validate header frontmatter.
- Run `python -m unittest tests/test_project_governance_rules.py -v` to ensure no two rules contradict each other.
