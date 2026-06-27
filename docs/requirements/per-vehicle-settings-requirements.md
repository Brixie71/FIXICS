# Per-Vehicle Settings Requirements

## Objective

Add a class-based FIXICS vehicle profile layer so currently registered FIXICS vehicles can use per-vehicle settings while preserving existing global behavior by default.

## Current System State

- Phase 1 ground vehicle systems read CBA settings from `missionNamespace`.
- Runtime Assist coordinates ABS, slope, stability, roll, sway bar, controlled slip, terrain tire, mass, and telemetry.
- Terrain Tire Behavior is implemented as a local-player SQF-first layer.
- Native advisory settings remain global only.

## SQA Questions And Answers

- Apply to currently registered FIXICS vehicles first: yes.
- Global defaults remain unchanged when no override exists: yes.
- Override lookup uses exact classname first, then parent class: yes.
- First version uses CBA text fields with SQF array syntax: yes.
- Players cannot change active profile mid-drive; profile is read on entry or diagnostic reset: yes.
- Server/admin setting wins over local client settings: yes.
- Phase 1 remains local-player only: yes.
- ACE interaction is read-only: "View FIXICS Vehicle Profile": yes.
- One unified profile per vehicle: yes.
- ABS, slope, stability, roll, sway, controlled slip, and terrain tire support overrides: yes.
- Native advisory settings remain global only: yes.
- Telemetry reports `vehicleProfileId`, `vehicleProfileSource`, and `vehicleProfileOverridesApplied`: yes.
- Add `FIXICS_fnc_dumpVehicleProfile`: yes.
- Starter presets: `DEFAULT`, `LIGHT_OFFROAD`, `MRAP`, `TRUCK`, `TRACKED`, `CUSTOM`: yes.

## Constraints

- No broad `CfgVehicles` patch.
- No new dependency.
- No native extension change.
- No multiplayer authority change.
- DEFAULT must mirror global settings exactly.
- Exact class override must take priority over parent class override.

## Approval Gates

- SQA approved class-based override architecture and accepted risk.
- SQA must manually verify DEFAULT behavior is identical before validating other presets.

## Validation Commands

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
powershell -ExecutionPolicy Bypass -File tools\check.ps1
```

## Expected Output

- Per-vehicle profile settings are optional and disabled by omission.
- Vehicles without profile matches use global settings.
- Exact class profiles override parent class profiles.
- ACE read-only action shows active profile details.
- Telemetry includes active profile id/source/override fields.
