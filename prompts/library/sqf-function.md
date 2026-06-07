# SQF Function Prompt

Use when adding or changing a `FIXICS_fnc_*` SQF function.

## Context

- Read `AGENTS.md`, `CODEX.md`, and `governance/policies/coding-standards.md`.
- Read `addons/main/config.cpp`.
- Read the target `fn_*.sqf` file or nearby examples.
- Check `addons/main/stringtable.xml` for user-facing text.
- Check the relevant specialist overlay.

## Rules

- One function per `fn_name.sqf`.
- Register new functions in `CfgFunctions`.
- Use `params`, private locals, and `FIXICS_` namespace keys.
- Preserve locality rules.
- Add or update tests before changing behavior.

## Validation

Run the relevant integration static test and `tools\check.ps1`.
