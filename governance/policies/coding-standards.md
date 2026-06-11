# Coding Standards

## Authority

Repository layout and existing addon source override generic examples. Use `FIXICS_` for public names, globals, public variables, and namespace keys.

## Quick Rules

| Topic | Rule |
|---|---|
| Function file | `addons/main/functions/fn_name.sqf` |
| Public function | `FIXICS_fnc_name` through `CfgFunctions` |
| PBO prefix | `x\fixics\addons\main` |
| Validation | `powershell -ExecutionPolicy Bypass -File tools\check.ps1` |
| Generated files | never edit `.hemttout/`, packed PBOs, reports, logs, or private keys |

## SQF Style

- Four-space indentation.
- One statement per line.
- Semicolons on SQF statements.
- `params` at the top for function inputs.
- `private` for locals after `params`.
- Guard invalid input early with `exitWith`.
- Use `call` for synchronous return values.
- Use `spawn` only when scheduled behavior such as `sleep` is required.
- Never use `execVM` in addon source.
- Do not shadow `_this`, `_x`, `_y`, `_forEachIndex`, `this`, `thisList`, or `thisTrigger`.
- Parenthesize expressions where precedence is not obvious.

## Function Header

```sqf
/*
 * FIXICS_fnc_name
 *
 * One-line description.
 *
 * Arguments:
 *   0: Vehicle <OBJECT>
 *
 * Return: <BOOL> true when the update was applied
 * Locality: local machine
 *
 * Engine note:
 *   Short note for non-obvious locality or PhysX behavior.
 *
 * Example:
 *   [_vehicle] call FIXICS_fnc_name;
 */
```

Detailed root cause, math, before/after observations, approval, and VR evidence belong in `docs/fixes/`, not in every function header.

## Multiplayer And Locality

- Modify an object where it is local.
- Use the minimum necessary `remoteExecCall` target.
- Never broadcast per-frame physics values.
- Do not assume `player` exists on dedicated servers.
- Treat every `setVariable` public flag as an explicit network decision.

## Config

- Keep `addons/main/config.cpp` synchronized with `fn_*.sqf`.
- Add only real `requiredAddons[]` dependencies.
- Do not patch broad parent classes without SQA approval.
- Do not add config experiments unless they are approved under `scope-control.md`.

## Comments

Use comments for intent, locality, engine constraints, and external references. Include Comments on SQF Syntax, for Balanced Technical and Easy-to-Understand purpose and instructions for SQA to adjust code themselves.

## Pre-Completion Checklist

- [ ] New functions are registered in `CfgFunctions`.
- [ ] All public identifiers use `FIXICS_`.
- [ ] Object mutation respects locality.
- [ ] Repeated user-facing text uses `stringtable.xml`.
- [ ] Static tests and `tools\check.ps1` pass or failures are reported with evidence.
- [ ] Manual Arma coverage is reported separately from automated validation.
