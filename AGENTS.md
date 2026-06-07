# Repository Guidelines

## Project

FIXICS is an Arma 3 addon built with HEMTT. Addon source lives under `addons/main/`; generated output lives under `.hemttout/` and must not be edited.

The public function tag and all public variables or namespace keys use `FIXICS`. Registered functions are called as `FIXICS_fnc_name`. The PBO prefix is `x\fixics\addons\main`.

ACE3 and CBA are hard runtime dependencies for the current vehicle controller.

## Source Layout

- `addons/main/config.cpp`: patch dependencies and `CfgFunctions`.
- `addons/main/functions/`: one SQF function per `fn_name.sqf`.
- `addons/main/stringtable.xml`: localized user-facing text.
- `addons/main/missions/`: manual test missions.
- `native/fixics_physics/`: approved optional Windows x64 extension source.
- `governance/`, `agents/`, `orchestration/`, `prompts/`: tracked Codex operating guidance.
- `docs/reference/`: research aids; verify technical claims against primary sources.
- `docs/fixes/`: issue, fix, and workaround project memory.

## Required Workflow

1. Read `AGENTS.md`, then `CODEX.md`.
2. Read relevant governance policy and specialist guidance.
3. Inspect affected source and current tests before proposing changes.
4. Obtain SQA approval when the risk-based gate in `CODEX.md` applies.
5. Use test-first development for behavior changes and bug fixes.
6. Run required automated validation.
7. Record manual Arma coverage separately; never claim it unless SQA verified it.

## Validation

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
powershell -ExecutionPolicy Bypass -File tools\check.ps1
```

Build with `tools\build.ps1`. Launch manual tests with `tools\launch-vr.ps1` or `tools\launch-eden.ps1`.

## Editing Rules

- Preserve the HEMTT layout and keep changes targeted.
- Keep `CfgFunctions` synchronized with `fn_*.sqf` files.
- Use four-space indentation.
- Do not revert unrelated local changes.
- Do not edit `.hemttout/`, packed PBOs, reports, logs, or private keys.
- Do not introduce new native binaries, dependencies, multiplayer authority, or broad `CfgVehicles` patches without explicit SQA approval.
