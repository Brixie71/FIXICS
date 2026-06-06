# Codex Operating Layer — Implementation Plan

> **CODEX instruction:** Execute task-by-task using `superpowers:subagent-driven-development` (preferred) or `superpowers:executing-plans`. Each step uses `- [ ]` checkbox syntax. Do not skip steps. Do not mark a step complete unless its expected output was verified.

---

## Goal

Add a practical CODEX operating layer around the existing BASE-ARMA HEMTT addon — without moving, renaming, or modifying any addon source files.

## Architecture Constraints

```
AUTHORITATIVE (do not move or restructure):
  .hemtt/           HEMTT project and launch configuration
  addons/main/      All addon source, functions, strings, missions
  .hemttout/        Generated output — never edited by hand

NEW (CODEX support layer — add only):
  CODEX.md          CODEX working memory and routing
  agents/           Agent role definitions
  tools/            PowerShell validation wrappers
  orchestration/    Task routing and shared state
  prompts/          Reusable prompt templates
  governance/       Policies, guardrails, audit log
  evals/            Evaluation definitions and reports
  tests/            Test procedures (not Arma source)
  docs/             Architecture maps and Superpowers artifacts
```

**Tech stack:** Arma 3 addon config, SQF, HEMTT, PowerShell, Markdown, YAML.

---

## Task 1 — Create Directory Scaffold

**Purpose:** Establish the full folder structure before any files are created so later tasks can reference paths confidently.

---

- [x] **Step 1.1 — Create all required directories**

```powershell
New-Item -ItemType Directory -Force -Path `
  'agents\orchestrator', `
  'agents\specialist', `
  'tools', `
  'orchestration', `
  'prompts\library', `
  'governance\policies', `
  'governance\guardrails', `
  'governance\audit', `
  'evals\suites', `
  'evals\reports', `
  'tests\manual', `
  'tests\integration', `
  'docs\architecture', `
  'docs\superpowers\specs', `
  'docs\superpowers\plans'
```

**Expected:** `Test-Path` returns `$true` for every path above.

---

- [x] **Step 1.2 — Verify scaffold**

```powershell
Get-ChildItem -Recurse -Directory | Where-Object { $_.FullName -notmatch '\.hemttout|\.hemtt|addons' } | Select-Object FullName
```

**Expected:** all 15 directories appear. No addon source directories appear in the new scaffold list.

---

## Task 2 — CODEX and Agent Guidance Files

**Purpose:** Give CODEX a single authoritative entry point (`CODEX.md`) and scoped specialist roles under `agents/`.

**Files to create:**

```
CODEX.md
agents/README.md
agents/orchestrator/README.md
agents/orchestrator/workflow.md
agents/orchestrator/policies.yaml
agents/specialist/README.md
agents/specialist/sqf-agent.md
agents/specialist/config-agent.md
agents/specialist/qa-agent.md
```

---

- [x] **Step 2.1 — Create `CODEX.md`**

Must contain all of these sections:

```
## Purpose
## Introduction
## Current Priorities
## Design Rules
## Known Limitations
## First Read
## Source Boundaries
## Agent Routing
## Superpowers Workflow
## Validation Gates
## Scope Rules
## SQA ↔ CODEX Workflow Protocol
```

The `## SQA ↔ CODEX Workflow Protocol` section must define:

- Stage 1: Intake & Analysis (parse report, ask questions)
- Stage 2: Pre-Implementation Review (files, requirements, risk/outcome)
- Stage 3: Planning & Approval (wait for explicit approval before touching source)
- Stage 4: Implementation (approved plan only, follow all standards)

**Expected:** `CODEX.md` exists and `Select-String` finds all 12 section headers.

---

- [x] **Step 2.2 — Create agent guidance files**

Each specialist file must state:

- Which task types it handles
- Which source paths it is allowed to touch
- Which validation steps it must run before closing a task
- Which other agents it should escalate to

`agents/specialist/sqf-agent.md` → covers SQF behavior in `addons/main/functions/`
`agents/specialist/config-agent.md` → covers `CfgFunctions`, `config.cpp`, `stringtable.xml`
`agents/specialist/qa-agent.md` → covers validation, smoke checks, error reporting

