# Scope Control

## Default Rule

Make the smallest targeted change that satisfies the approved task and keeps the addon valid.

## Stay In Scope

- Preserve the HEMTT layout.
- Keep addon source under `addons/main/`.
- Add abstractions only when they reduce real duplication or clarify ownership.
- Keep generated output, logs, reports, and release artifacts untouched.
- Do not rename folders to match diagrams or documentation if tooling already works.

## Escalate Before Changing

Ask SQA before:

- moving addon source;
- changing build tooling;
- adding dependencies;
- changing public function names;
- adding native binaries;
- broad `CfgVehicles` inheritance changes;
- multiplayer authority or synchronization work;
- release packaging or signing behavior.

## Approved Exception

### FIXICS-EXC-2026-06-07-VEHICLE-PHYSICS-BEYOND-SQF

Phase 1 may evaluate work beyond SQF when SQA reproduces a vehicle physics defect that remains after local SQF mitigation and the defect is tied to engine handling, config, PhysX, gearbox, or extension behavior.

This exception authorizes the current native source scaffold, optional SQF bridge, local Windows x64 build wrapper, and approved root `FIXICSPhysics_x64.dll`.

It does not authorize additional native binaries, new dependencies, multiplayer authority, broad config patching, release packaging, or generated-output edits.

Preferred escalation order:

1. SQF diagnostics and local scripted mitigation.
2. Targeted config-class experiment.
3. Native extension research or implementation.
