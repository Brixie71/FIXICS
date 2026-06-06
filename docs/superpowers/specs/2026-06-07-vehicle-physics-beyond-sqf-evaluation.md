# Vehicle Physics Beyond SQF Evaluation

## Purpose

Evaluate when FIXICS may go beyond normal SQF-only runtime mitigation for Phase 1 Ground Vehicle Physics.

This is a rule-exception evaluation, not implementation approval. The controlling exception is `FIXICS-EXC-2026-06-07-VEHICLE-PHYSICS-BEYOND-SQF` in `governance/policies/scope-control.md`.

## Current SQF Boundary

FIXICS currently uses SQF to:

- disable idle autobrake with `disableBrakes`;
- expose the persistent handbrake through ACE interaction;
- enforce the ACE handbrake as a local hard lock;
- apply local downhill rollback assist with `surfaceNormal`, `velocity`, and `setVelocity`.

This remains the default implementation layer because it is inspectable, HEMTT-validated, easy to remove, and does not require binaries or external trust decisions.

The observed risk is that Arma can still apply engine-level vehicle behavior during stationary, brake, and Drive/Reverse transitions. Bohemia documents `disableBrakes` as disabling stationary autobrake, and Arma vehicle handling config includes `brakeIdleSpeed`, which applies brakes under a configured speed. That makes the remaining issue a likely vehicle-handling/config problem rather than a pure SQF problem.

Sources:

- `disableBrakes`: https://community.bohemia.net/wiki/disableBrakes
- Vehicle handling config: https://community.bohemia.net/wiki/Arma_3:_Vehicle_Handling_Configuration
- Cars config guidelines: https://community.bohemia.net/wiki/Arma_3:_Cars_Config_Guidelines
- Extensions: https://community.bohemia.net/wiki/Extensions

## Evaluation Options

### Option A: Targeted Config-Class Patch

Patch specific `CfgVehicles` classes or selected base classes to tune vehicle handling values.

Candidate areas:

- `brakeIdleSpeed`: likely first candidate because it controls the speed below which engine autobrake is applied.
- `class complexGearbox`: candidate for Drive/Reverse transition behavior, including gearbox ratios, `moveOffGear`, gear change timing, and automatic gearbox behavior.
- `antiRollbar*` and related handling values: candidates only if slope behavior is affected by roll stability rather than stationary brake behavior.

Advantages:

- Uses normal Arma addon config.
- Still builds and validates through HEMTT.
- Does not require native binaries.
- Can be tested class by class and reverted cleanly.

Risks:

- May require per-vehicle or per-family tuning.
- Can alter handling balance for vehicles that do not need the fix.
- Config values can interact in non-obvious ways across CarX, TankX, amphibious, and modded vehicles.
- Broad base-class patches may create compatibility issues with other mods.

Recommended use:

- Next escalation step if SQA confirms the current SQF mitigation still cannot overcome the idle stop or Drive/Reverse transition behavior.

### Option B: SQF Diagnostics Before Config Patch

Add temporary or gated diagnostics that read vehicle config values at runtime and report them for tested vehicle classes.

Candidate values:

- `brakeIdleSpeed`
- `simulation`
- `complexGearbox`
- `changeGearMinEffectivity`
- `changeGearType`
- `switchTime`
- `latency`
- `antiRollbarForceCoef`
- `antiRollbarSpeedMin`
- `antiRollbarSpeedMax`

Advantages:

- Keeps the investigation inside SQF.
- Builds an evidence table before class patching.
- Helps avoid broad config edits based on one vehicle.

Risks:

- Diagnostic SQF does not change the engine behavior by itself.
- Runtime config reads can show the configured values but not necessarily the internal PhysX state.

Recommended use:

- Pair with Option A before changing `CfgVehicles`.

### Option C: Native Extension Research

Research a native extension only after SQF and config-class work fail to reach the required behavior.

Arma extensions are loaded from mod roots or the Arma install folder. They require exported `RVExtension` / `RVExtensionArgs` interfaces, 32-bit and 64-bit deployment, and client-side BattlEye whitelisting where applicable.

Pre-research is documented in `docs/superpowers/specs/2026-06-07-native-extension-pre-research.md`.

Advantages:

- May allow performance-sensitive or external-system integration beyond SQF.
- Could support diagnostics that are not practical in SQF.

Risks:

- High trust and deployment cost.
- Requires native development, binary distribution, signatures, and BattlEye considerations.
- May still not expose direct control over Arma's private PhysX gearbox state.
- Increases support burden for clients and dedicated servers.

Recommended use:

- Last resort only. A native extension should not be selected unless there is evidence that Arma exposes the required control through extension-accessible APIs or a clearly bounded diagnostic use case exists.
- Treat the first possible extension spike as diagnostics-only unless a documented native control surface for vehicle physics is found.

## Decision

The approved evaluation path is:

1. Keep the current SQF mitigation as the baseline.
2. If SQA reproduces the defect after the current mitigation, collect a small vehicle-class evidence matrix.
3. Evaluate targeted config-class patches before native extensions.
4. Treat native extension work as a separate phase requiring explicit approval, a security/deployment plan, and a rollback plan.

