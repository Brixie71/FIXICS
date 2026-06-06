# Arma Scripting Docs — Design Spec

## Purpose

Improve the BASE-ARMA repository's Arma 3 scripting knowledge base so CODEX can edit scripts accurately without needing to re-derive language rules from first principles each session.

The update targets exactly two files:

| File | Role |
|---|---|
| `SQF-Syntax.md` | Deep research notebook and SQF language reference. CODEX reads this for explanation and examples. |
| `governance/policies/coding-standards.md` | Enforceable project checklist. CODEX reads this before every edit. |

This spec does **not** change addon source, HEMTT config, or any runtime behavior.

---

## Source Set

All content must be derived from these official Bohemia Interactive Community sources. Do not copy large sections verbatim — summarize, organize, and adapt to addon work.

### Core Language References

| Topic | URL |
|---|---|
| Introduction to Arma Scripting | https://community.bistudio.com/wiki/Introduction_to_Arma_Scripting |
| Argument | https://community.bistudio.com/wiki/Argument |
| Identifier | https://community.bistudio.com/wiki/Identifier |
| Expression | https://community.bistudio.com/wiki/Expression |
| Operand | https://community.bistudio.com/wiki/Operand |
| Operators | https://community.bistudio.com/wiki/Operators |
| Parameter | https://community.bistudio.com/wiki/Parameter |
| Statement | https://community.bistudio.com/wiki/Statement |
| Variables | https://community.bistudio.com/wiki/Variables |
| Magic Variables | https://community.bistudio.com/wiki/Magic_Variables |
| Function | https://community.bistudio.com/wiki/Function |
| SQF Syntax | https://community.bistudio.com/wiki/SQF_Syntax |
| Order of Precedence | https://community.bistudio.com/wiki/Order_of_Precedence |
| Control Structures | https://community.bistudio.com/wiki/Control_Structures |
| Code Best Practices | https://community.bistudio.com/wiki/Code_Best_Practices |
| Multiplayer Scripting | https://community.bistudio.com/wiki/Multiplayer_Scripting |
| Array | https://community.bistudio.com/wiki/Array |
| Exception Handling | https://community.bistudio.com/wiki/Exception_handling |
| Event Scripts | https://community.bistudio.com/wiki/Event_Scripts |
| Scripted Event Handlers | https://community.bistudio.com/wiki/Arma_3:_Scripted_Event_Handlers |
| UI Event Handlers | https://community.bistudio.com/wiki/User_Interface_Event_Handlers |
| PreProcessor Commands | https://community.bistudio.com/wiki/PreProcessor_Commands |
| Initialisation Order | https://community.bistudio.com/wiki/Initialisation_Order |
| Arma 3 Functions Library | https://community.bistudio.com/wiki/Arma_3:_Functions_Library |
| Writing a Function / Recompiling | https://community.bistudio.com/wiki/Arma_3:_Writing_a_Function#Recompiling |

### Data Type References

| Type | URL |
|---|---|
| Boolean | https://community.bistudio.com/wiki/Boolean |
| Code | https://community.bistudio.com/wiki/Code |
| Config | https://community.bistudio.com/wiki/Config |
| Control | https://community.bistudio.com/wiki/Control |
| Display | https://community.bistudio.com/wiki/Display |
| Group | https://community.bistudio.com/wiki/Group |
| HashMap | https://community.bistudio.com/wiki/HashMap |
| Namespace | https://community.bistudio.com/wiki/Namespace |
| Number / NaN | https://community.bistudio.com/wiki/Number — https://community.bistudio.com/wiki/NaN |
| Object | https://community.bistudio.com/wiki/Object |
| Script Handle | https://community.bistudio.com/wiki/Script_Handle |
| Side | https://community.bistudio.com/wiki/Side |
| String | https://community.bistudio.com/wiki/String |
| Structured Text | https://community.bistudio.com/wiki/Structured_Text |
| Nothing / Void / Anything | https://community.bistudio.com/wiki/Nothing — https://community.bistudio.com/wiki/Void — https://community.bistudio.com/wiki/Anything |
| If_Type / For_Type / While_Type / Switch_Type / With_Type | BIC wiki pages for each |
| Position / Vector3D / Color / Date | BIC wiki pages for each |
| Waypoint / Task / Team / Team Member | BIC wiki pages for each |
| Unit Loadout Array | https://community.bistudio.com/wiki/Unit_Loadout_Array |

### Command and Function Index

| Category | URL |
|---|---|
| Scripting Commands (all) | https://community.bistudio.com/wiki/Category:Scripting_Commands |
| Arma 3 Scripting Commands | https://community.bistudio.com/wiki/Category:Arma_3:_Scripting_Commands |
| Commands by Functionality | https://community.bistudio.com/wiki/Category:Scripting_Commands_by_Functionality |
| Functions | https://community.bistudio.com/wiki/Category:Functions |
| Functions by Functionality | https://community.bistudio.com/wiki/Category:Functions_by_Functionality |
| Common Scripting Errors | https://community.bistudio.com/wiki/Category:Common_Scripting_Errors |

---

## Architecture Decision

Split documentation by **audience and use frequency**:

```
SQF-Syntax.md
  ↳ CODEX reads when it needs explanation, examples, or edge-case rules
  ↳ Long, thorough, organized by topic
  ↳ Not enforced — reference only

governance/policies/coding-standards.md
  ↳ CODEX reads before every edit
  ↳ Short, direct, no tutorial prose
  ↳ Enforced — every rule is a project standard
```

---

## SQF-Syntax.md Design

### Required Section Order

