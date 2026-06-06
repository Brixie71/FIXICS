# Arma Scripting Docs — Implementation Plan

> **CODEX instruction:** Execute task-by-task using `superpowers:subagent-driven-development` (preferred) or `superpowers:executing-plans`. Each step uses `- [ ]` checkbox syntax for tracking. Do not skip steps. Do not mark a step complete unless its expected output was verified.

---

## Goal

Improve the repository's SQF knowledge base and coding policy so CODEX can edit BASE-ARMA scripts with accurate, unambiguous Arma 3 context.

## Architecture Constraints

| File | Role | Rule |
|---|---|---|
| `SQF-Syntax.md` | Broad SQF research notebook and language reference | Reference only — no enforcement |
| `governance/policies/coding-standards.md` | Enforceable project checklist | Short, direct, no tutorial prose |
| `docs/additional-sqf-files` | Supplemental mission reference material | Not addon source — promote explicitly only |

**Tech stack:** Markdown, SQF, Arma 3, HEMTT, PowerShell validation wrappers.

---

## Task 1 — Supplemental SQF Folder Inventory

**Purpose:** Confirm the boundary between reference material and addon source before editing any docs.

**Touches:** `docs/additional-sqf-files` → `SQF-Syntax.md`, `governance/policies/coding-standards.md`

---

- [x] **Step 1.1 — List all reference scripts**

```powershell
rg --files docs\additional-sqf-files -g '*.sqf' -g '*.ext' -g '*.hpp' -g '*.cpp'
```

**Expected:** command lists `unifiedArtilleryFire.sqf`, `reviveSystem.sqf`, `paraDropHelpers.sqf`, `commonFunctions.sqf`, `Description.ext`, and the remaining 13 files.

**If it fails:** confirm `docs/additional-sqf-files` exists and `rg` (ripgrep) is available on PATH.

---

- [x] **Step 1.2 — Record the folder boundary in both docs**

In `SQF-Syntax.md` under `## Local Supplemental Examples`, document:

- The 18 files grouped by area (artillery, movement, AI, mission systems).
- That these files are useful for pattern mining and review only.
- That they are not addon runtime source until explicitly promoted.
- The full promotion checklist (rename → register → validate).

In `governance/policies/coding-standards.md` under `## Supplemental SQF Reference Files`, document:

- The same promotion checklist as a gated step list.
- That no script from this folder may be used directly in addon code without completing all promotion steps.

**Expected:** both files describe the same boundary in language consistent with `CODEX.md`.

---

## Task 2 — Rewrite SQF Syntax Notebook

**Purpose:** Replace mixed notes with a structured, CODEX-navigable reference.

**Touches:** `SQF-Syntax.md`

---

- [x] **Step 2.1 — Apply the required section structure**

Rewrite `SQF-Syntax.md` using exactly these top-level sections, in this order:

```
# SQF Syntax Reference
## Purpose
## Source Index
## How To Use This File
## Local Supplemental Examples
## SQF Overview
## Core Terminology
## Syntax Basics
## Data Types
## Operators
## Order of Precedence
## Control Structures
## Variables and Scope
## Functions
## Arrays
## HashMaps
## Magic Variables
## Event Handlers
## Scheduling: Unscheduled vs Scheduled Execution
## Multiplayer Scripting
## Error Handling and Debugging
## Performance Guidelines
## Common Scripting Mistakes
## Practical Review Checklist
```

**Do not** add sections not listed above without SQA approval.

---

- [x] **Step 2.2 — Preserve the approved precedence material**

Keep the exact 3-column precedence table (Level / Type / Examples) and the 3-column examples table (Input / Process / Comment) under `## Order of Precedence`. Do not reorder rows. Keep `sleep (10 + random 20)` as the canonical example of the unary-precedence trap.

---

- [x] **Step 2.3 — Preserve and complete the magic variables table**

Keep all existing rows. Ensure these variables are present with description and version source:

