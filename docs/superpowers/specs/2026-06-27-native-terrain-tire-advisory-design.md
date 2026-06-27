# Native Terrain Tire Advisory - Design

## Decision

Extend the existing `FIXICSPhysics_x64.dll`. Do not add a second DLL.

This keeps packaging, CMake, tests, schema reporting, and SQF bridge behavior in
one native extension.

## Command

Add one new command:

```text
terrainTireV2
```

The command is advisory-only.

## Inputs

The SQF bridge passes scalar values already gathered by SQF:

- speed km/h;
- terrain class index;
- throttle demand;
- brake demand;
- steering demand;
- slope severity;
- mass kg;
- delta time;
- tire air state;
- tire damage;
- grounded flag;
- last grounded age;
- vector up Z;
- driver present flag;
- destroyed tire threshold;
- rollover safety enabled flag;
- airborne grace window;
- driverless decay enabled flag;
- driverless decay cap;
- tire pressure settings;
- destroyed tire count or per-wheel damage values when practical.

## Outputs

Return a parseable SQF array:

```sqf
[
    applied,
    tractionMultiplier,
    accelerationTractionMultiplier,
    brakingTractionMultiplier,
    turningTractionMultiplier,
    slopeTractionMultiplier,
    wheelspinEstimate,
    tireAirState,
    tireDragPenalty,
    tireSteeringPenalty,
    massModifier,
    wheelSupportState,
    rolloverSuppressed,
    driverlessDecay,
    destroyedTireCount,
    destroyedTireRatio,
    destroyedTirePenalty,
    mobilityLimiter,
    telemetry
]
```

## SQF Boundary

SQF remains responsible for:

- choosing whether native advisory is enabled;
- collecting Arma state;
- validating native output types and bounds;
- falling back to SQF when native output is invalid;
- applying all vehicle mutation;
- telemetry.

## Settings

Add one setting:

```sqf
FIXICS_nativeTerrainTireEnabled
```

Default: `false`.

This keeps the new native path opt-in while SQA compares native and SQF
telemetry.

## Risks

- `callExtension` blocks Arma while it runs. Do not call it more frequently than
  the existing driver-controller cadence without profiling.
- Native and SQF math can drift. Tests must lock the native outputs and SQF must
  keep fallback behavior.
- This improves math performance and determinism only. It does not expose hidden
  gearbox, tire friction, or PhysX internals.
