# Project State

## Stable Facts

- Project name: FIXICS.
- Type: Arma 3 addon.
- Build tool: HEMTT.
- Addon source: `addons/main/`.
- Function tag: `FIXICS`.
- PBO prefix: `x\fixics\addons\main`.
- Required runtime dependencies: ACE3 interaction menu and CBA.
- Native extension boundary: optional Windows x64 `FIXICSPhysics_x64.dll`, approved only under `FIXICS-EXC-2026-06-07-VEHICLE-PHYSICS-BEYOND-SQF`.

## Current Phase

Phase 1, Ground Vehicle Physics, is In Progress.

Current Phase 1 systems:

- ACE/FIXICS persistent handbrake.
- Local idle autobrake bypass and slope rolling.
- Local player driver controller.
- ABS-like service braking.
- Reverse/Drive neutral handoff.
- Optional native slope-control bridge, disabled by default.
- Optional Native Driver Assist v2 advisory math for ABS and direction transitions, disabled by default.
- Vehicle Stability Assistance for the approved `EMP_Polaris_DAGOR` class, applying bounded lateral damping only through the local driver controller.
- Roll Stability Assist, server-global and enabled by default, applying bounded model-space vertical damping for registered vehicles and awaiting SQA manual validation.

## Last Decision

- Native Driver Assist v2 was accepted by SQA on 2026-06-12 after high-speed braking and moderate-turn testing.
- ISSUE-001 steering research is complete and a bounded continuous diagnostic sampler is implemented.
- SQA must run `FIXICS_fnc_startSteeringDiagnostics` for keyboard and analog high-speed sharp turns before steering coefficients are changed.
- Vehicle Stability Assistance implementation was approved by SQA for `EMP_Polaris_DAGOR`.
- The first release boundary is bounded lateral damping only; direct yaw/countersteering mutation and passive config changes remain pending SQA evidence.
- ISSUE-001 remains open until SQA completes the manual `EMP_Polaris_DAGOR` matrix across 30, 60, 90, and 120 km/h on paved, dirt, and grass surfaces.
- Roll Stability Assist was implemented as a separate vertical model-space damping layer after SQA telemetry showed mode 2 reduced yaw/pitch but did not prevent rollovers.
- Vehicle handling telemetry was expanded on 2026-06-20 through `FIXICS_fnc_logVehicleHandlingConfig` to capture drive/reverse/brake inputs, world/model velocity, world/ASL position, heading/yaw rate, pitch/bank/rates, vectors, terrain normal, ground contact, wheel hitpoint damage proxy data, and relevant FIXICS state values.

## Constraints

- Manual gameplay validation is performed by SQA.
- Multiplayer vehicle authority is deferred.
- Broad config patches and additional native binaries require explicit SQA approval.
- Generated output and reports are ignored and not edited by hand.
- Do not mark ISSUE-001 resolved until SQA verifies rollover behavior and controlled sliding in-game.

## Required Checks

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
powershell -ExecutionPolicy Bypass -File tools\check.ps1
```
