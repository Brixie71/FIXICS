# Codex Operating Layer — Design Spec

## Purpose

Add a repo-level CODEX operating layer that helps CODEX work on BASE-ARMA consistently across sessions — without moving, renaming, or modifying any addon source files.

The existing addon structure remains the single source of truth for game code. The new layer exists only to support CODEX's reasoning, routing, validation, and documentation workflows.

---

## Architecture

Two connected layers. Only the support layer is new.

```
┌─────────────────────────────────────────────────────────────┐
│  ARMA ADDON LAYER  (authoritative — do not restructure)     │
│                                                             │
│  .hemtt/           HEMTT project and launch config          │
│  addons/main/      Addon source, functions, strings         │
│  .hemttout/        Generated output (never edited by hand)  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  CODEX SUPPORT LAYER  (new — does not touch addon source)   │
│                                                             │
│  CODEX.md          CODEX entry point and routing memory     │
│  AGENTS.md         Repository rules (existing — keep)       │
│  README.md         Human-facing project overview (existing) │
│  agents/           Agent role definitions                   │
│  tools/            PowerShell validation wrappers           │
│  orchestration/    Task routing and shared state            │
│  prompts/          Reusable prompt templates                │
│  governance/       Policies, guardrails, audit log          │
│  evals/            Evaluation definitions and reports       │
│  tests/            Test procedures (not Arma source)        │
│  docs/             Architecture maps, Superpowers artifacts │
└─────────────────────────────────────────────────────────────┘
```

---

## Component Specifications

### CODEX.md

The primary entry point for every CODEX session. CODEX must read this file before taking any action.

**Must contain:**

| Section | Content |
|---|---|
| `## Purpose` | One paragraph: what this repository is and what CODEX's role is |
| `## Introduction` | FIXICS project description and motivation |
| `## Current Priorities` | Phase checklist with completion status |
| `## Design Rules` | What is always true in this project |
| `## Known Limitations` | Engine and project constraints |
| `## First Read` | Ordered list of files to read at session start |
| `## Source Boundaries` | What is and is not addon source |
| `## Agent Routing` | Table: task type → specialist agent file |
| `## Superpowers Workflow` | When to use brainstorming, writing-plans, verification |
| `## Validation Gates` | Exact commands with pass criteria |
| `## Scope Rules` | What CODEX must never do |
| `## SQA ↔ CODEX Workflow Protocol` | Full 4-stage workflow with explicit approval gate |

**SQA ↔ CODEX Workflow Protocol must define:**

- **Stage 1 — Intake & Analysis:** Parse the bug report. Identify root cause. Ask clarifying questions before proposing anything.
- **Stage 2 — Pre-Implementation Review:** List files to modify, requirements, dependencies, and a risk/outcome assessment. Do not write code yet.
- **Stage 3 — Planning & Approval:** Propose fix plan with alternatives. Wait for explicit SQA approval. Do not touch source until approval is given.
- **Stage 4 — Implementation:** Execute only the approved plan. Follow all standards. Run `hemtt check` before reporting complete.

---

### agents/

Agent role files are guidance documents for CODEX — they define scope, allowed paths, and validation requirements. They are not executable agents.

#### `agents/orchestrator/workflow.md`

Must describe:

- The full task lifecycle: intake → planning → SQA approval → implementation → validation → report
- How CODEX identifies which specialist agent applies to a task
- Escalation conditions — when CODEX must stop and ask the user before proceeding

#### `agents/orchestrator/policies.yaml`

Must enumerate as machine-readable YAML:

- `forbidden_paths`: files and directories CODEX must never modify
- `require_sqa_approval`: task types that need explicit approval before implementation
- `required_validation`: commands that must pass before any task is closed
- `naming_rules`: the `BASEARMA_` prefix requirements

#### `agents/specialist/sqf-agent.md`

