# Codex Operating Layer — Design Spec

> **Codex:** This is a reference document. Do NOT act on it directly.
> When SQA assigns this task, load this file via `CONTEXT-LOAD.md` → Codex Operating Layer row.
> Present the suggestion card. Wait for yes. Then execute task by task.

---

## Purpose

Add a repo-level Codex operating layer that helps Codex work on FIXICS consistently across sessions — without moving, renaming, or modifying any addon source files.

The existing addon structure remains the single source of truth for game code. The new layer exists only to support Codex's reasoning, routing, validation, and documentation workflows.

---

## Operating Model

SQA is the authority. Codex is the delegator.
Loop: **Ask → Suggest → Wait → Do.**

Codex presents one suggestion card per task. No task proceeds without SQA approval.
Codex does not re-read files already in context. Codex does not load files not listed in `CONTEXT-LOAD.md` for this task.

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
│  CODEX.md          Codex entry point and routing memory     │
│  AGENTS.md         Delegator contract, session rules        │
│  CONTEXT-LOAD.md   Objective-to-file map, loading rules     │
│  agents/           Thin domain role overlays                │
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

## Authority Order

When guidance conflicts, resolve in this order:

| Priority | File | Role |
|---|---|---|
| 1 | `AGENTS.md` | Delegator contract, session rules, hard rules |
| 2 | `CODEX.md` | Task lifecycle, phase table, approval gates |
| 3 | `governance/policies/` | Enforceable coding, scope, phase, workaround rules |
| 4 | `agents/` | Thin domain overlays only — no duplicate policy |
| 5 | `docs/reference/` | Technical research aids — verify all claims |

The only valid public namespace is `FIXICS_`. The only valid addon path is `x\fixics\addons\main`.

---

## Component Specifications

### CODEX.md

Primary entry point. Must contain:

| Section | Content |
|---|---|
| `## Purpose` | What this repository is and what Codex's role is |
| `## Current Phase` | Phase table with status |
| `## First Read` | Ordered list: `CODEX.md` → `AGENTS.md` → `orchestration/state.md` only |
| `## Task Lifecycle` | Intake → Research → Approval → Implementation → Verification |
| `## Agent Routing` | Table: task type → specialist file |
| `## Evidence Policy` | What goes in function headers vs `docs/fixes/` |

### AGENTS.md

The delegator contract. Every session start behavior lives here.

Must contain:

| Section | Content |
|---|---|
| Operating model | SQA is authority. Loop: Ask → Suggest → Wait → Do. |
| Session start | Read 3 files silently. Ask: "Ready. What are we working on?" |
| Suggestion card format | Fixed 4-line card — Objective, Approach, Files, Risk |
| Approval gate format | Fixed 4-line card — Risk, Approach, Impact, Approve? |
| Validation commands | All 3 PowerShell commands with exact paths |
| Completion report format | Done, Validated, Logged, Next |
| Hard rules | Phases 2–7 blocked, no directory scans, no re-reads |

### CONTEXT-LOAD.md

The sole file-routing source. Must contain:

| Section | Content |
|---|---|
| Session start | 3 cold-start files only, then ask SQA |
| Objective-to-file map | One row per task type, files listed in load order |
| Resume rule | Check state.md, confirm with SQA before loading |
| Mid-task lookup table | Gap → exact file, no preloading |
| Hard rules | Same hard rules as AGENTS.md |

Agent files must not contain their own file-loading instructions. All routing goes through `CONTEXT-LOAD.md`.

---

### agents/

Thin domain overlays only. Each file must satisfy:

- Contains only domain-specific guidance not already in `AGENTS.md` or governance
- Does not duplicate workflow steps from `CODEX.md`
- Does not duplicate policy rules from `governance/policies/`
- Is loadable in isolation without pulling the entire `agents/` directory

#### `agents/specialist/sqf-agent.md`

| Field | Value |
|---|---|
| Scope | SQF behavior in `addons/main/functions/` |
| Allowed paths | `addons/main/functions/fn_*.sqf` |
| Forbidden paths | `.hemttout/`, packed PBOs |
| Required validation | `tools\check.ps1` |
| Escalate to | Orchestrator if change requires new `CfgFunctions` entry |

#### `agents/specialist/config-agent.md`

| Field | Value |
|---|---|
| Scope | `CfgFunctions`, `config.cpp`, `stringtable.xml` |
| Allowed paths | `addons/main/config.cpp`, `addons/main/stringtable.xml` |
| Required validation | `tools\check.ps1` |
| Escalate to | Orchestrator if registration affects more than one file |

#### `agents/specialist/qa-agent.md`

| Field | Value |
|---|---|
| Scope | Validation, smoke checks, error reporting |
| Allowed paths | Read-only on all source; write to `governance/audit/validation-log.md` only |
| Required validation | `tools\check.ps1` for automated; `tools\launch-vr.ps1` for manual |
| Output | Structured report: command / result / coverage / known gaps |

#### `agents/orchestrator/policies.yaml`

Machine-readable YAML. Must contain:

- `forbidden_paths` — files and directories Codex must never modify
- `approval_required` — task types needing explicit SQA approval
- `validation` — commands that must pass before any task closes
- `naming` — `FIXICS_` prefix rule and PBO prefix

