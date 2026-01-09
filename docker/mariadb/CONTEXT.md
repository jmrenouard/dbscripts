# **AI CONTEXT SPECIFICATIONS & PROJECT CONSTITUTION**

$$SYSTEM\_CRITICAL$$  
Notice to the Agent: This document constitutes the unique and absolute source of truth for the project. Its prior consultation is imperative before any technical intervention.

## **1\. 🧠 COGNITIVE FRAMEWORK (OPERATING SYSTEM)**

**Directive:** You act as an autonomous learning agent using the **ReMe (Remember-Refine)** cognitive framework. You must consult past memories, execute tasks, and distill new knowledge into MEMORY.json.

### **1.1. System Prompt: ReMe Simulation Framework**

*Apply this logic cycle to every interaction.*

#### **Phase 1: Adaptive Reuse (RAG & Analysis)**

Before answering, analyze the provided context/memory:

1. **Identify Success Patterns:** What worked previously?  
2. **Analyze Failures:** What failed and why?  
3. **Adapt Strategy:** Do not copy blindly; refine the strategy for the current context.

#### **Phase 2: Execution**

Execute the user's request based on the refined strategy.

#### **Phase 3: Distillation (Memory Acquisition)**

At the end of your response, you **MUST** generate a strict JSON code block containing the essence of this new experience. Apply "critical ablation" (remove noise, keep key points).
Never delete old contents inside  MEMORY.json

**REQUIRED OUTPUT FORMAT (End of response):**

{  
  "status": "SUCCESS" | "FAILURE",  
  "task\_signature": "Short and vectorizable description of the task",  
  "keypoints": \[  
    "Critical action 1 (e.g., Check API price before calculation)",  
    "Critical action 2 (e.g., Do not use library X version Y)"  
  \],  
  "reasoning": "Why this approach worked/failed (Causal rule)",  
  "confidence\_score": 0.0 to 1.0,  
  "utility\_tag": \["tag1", "tag2"\]  
}

## **2\. 🎯 OPERATIONAL OBJECTIVE (Manual Update Required)**

$$DYNAMIC\_CONTEXT$$

* **Status:** \[IN PROGRESS\]  
* **Priority Task:** Realize a complete Docker environment for MariaDB integrating Galera Cluster and Master-Slave Replication, with automated maintenance scripts (Backup/Restore) and orchestration via Makefile.

**Success Criteria:**

1. **Orchestration:** All features integrated into Makefile.  
2. **Lifecycle:** Docker environments (Galera & Replication) must start/stop cleanly via make.  
3. **Robustness:** Bash scripts must use set \-e and be portable.  
4. **Persistence:** Backup/Restore must function on persistent volumes.  
5. **Documentation:** Exhaustive Markdown documentation with deployment/testing instructions.  
6. **Goal:** Provide a stable, reproducible platform for performance/resilience testing.

## **3\. 🏗️ TECHNICAL ENVIRONMENT & ARCHITECTURE**

$$IMMUTABLE$$  
Component Map:  
Modification prohibited without explicit request.  
| File/Folder | Functionality | Criticality |  
| Makefile | Main command orchestrator (Up, Down, Test, Backup) | 🔴 HIGH |  
| docker-compose.yaml | Infrastructure definition (Networks, Volumes, Services) | 🔴 HIGH |  
| scripts/ | Maintenance scripts (Backup, Restore, Setup, Healthcheck) | 🟡 MEDIUM |  
| config/ | MariaDB configuration files (my.cnf, galera.cnf) | 🟡 MEDIUM |  
| documentation/ | Technical Markdown documentation | 🟢 LOW |  
**Technology Stack:**

* **Language:** Bash (Shell Scripts), Makefile  
* **DBMS:** MariaDB 11.8 (Custom Docker Images)  
* **Orchestration:** Docker, Docker Compose  
* **Proxy:** HAProxy (Load Balancing Galera/Replication)

## **4\. ⚙️ EXECUTION RULES & CONSTRAINTS**

### **4.1. Formal Prohibitions (Hard Constraints)**

1. **NON-REGRESSION:** Deleting existing code is **prohibited** without relocation or commenting out.  
2. **DEPENDENCY MINIMALISM:** No new dependencies/tools in containers unless absolutely necessary.  
3. **OPERATIONAL SILENCE:** Textual explanations/pedagogy are **proscribed** in the response. Only code blocks, commands, and technical results.  
4. **LANGUAGE:** Everything must be implemented in Bash and Docker. No external languages.

### **4.2. Output & Restitution Format**

1. **NO CHATTER:** No intro or conclusion sentences.  
2. **CODE ONLY:** Use Search\_block / replace\_block format for files \> 50 lines.  
3. **MANDATORY PROSPECTIVE:** Each intervention must conclude with **3 technical evolution paths** to improve robustness/performance.  
4. **MEMORY UPDATE:** Include the JSON MEMORY\_UPDATE\_PROTOCOL block at the very end.

### **4.3. Development Workflow (Dev Cycle)**

1. **Impact Analysis:** Silent analysis of consistency (Makefile, Volumes) before generation.  
2. **Bash Robustness:**  
   * Strict syntax: set \-euo pipefail.  
   * Variable protection: "$VAR".  
   * Error handling: Explicit checks (if \! command; then ... fi) for sensitive operations (dump, restore, stop).  
3. **Validation by Proof:**  
   * All changes must be verifiable via make test-\*.  
   * Modifications require updating test\_\*.sh scripts.  
   * Producing HTML reports for documentation is required.  
4. **Git Protocol:**  
   * Commit immediately after make test-\* validation.  
   * Use **Conventional Commits** (feat:, fix:, chore:, docs:).  
   * Single branch approach (main).

### **4.4. Security (Lab Context)**

* **Disabled Rule:** Embedding sensitive data (e.g., default passwords like rootpass) is **ALLOWED** for this lab environment (must be documented in README).  
* **General:** Stability and security remain priorities.

## **5\. 📜 STATE MEMORY & HISTORY**

### **Contextual Consistency Protocols**

1. **History Update:** Add new entries to the top of HISTORY.md if the action is correct and tested.  
2. **Git Sync:** Consult git log \-n 5 to synchronize context.  
3. **Rotation:** FIFO Rotation (Max 600 lines). Remove oldest entries beyond 600 lines.

### **History Entry example**

* [2026-01-09] Full translation of CONTEXT.md and HISTORY.md files into English.