| Field | Value |
|---|---|
| Scope | SQF behavior in `addons/main/functions/` |
| Allowed paths | `addons/main/functions/fn_*.sqf` |
| Forbidden paths | `.hemttout/`, packed PBOs, `docs/additional-sqf-files` (read-only) |
| Required validation | `hemtt check` |
| Reference docs | `SQF-Syntax.md`, `governance/policies/coding-standards.md` |
| Escalate to | Orchestrator if change requires new CfgFunctions entry |

#### `agents/specialist/config-agent.md`

| Field | Value |
|---|---|
| Scope | `CfgFunctions`, `config.cpp`, `stringtable.xml` |
| Allowed paths | `addons/main/config.cpp`, `addons/main/stringtable.xml` |
| Required validation | `hemtt check` |
| Escalate to | Orchestrator if function registration affects more than one file |

#### `agents/specialist/qa-agent.md`

| Field | Value |
|---|---|
| Scope | Validation, smoke checks, error reporting |
| Allowed paths | Read-only on all source; write to `governance/audit/validation-log.md`, `evals/reports/` |
| Required validation | `hemtt check` for automated; `hemtt launch vr` for manual |
| Output format | Structured report: command / result / coverage / known gaps |

---

### tools/

Small PowerShell wrappers that make HEMTT commands reproducible across sessions and environments.

**All wrappers must follow this pattern:**

```powershell
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)   # always run from repo root
$hemtt = if (Test-Path '.\hemtt.exe') { '.\hemtt.exe' } else { 'hemtt' }
& $hemtt <command> @args
exit $LASTEXITCODE
```

| File | HEMTT command | Purpose |
|---|---|---|
| `tools/check.ps1` | `check` | Validate all config and SQF — required before every commit |
| `tools/build.ps1` | `build` | Build PBOs for release |
| `tools/launch-vr.ps1` | `launch vr` | Launch VR smoke mission for manual testing |

**Design rules:**
- Scripts must not hard-code paths to `hemtt.exe`.
- Scripts must exit with HEMTT's exit code so CI and CODEX can detect failure.
- Scripts must work from any working directory.

---

### orchestration/

Provides stable routing and state so CODEX does not need to re-derive project structure each session.

#### `orchestration/router.yaml`

Maps task types to agents, validation gates, and approval requirements. Format:

```yaml
tasks:
  <task_type>:
    agent: <path to specialist md>
    validation: [<command>, ...]
    sqa_approval_required: <true | false>
    notes: <optional context>
```

Minimum required task types: `sqf_behavior`, `config_registration`, `qa_smoke_test`, `documentation`, `script_promotion`.

#### `orchestration/state.md`

Records stable project facts CODEX should not need to re-derive:

- Current active phase and its completion status
- Repository root path and layout summary
- Known constraints and engine limitations
- Date and result of last HEMTT validation

---

### prompts/

Reusable prompt templates reduce session-start overhead and ensure CODEX applies consistent patterns.

#### `prompts/registry.yaml`

Index of all templates in `prompts/library/`. Each entry: name, file path, purpose, when to use.

#### `prompts/library/sqf-function.md`

Template for implementing a new `BASEARMA_fnc_*` function. Must include placeholders for: function name, description, arguments, return type, locality, and logic body.

#### `prompts/library/code-review.md`

Template for reviewing an existing function against `governance/policies/coding-standards.md`. Must produce a structured report: pass/fail per checklist item, recommended fixes.

#### `prompts/library/validation-report.md`

Template for recording a validation run. Must include: date, command, exit code, output summary, coverage, and known gaps.

---

### governance/

Keeps policies short and enforceable. CODEX reads `coding-standards.md` before every edit.

#### `governance/policies/scope-control.md`

Explicit list of:
- Paths CODEX must never modify (with reason)
- Paths requiring SQA approval before modification
- The rule that `addons/main/` is the only addon source location
- The rule that `docs/additional-sqf-files` is reference-only

#### `governance/guardrails/generated-files.md`

Table of every generated or protected path:

| Path | Reason |
|---|---|
| `.hemttout/` | HEMTT build output — regenerated every build |
| `*.pbo` | Packed addon binary |
| `keys/` | Signing keys — never modify or commit |
| `releases/` | Release archives from `hemtt build` |