**Expected:** each file exists and contains a clearly labeled scope section and a validation requirements section.

---

- [x] **Step 2.3 — Create orchestrator files**

`agents/orchestrator/workflow.md` must describe:

- Task intake → planning → SQA approval → implementation → validation flow
- How tasks are routed to specialist agents
- Escalation conditions (when to stop and ask the user)

`agents/orchestrator/policies.yaml` must enumerate:

- Mandatory validation gates
- Files that must never be edited
- Prefixes that must be used for globals and namespace keys

**Expected:** both files exist and reference the `BASEARMA_` prefix rule and `hemtt check` gate.

---

## Task 3 — Tool Wrappers

**Purpose:** Make HEMTT commands consistent and portable across sessions.

**Files to create:**

```
tools/README.md
tools/check.ps1
tools/build.ps1
tools/launch-vr.ps1
```

---

- [x] **Step 3.1 — Create PowerShell wrappers**

Every script must:

1. Set `$ErrorActionPreference = 'Stop'` at the top
2. Resolve the repository root from the script's location — do not hard-code paths
3. Prefer `.\hemtt.exe` if present; fall back to `hemtt` on PATH
4. Pass all arguments through to HEMTT unchanged
5. Exit with HEMTT's exit code so CI and CODEX can detect failure

```powershell
# tools/check.ps1 — canonical form
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
$hemtt = if (Test-Path '.\hemtt.exe') { '.\hemtt.exe' } else { 'hemtt' }
& $hemtt check @args
exit $LASTEXITCODE
```

Apply the same pattern to `build.ps1` (command: `build`) and `launch-vr.ps1` (command: `launch vr`).

**Expected:** each wrapper runs without error from any working directory and exits non-zero when HEMTT fails.

---

- [x] **Step 3.2 — Verify wrappers**

```powershell
.\tools\check.ps1
```

**Expected:** exits `0` on a clean repository. If HEMTT is not available, document that in `tools/README.md`.

---

## Task 4 — Orchestration and Prompt Library

**Purpose:** Give CODEX stable routing logic and reusable prompt templates so it does not reinvent them each session.

**Files to create:**

```
orchestration/README.md
orchestration/router.yaml
orchestration/state.md
prompts/README.md
prompts/registry.yaml
prompts/library/sqf-function.md
prompts/library/code-review.md
prompts/library/validation-report.md
```

---

- [x] **Step 4.1 — Create `orchestration/router.yaml`**

Must map every common task type to:

- The responsible specialist agent
- Required validation gate(s)
- Whether SQA approval is needed before implementation

Example entries required:

```yaml
tasks:
  sqf_behavior:
    agent: agents/specialist/sqf-agent.md
    validation: [hemtt check]
    sqa_approval_required: true

  config_registration:
    agent: agents/specialist/config-agent.md
    validation: [hemtt check]
    sqa_approval_required: true

  qa_smoke_test:
    agent: agents/specialist/qa-agent.md
    validation: [hemtt launch vr]
    sqa_approval_required: false

  documentation:
    agent: null
    validation: [hemtt check]
    sqa_approval_required: false
```

**Expected:** file is valid YAML. All four task types above are present.

---

- [x] **Step 4.2 — Create `orchestration/state.md`**

Must record:

- Current active phase (Phase 1: Ground Vehicle Physics)
- Repository root structure summary
- Known constraints and limitations
- Last validated state (date + result)

**Expected:** file exists and accurately reflects the current project state.

---

- [x] **Step 4.3 — Create prompt templates**

Each template in `prompts/library/` must include:

- A `## Purpose` section stating when to use it
- A `## Template` section with the actual prompt text
- Placeholders clearly marked as `{{PLACEHOLDER_NAME}}`
- A `## Example` section showing a filled-in usage

**Expected:** all three library files exist and follow this structure.

---

## Task 5 — Governance, Evals, Tests, and Docs

**Purpose:** Provide CODEX with policies it can enforce, evaluation criteria it can check against, and architecture context it can use for routing.

**Files to create:**

