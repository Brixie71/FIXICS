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

## Constraints

- Manual gameplay validation is performed by SQA.
- Multiplayer vehicle authority is deferred.
- Broad config patches and additional native binaries require explicit SQA approval.
- Generated output and reports are ignored and not edited by hand.

## Required Checks

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
powershell -ExecutionPolicy Bypass -File tools\check.ps1
```