#### `governance/audit/validation-log.md`

Running log of validation runs. Each entry: date, command, result, coverage, follow-up needed. CODEX appends an entry after every task that runs validation.

---

### evals/

Defines what pass/fail looks like for each validation type.

#### `evals/suites/hemtt-check.md`

- **Command:** `.\tools\check.ps1`
- **Pass:** exit code `0`, no errors in stdout/stderr
- **Fail:** any non-zero exit code or error line in output
- **When to run:** after every source or config change

#### `evals/suites/vr-smoke.md`

- **Command:** `.\tools\launch-vr.ps1`
- **Pass:** mission loads, no script errors in RPT log, physics behavior matches expected
- **Fail:** script error, game crash, or confirmed physics regression
- **When to run:** after any gameplay, physics, or vehicle behavior change
- **Note:** must be run by a human — CODEX cannot verify in-game behavior

---

### tests/

Complements `evals/`. Tests describe procedures; evals describe pass/fail criteria.

#### `tests/integration/hemtt-check.md`

Step-by-step procedure for running `hemtt check`, interpreting output, and recording results.

#### `tests/manual/vr-smoke.md`

Step-by-step procedure for launching the VR mission, identifying script errors in the RPT log, and verifying ground vehicle physics behavior.

---

### docs/

#### `docs/architecture/project-map.md`

Visual map of how the CODEX support layer relates to the HEMTT addon structure. Must show:
- Which paths are authoritative addon source
- Which paths are CODEX support only
- Which paths are generated output (never edit)

#### `docs/superpowers/README.md`

Explains how Superpowers workflow integrates with this repository:
- `superpowers:brainstorming` → creates specs in `docs/superpowers/specs/`
- `superpowers:writing-plans` → creates plans in `docs/superpowers/plans/`
- `superpowers:verification-before-completion` → runs before claiming any validation passed
- Git worktree steps are limited when the folder is not a git repository

---

## Data Flow

Every CODEX session follows this sequence:

```
Session Start
  ↓
Read CODEX.md                       Scope, routing, SQA protocol, validation gates
  ↓
Read AGENTS.md                      Repository rules
  ↓
Read relevant folder README         Context for the task area
  ↓
Read coding-standards.md            Rules to follow before writing any code
  ↓
Consult orchestration/router.yaml   Which specialist agent handles this task
  ↓
Read specialist agent file          Scoped guidance, allowed paths, validation
  ↓
Read SQF-Syntax.md section(s)       Explanation and examples as needed
  ↓
Stage 1: Intake & Analysis          Parse report, identify root cause, ask questions
  ↓
Stage 2: Pre-Implementation Review  Files, requirements, dependencies, risk/outcome
  ↓
Stage 3: Planning & Approval        Propose plan → wait for SQA approval
  ↓
Stage 4: Implementation             Execute approved plan only
  ↓
Run .\tools\check.ps1               Must pass
  ↓
Append to validation-log.md         Record result
  ↓
Report to SQA
```

---

## Error Handling

| Situation | Rule |
|---|---|
| HEMTT not on PATH and no `.\hemtt.exe` | Tool scripts exit with a clear error message — do not silently succeed |
| Validation fails on a documentation-only change | Indicates a pre-existing issue — record it, do not block the doc change |
| CODEX is unsure which specialist agent applies | Route to orchestrator; ask the user before proceeding |
| A source file is not under `addons/main/` | Do not treat it as addon source — confirm with SQA before promoting |
| Two sources conflict | Repository layout wins over wiki; SQA judgment wins over both |

---

## Scope Limits

This design does **not**:

- move or rename files under `addons/main/`
- replace or modify HEMTT project layout
- introduce a Python, REST, or external agent platform
- create live or autonomous agents
- edit `.hemttout/`, packed PBOs, or release output
- generate evaluation reports before real validation data exists
- claim manual Arma coverage unless a launch actually ran and behavior was verified by a human