# SQF Syntax Reference

## Purpose

This file is the **long-form SQF and Arma 3 scripting reference** for the FIXICS repository. Use it when CODEX or a human contributor needs language context, syntax rules, behavioral explanations, or source links.

This reference is descriptive. For enforceable project coding rules, use `governance/policies/coding-standards.md`.

---

## Table of Contents

1. [Source Index](#source-index)
2. [How To Use This File](#how-to-use-this-file)
3. [Local Supplemental Examples](#local-supplemental-examples)
4. [SQF Overview](#sqf-overview)
5. [Core Terminology](#core-terminology)
6. [Syntax Basics](#syntax-basics)
7. [Data Types](#data-types)
8. [Operators](#operators)
9. [Order of Precedence](#order-of-precedence)
10. [Control Structures](#control-structures)
11. [Variables and Scope](#variables-and-scope)
12. [Functions](#functions)
13. [Arrays](#arrays)
14. [HashMaps](#hashmaps)
15. [Magic Variables](#magic-variables)
16. [Event Handlers](#event-handlers)
17. [Scheduling: Unscheduled vs Scheduled Execution](#scheduling-unscheduled-vs-scheduled-execution)
18. [Multiplayer Scripting](#multiplayer-scripting)
19. [Error Handling and Debugging](#error-handling-and-debugging)
20. [Performance Guidelines](#performance-guidelines)
21. [Common Scripting Mistakes](#common-scripting-mistakes)
22. [Practical Review Checklist](#practical-review-checklist)

---

## Source Index

### Primary Bohemia Interactive Community (BIC) References

These are the authoritative sources. When engine behavior is unclear, go here first.

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

### Related Source Families

Check these during deeper or specialized work:

**Data Types**
`Boolean`, `Code`, `Config`, `Control`, `Display`, `Group`, `HashMap`, `Namespace`, `Number`, `Object`, `Script_Handle`, `String`, `Structured_Text`, `Nothing`, `Void`, `If_Type`, `For_Type`, `Switch_Type`, `While_Type`, `With_Type`

**Advanced Topics**
- `Event_Scripts` and scripted event handlers
- UI event handlers
- `PreProcessor_Commands` (`#define`, `#include`, `#ifdef`, etc.)
- `Initialisation_Order` — critical for understanding when scripts and functions are first available
- Function recompiling
- Common scripting errors
- Exception handling (`try`/`catch`/`throw`)
- Arma 3 functions library pages (BIS built-in functions)

---

## How To Use This File

Read the appropriate sections **before** making changes — not after.

| You are about to… | Read this first |
|---|---|
| Ask CODEX to explain or refactor SQF | `Core Terminology` |
| Change an expression with commands, arithmetic, `select`, `#`, `&&`, or `\|\|` | `Order of Precedence` |
| Create or move a `fn_*.sqf` file | `Variables and Scope`, `Functions` |
| Write server/client branching, remote execution, event handlers, or JIP handling | `Multiplayer Scripting` |
| Work with loops, long-running behavior, or anything that calls `sleep` | `Scheduling: Unscheduled vs Scheduled Execution` |
| Add or modify event handlers | `Event Handlers` |
| Debug unexpected behavior or silent failures | `Error Handling and Debugging` |
| Optimize existing code for performance | `Performance Guidelines` |
| Commit implementation changes | `governance/policies/coding-standards.md` — decision checklist |

---

## Local Supplemental Examples

The folder `docs/additional-sqf-files` contains local reference material added by the project owner. It currently includes **18 SQF/config-style mission files** and a large sound library.

### Representative Script Groups

| Area | Files |
|---|---|
| Artillery and projectiles | `autoArtilleryFire.sqf`, `scoutArtilleryFire.sqf`, `unifiedArtilleryFire.sqf`, `trackProjectile.sqf` |
| Movement and insertion | `flyInChopper.sqf`, `paraDropHelpers.sqf`, `moveCaptives.sqf` |
| AI and group behavior | `manageGunCrew.sqf`, `manageJeepCrew.sqf`, `monitorGroupRespawn.sqf`, `huntRemainingEnemies.sqf`, `checkCompanyStatus.sqf` |
| Mission systems | `reviveSystem.sqf`, `turnOffLights.sqf`, `runTest.sqf`, `common.sqf`, `commonFunctions.sqf`, `Description.ext` |

### CODEX Boundary Rules for This Folder

- These files are useful for **examples, pattern mining, and manual review only**.
- They are **not** addon runtime source while they remain under `docs/additional-sqf-files`.
- To promote a file into the addon:
  1. Move or rewrite it into `addons/main/functions/fn_name.sqf`
  2. Register it in `addons/main/config.cpp` under `CfgFunctions`
  3. Rename all references to the `BASEARMA_fnc_name` convention
  4. Run HEMTT validation: `hemtt check`
- Sound files under this folder are **reference assets only** unless a future task explicitly moves them into an addon asset path and registers their usage.

---

## SQF Overview

**SQF** stands for **Status Quo Function**. It is the main Arma scripting language and succeeded the older SQS format. SQF is intentionally simple at the grammar level — most behavior is delivered through **engine commands** that act as operators rather than through language keywords.

### The Three Command Shapes

Every SQF command fits one of three shapes:

| Shape | Form | Description | Example |
|---|---|---|---|
| **Nular** | `commandName` | Takes no argument. Reads or returns current engine state. | `allUnits`, `time`, `player` |
| **Unary** | `commandName argument` | Takes one argument to its right. | `alive player`, `str _num` |
| **Binary** | `left commandName right` | Takes arguments on both sides. | `player setDir 90`, `_a + _b` |

> **Important:** SQF is unforgiving because many commands are direct engine calls, not ordinary language keywords. When in doubt: add parentheses, name intermediate values with `private`, and always validate with `hemtt check` before committing.

### Script Execution Contexts

SQF code can run in two distinct contexts. This matters for `sleep`, `waitUntil`, and anything involving time:

| Context | How entered | Can call `sleep`? | Notes |
|---|---|---|---|
| **Unscheduled** | `call`, config `init`, event handlers | ❌ No | Runs synchronously; blocks the game frame until complete. |
| **Scheduled** | `spawn`, `execVM` | ✅ Yes | Runs asynchronously; can yield execution to the engine. |

---

## Core Terminology

Understanding these terms precisely prevents misdiagnosis when bugs arise.

| Term | Formal Meaning | Practical Use in This Repository |
|---|---|---|
| **Argument** | A value passed to a command, script, or function at the call site. | In `[_unit, 50] call BASEARMA_fnc_name`, the array `[_unit, 50]` is the argument. |
| **Parameter** | The local name that receives an argument inside a script or function body. | Use `params ["_unit", "_radius"];` at the top of every function. |
| **Identifier** | The name of a variable, function, class, or config entry. | Use descriptive names. Prefix all global/public names with `BASEARMA_`. |
| **Expression** | Any fragment of code that evaluates to a single value. | The final expression in a `call`ed code block is its return value. |
| **Operand** | A value consumed by an operator. | In `_a + _b`, both `_a` and `_b` are operands. |
| **Operator** | A command or symbol that performs work on one or more operands. | `+`, `#`, `select`, `setDir`, `&&`, `remoteExec` — each has precedence and locality implications. |
| **Statement** | A complete instruction or expression terminated by `;`. | Write one clear statement per line. Avoid stacking multiple statements on one line. |
| **Variable** | A named value stored in a namespace or local scope. | Prefer local `_variables`. Use globals only deliberately and with full prefix. |
| **Magic Variable** | An engine-provided, scope-specific variable such as `_this`, `_x`, or `thisList`. | Know when the engine provides one; avoid accidentally shadowing it. |
| **Function** | A code block or registered file invoked with `call`, `spawn`, or engine systems. | Addon functions live in `addons/main/functions/fn_name.sqf` and are exposed as `BASEARMA_fnc_name`. |
| **Locality** | Whether an object, variable, or effect is owned/visible on the current machine. | The most common source of silent multiplayer bugs. Always check command docs for locality requirements. |
| **Scheduling** | Whether a code block runs in the unscheduled (frame-blocking) or scheduled (yielding) context. | Mismatching scheduling context and `sleep` calls is a common source of hard-to-trace errors. |

---

## Syntax Basics

### Expression Termination

Every SQF statement must end with a semicolon (`;`):

```sqf
private _num = 10;
_num = _num + 20;
systemChat str _num;
```

Line breaks are **not** statement separators. You can place multiple statements on one line, but this repository uses **one statement per line** for readability and diff clarity.

```sqf
// ✅ Correct — one statement per line
private _a = 5;
private _b = 10;
private _c = _a + _b;

// ⚠️ Technically valid but avoid in this repo
private _a = 5; private _b = 10; private _c = _a + _b;
```

### Bracket Types and Their Roles

| Bracket | Role | Example |
|---|---|---|
| `( )` | Override evaluation order; group subexpressions explicitly. | `(1 + 2) * 3` |
| `[ ]` | Create array literals; pass argument lists to functions. | `[player, 50]` |
| `{ }` | Create code values (unevaluated blocks). Used for lambdas, loops, and control bodies. | `{ alive _x }` |

```sqf
private _total = 1 + (2 * 3);          // parentheses override precedence
private _units = [player];              // array literal
private _alive = _units select { alive _x };  // code block as filter predicate
```

### Whitespace and Indentation

Whitespace is ignored by the engine in most positions, but it is critical for maintainability. This repository uses **4-space indentation**.

```sqf
if (alive _unit) then {
    _unit setDamage 0;
    _unit enableAI "PATH";
};
```

### Comments

Use comments to explain **intent** and **non-obvious engine constraints** — not to restate what the code already says clearly.

```sqf
// ✅ Good — explains a non-obvious engine constraint
// Guard UI work: dedicated servers do not have a player interface.
if (!hasInterface) exitWith {};

// ❌ Bad — restates what the code already says
// Check if unit is alive
if (alive _unit) then { ... };
```

Use block comments for function headers:

```sqf
/*
 * BASEARMA_fnc_resetUnit
 *
 * Resets a unit's damage and re-enables its AI pathfinding.
 *
 * Arguments:
 *   0: Unit to reset <OBJECT>
 *   1: Delay in seconds before reset <NUMBER> (default: 0)
 *
 * Return Value:
 *   Success <BOOL>
 *
 * Locality: Must be called on the machine where the unit is local.
 *
 * Example:
 *   [player, 2] call BASEARMA_fnc_resetUnit;
 */
```

### Code Values

Curly-brace blocks `{ }` are **values** until executed by a command. This is fundamental to how SQF works.

```sqf
private _announce = {
    params ["_message"];
    systemChat _message;
};

["Ready"] call _announce;
```

This is why control structures feel unusual at first — `if`, `while`, `forEach`, and `switch` are engine commands that accept code blocks as arguments, not language keywords in the traditional sense.

---

## Data Types

SQF is dynamically typed. Every value has a type at runtime. Understanding types prevents silent coercion bugs.

| Type | Description | Literal Form |
|---|---|---|
| `Boolean` | True or false. | `true`, `false` |
| `Number` | IEEE 754 floating-point. All arithmetic is floating-point. | `1`, `3.14`, `-0.5` |
| `String` | Text. Double or single quotes. | `"hello"`, `'world'` |
| `Array` | Ordered, zero-indexed, mixed-type collection. | `[1, "a", true]` |
| `Code` | An unevaluated block. | `{ systemChat "hi"; }` |
| `Object` | An Arma entity (unit, vehicle, building, etc.). | returned by commands like `player`, `vehicle _unit` |
| `Group` | A collection of units under one commander. | returned by `group _unit`, `createGroup` |
| `Config` | A config entry node. | `configFile >> "CfgVehicles"` |
| `Control` | A UI control element. | returned by `findDisplay`, `ctrlCreate` |
| `Display` | A UI display/dialog. | returned by `findDisplay`, `createDisplay` |
| `Namespace` | A named storage space for variables. | `missionNamespace`, `uiNamespace`, `parsingNamespace` |
| `HashMap` | An unordered key-value store. Keys must be strings. | `createHashMap` |
| `Script Handle` | A handle to a spawned script. | returned by `spawn`, `execVM` |
| `Nothing` / `Void` | No value returned. Assigning this to a variable leads to undefined behavior. | returned by commands like `hint` |

### Type Checking

```sqf
// Check type at runtime with typeName
private _val = 42;
if (typeName _val == "SCALAR") then {
    systemChat "It's a number.";
};

// Common type strings
// "SCALAR"   — Number
// "BOOL"     — Boolean
// "STRING"   — String
// "ARRAY"    — Array
// "CODE"     — Code
// "OBJECT"   — Object
// "GROUP"    — Group
// "NAMESPACE"— Namespace
// "NOTHING"  — Nothing
```

### Number Precision Notes

- All numbers are 32-bit floats. Very large integers lose precision above ~16 million.
- Avoid comparing floats with `==`. Use a tolerance band instead:

```sqf
private _epsilon = 0.001;
if (abs (_a - _b) < _epsilon) then {
    // treat as equal
};
```

### String Notes

- String equality via `==` is **case-insensitive** in SQF.
- For case-sensitive comparison, convert both strings to the same case first:

```sqf
if (toLower _str1 == toLower _str2) then { ... };
```

- Use `format` for string construction:

```sqf
private _msg = format ["Unit %1 has %2 HP", name _unit, damage _unit];
```

---

## Operators

### Nular Operators

Nular operators take no argument and return engine state or a value:

```sqf
private _allUnitsNow = allUnits;   // returns array of all units
private _now = time;               // returns mission time in seconds
private _me = player;              // returns the local player object
```

> **Performance note:** Treat expensive nular commands as commands, not free property reads. If you call a nular command repeatedly in a loop, store the result once before the loop:

```sqf
// ❌ Calls allUnits on every iteration
{
    systemChat name _x;
} forEach allUnits;

// ✅ Captures once
private _all = allUnits;
{
    systemChat name _x;
} forEach _all;
```

### Unary Operators

Unary operators take one argument to their right:

```sqf
private _isDead = !alive player;
private _copy = +_array;
private _asString = str _someNumber;
```

Unary commands bind **tightly** to the next argument. If a calculated expression is intended as the argument, parenthesize it:

```sqf
// ❌ Wrong: sleep receives 10, then Nothing + random 20 is evaluated and discarded
sleep 10 + random 20;

// ✅ Correct: entire expression is evaluated first, then passed to sleep
sleep (10 + random 20);
```

### Binary Operators

Binary operators take a left and a right operand:

```sqf
player setDir 180;
private _sum = _a + _b;
private _item = _array # 0;
private _alive = _units select { alive _x };
```

When two binary operators share the same precedence, evaluation proceeds **left to right**:

```sqf
// These are equivalent:
_a - _b - _c
(_a - _b) - _c
```

Parentheses are always cheaper than a precedence bug.

### Operator Reference Table

| Operator Family | Operators | Notes |
|---|---|---|
| **Arithmetic** | `+` `-` `*` `/` `%` `mod` `^` `min` `max` `atan2` | All floating-point. `%` and `mod` are equivalent. `^` is exponentiation. |
| **Comparison** | `==` `!=` `<` `>` `<=` `>=` | String `==` is case-insensitive. Use `toLower` for case-sensitive comparisons. |
| **Logical** | `&&` `and` `\|\|` `or` `!` `not` | `&&` and `and` are identical. `\|\|` and `or` are identical. Short-circuit evaluation applies. |
| **Array Access** | `#` `select` | `#` is higher precedence and faster for direct index access. `select` is more readable for conditions. |
| **String** | `+` | String concatenation. |
| **Config Access** | `>>` `/` | `>>` navigates config hierarchy. `/` divides config entries. Both have precedence implications — parenthesize when chaining. |
| **Assignment** | `=` | Stores a value. Should stand alone on its own line. Does not return the assigned value. |
| **Unary Arithmetic** | `+array` `-number` | `+array` deep-copies an array. `-number` negates. |

### Short-Circuit Evaluation

`&&` and `||` short-circuit — the right side is only evaluated if the left side does not determine the result:

```sqf
// If !alive _unit is false, the right side is never evaluated
if (!alive _unit && { _unit distance _target < 50 }) then { ... };
```

Wrapping the right-side expression in `{ }` is recommended when it involves expensive commands — the code block is only called if needed.

---

## Order of Precedence

Precedence controls which operations bind first when no parentheses are present. Higher number = higher priority. Associativity is left-to-right within the same level.

| Level | Type | Examples |
|---|---|---|
| **11** | Nular operators, literals, and grouped expressions | Variables, numbers, strings, `()`, `[]`, `{}` |
| **10** | Unary operators | `+a`, `-a`, `+array`, `!b`, `not b`, `alive x`, `str x` |
| **9** | Hash-select | `array # index` |
| **8** | Power | `a ^ b` |
| **7** | Multiply, divide, remainder, `atan2`, config `/` | `a * b`, `a / b`, `a % b`, `a mod b`, `a atan2 b` |
| **6** | Add, subtract, string concat, `min`, `max` | `a + b`, `a - b`, `str1 + str2`, `a min b`, `a max b` |
| **5** | `else` | Used in `if-then-else` structure |
| **4** | Binary operators (general engine commands) | `setDir`, `setDamage`, `remoteExec`, `call`, `:` in switch |
| **3** | Comparisons, config `>>` | `==`, `!=`, `>`, `<`, `>=`, `<=`, `config >> name` |
| **2** | Logical AND | `&&`, `and` |
| **1** | Logical OR | `\|\|`, `or` |

### Precedence Examples and Traps

| Expression | How Engine Reads It | Correct Form |
|---|---|---|
| `1 + 2 * 3` | `1 + (2 * 3)` → `7` | As written is correct; just be aware. |
| `sleep 10 + random 20` | `(sleep 10) + random 20` → discards result | `sleep (10 + random 20)` |
| `!alive _unit && _unit distance _pos < 50` | `(!alive _unit) && ((_unit distance _pos) < 50)` | Add explicit parentheses for clarity even when technically correct. |
| `_arr select 0 + 1` | `_arr select (0 + 1)` → index 1 | Usually intended, but parenthesize explicitly. |
| `a setVariable ["key", val, true]` | Binary operator — `setVariable` binds `a` on left and array on right. | Fine as written. |

> **Rule of thumb:** If you cannot immediately state the evaluation order of an expression, add parentheses until you can. Parentheses have no performance cost.

---

## Control Structures

SQF control structures are engine commands that receive expressions or code blocks. They are not special language keywords.

### `if / then / else`

```sqf
// Basic form
if (_condition) then {
    // true branch
};

// With else
if (_condition) then {
    // true branch
} else {
    // false branch
};

// exitWith — acts as an early return for the current scope
if (!alive _unit) exitWith {
    diag_log "Unit is dead — aborting.";
    false  // return value
};
```

> Use `exitWith` for **guard clauses** at the top of a function to reduce nesting depth. Do not use it mid-function as a flow-control replacement for `else`.

### `switch / do`

```sqf
switch (_state) do {
    case "ready": {
        _unit enableAI "PATH";
    };
    case "hold": {
        _unit disableAI "PATH";
    };
    case "retreat";  // fall-through: shares the next case's body
    case "withdraw": {
        _unit doMove _retreatPos;
    };
    default {
        _unit setBehaviour "AWARE";
    };
};
```

> Use `switch` when many branches test **the same single concept**. Do not use it when conditions are varied and unrelated — use `if/else if` chains instead.

### `while / do`

```sqf
while { alive _unit } do {
    sleep 1;
    _unit doMove (getPos _unit vectorAdd [0, 10, 0]);
};
```

> `while` loops **must** run in a scheduled context (`spawn`/`execVM`) if they use `sleep` or `waitUntil`. Running a non-yielding `while` loop in an unscheduled context (`call`) will freeze the game.

### `for / do` (Counted Loop)

```sqf
// Basic counted loop
for "_i" from 0 to (count _array - 1) do {
    private _element = _array select _i;
    systemChat str _element;
};

// With step
for "_i" from 0 to 100 step 10 do {
    systemChat str _i;  // 0, 10, 20, ... 100
};

// Counting down
for "_i" from 10 to 0 step -1 do {
    systemChat str _i;  // 10, 9, 8, ... 0
};
```

> Use `_i` for numeric counters. Use meaningful names for everything else. Prefer `forEach` over `for` when iterating arrays — it is cleaner and less prone to off-by-one errors.

### `forEach`

```sqf
// Basic iteration
{
    _x setDamage 0;
} forEach units _group;

// With index
{
    systemChat format ["%1: %2", _forEachIndex, name _x];
} forEach allUnits;

// Destructuring each element (when elements are sub-arrays)
{
    _x params ["_name", "_position"];
    systemChat format ["%1 at %2", _name, _position];
} forEach _waypoints;
```

> Inside `forEach`, `_x` is the current element and `_forEachIndex` is the zero-based index. Do **not** shadow `_x` in nested loops — store the outer value first:

```sqf
{
    private _outerUnit = _x;
    {
        if (_x != _outerUnit) then {
            _outerUnit doTarget _x;
        };
    } forEach allUnits;
} forEach units _group;
```

### `waitUntil`

```sqf
// Block scheduled execution until condition is true
waitUntil { alive _target };

// With a timeout pattern
private _startTime = time;
waitUntil {
    (alive _target) || { (time - _startTime) > 30 }
};
```

> `waitUntil` only works in a **scheduled context**. The condition code block is re-evaluated every frame by default. If the check is expensive, add a `sleep` inside:

```sqf
waitUntil {
    sleep 0.5;
    alive _target
};
```

### `try / catch`

```sqf
try {
    private _result = _riskyArray select 999;  // out-of-bounds
} catch {
    diag_log format ["Caught exception: %1", _exception];
};
```

> `_exception` is the magic variable available inside the `catch` block. See the [Error Handling](#error-handling-and-debugging) section for full details.

---

## Variables and Scope

### Local Variables

Local variables begin with `_` and exist only within the current code block scope. Always declare them with `private` or `params`:

```sqf
params ["_unit", ["_radius", 25, [0]]];

private _nearUnits = _unit nearEntities ["Man", _radius];
private _count = count _nearUnits;
```

**Never use a local variable before declaring it.** Undefined `_variables` return `nil` in modern Arma and cause runtime errors.

### Global Variables

Global variables do **not** start with `_` and persist for the duration of the mission on the machine where they were set. In this repository, all global names **must** be prefixed with `BASEARMA_`:

```sqf
// Setting a global
BASEARMA_debugEnabled = true;

// Broadcasting to all machines
publicVariable "BASEARMA_debugEnabled";
```

> Never use unprefixed global names like `debugEnabled` — they risk collisions with engine variables, other mods, or mission scripts.

### Namespace Variables

Use namespace variables to share data scoped to a namespace rather than polluting the global space:

```sqf
// Per-object data
player setVariable ["BASEARMA_lastInteraction", time, true];
private _last = player getVariable ["BASEARMA_lastInteraction", 0];

// Mission-wide data on missionNamespace
missionNamespace setVariable ["BASEARMA_objectiveState", "active"];

// UI-scoped data (survives between dialogs)
uiNamespace setVariable ["BASEARMA_selectedUnit", player];
```

The third argument to `setVariable` controls whether the variable is broadcast to all machines (`true`) or remains local (`false`/omitted). **Do not broadcast per-frame or private data.**

### The `with` Statement

`with` changes the default namespace for a block:

```sqf
with uiNamespace do {
    private _disp = findDisplay 46;
    // operations here use uiNamespace by default
};
```

### Scope Summary

| Variable Type | Prefix | Scope | Use Case |
|---|---|---|---|
| Local | `_name` | Current code block only | Parameters, intermediate values, loop counters |
| Global | `BASEARMA_name` | Mission-wide on declaring machine | Shared state flags, module-level configuration |
| Public | `BASEARMA_name` + `publicVariable` | All machines | Synchronized mission state (use sparingly) |
| Namespace | `setVariable` with prefix | Attached to an object/namespace | Per-unit data, UI state, mission namespace state |

---

## Functions

### File Location and Naming Convention

All addon functions must follow this exact structure:

```
addons/main/functions/fn_name.sqf   → file
BASEARMA_fnc_name                   → exposed identifier
```

Register every function in `addons/main/config.cpp` under `CfgFunctions`. Failing to register a function means it will not be compiled or available at mission start.

### Standard Function File Structure

Every function file must follow this template:

```sqf
/*
 * BASEARMA_fnc_exampleFunction
 *
 * Brief description of what this function does.
 *
 * Arguments:
 *   0: The primary object or unit <OBJECT>
 *   1: Radius in meters <NUMBER> (default: 25)
 *   2: Optional flag to enable debug output <BOOL> (default: false)
 *
 * Return Value:
 *   Whether the operation succeeded <BOOL>
 *
 * Locality:
 *   Must be called on the machine where the primary object is local.
 *   Effect is local unless the function internally calls publicVariable or remoteExec.
 *
 * Examples:
 *   [player] call BASEARMA_fnc_exampleFunction;
 *   [_vehicle, 50, true] call BASEARMA_fnc_exampleFunction;
 *
 * Dependencies:
 *   BASEARMA_fnc_otherFunction
 */

params [
    ["_object", objNull, [objNull]],
    ["_radius", 25, [0]],
    ["_debug", false, [false]]
];

// Guard: reject null input early
if (isNull _object) exitWith {
    if (_debug) then {
        diag_log "[BASEARMA_fnc_exampleFunction] ERROR: null object passed.";
    };
    false
};

// --- Main logic ---

private _nearUnits = _object nearEntities ["Man", _radius];

if (_debug) then {
    diag_log format ["[BASEARMA_fnc_exampleFunction] Found %1 units within %2m.", count _nearUnits, _radius];
};

// Return value — last evaluated expression
count _nearUnits > 0
```

### The `params` Command in Detail

`params` is the correct way to extract function arguments. Always use it.

```sqf
// Full form with type checking and defaults
params [
    ["_unit",   objNull, [objNull]],    // arg 0: Object, default objNull
    ["_radius", 25,      [0]],          // arg 1: Number, default 25
    ["_label",  "none",  [""]],         // arg 2: String, default "none"
    ["_flags",  [],      [[]]],          // arg 3: Array, default []
];

// Minimal form (no defaults, no type checking — use only for trusted internal calls)
params ["_unit", "_radius"];
```

Type checking via `params` generates a meaningful error if the wrong type is passed, which is invaluable during development and QA.

### Return Values

The return value of a `call`ed function is **the last evaluated expression**:

```sqf
// Returns true on success, false on early exit
params ["_unit"];

if (isNull _unit) exitWith { false };

_unit setDamage 0;

true  // This is the return value — no semicolon needed on the last line, but one is harmless
```

### Call, Spawn, ExecVM — When to Use Each

| Form | Context | Returns | Can `sleep`? | Use For |
|---|---|---|---|---|
| `call` | Unscheduled | Function's return value | ❌ No | Pure helpers, synchronous setup, immediate calculations |
| `spawn` | Creates a new scheduled thread | `Script Handle` | ✅ Yes | Long-running behavior, loops, anything that needs to wait |
| `execVM` | Creates a new scheduled thread | `Script Handle` | ✅ Yes | Mission scripts (`.sqf` files); prefer registered functions in addon code |

```sqf
// call — synchronous, immediate
private _result = [player, 50] call BASEARMA_fnc_exampleFunction;

// spawn — asynchronous, returns handle
private _handle = [player] spawn {
    params ["_unit"];
    waitUntil { !alive _unit };
    systemChat "Unit died!";
};

// Check if spawned script is still running
if !(scriptDone _handle) then {
    systemChat "Still running.";
};
```

> **Never mix contexts casually.** A function designed to be called with `call` must not contain `sleep`. A function that uses `sleep` must be run with `spawn` or `execVM`.

### Recursive Functions

SQF supports recursion but has no tail-call optimization. Keep recursion shallow. For deep traversal, prefer iterative approaches with an explicit stack array.

```sqf
// Example: recursive group-tree traversal (keep depth bounded)
BASEARMA_fnc_countSubordinates = {
    params ["_group"];
    private _count = count units _group;
    {
        _count = _count + ([_x] call BASEARMA_fnc_countSubordinates);
    } forEach subordinates _group;
    _count
};
```

---

## Arrays

Arrays in SQF are **ordered, zero-indexed, and mutable**. They can hold mixed types.

### Creation and Access

```sqf
private _items = ["radio", "map", "compass"];

// Access by index
private _first = _items # 0;         // "radio" — prefer # for direct index
private _second = _items select 1;    // "map" — clearer for dynamic or conditional use

// Get the last element
private _last = _items select (count _items - 1);
```

### Mutation

```sqf
private _arr = [1, 2, 3];

// Append
_arr pushBack 4;              // _arr = [1, 2, 3, 4]
_arr append [5, 6];           // _arr = [1, 2, 3, 4, 5, 6]

// Remove by index
_arr deleteAt 0;              // removes index 0, _arr = [2, 3, 4, 5, 6]

// Remove by value (removes first matching element)
_arr deleteAt (_arr find 3);  // find returns -1 if not found — check before using!

// Set a value at an index
_arr set [0, 99];             // _arr select 0 is now 99

// Sort (ascending)
_arr sort true;

// Reverse
reverse _arr;
```

> **Always guard `find` results** before using as an index:

```sqf
private _idx = _arr find _searchValue;
if (_idx >= 0) then {
    _arr deleteAt _idx;
};
```

### Copying

This is one of the most common sources of bugs in SQF. Assignment does not copy — it creates an alias.

```sqf
private _original = [1, 2, 3];
private _alias = _original;       // same array in memory
_alias set [0, 99];               // modifies _original too!

// Shallow copy (copies top level, nested arrays are still shared)
private _shallow = _original + [];

// Deep copy (copies all levels)
private _deep = +_original;
```

| Method | Copies Top Level | Copies Nested Arrays | Notes |
|---|---|---|---|
| `_b = _a` | ❌ (alias) | ❌ | Same reference — mutations affect both |
| `_b = _a + []` | ✅ | ❌ | Fast; nested arrays are still shared |
| `_b = +_a` | ✅ | ✅ | Full deep copy; safer for complex structures |

### Useful Array Operations

```sqf
// Filter
private _alive = allUnits select { alive _x };

// Transform (apply)
private _names = allUnits apply { name _x };

// Check any match
private _anyDead = allUnits findIf { !alive _x } >= 0;

// Count matches
private _deadCount = { !alive _x } count allUnits;

// Sort by computed value (ascending by distance to player)
private _sorted = [allUnits, [], { _x distance player }, "ASCEND"] call BIS_fnc_sortBy;

// Flatten nested array one level
private _flat = [1, [2, 3], [4, [5]]] call BIS_fnc_arrayFlatten;  // [1, 2, 3, 4, [5]]
```

### Multi-Dimensional Arrays (Structured Data)

Prefer predictable element shapes for arrays that represent structured data:

```sqf
// Each element: [name <STRING>, position <ARRAY>, priority <NUMBER>]
private _objectives = [
    ["alpha", [100, 200, 0], 1],
    ["bravo", [300, 150, 0], 2],
    ["charlie", [500, 400, 0], 1]
];

{
    _x params ["_name", "_pos", "_priority"];
    if (_priority == 1) then {
        systemChat format ["High priority: %1", _name];
    };
} forEach _objectives;
```

---

## HashMaps

HashMaps (introduced in Arma 3 2.02) provide O(1) key lookups. Use them when you need to look up values by a string key frequently.

```sqf
// Create and populate
private _map = createHashMap;
_map set ["alpha", [100, 200, 0]];
_map set ["bravo", [300, 150, 0]];

// Read
private _pos = _map get "alpha";      // [100, 200, 0]
private _exists = _map getOrDefault ["charlie", objNull];

// Check existence
if ("alpha" in _map) then { ... };

// Iterate — _x is key, _y is value
{
    systemChat format ["%1 → %2", _x, _y];
} forEach _map;

// Remove
_map deleteAt "alpha";

// All keys / values
private _keys = keys _map;
private _vals = values _map;
```

> **Use HashMaps over large arrays** when you are doing frequent lookups by name. Searching an array with `find` is O(n); a HashMap lookup is O(1).

---

## Magic Variables

Magic variables are engine-maintained and only valid within specific scopes. Do not attempt to set them manually unless a command pattern explicitly expects it.

| Magic Variable | Scope | Description |
|---|---|---|
| `_this` | `call`, `spawn`, `execVM`, event handlers | The argument(s) passed to the script. In event handlers, contains the event parameters array. |
| `_x` | `forEach`, `apply`, `count`, `findIf`, `select` (with code), `configClasses`, `configProperties` | The current element during iteration. |
| `_y` | `forEach` over a `HashMap` | The value corresponding to key `_x` in a HashMap iteration. |
| `_forEachIndex` | `forEach`, `forEachReversed` | Zero-based index of the current element. |
| `_exception` | `catch` block | Object describing the exception thrown in the preceding `try` block. |
| `_fnc_scriptName` | Inside any registered function | The `TAG_fnc_functionName` string of the current function. Added by `functions_f/initFunctions.sqf`. |
| `_fnc_scriptNameParent` | Inside any registered function | The name of the calling function, or same as `_fnc_scriptName` if not called by another function. |
| `_self` | HashMapObject method bodies | The HashMapObject instance the method was invoked on. |
| `_thisArgs` | `addMissionEventHandler` handlers | Additional event arguments. |
| `_thisEvent` | `addEventHandler`, `addMPEventHandler`, `addMissionEventHandler`, `ctrlAddEventHandler`, `displayAddEventHandler` | String name of the fired event (e.g., `"Killed"`, `"Hit"`). |
| `_thisEventHandler` | Same as `_thisEvent` sources | Numeric index of the event handler as registered. Useful for self-removing handlers. |
| `_thisFSM` | `execFSM` bodies | FSM ID of the running FSM. |
| `_thisScript` | `execVM`, `call`, `spawn` | Script handle of the current script. |
| `this` | Config `onInit`, object init fields, waypoints, triggers | The object or entity the code is attached to. Context-dependent (see full details below). |
| `thisList` | Trigger Condition, On Activation, On Deactivation | Array of detected objects inside the trigger. Unreliable in On Deactivation — do not use. |
| `thisTrigger` | Trigger code blocks | The trigger object itself. |

### `this` Context Details

| Location | `this` refers to |
|---|---|
| Config `UserActions`, `onInit` | The object the config entry belongs to |
| Object init field (Eden/`createVehicle`) | The spawned object |
| Dialog/control `mouseEnter` etc. | The player who activated the control; `false` if non-activated |
| Trigger Condition | The Boolean result of the condition expression |
| Trigger On Activation / On Deactivation | Usually `false` — do not rely on it |
| Waypoint Condition / On Activation | The group leader who completed the waypoint, or the vehicle driver |

---

## Event Handlers

Event handlers execute code in response to engine events. They are a primary integration point with physics, damage, and vehicle systems — all directly relevant to FIXICS.

### Adding Event Handlers

```sqf
// Object event handler — fires when the unit is hit
private _ehIdx = _unit addEventHandler ["Hit", {
    params ["_unit", "_causedBy", "_damage", "_instigator"];
    diag_log format ["%1 was hit by %2 for %3 damage.", name _unit, name _causedBy, _damage];
}];

// Remove by index
_unit removeEventHandler ["Hit", _ehIdx];

// Self-removing handler (fires once then removes itself)
_unit addEventHandler ["Hit", {
    params ["_unit", "_causedBy", "_damage", "_instigator"];
    _unit removeEventHandler [_thisEvent, _thisEventHandler];
    // ... do work ...
}];
```

### Mission Event Handlers

```sqf
addMissionEventHandler ["EntityKilled", {
    params ["_entity", "_killer", "_instigator", "_useEffects"];
    diag_log format ["%1 was killed.", name _entity];
}];
```

### Common Vehicle/Physics Event Handlers Relevant to FIXICS

| Event | Object Type | Parameters | Notes |
|---|---|---|---|
| `"Hit"` | Any | `[unit, causedBy, damage, instigator]` | Fires on any damage event |
| `"HitPart"` | Vehicle | `[[hitUnit, causedBy, damage, hitSelections, hitPoints, ...]]` | Detailed hit data per component |
| `"Killed"` | Any | `[unit, killer, instigator, useEffects]` | Fires on death |
| `"GetIn"` | Vehicle | `[vehicle, role, unit, turretPath]` | Unit enters vehicle |
| `"GetOut"` | Vehicle | `[vehicle, role, unit, turretPath]` | Unit exits vehicle |
| `"EngineChanged"` | Vehicle | `[vehicle, engineState]` | Engine on/off |
| `"GearChanged"` | Wheeled vehicle | `[vehicle, gearIndex]` | Gear shift event |
| `"FuelChanged"` | Vehicle | `[vehicle, fuel]` | Fuel level change |
| `"LandedTouchDown"` | Aircraft | `[plane, airportID]` | Touchdown |
| `"RopeAttach"` | Vehicle/unit | `[object, rope, attachedObject]` | Rope physics |
| `"PhysicsCollision"` | Vehicle | `[object1, object2, collPoint, collSpeed, ...]` | Physics collision data |

> **`"PhysicsCollision"` is especially relevant to FIXICS.** Use it to detect, log, and modify the response to vehicle collisions.

### Event Handler Locality Rules

- Event handlers added with `addEventHandler` are **local to the machine** they are added on.
- Use `addMPEventHandler` for handlers that must fire on **all machines**.
- For synchronized global effects on a hit event, have the local handler call `remoteExecCall` on the server.

---

## Scheduling: Unscheduled vs Scheduled Execution

This is one of the most important distinctions in SQF. Confusing the two is a frequent source of hard-to-debug errors.

### Unscheduled (Frame-Synchronous) Execution

Code executed via `call` or from config entries (object init, event handlers, `onEachFrame`, triggers) runs **synchronously** in the current game frame. The engine waits for it to finish before continuing.

**Rules:**
- Cannot call `sleep`, `waitUntil`, or any command that yields.
- Must complete quickly — long-running logic in an unscheduled context will stutter or freeze the game.
- Returns the function's return value immediately.

```sqf
// ❌ This will freeze the game — sleep in unscheduled context
player addEventHandler ["Hit", {
    sleep 2;  // WRONG — event handlers are unscheduled
    hint "You were hit!";
}];

// ✅ Correct — spawn a new scheduled thread from the event handler
player addEventHandler ["Hit", {
    [] spawn {
        sleep 2;
        hint "You were hit!";
    };
}];
```

### Scheduled (Asynchronous) Execution

Code executed via `spawn` or `execVM` runs in its own **scheduled thread**. The engine can suspend it at `sleep`, `waitUntil`, and similar commands.

**Rules:**
- Can call `sleep`, `waitUntil`, `uiSleep`.
- Runs concurrently with other scheduled scripts.
- Cannot return a value directly (returns a script handle; use shared variables to communicate results).
- Multiple scripts may interleave — avoid shared mutable state without careful ordering.

```sqf
// Spawn a monitoring loop
private _monitorHandle = [player] spawn {
    params ["_unit"];
    while { alive _unit } do {
        private _speed = speed _unit;
        if (_speed > 100) then {
            diag_log format ["[FIXICS] High speed detected: %1 km/h", _speed];
        };
        sleep 0.5;
    };
};
```

### Communicating Between Contexts

Use a shared namespace variable to pass results from a scheduled thread back to unscheduled code:

```sqf
// Spawn a calculation in scheduled context
[] spawn {
    sleep 1;  // simulate async work
    BASEARMA_calculationResult = 42;
};

// Later (in a polling loop or another event), read the result
if (!isNil "BASEARMA_calculationResult") then {
    systemChat str BASEARMA_calculationResult;
};
```

---

## Multiplayer Scripting

### Machine Role Checks

Always establish which machine is running the code before performing role-sensitive operations:

| Check | Meaning | Use For |
|---|---|---|
| `isServer` | This machine is the server (dedicated or hosted). | Writing authoritative mission state, spawning AI, making decisions. |
| `isDedicated` | This machine is a dedicated server with no player UI. | Server-only logic that must not run on player-hosted servers. |
| `hasInterface` | This machine has a player UI (human player). | UI updates, `hint`, `systemChat`, HUD manipulation. |
| `!hasInterface && !isDedicated` | This machine is a headless client. | Offloaded AI processing. |
| `didJIP` | This client joined after mission start. | Sending catch-up state to late joiners. |

### The Locality Principle

Every object in Arma has an **owner machine** — the machine where it is "local." Commands that modify an object's physical state usually require that you run them on the object's local machine.

```sqf
// Check locality
if (local _vehicle) then {
    _vehicle setVelocity [0, 0, 0];  // safe — we own this vehicle
} else {
    // We don't own it — ask the owner to do it
    [_vehicle] remoteExecCall ["BASEARMA_fnc_stopVehicle", owner _vehicle];
};
```

### Remote Execution

```sqf
// Execute on the server
["BASEARMA_fnc_doServerWork", 2] call bis_fnc_mp;

// Better modern form — remoteExec
[_args, "BASEARMA_fnc_doServerWork", 2] remoteExec ["call", 2];  // 2 = server

// remoteExecCall (no return value needed)
[_args] remoteExecCall ["BASEARMA_fnc_doServerWork", 2];

// Execute on all clients (excluding server)
[_args] remoteExecCall ["BASEARMA_fnc_updateUI", -2];

// Execute on all machines including server
[_args] remoteExecCall ["BASEARMA_fnc_broadcastState", 0];

// Execute on a specific machine by owner ID
[_args] remoteExecCall ["BASEARMA_fnc_doWork", owner _unit];
```

### Machine Target Reference

| Target | Meaning |
|---|---|
| `0` | All machines |
| `2` | Server |
| `-2` | All clients (excluding server) |
| `owner _unit` | The machine where `_unit` is local |
| A specific number | A specific machine's owner ID |

### `publicVariable`

```sqf
// Broadcast a variable to all machines
BASEARMA_objectiveState = "complete";
publicVariable "BASEARMA_objectiveState";

// Broadcast to a specific machine
publicVariableTo [clientOwner, "BASEARMA_someVar"];
```

> Only broadcast variables that are genuinely needed everywhere. Broadcasting large arrays or per-frame values causes network load. For per-unit data, use `setVariable` with broadcast flag instead.

### JIP (Join-In-Progress) Handling

Players who join a running mission miss all initialization that already ran. Handle this explicitly:

```sqf
// On server: maintain a JIP queue
if (isServer) then {
    [{ BASEARMA_objectiveState = "active"; }, [], "BASEARMA_jip_objectives"] call BIS_fnc_MP;
};
```

`BIS_fnc_MP` with a JIP ID re-sends the call to any player who connects after the fact.

### Multiplayer Architecture Pattern for FIXICS

```sqf
// Server: authoritative physics state management
if (isServer) then {
    {
        _x addEventHandler ["PhysicsCollision", {
            params ["_veh", "_other", "_collPoint", "_collVel"];
            // Server decides what happens
            if (speed _veh > 80) then {
                [_veh, _collVel] remoteExecCall ["BASEARMA_fnc_applyCollisionDamage", 2];
            };
        }];
    } forEach vehicles;
};

// Clients: local presentation only
if (hasInterface) then {
    player addEventHandler ["Hit", {
        params ["_unit", "", "_damage"];
        if (_damage > 0.3) then {
            playSound "heavyImpact";
        };
    }];
};
```

---

## Error Handling and Debugging

### `try / catch`

```sqf
try {
    private _result = _someArray select 999;  // intentionally out of bounds
} catch {
    diag_log format ["[BASEARMA] Exception in fnc_example: %1", _exception];
};
```

`_exception` is an object with these useful properties:

```sqf
_exception select 0   // Error code (Number)
_exception select 1   // Error message (String)
```

### `diag_log` vs `hint` vs `systemChat`

| Command | Output | Visible To | Use For |
|---|---|---|---|
| `diag_log` | `arma3.log` | Developer only | Permanent debug output — safe to leave in shipping code (minimal perf cost) |
| `hint` | Screen popup | Local player only | Quick temporary debug; remove before shipping |
| `systemChat` | Chat area | Local player only | Lightweight status messages during dev |
| `remoteExec ["hint", 0]` | Screen popup | All players | Never use in production |

### Defensive Coding Patterns

```sqf
// Guard against null objects
if (isNull _vehicle) exitWith {
    diag_log "[BASEARMA_fnc_example] ERROR: null vehicle.";
    false
};

// Guard against wrong array length
if (count _args < 2) exitWith {
    diag_log format ["[BASEARMA_fnc_example] ERROR: expected 2 args, got %1.", count _args];
    false
};

// Safe array access
private _val = _arr param [0, "default"];  // returns "default" if index 0 absent or wrong type
```

### Checking for `nil`

```sqf
// isNil takes a STRING name of the variable
if (isNil "BASEARMA_someFlag") then {
    diag_log "Variable not yet initialized.";
};

// isNil also accepts a code block
if (isNil { missionNamespace getVariable "BASEARMA_someFlag" }) then { ... };
```

### Common Runtime Error Messages

| Error Message | Likely Cause |
|---|---|
| `Undefined variable in expression: _x` | `_x` used outside a `forEach` or iteration context, or a typo in variable name |
| `Type Array, expected Object` | Passing an array where a command expects an object |
| `Type Nothing, expected Number` | Using the return value of a command that returns `Nothing` (like `sleep`) |
| `Error: 0 elements provided, 1 expected` | `params` received fewer arguments than required |
| `Script ... not found` | Path typo in `execVM`, or function not registered in `CfgFunctions` |

---

## Performance Guidelines

Physics scripting in FIXICS runs frequently and must be efficient. Follow these rules:

### Avoid Per-Frame Work in Unscheduled Contexts

```sqf
// ❌ Very expensive — nearEntities called every frame
player addEventHandler ["EachFrame", {
    private _near = player nearEntities ["Car", 50];
}];

// ✅ Use a scheduled loop with sleep to throttle
[] spawn {
    while { true } do {
        private _near = player nearEntities ["Car", 50];
        // process _near
        sleep 0.5;  // check twice per second, not every frame
    };
};
```

### Cache Expensive Calls

```sqf
// ❌ Calls allVehicles on every loop iteration
while { true } do {
    { /* ... */ } forEach allVehicles;
    sleep 1;
};

// ✅ Cache if the list doesn't change during the loop
private _vehicles = allVehicles;
while { true } do {
    { /* ... */ } forEach _vehicles;
    sleep 1;
};
```

### Prefer `#` Over `select` for Direct Index Access

```sqf
private _fast = _arr # 0;         // slightly faster — no command overhead
private _also = _arr select 0;    // fine but marginally more overhead
```

### Minimize `remoteExec` Calls

Each `remoteExec` generates network traffic. Batch multiple updates into one call when possible:

```sqf
// ❌ Three separate network messages
[_veh] remoteExecCall ["BASEARMA_fnc_updateSpeed", 2];
[_veh] remoteExecCall ["BASEARMA_fnc_updateFuel", 2];
[_veh] remoteExecCall ["BASEARMA_fnc_updateDamage", 2];

// ✅ One message with all state
[_veh, speed _veh, fuel _veh, damage _veh] remoteExecCall ["BASEARMA_fnc_updateVehicleState", 2];
```

### Avoid `execVM` in Addon Code

`execVM` compiles the script from disk every call. Use pre-registered functions via `call` instead — they are compiled once at mission start.

### Use `BIS_fnc_sortBy` Instead of Manual Sort Loops

The built-in sort function is implemented in engine code and is faster than a handwritten bubble sort.

---

## Common Scripting Mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Using `sleep` in an event handler or `call`ed function | Game freezes or `sleep` is silently ignored | `spawn` a new thread from the event handler body |
| Not deep-copying arrays with `+` | Mutations unexpectedly affect the original array | Use `+_array` for a deep copy |
| Using `find` result as an index without checking for `-1` | Array index out of bounds error | Always check `if (_idx >= 0)` before using `find` result |
| Comparing floats with `==` | Condition never triggers due to precision | Use `abs (_a - _b) < epsilon` |
| Accessing a variable before it is set in a JIP scenario | `nil` variable errors on late-joining clients | Use `getVariable` with a default, or add to a JIP queue |
| Forgetting to register a new function in `CfgFunctions` | Function undefined at mission start | Keep `fn_*.sqf` and `CfgFunctions` in sync — run `hemtt check` |
| Broadcasting variables too frequently | Network lag and desync | Only broadcast state that genuinely needs to be global |
| Running `nearEntities` / `allUnits` every frame | Frame rate drops | Throttle with `sleep` in a scheduled loop |
| Using `_x` in a nested `forEach` without aliasing the outer `_x` | Outer loop variable gets shadowed | `private _outerItem = _x;` before the nested loop |
| Not parenthesizing `sleep (time + N)` | `sleep` receives `time`, then `+ N` is ignored | Always parenthesize compound arguments to unary commands |

---

## Practical Review Checklist

Before asking CODEX to modify or create SQF, verify:

### Scope and Targeting

- [ ] Is the target file addon source under `addons/main/functions/`, or only reference material under `docs/additional-sqf-files/`?
- [ ] If promoting a reference file to addon source, has the renaming, registration, and HEMTT validation been planned?

### Function Structure

- [ ] Are parameters declared with `params` at the top of the function?
- [ ] Does the function have a complete header comment (description, arguments, return value, locality)?
- [ ] Does the function guard against null/invalid inputs with early `exitWith`?
- [ ] Is the return value explicitly the last expression?

### Variable Hygiene

- [ ] Are all locals declared `private` or via `params`?
- [ ] Are all local variable names prefixed with `_`?
- [ ] Are all globals and namespace keys prefixed with `BASEARMA_`?
- [ ] Are there any unprotected `find` results used directly as array indices?

### Precedence and Correctness

- [ ] Is expression precedence obvious without relying on memory?
- [ ] Are compound arguments to unary commands (like `sleep`) properly parenthesized?
- [ ] Are float comparisons handled with a tolerance instead of `==`?

### Scheduling

- [ ] Does code that uses `sleep` or `waitUntil` run in a scheduled context (`spawn`/`execVM`)?
- [ ] Are event handlers free of direct `sleep` calls?
- [ ] Is per-frame or high-frequency work throttled appropriately?

### Multiplayer

- [ ] Does the code identify server, client, UI, headless client, and JIP responsibilities clearly?
- [ ] Are object modifications performed on the machine where the object is local?
- [ ] Are `remoteExec` targets correct and minimal?
- [ ] Are `publicVariable` calls restricted to genuinely global state?
- [ ] Is JIP handling implemented for state that late joiners need?

### Validation and Registration

- [ ] Is `addons/main/config.cpp` synchronized with any new or renamed function files?
- [ ] Did `.\tools\check.ps1` (or `hemtt check`) pass after the change?
- [ ] Are debug `hint` calls removed or gated behind a debug flag before committing?