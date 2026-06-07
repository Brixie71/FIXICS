# SQF Specialist

Use for behavior under `addons/main/functions/`.

## Focus

- Read the complete affected function before editing.
- Trace inputs, locality, state variables, and return values.
- Keep new functions under `addons/main/functions/fn_name.sqf`.
- Escalate to config work when `CfgFunctions` registration changes.

## Rules

- Follow `governance/policies/coding-standards.md`.
- Use `FIXICS_` names and namespace keys.
- Do not edit `.hemttout/`, packed PBOs, or reference-only scripts.
- Use test-first changes for bug fixes and behavior changes.

## Validation

Run the relevant integration static test and `tools\check.ps1`.
