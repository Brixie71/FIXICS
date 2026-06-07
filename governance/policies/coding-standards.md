# Coding Standards

## Authority

Repository layout overrides broad BIC wiki guidance when they conflict.
Source basis: `AGENTS.md`, `CODEX.md`, BIC wiki (SQF syntax, variables, functions, arrays, best practices, precedence, multiplayer scripting).

---

## Quick-Decision Table

Use this before writing any line of code.

| Question | Rule |
|---|---|
| Where does a new function file go? | `addons/main/functions/fn_name.sqf` |
| How is it called? | `FIXICS_fnc_name` via registered `CfgFunctions` |
| What prefix do all globals, namespace keys, public vars use? | `FIXICS_` |
| When do I use `call` vs `spawn`? | `call` = needs return value or must be synchronous. `spawn` = needs `sleep` or runs long. |
| When do I use `execVM`? | Never in addon code. Mission scripts only. |
| What validation must pass before commit? | `.\tools\check.ps1` (or `hemtt check`) |
| Do I touch `.hemttout/`, packed PBOs, or release output? | Never. |

---

## Formatting

```
Indentation : 4 spaces — SQF, C++ config, XML, HPP
Semicolons  : required on every SQF statement
Line density: one statement per line
Braces (SQF): compact — if (_cond) then { ... };
Braces (cfg): Allman — matches existing addons/main/config.cpp style
```

- Add blank lines between logical blocks; do not compress unrelated work onto one line.
- Parenthesize any expression where precedence is not immediately obvious.

```sqf
// ✅
sleep (10 + random 20);
private _result = (a + b) * c;

// ❌
sleep 10 + random 20;       // sleep gets 10; rest is discarded
private _result = a + b * c; // ambiguous intent
```

---

## Naming

| Thing | Convention | Example |
|---|---|---|
| Addon function file | `fn_name.sqf` | `fn_resetVehicle.sqf` |
| Public function identifier | `FIXICS_fnc_name` | `FIXICS_fnc_resetVehicle` |
| Local variable | `_lowerCamelCase` | `_targetUnit` |
| Loop counter | short `_i`, `_j` acceptable | `_i` |
| Global / public variable | `FIXICS_name` | `FIXICS_debugEnabled` |
| Namespace key (`setVariable`) | `"FIXICS_keyName"` | `"FIXICS_lastInteraction"` |
| Macro / constant | `UPPER_SNAKE_CASE` | `MAX_VEHICLE_SPEED` |
| User-facing string | entry in `addons/main/stringtable.xml` | never hardcoded in multiple scripts |

---

## Variables and Scope

**Rules — no exceptions:**

1. Declare all function inputs with `params` at the top.
2. Declare all subsequent locals with `private`.
3. Never use a variable before declaring it.
4. Never assign an unprefixed name at global scope — it pollutes all mods.
5. Never shadow engine magic variables: `_this`, `_x`, `_y`, `_forEachIndex`, `this`, `thisList`, `thisTrigger`.
6. Prefix every `setVariable` key with `FIXICS_`.
7. Treat broadcast flags (`publicVariable`, `setVariable` third arg) as explicit network decisions — not defaults or copy-paste.

```sqf
// ✅ Correct scope discipline
params [
    ["_unit",   objNull, [objNull]],
    ["_radius", 25,      [0]]
];
private _nearVehicles = _unit nearEntities ["Car", _radius];

// ❌ Violations
nearVehicles = nearEntities ["Car", 25];   // unprefixed global
_unit setVariable ["lastHit", time];       // unprefixed key
```

---

## Function Structure

### Required Template

Every new addon function must follow this shape exactly:

```sqf
/*
 * FIXICS_fnc_name
 *
 * One-line description.
 *
 * Arguments:
 *   0: <TYPE>  description (default: value)
 *   1: <TYPE>  description (default: value)
 *
 * Return: <TYPE> description
 * Locality: server | local machine | any
 *
 * Example:
 *   [player, 50] call FIXICS_fnc_name;
 */

params [
    ["_unit",   objNull, [objNull]],
    ["_radius", 25,      [0]]
];

// Guard: reject invalid input immediately
if (isNull _unit) exitWith {
    diag_log "[FIXICS_fnc_name] ERROR: null unit.";
    false
};

// --- logic ---

true  // explicit return
```