`_this`, `_x`, `_y`, `_exception`, `_fnc_scriptName`, `_fnc_scriptNameParent`, `_forEachIndex`, `_self`, `_thisArgs`, `_thisEvent`, `_thisEventHandler`, `_thisFSM`, `_thisScript`, `_thisScriptedEventHandler`, `this`, `thisList`, `thisTrigger`

---

- [x] **Step 2.4 — Verify section anchors exist**

```powershell
Select-String -Path SQF-Syntax.md -Pattern `
  'Source Index', `
  'Local Supplemental Examples', `
  'Order of Precedence', `
  'Magic Variables', `
  'Multiplayer Scripting', `
  'Error Handling and Debugging', `
  'Performance Guidelines', `
  'Practical Review Checklist'
```

**Expected:** all eight patterns found. If any are missing, add the section before closing this task.

---

## Task 3 — Rewrite Coding Standards Policy

**Purpose:** Replace tutorial prose with machine-readable, CODEX-enforceable rules.

**Touches:** `governance/policies/coding-standards.md`

---

- [x] **Step 3.1 — Apply the required section structure**

Rewrite using exactly these sections, in this order:

```
# Coding Standards
## Authority
## Quick-Decision Table
## Formatting
## Naming
## Variables and Scope
## Function Structure
## Arrays and Data Structures
## Control Flow
## Comments
## Multiplayer and Locality
## Promoting Scripts from docs/additional-sqf-files
## Validation
## CODEX Pre-Commit Checklist
```

---

- [x] **Step 3.2 — Enforce repository-specific rules**

The following facts must appear explicitly:

| Fact | Where |
|---|---|
| Addon functions live in `addons/main/functions/fn_name.sqf` | `## Naming` and `## Function Structure` |
| Public functions are registered as `BASEARMA_fnc_name` via `CfgFunctions` | `## Naming` and `## Function Structure` |
| All globals, namespace keys, and public vars use `BASEARMA_` prefix | `## Variables and Scope` |
| Indentation is 4 spaces everywhere | `## Formatting` |
| Repeated user-facing text goes in `addons/main/stringtable.xml` | `## Naming` |
| `execVM` is never used in addon code | `## Function Structure` |
| `hemtt check` must pass before any commit | `## Validation` and `## CODEX Pre-Commit Checklist` |

---

- [x] **Step 3.3 — Verify policy anchors**

```powershell
Select-String -Path governance\policies\coding-standards.md -Pattern `
  'Authority', `
  'Quick-Decision Table', `
  'Function Structure', `
  'Multiplayer and Locality', `
  'Supplemental SQF Reference Files', `
  'CODEX Pre-Commit Checklist'
```

**Expected:** all six patterns found.

---

## Task 4 — Validate Documentation Changes

**Purpose:** Confirm that documentation edits did not break HEMTT compilation or config parsing.

**Touches:** `tools/check.ps1`, `.hemtt/project.toml`, `addons/main/config.cpp` (read-only)

---

- [x] **Step 4.1 — Run automated validation**

```powershell
.\tools\check.ps1
```

**Expected:** HEMTT exits with code `0`. Config rapifies. SQF compiles. Stringtable passes.

**If it fails:** documentation edits do not touch addon source, so a failure here indicates a pre-existing issue. Record it in `governance/audit/validation-log.md` and do not block the doc changes.

---

- [x] **Step 4.2 — Record manual coverage**

Add a short entry to `governance/audit/validation-log.md`:

```
Date      : 2026-06-06
Command   : .\tools\check.ps1
Result    : [pass | fail | pre-existing failure]
Coverage  : automated only — no manual Arma launch required for documentation-only changes
Follow-up : .\hemtt.exe launch vr — required before any gameplay or UI changes
```

---

## Scope Limits

This plan does **not**:

- change addon source files under `addons/main/`
- add or rename SQF functions
- move HEMTT configuration files
- edit `.hemttout/` or packed PBOs
- quote large sections of the Bohemia wiki verbatim
- create a separate documentation generation system

All changes are limited to `SQF-Syntax.md`, `governance/policies/coding-standards.md`, and this plan file.