#### `agents/orchestrator/workflow.md`

Thin overlay only. Must describe:

- How tasks are routed to specialist agents
- Escalation conditions — when Codex must stop and ask SQA

Must NOT duplicate the suggestion card, approval gate, or session start behavior from `AGENTS.md`.

---

### tools/

All wrappers follow this pattern:

```powershell
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
$hemtt = if (Test-Path '.\hemtt.exe') { '.\hemtt.exe' } else { 'hemtt' }
& $hemtt <command> @args
exit $LASTEXITCODE
```

| File | Command | Purpose |
|---|---|---|
| `tools/check.ps1` | `check` | Validate config and SQF — required before every commit |
| `tools/build.ps1` | `build` | Build PBOs for release |
| `tools/launch-vr.ps1` | `launch vr` | Launch VR smoke mission |
| `tools/launch-eden.ps1` | `launch eden` | Open VR mission in Eden Editor |
| `tools/rpt-patterns.ps1` | — | Central RPT pattern strings — imported by parser and watcher |
| `tools/rpt-parser.ps1` | — | Parse RPT log — imports from `rpt-patterns.ps1` |
| `tools/watch-rpt.ps1` | — | Watch RPT log live — imports from `rpt-patterns.ps1` |

Rules:
- No hard-coded paths to `hemtt.exe`
- All console output prefixed with `FIXICS`
- ASCII output only
- Exit with HEMTT's exit code

---

### orchestration/

#### `orchestration/router.yaml`

Maps task types to agents, validation gates, and approval requirements.

Minimum required entries: `sqf_behavior`, `config_registration`, `qa_smoke_test`, `documentation`, `physics_behavior`, `workaround_decision`.

#### `orchestration/state.md`

Records stable project facts Codex must not re-derive each session:

- Current active phase and status
- Last known decision and position
- Last validated state — date and result

---

### prompts/

Each template in `prompts/library/` must include:

- `## Purpose` — when to use it
- `## Template` — prompt text with `{{PLACEHOLDER}}` markers
- `## Example` — filled-in usage

Files: `sqf-function.md`, `code-review.md`, `validation-report.md`

---

### governance/

| File | Purpose |
|---|---|
| `policies/coding-standards.md` | Naming, indentation, header format, locality rules |
| `policies/scope-control.md` | Forbidden paths, SQA-approval paths, addon source rule |
| `policies/phase-control.md` | Phase table, gate rules, blocked-phase enforcement |
| `policies/workaround-policy.md` | When workarounds are allowed, how to register them |
| `guardrails/generated-files.md` | Table of every generated/protected path with reason |
| `audit/validation-log.md` | Running log — Codex appends after every validated task |

---

### evals/

#### `evals/suites/hemtt-check.md`

- Command: `.\tools\check.ps1`
- Pass: exit code `0`, no errors
- Fail: any non-zero exit or error line
- When: after every source or config change

#### `evals/suites/vr-smoke.md`

- Command: `.\tools\launch-vr.ps1`
- Pass: mission loads, no script errors in RPT, physics matches expected
- Fail: script error, crash, or physics regression
- When: after any gameplay or physics change
- Note: must be run by SQA — Codex cannot verify in-game behavior

---

### docs/

#### `docs/architecture/project-map.md`

Visual map showing addon layer vs Codex support layer vs generated output.

#### `docs/superpowers/README.md`

Superpowers workflow: naming convention, design phase, planning phase, execution phase.

#### `docs/fixes/`

| File | Purpose |
|---|---|
| `fix-log.md` | Root cause, evidence, approval, VR results per fix |
| `workaround-registry.md` | Active scripted approximations with removal conditions |
| `open-issues.md` | Unresolved gameplay defects — empty unless a real issue exists |

All entries use committed evidence only. Missing data recorded as `not recorded`.

---

## Session Data Flow

```
Session Start
  ↓
Read CODEX.md, AGENTS.md, orchestration/state.md     (always, silently)
  ↓
Ask SQA: "Ready. What are we working on?"
  ↓
Match objective → CONTEXT-LOAD.md table              (load one row only)
  ↓
Present suggestion card                              (wait for yes)
  ↓
Intake — inspect affected source and tests
  ↓
Approval gate if risk triggered                      (wait for yes)
  ↓
Implement approved plan only
  ↓
Run tools\check.ps1                                  (must pass)
  ↓
Append to governance/audit/validation-log.md
  ↓
Present completion report to SQA
  ↓
Update orchestration/state.md
```

---

## Error Handling

| Situation | Rule |
|---|---|
| HEMTT not found | Exit with clear error — do not silently succeed |
| Validation fails on doc-only change | Pre-existing issue — record it, do not block the doc change |
| Objective does not match CONTEXT-LOAD table | Ask SQA before loading anything |
| Two sources conflict | Repository layout wins over wiki; SQA judgment wins over both |
| File already in context | Do not re-read — use what is already loaded |

---

## Scope Limits

This design does NOT:

- Move or rename files under `addons/main/`
- Replace or modify HEMTT project layout
- Introduce Python, REST, or external agent platforms
- Create live or autonomous agents
- Edit `.hemttout/`, packed PBOs, or release output
- Generate evaluation reports before real validation data exists
- Claim manual Arma coverage unless SQA verified it in-game