### Function Rules

| Rule | Rationale |
|---|---|
| One function per file | Matches HEMTT compile model; keeps diffs clean |
| `params` for all inputs | Type-safe; generates useful errors during QA |
| `private` for all post-params locals | Prevents scope leaks |
| Guard with `exitWith` at top | Reduces nesting; exits cleanly |
| Explicit return as last expression | Prevents returning `Nothing` accidentally |
| `call` when caller needs a return value | Synchronous; safe in any context |
| `spawn` only when `sleep` or long-running | Creates a scheduled thread; do not use casually |
| Never `execVM` in addon code | Recompiles from disk every call; use registered functions |
| Split when nesting depth > 3 or logic > ~60 lines | Keeps each function reviewable in one pass |
| Keep `CfgFunctions` synchronized | HEMTT fails to compile unregistered functions |

---

## Arrays and Data Structures

### Access

```sqf
_arr # 0          // direct index — preferred for clarity and precedence
_arr select 0     // use when condition or command form is clearer
```

### Copying — Read Before Mutating

| Form | Top-level copy | Nested copy | Use when |
|---|---|---|---|
| `_b = _a` | ❌ alias | ❌ | Never — mutates original |
| `_b = _a + []` | ✅ | ❌ | Nested arrays are intentionally shared |
| `_b = +_a` | ✅ | ✅ | Full independence required |

```sqf
// ✅ Safe mutation
private _copy = +_originalArray;
_copy set [0, "changed"];   // _originalArray untouched

// ❌ Alias trap
private _alias = _originalArray;
_alias set [0, "changed"];  // modifies _originalArray too
```

### Unpack Structured Elements

```sqf
// ✅ Unpack known-shape elements with params
{
    _x params ["_name", "_pos", "_priority"];
    if (_priority == 1) then {
        [_name, _pos] call FIXICS_fnc_markObjective;
    };
} forEach _objectives;

// ❌ Magic indices obscure intent
_x select 0   // what is index 0?
```

### Mutation Rules

- Document or avoid mutating arrays that were passed in by the caller.
- Always guard `find` before using its result as an index:

```sqf
private _idx = _arr find _target;
if (_idx >= 0) then { _arr deleteAt _idx; };
```

- Prefer `apply` over manual `forEach` + `pushBack` for transforms:

```sqf
private _names = allUnits apply { name _x };   // ✅ concise
```

---

## Control Flow

### Guard Clauses First

```sqf
// ✅ Guards at top — main logic reads left-to-right with no deep nesting
if (isNull _vehicle) exitWith { false };
if (!alive _driver)  exitWith { false };

// main logic here — no extra indent level needed
```

### When to Use Each Structure

| Structure | Use when |
|---|---|
| `if / exitWith` | Early return / guard clause |
| `if / then / else` | Two-branch conditional |
| `switch / do` | Multiple branches testing the same concept |
| `for / do` | Counted numeric iteration |
| `forEach` | Iterating arrays or groups — prefer over `for` |
| `while / do` | Condition-driven loop (scheduled context only if it contains `sleep`) |
| `waitUntil` | Block a scheduled thread until a condition is true |

### Scheduling Rules — Critical

```
Unscheduled (call, event handlers, config init):
  ✅ Can: return values, run fast deterministic logic
  ❌ Cannot: sleep, waitUntil, block for time

Scheduled (spawn, execVM):
  ✅ Can: sleep, waitUntil, run long behavior
  ❌ Cannot: return values directly to caller
```

```sqf
// ❌ Freezes the game — sleep in event handler (unscheduled)
player addEventHandler ["Hit", {
    sleep 2;
    hint "Hit!";
}];

// ✅ Correct — spawn a thread from the event handler
player addEventHandler ["Hit", {
    [] spawn { sleep 2; hint "Hit!"; };
}];
```

---

## Comments

**Write comments for:** intent, locality requirements, engine constraints, non-obvious tradeoffs, adapted community logic (with source link).

**Never write comments that:** restate the command name, explain what SQF syntax does, describe obvious variable assignments.

```sqf
// ✅ Explains a non-obvious engine constraint
// Guard: dedicated servers have no player object — UI commands will error.
if (!hasInterface) exitWith {};

// ❌ Restates the code
// Check if unit is alive
if (alive _unit) then { ... };
```

For adapted community logic, record the source:

