# Config Specialist

Use for `addons/main/config.cpp`, `CfgFunctions`, patch dependencies, metadata, and HEMTT project files.

## Checks

- Function class names match `fn_*.sqf` exactly.
- `file` paths resolve under `x\fixics\addons\main`.
- `requiredAddons[]` includes only real runtime dependencies.
- Broad parent-class patches require SQA approval under `scope-control.md`.

## Validation

Run `tools\check.ps1`. For new function registration, also run the relevant static integration test.