## Config-Class Experiment 1

Status: failed in SQA testing and rolled back.

Files:

- `addons/main/config.cpp`
- `addons/main/functions/fn_logVehicleHandlingConfig.sqf`
- `tests/integration/fixics-vehicle-physics-static.ps1`

Patch:

- `CfgPatches.requiredAddons[]` now includes `A3_Soft_F` and `A3_Armor_F` so FIXICS loads after the vanilla soft and armored vehicle base classes.
- `CfgVehicles >> Car_F` sets:
  - `brakeIdleSpeed = 0.01;`
  - `dampingRateZeroThrottleClutchEngaged = 0.25;`
  - `dampingRateZeroThrottleClutchDisengaged = 0.25;`
- `CfgVehicles >> Tank_F` sets the same values for the tracked ground-vehicle test path.
- `FIXICS_fnc_logVehicleHandlingConfig` logs the effective handling values for the tested vehicle class.

Rationale:

- `brakeIdleSpeed` is the first config candidate because it controls low-speed braking behavior for PhysX cars.
- Bohemia describes zero-throttle damping as the mechanism that can bring a vehicle quickly to rest when not driven, so the experiment lowers the engaged and disengaged damping values to the lower end of the documented typical range.
- The patch is base-class level for the first pass. If SQA sees compatibility or handling side effects, the next refinement should narrow the patch to specific tested vehicle families.

Manual SQA command:

```sqf
[vehicle player] call FIXICS_fnc_logVehicleHandlingConfig;
```

Run this from the debug console while seated in the tested vehicle, or replace `vehicle player` with the target vehicle object. The values are written to the RPT log with the prefix `[FIXICS] Vehicle handling evidence:`.

SQA retest focus:

- Empty vehicle on a slope with ACE handbrake released.
- Driver-occupied vehicle, W released while pointed uphill.
- Driver-occupied vehicle, S released while pointed downhill in reverse.
- Drive to Reverse and Reverse to Drive transitions without double-tapping W/S.
- ACE Set Handbrake must still hard-lock the vehicle until Release Handbrake is used.

SQA result:

- The vehicle behavior became more buggy than before.
- The broad `Car_F` / `Tank_F` handling patch was removed from `addons/main/config.cpp`.
- `FIXICS_fnc_logVehicleHandlingConfig` remains available as a diagnostic helper.

## Native Gameplay-Control Experiment 1

Status: source scaffold, optional SQF bridge, local Windows x64 build wrapper, and approved root DLL implemented.

Files:

- `native/fixics_physics/src/FIXICSPhysics.cpp`
- `native/fixics_physics/README.md`
- `addons/main/functions/fn_getNativeSlopeControl.sqf`
- `addons/main/functions/fn_applySlopeRollback.sqf`
- `addons/main/functions/fn_registerSettings.sqf`
- `addons/main/config.cpp`
- `native/fixics_physics/CMakeLists.txt`
- `tools/build-native.ps1`
- `FIXICSPhysics_x64.dll`

Architecture:

- `FIXICSPhysics` exports `RVExtensionVersion`, `RVExtension`, and `RVExtensionArgs`.
- `RVExtensionArgs` supports `version`, `ping`, `schema`, and `slopeControl`.
- `FIXICS_fnc_getNativeSlopeControl` calls `FIXICSPhysics` through `callExtension ["slopeControl", ...]`.
- `FIXICS_fnc_applySlopeRollback` consults the native bridge after calculating slope state.
- SQF still owns vehicle mutation through `setVelocity`; the native extension returns only a delta recommendation.
- `FIXICS_nativeSlopeControlEnabled` defaults to `false`, so missing or unbuilt extension binaries cannot change gameplay by default.
- `FIXICSPhysics_x64.dll` is built to the repository root so Arma can load it from the loaded mod root.

Boundary:

- This is native-assisted gameplay control, not direct native ownership of Arma objects or PhysX internals.
- The only approved native binary is root `FIXICSPhysics_x64.dll`.
- No `.dll`, `.so`, `.dylib`, or build outputs may be stored under `native/`.
- A separate release deployment plan is required before shipping binaries outside local SQA testing.

## Evidence Required Before Implementation

Before changing config classes or adding native-extension scaffolding, capture:

- vehicle class name from `typeOf _vehicle`;
- terrain/slope test location or reproducible Eden setup;
- whether ACE handbrake is set or released;
- whether driver is present;
- input state tested: no input, W release, S release, Drive to Reverse, Reverse to Drive;
- expected behavior;
- actual behavior;
- current relevant config values when available.

## Validation Requirements

For config-class experiments:

- Add a static regression proving the intended class patch exists.
- Run `powershell -ExecutionPolicy Bypass -File tools\check.ps1`.
- Manually test at least one empty vehicle, one driver-occupied vehicle, and one passenger-only vehicle on a slope.
- Record manual coverage and known side effects in `governance/audit/validation-log.md`.

For native-extension research:

- Do not add binaries without explicit user approval.
- Document language, build toolchain, 32-bit and 64-bit output names, BattlEye implications, and deployment layout.
- Keep SQF fallback behavior available.
- Treat multiplayer authority as out of scope until a separate multiplayer plan exists.
