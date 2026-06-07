# Native Driver Assist v2 - Design Spec

## Purpose

Improve FIXICS ABS, Drive/Reverse transition, and diagnostic behavior by moving controller math into the optional `FIXICSPhysics` native extension while keeping SQF as the only layer that mutates Arma vehicles.

This is a Phase 1 Ground Vehicle Physics feature. It improves the existing local driver controller; it does not attempt to replace Arma 3's hidden gearbox.

## Current Baseline

The current controller is local-first and already working:

- `FIXICS_fnc_updateDriverController` owns Drive, Reverse, Coast, Service Brake, Neutral, and Handbrake state.
- `FIXICS_fnc_applyABSBraking` applies model-space ABS-like braking.
- `FIXICS_fnc_setVehicleHandbrake` and ACE interaction own the persistent FIXICS handbrake.
- `FIXICSPhysics` currently supports `slopeControl` only.
- SQF fallback behavior must remain functional when the DLL is missing or native assist is disabled.

## Architecture

Add a native advisory call named `driverAssist`.

SQF sends the current vehicle/controller state and settings to the extension. The extension returns a bounded recommendation. SQF validates the recommendation and remains responsible for `disableBrakes`, `setVelocityModelSpace`, and all vehicle mutation.

This keeps the native extension inside the approved gameplay-control boundary:

- native code performs deterministic controller math;
- SQF owns locality, safety checks, vehicle commands, and fallback;
- no direct hidden gearbox forcing;
- no multiplayer authority changes;
- no broad vehicle config patching.

## Native Interface

### Command

```text
driverAssist
```

### Inputs

The SQF bridge passes strings through `callExtension ["driverAssist", [...]]`.

Required input order:

1. current driver state
2. requested direction: `-1` reverse, `0` neutral/brake/coast, `1` drive
3. longitudinal model-space speed in m/s
4. slope magnitude
5. downhill alignment relative to vehicle forward axis
6. delta time in seconds
7. ABS brake strength
8. ABS release bias
9. ABS slope compensation
10. direction-change threshold in m/s
11. direction launch velocity in m/s
12. neutral pulse seconds
13. low-speed cutoff in m/s
14. ignore low-speed cutoff: `0` or `1`

### Output

The extension returns an SQF-safe array string:

```sqf
[applied, mode, targetLongitudinalSpeed, brakeDelta, launchDirection, telemetry]
```

Where:

- `applied` is a boolean.
- `mode` is one of `"NONE"`, `"ABS"`, `"SERVICE_BRAKE"`, `"NEUTRAL"`, or `"LAUNCH"`.
- `targetLongitudinalSpeed` is the recommended model-space longitudinal speed in m/s.
- `brakeDelta` is the amount of speed removed in m/s.
- `launchDirection` is `-1`, `0`, or `1`.
- `telemetry` is a compact string for debug logging.

Invalid input returns:

```sqf
[false,"NONE",0,0,0,"invalid"]
```

The existing `slopeControl` command and schema remain backward compatible.

## SQF Components

### `FIXICS_fnc_getNativeDriverAssist`

New SQF bridge.

Responsibilities:

- honor `FIXICS_nativeDriverAssistEnabled`, default `false`;
- call `FIXICSPhysics` `driverAssist`;
- validate extension return code and error code;
- parse the returned array with `parseSimpleArray`;
- reject invalid types, non-finite values, or unsafe bounds;
- return `[]` for disabled, missing, invalid, or failed native calls.

### `FIXICS_fnc_applyABSBraking`

Use native assist first when enabled and valid.

Responsibilities:

- keep the current SQF ABS fallback;
- continue accepting decoded controller intent instead of reading W/S itself;
- apply only bounded model-space velocity changes;
- reject native recommendations while the FIXICS handbrake is enabled;
- log native/SQF source only when debug telemetry is enabled.

### `FIXICS_fnc_updateDriverController`

Use native assist inside the existing state machine.

Responsibilities:

- keep current state names and neutral-pulse behavior;
- ask native assist for service-brake and direction-transition recommendations;
- do not let native assist skip the neutral pulse;
- keep `disableBrakes false` for service brake and neutral;
- keep `disableBrakes true` for Drive/Reverse/Coast slope assist;
- fall back to current SQF calculations when native assist is unavailable.

