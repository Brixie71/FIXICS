# Codex Operating Layer — Implementation Plan

> **Codex:** Do NOT start. Present the suggestion card. Wait for SQA approval before touching any file.
> **Loop: Ask → Suggest → Wait → Do.**
> Do not mark a step complete unless its expected output was verified.

---

## Goal

Add a practical Codex operating layer around the existing FIXICS HEMTT addon — without moving, renaming, or modifying any addon source files.

## Architecture Constraints

```
AUTHORITATIVE (do not move or restructure):
  .hemtt/           HEMTT project and launch configuration
  addons/main/      All addon source, functions, strings, missions
  .hemttout/        Generated output — never edited by hand

NEW (Codex support layer — add only):
  CODEX.md          Codex working memory and routing
  AGENTS.md         Delegator contract, session rules, hard rules
  CONTEXT-LOAD.md   Objective-to-file map — controls what Codex loads
  agents/           Agent role overlays
  tools/            PowerShell validation wrappers
  orchestration/    Task routing and shared state
  prompts/          Reusable prompt templates
  governance/       Policies, guardrails, audit log
  evals/            Evaluation definitions and reports
  tests/            Test procedures (not Arma source)
  docs/             Architecture maps and Superpowers artifacts
```

**Tech stack:** Arma 3 addon config, SQF, HEMTT, PowerShell, Markdown, YAML.

**SQA Authority:** SQA approves each task before implementation. Codex presents one suggestion card per task. No task proceeds without a yes.

---

## Suggestion Card Format

Before starting any task, present this to SQA:

```
Objective  : [task name]
Approach   : [one sentence]
Files      : [exact files to be created or modified]
Risk       : [what could break]
Ready to proceed?
```

Wait. Do not write code. Do not modify files. SQA says yes — then execute.

---

## Task 1 — Create Directory Scaffold

**Purpose:** Establish the full folder structure before any files are created so later tasks can reference paths confidently.

**Approval required:** No — directory creation only, no source changes.

- [ ] Present suggestion card to SQA. Wait for yes.
- [ ] Create all required directories:

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

- [ ] Verify scaffold:

```powershell
Get-ChildItem -Recurse -Directory | Where-Object { $_.FullName -notmatch '\.hemttout|\.hemtt|addons' } | Select-Object FullName
```

**Expected:** all 15 directories present. No addon source directories in the list.

- [ ] Report completion card to SQA.

---

## Task 2 — Codex and Agent Guidance Files

**Purpose:** Give Codex a single authoritative entry point (`CODEX.md`), the delegator contract (`AGENTS.md`), the file-routing map (`CONTEXT-LOAD.md`), and scoped specialist overlays under `agents/`.

**Approval required:** Yes — establishes authority order and session contract.

**Files:**
```
CODEX.md
AGENTS.md
CONTEXT-LOAD.md
agents/README.md
agents/orchestrator/README.md
agents/orchestrator/workflow.md
agents/orchestrator/policies.yaml
agents/specialist/README.md
agents/specialist/sqf-agent.md
agents/specialist/config-agent.md
agents/specialist/qa-agent.md
```

- [ ] Present suggestion card to SQA. Wait for yes.
- [ ] Create `CODEX.md` with these sections:

```
## Purpose
## Current Phase
## First Read
## Task Lifecycle
## Agent Routing
## Evidence Policy
```

- [ ] Create `AGENTS.md` with the delegator contract:
  - Identity: delegator under SQA authority. Loop: Ask → Suggest → Wait → Do.
  - Session start: read `CODEX.md`, `AGENTS.md`, `orchestration/state.md` silently. Then ask: "Ready. What are we working on?"
  - Suggestion card format
  - Approval gate format
  - Validation commands
  - Completion report format
  - Hard rules

- [ ] Create `CONTEXT-LOAD.md` with:
  - Objective-to-file map (one row per task type)
  - Resume rule
  - Mid-task lookup table
  - Hard rules

- [ ] Create agent specialist overlays — thin domain guidance only, no duplicate policy:
  - `sqf-agent.md` → SQF behavior in `addons/main/functions/`
  - `config-agent.md` → `CfgFunctions`, `config.cpp`, `stringtable.xml`
  - `qa-agent.md` → validation, smoke checks, error reporting

- [ ] Create `agents/orchestrator/policies.yaml` with: naming rules, forbidden paths, approval triggers.
- [ ] Create `agents/orchestrator/workflow.md` as a thin overlay — no rules duplicated from `AGENTS.md` or governance.

**Expected:** `AGENTS.md` contains the delegator loop. `CONTEXT-LOAD.md` contains the objective table. Agent files contain domain guidance only.

- [ ] Report completion card to SQA.

---

## Task 3 — Tool Wrappers

**Purpose:** Make HEMTT commands consistent and portable across sessions.

**Approval required:** No — wrapper scripts only, no source changes.

**Files:**
```
tools/README.md
tools/check.ps1
tools/build.ps1
tools/launch-vr.ps1
tools/launch-eden.ps1
tools/rpt-patterns.ps1
tools/rpt-parser.ps1
tools/watch-rpt.ps1
```