```
governance/README.md
governance/policies/coding-standards.md     (already handled — see arma-scripting-docs plan)
governance/policies/scope-control.md
governance/guardrails/generated-files.md
governance/audit/validation-log.md
evals/README.md
evals/suites/hemtt-check.md
evals/suites/vr-smoke.md
evals/reports/.gitkeep
tests/README.md
tests/integration/hemtt-check.md
tests/manual/vr-smoke.md
docs/architecture/project-map.md
docs/superpowers/README.md
```

---

- [x] **Step 5.1 — Create `governance/policies/scope-control.md`**

Must list:

- Paths that CODEX must never modify (`.hemttout/`, packed PBOs, release output, private keys)
- Paths that require SQA approval before modification
- The rule that `addons/main/` is the only addon source location
- The rule that `docs/additional-sqf-files` is reference-only until promotion is complete

---

- [x] **Step 5.2 — Create `governance/guardrails/generated-files.md`**

Must list every generated or protected file/folder with a one-line explanation of why it must not be edited:

| Path | Reason |
|---|---|
| `.hemttout/` | HEMTT build output — regenerated on every build |
| `*.pbo` | Packed addon — binary output |
| `keys/` | Signing keys — never modify or commit |
| `releases/` | Release archives — generated by `hemtt build` |

---

- [x] **Step 5.3 — Create eval suites**

`evals/suites/hemtt-check.md` must define:

- Command to run: `.\tools\check.ps1`
- Pass criteria: exit code `0`, no errors in output
- Fail criteria: any non-zero exit code or error message
- When to run: after every source change

`evals/suites/vr-smoke.md` must define:

- Command to run: `.\tools\launch-vr.ps1`
- Pass criteria: mission loads, no script errors in RPT log, vehicle physics behavior matches expected
- Fail criteria: script error, crash, or unexpected physics regression
- When to run: after any gameplay or physics change

---

- [x] **Step 5.4 — Create `docs/architecture/project-map.md`**

Must show how the CODEX operating layer maps to the HEMTT addon structure:

```
BASE-ARMA/
├── .hemtt/                   HEMTT project config (authoritative)
├── addons/main/              Addon source (authoritative)
│   ├── functions/            fn_*.sqf files registered in CfgFunctions
│   ├── config.cpp            CfgFunctions and addon config
│   └── stringtable.xml       User-facing strings
├── .hemttout/                Generated output (never edit)
├── CODEX.md                  CODEX entry point
├── agents/                   Agent role definitions
├── tools/                    Validation wrappers
├── orchestration/            Routing and state
├── prompts/                  Reusable templates
├── governance/               Policies and audit
├── evals/                    Pass/fail criteria
├── tests/                    Test procedures
└── docs/                     Architecture and Superpowers
```

---

## Task 6 — Validate Full Scaffold

**Purpose:** Confirm the new layer does not break HEMTT and all expected files exist.

---

- [x] **Step 6.1 — Verify file count**

```powershell
Get-ChildItem -Recurse -File | Where-Object { $_.FullName -notmatch '\.hemttout|addons\\main\\' } | Measure-Object
```

**Expected:** file count matches the total number of files created in Tasks 2–5. If count is lower, identify which files are missing.

---

- [x] **Step 6.2 — Run HEMTT validation**

```powershell
.\tools\check.ps1
```

**Expected:** exit code `0`. The new scaffold files are all Markdown/YAML and do not affect HEMTT compilation.

---

- [x] **Step 6.3 — Record validation**

Add an entry to `governance/audit/validation-log.md`:

```
Date      : 2026-06-06
Task      : Codex Operating Layer scaffold
Command   : .\tools\check.ps1
Result    : [pass | fail | pre-existing failure — describe]
Coverage  : automated only
Manual    : not required — no addon source was changed
Follow-up : .\hemtt.exe launch vr — required before any gameplay or physics change
```

---

## Scope Limits

This plan does **not**:

- move or rename files under `addons/main/`
- replace HEMTT project layout or config
- introduce a Python, REST, or external agent platform
- create live autonomous agents
- edit `.hemttout/`, packed PBOs, or release output
- generate evaluation reports before real validation data exists
- claim manual Arma coverage unless a launch actually ran and behavior was verified