## Settings

Add CBA settings:

- `FIXICS_nativeDriverAssistEnabled`, default `false`.
- `FIXICS_driverAssistDebugLogging`, default `false`.

Existing ABS and direction settings remain authoritative:

- `FIXICS_absBrakeStrength`
- `FIXICS_absReleaseBias`
- `FIXICS_absLowSpeedCutoffKmh`
- `FIXICS_absSlopeCompensation`
- `FIXICS_directionChangeThresholdKmh`
- `FIXICS_directionLaunchVelocity`
- `FIXICS_directionNeutralPulseSeconds`
- `FIXICS_driverControllerInterval`

No tuning presets are implemented in this feature. Setting names and native input layout should allow presets later.

## Telemetry

Telemetry is silent by default.

When `FIXICS_driverAssistDebugLogging` is enabled, SQF writes compact RPT lines such as:

```text
FIXICS driverAssist: state=SERVICE_BRAKE mode=ABS source=native speed=4.2 target=3.9 delta=0.3 slope=0.12
```

Telemetry goals:

- make QA tuning possible without reading every function;
- show native versus SQF fallback source;
- include state, mode, speed, target, delta, slope, and requested direction;
- avoid per-frame spam unless SQA intentionally enables debug logging.

## Data Flow

Per local driver-controller tick:

1. SQF verifies interface, locality, driver ownership, ground contact, and handbrake state.
2. SQF decodes driver input intent.
3. SQF computes model-space speed, slope magnitude, downhill alignment, and delta time.
4. SQF calls native `driverAssist` only for service braking, opposite-direction transition braking, neutral launch recommendation, or combined W+S braking.
5. SQF validates the recommendation.
6. SQF applies the final action or uses existing fallback math.

Failure behavior:

- native disabled: no behavior change;
- DLL missing or extension error: fallback path;
- parse failure: fallback path and optional debug log;
- unsafe recommendation: reject and fallback;
- handbrake set: native assist ignored.

## Safety Rules

- SQF remains the final authority.
- The extension must never return unbounded speed or delta values.
- The extension must clamp negative delta time to a safe minimum.
- The extension must reject non-finite parsed values.
- The extension must not require persistent native memory for correctness.
- The feature must not increase multiplayer authority scope.
- The feature must not change ACE handbrake persistence rules.

## Automated Validation

Extend `tests/integration/fixics-vehicle-physics-static.ps1` to require:

- `addons/main/functions/fn_getNativeDriverAssist.sqf`;
- `getNativeDriverAssist` registered in `addons/main/config.cpp`;
- `FIXICS_nativeDriverAssistEnabled` setting and stringtable keys;
- `FIXICS_driverAssistDebugLogging` setting and stringtable keys;
- native source supports `driverAssist`;
- native source schema includes `driverAssist`;
- native README documents `driverAssist`;
- current SQF fallback remains present;
- existing `slopeControl` remains present and backward compatible.

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
powershell -ExecutionPolicy Bypass -File tools\check.ps1
powershell -ExecutionPolicy Bypass -File tools\build-native.ps1
git diff --check
```

## Manual SQA Acceptance

SQA should test in VR or Eden:

- native assist disabled: existing ABS and Drive/Reverse behavior is unchanged;
- native assist enabled with DLL installed: ABS remains smooth;
- Reverse-to-Drive responds with the same or better delay than current behavior;
- Drive-to-Reverse remains controlled and does not skip neutral behavior;
- ACE handbrake hard-locks and overrides Drive, Reverse, and service brake;
- telemetry is silent by default;
- telemetry is useful when enabled and appears in RPT.

## Non-Goals

- No hidden gearbox forcing.
- No multiplayer authority or synchronization changes.
- No tuning presets in this feature.
- No release packaging or signing changes.
- No broad vehicle class config patching.
- No dependency on native assist for basic gameplay fallback.

## Open Risks

- `callExtension` is blocking, so native assist must be gated and cheap.
- Native build and DLL presence can differ between machines.
- SQF still competes with the engine drivetrain, so this remains an approximation.
- Manual SQA is required to judge vehicle feel; automated checks only protect structure and fallback safety.