- [ ] Present suggestion card to SQA. Wait for yes.
- [ ] Create all wrappers following this pattern:

```powershell
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
$hemtt = if (Test-Path '.\hemtt.exe') { '.\hemtt.exe' } else { 'hemtt' }
& $hemtt <command> @args
exit $LASTEXITCODE
```

- [ ] Create `tools/rpt-patterns.ps1` — centralize all RPT pattern strings here.
- [ ] `rpt-parser.ps1` and `watch-rpt.ps1` import from `rpt-patterns.ps1` — no inline patterns.
- [ ] All console output prefixed with `FIXICS`. ASCII output only.
- [ ] Verify:

```powershell
.\tools\check.ps1
```

**Expected:** exits `0` on a clean repository.

- [ ] Report completion card to SQA.

---

## Task 4 — Orchestration and Prompt Library

**Purpose:** Give Codex stable routing logic and reusable prompt templates.

**Approval required:** No — support files only.

**Files:**
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

- [ ] Present suggestion card to SQA. Wait for yes.
- [ ] Create `orchestration/router.yaml` — maps task types to specialist, validation gates, approval flag.
- [ ] Create `orchestration/state.md` — current phase, layout summary, last validated state.
- [ ] Create prompt templates each with: `## Purpose`, `## Template` with `{{PLACEHOLDERS}}`, `## Example`.
- [ ] Report completion card to SQA.

---

## Task 5 — Governance, Evals, Tests, and Docs

**Purpose:** Provide Codex with policies it can enforce, evaluation criteria, and architecture context.

**Approval required:** Yes — establishes enforceable governance.

**Files:**
```
governance/README.md
governance/policies/coding-standards.md
governance/policies/scope-control.md
governance/policies/phase-control.md
governance/policies/workaround-policy.md
governance/guardrails/generated-files.md
governance/audit/validation-log.md
evals/README.md
evals/suites/hemtt-check.md
evals/suites/vr-smoke.md
evals/reports/.gitkeep
tests/README.md
tests/integration/fixics-governance-static.ps1
tests/integration/fixics-vehicle-physics-static.ps1
tests/manual/vr-smoke.md
docs/architecture/project-map.md
docs/superpowers/README.md
docs/fixes/fix-log.md
docs/fixes/workaround-registry.md
docs/fixes/open-issues.md
```

- [ ] Present suggestion card to SQA. Wait for yes.
- [ ] `governance/policies/scope-control.md` — forbidden paths, SQA-approval paths, addon source rule.
- [ ] `governance/guardrails/generated-files.md` — table of every generated/protected path with reason.
- [ ] `governance/policies/phase-control.md` — phase table, gate rules, blocked-phase enforcement.
- [ ] `governance/policies/workaround-policy.md` — when workarounds are allowed, how to register them.
- [ ] `evals/suites/hemtt-check.md` and `vr-smoke.md` — command, pass criteria, fail criteria, when to run.
- [ ] `docs/architecture/project-map.md` — visual map of addon layer vs Codex support layer.
- [ ] `docs/superpowers/README.md` — Superpowers workflow, naming convention, design/plan/execution phases.
- [ ] `docs/fixes/` — `fix-log.md`, `workaround-registry.md`, `open-issues.md` initialized empty with correct headers.
- [ ] Report completion card to SQA.

---

## Task 6 — Validate Full Scaffold

**Purpose:** Confirm the new layer does not break HEMTT and all expected files exist.

**Approval required:** No — validation only.

- [ ] Verify file count:

```powershell
Get-ChildItem -Recurse -File | Where-Object { $_.FullName -notmatch '\.hemttout|addons\\main\\' } | Measure-Object
```

**Expected:** count matches total files created in Tasks 2–5.

- [ ] Run HEMTT validation:

```powershell
.\tools\check.ps1
```

**Expected:** exit code `0`.

- [ ] Run governance static test:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1
```

**Expected:** all assertions pass.

- [ ] Record validation in `governance/audit/validation-log.md`:

```
Date      : [today]
Task      : Codex Operating Layer scaffold
Command   : .\tools\check.ps1
Result    : [pass | fail | pre-existing failure — describe]
Coverage  : automated only
Manual    : not required — no addon source was changed
Follow-up : .\tools\launch-vr.ps1 — required before any gameplay or physics change
```

- [ ] Report final completion card to SQA:

```
Done      : Full Codex operating layer scaffold created
Validated : fixics-governance-static.ps1, fixics-vehicle-physics-static.ps1, tools\check.ps1
Logged    : governance/audit/validation-log.md updated
Next      : Canonical Guidance Cleanup — verify all files are internally consistent
```

---

## Scope Limits

This plan does NOT:

- Move or rename files under `addons/main/`
- Replace HEMTT project layout or config
- Introduce Python, REST, or external agent platforms
- Create live or autonomous agents
- Edit `.hemttout/`, packed PBOs, or release output
- Generate evaluation reports before real validation data exists
- Claim manual Arma coverage unless a launch actually ran and behavior was verified by SQA