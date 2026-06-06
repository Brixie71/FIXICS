# Scope Control

## Default Rule

Make the smallest change that satisfies the task and keeps the addon valid.

## Stay In Scope

- Preserve the HEMTT layout.
- Keep addon code under `addons/main/`.
- Add abstractions only when they reduce real duplication or clarify ownership.
- Do not rename folders just to match a diagram if it breaks project tooling.

## Escalate Before Changing

Ask for approval before:

- moving addon source;
- changing build tooling;
- adding new dependencies;
- introducing broad gameplay systems;
- changing public function names used by missions.

## Approved Exception Under Evaluation

### FIXICS-EXC-2026-06-07-VEHICLE-PHYSICS-BEYOND-SQF

Phase 1 Ground Vehicle Physics may evaluate work beyond normal SQF-only runtime changes when all of these conditions are true:

- SQA reproduces a vehicle physics defect that remains after the local SQF rollback/autobrake mitigation.
- The defect is tied to engine vehicle handling, class config, PhysX, gearbox, or extension behavior rather than ordinary script control flow.
- The change is documented in a design or evaluation spec before implementation.
- The user explicitly approves the chosen path before any non-SQF source, dependency, binary, or broad config patch is added.

This exception authorizes the current native source scaffold and optional SQF bridge after SQA reported that the config-class experiment made handling worse. It does not authorize native binaries, new dependencies, multiplayer authority changes, broad `CfgVehicles` patching, build-tool changes, or edits to generated output.

Preferred escalation order:

1. SQF diagnostics and local scripted mitigation.
2. Targeted `CfgVehicles` / vehicle handling config-class experiments.
3. Native extension research only if config-class work cannot reach the required behavior.