```
# SQF Syntax Reference
## Purpose
## Source Index
## How To Use This File          ← navigation guide: which section to read for which task
## Local Supplemental Examples   ← docs/additional-sqf-files inventory and boundary rules
## SQF Overview                  ← language history, three command shapes, execution contexts
## Core Terminology              ← table: argument, parameter, identifier, expression, operand, operator, statement, variable, magic variable, function, locality, scheduling
## Syntax Basics                 ← termination, bracket roles, whitespace, comments, code values
## Data Types                    ← type table, typeName, float precision, string case behavior
## Operators                     ← nular, unary, binary, short-circuit, operator family table
## Order of Precedence           ← approved 3-column table + approved examples table (do not alter)
## Control Structures            ← if/exitWith, switch, while, for, forEach, waitUntil, try/catch
## Variables and Scope           ← local, global, namespace, with statement, scope table
## Functions                     ← required template, params deep-dive, return values, call/spawn/execVM table, recursion note
## Arrays                        ← creation, access, mutation, copying table, find guard, apply/findIf/count, structured data
## HashMaps                      ← creation, CRUD, iteration, when to prefer over arrays
## Magic Variables               ← full table with description + version source
## Event Handlers                ← addEventHandler, addMPEventHandler, self-removing pattern, FIXICS-relevant physics events table
## Scheduling                    ← unscheduled vs scheduled table, sleep-in-event-handler anti-pattern, inter-context communication
## Multiplayer Scripting         ← machine role checks, locality principle, remoteExec target table, publicVariable rules, JIP pattern, FIXICS architecture example
## Error Handling and Debugging  ← try/catch, _exception, diag_log/hint/systemChat table, defensive patterns, isNil, common error messages
## Performance Guidelines        ← per-frame caching, throttle with sleep, # vs select, remoteExec batching, execVM cost
## Common Scripting Mistakes     ← table: mistake / symptom / fix (minimum 10 rows)
## Practical Review Checklist    ← categorized checklist: scope, function structure, variable hygiene, precedence, scheduling, multiplayer, validation
```

### Content Rules

- Each section must be independently useful — CODEX should be able to jump to any section without reading others first.
- Use `✅` / `❌` pairs for every correct/incorrect code example.
- Every code example must be syntactically valid SQF.
- The `## Order of Precedence` table must not be modified without SQA approval.
- Magic variables table must preserve all existing rows and their version sources.
- The `## How To Use This File` section must be a lookup table: "If you are about to do X, read section Y."

---

## Coding Standards Design

### Required Section Order

```
# Coding Standards
## Authority                     ← one sentence: repo layout beats wiki when they conflict
## Quick-Decision Table          ← 7-row table answering the most common CODEX questions instantly
## Formatting                    ← indentation, semicolons, line density, brace style (SQF vs config)
## Naming                        ← table: thing / convention / example (function file, public name, local var, global, macro, string)
## Variables and Scope           ← 7 numbered hard rules + one correct/incorrect code pair
## Function Structure            ← required template + rules table with rationale column
## Arrays and Data Structures    ← access, copying table, mutation rules, find guard, apply preference
## Control Flow                  ← guard-clause pattern, structure-selection table, scheduling rules box
## Comments                      ← write for / never write for lists + source attribution rule
## Multiplayer and Locality      ← machine role checks, locality rule, remoteExec target table, network discipline, JIP pattern
## Promoting Scripts             ← gated checklist for docs/additional-sqf-files → addons/main/
## Validation                    ← exact commands + manual coverage recording rule
## CODEX Pre-Commit Checklist    ← 20-item categorized checklist: files, code quality, multiplayer, strings/assets, validation
```

### Content Rules

- Every rule must be phrased as a project standard, not tutorial prose.
- The `## Quick-Decision Table` must answer the 7 questions CODEX most frequently needs to look up.
- The `## CODEX Pre-Commit Checklist` must be the last thing CODEX reads before claiming a fix is complete.
- No section may exceed what fits in a single focused read — split if a section grows beyond ~40 lines.
- Rules must be binary — either done or not done. Avoid rules with qualifications like "usually" or "generally."

---

## Data Flow

After this design is implemented, the intended CODEX workflow is:

```
1. Read CODEX.md                          → project scope, validation gates, SQA protocol
2. Read coding-standards.md              → rules to follow before writing any code
3. Read SQF-Syntax.md section(s)         → explanation and examples for the specific task
4. Read agents/specialist/<role>.md      → scoped guidance for the task type
5. Edit source under addons/main/        → targeted change only
6. Run .\tools\check.ps1                 → must pass before proceeding
7. Report to SQA for approval            → Stage 3 of the SQA ↔ CODEX protocol
```

---

## Error Handling Rules

| Conflict | Resolution |
|---|---|
| Wiki guidance vs. repository HEMTT layout | Repository layout wins |
| Broad or mission-oriented source material | Adapt to addon work — do not copy blindly |
| Topic is important but not actionable for BASE-ARMA | Put in `SQF-Syntax.md`, not in coding standards |
| Source page is unclear or outdated | Note the uncertainty; do not invent engine behavior |

---

## Testing

Documentation changes do not alter addon runtime behavior. Required validation after every edit:

```powershell
.\tools\check.ps1
```

Pass criteria:
- HEMTT loads project config without error
- Addon configs rapify
- SQF files compile
- Stringtable checks pass

Manual Arma launch (`.\hemtt.exe launch vr`) is **not required** for documentation-only changes.

---

## Scope Limits

This design does **not**:

- change any file under `addons/main/`
- add, rename, or delete SQF functions
- move HEMTT configuration files
- edit `.hemttout/` or packed PBOs
- quote large sections of the Bohemia wiki verbatim
- create a separate documentation generation system
- make claims about engine behavior that are not backed by a BIC source