```sqf
// Adapted from BIS_fnc_nearestBuilding — simplified for vehicle-only use.
// Source: https://community.bistudio.com/wiki/BIS_fnc_nearestBuilding
```

---

## Multiplayer and Locality

### Machine Role Checks

```sqf
isServer        // authoritative decisions, AI spawning, state writes
isDedicated     // server-only logic that must not run on hosted sessions
hasInterface    // UI updates, hints, HUD — never run these on dedicated
didJIP          // client joined late — needs catch-up state
```

### Locality Rule

> Modify an object on the machine where it is local. If you do not own it, use `remoteExecCall` to the owner.

```sqf
if (local _vehicle) then {
    _vehicle setVelocity [0,0,0];
} else {
    [_vehicle] remoteExecCall ["FIXICS_fnc_stopVehicle", owner _vehicle];
};
```

### `remoteExec` Target Reference

| Target value | Meaning |
|---|---|
| `0` | All machines |
| `2` | Server |
| `-2` | All clients (excluding server) |
| `owner _unit` | Machine where `_unit` is local |

### Network Discipline

- Do not broadcast large arrays or per-frame values. Each `publicVariable` and `remoteExec` has network cost.
- Do not assume `player` exists on a dedicated server.
- JIP clients miss all past initialization — use `BIS_fnc_MP` with a JIP ID for state they need:

```sqf
// Server — queue state for any client that joins late
if (isServer) then {
    [{ FIXICS_objectiveState = "active"; }, [], "FIXICS_jip_init"] call BIS_fnc_MP;
};
```

---

## Promoting Scripts from `docs/additional-sqf-files`

Before any script in that folder becomes addon source, complete **all** steps:

- [ ] Identify: is this mission-only or addon-safe?
- [ ] Strip: mission file paths, editor object references, hardcoded sounds, trigger names, unprefixed globals
- [ ] Rewrite into `addons/main/functions/fn_name.sqf`
- [ ] Rename all public behavior to `FIXICS_fnc_name`
- [ ] Register in `addons/main/config.cpp` under `CfgFunctions`
- [ ] Move required assets to an intentional addon asset path
- [ ] Add stringtable entries for all repeated user-facing strings
- [ ] Run `hemtt check` — must pass before promotion is complete

---

## Validation

```powershell
# After every source change
.\tools\check.ps1       # or: hemtt check

# After gameplay / UI / mission-flow changes — must actually launch and verify
.\hemtt.exe launch vr
.\hemtt.exe launch eden
```

Record manual coverage and known limitations in the PR notes or final report. Do not claim manual coverage unless the launch ran and behavior was checked.

---

## CODEX Pre-Commit Checklist

Run through every item before claiming a fix is complete.

### Files
- [ ] Edited file is addon source — not generated `.hemttout` output, packed PBOs, or release files
- [ ] New functions are under `addons/main/functions/` and registered in `CfgFunctions`
- [ ] `CfgFunctions` is synchronized — no orphaned or unregistered `fn_*.sqf` files

### Code Quality
- [ ] All inputs declared with `params`; all locals declared with `private`
- [ ] All globals, public vars, and namespace keys prefixed with `FIXICS_`
- [ ] No magic variables shadowed (`_this`, `_x`, `_y`, `_forEachIndex`, `this`, `thisList`, `thisTrigger`)
- [ ] Precedence-sensitive expressions are parenthesized
- [ ] `find` results checked `>= 0` before use as an index
- [ ] No `sleep` or `waitUntil` in unscheduled contexts (event handlers, `call`ed functions)
- [ ] No `execVM` in addon code — use registered functions

### Multiplayer
- [ ] Server/client/UI/JIP responsibilities are explicit and correct
- [ ] Object modifications run on the machine where the object is local
- [ ] `remoteExec` targets are correct and the minimum necessary
- [ ] No large arrays or per-frame values broadcast unnecessarily

### Strings and Assets
- [ ] Repeated user-facing text uses `stringtable.xml` — not hardcoded in multiple scripts
- [ ] Reference scripts from `docs/additional-sqf-files` were fully adapted before promotion

### Validation
- [ ] `.\tools\check.ps1` passed, or final report explains why it could not run
- [ ] Debug `hint` / `systemChat` calls removed or gated behind a `FIXICS_debugEnabled` flag