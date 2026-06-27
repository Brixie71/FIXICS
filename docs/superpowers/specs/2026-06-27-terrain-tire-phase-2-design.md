# Terrain Tire Behavior Phase 2 - Design

## Status

Requirements approved by SQA on 2026-06-27 in
`docs/requirements/terrain-tire-behavior-requirements.md`.

This design extends the existing Terrain Tire layer. It does not replace ABS,
Slope Assist, Controlled Slip, Vehicle Stability, Roll Stability, Sway Bar
Assist, Per-Vehicle Settings, or the ACE/FIXICS handbrake.

## Objective

Improve terrain and tire behavior for wheeled Phase 1 vehicles by adding:

- stronger terrain transition behavior for paved, dirt, grass, sand, rock, and
  unknown surfaces;
- rollover and wheel-contact safety for flipped, side-resting, and airborne
  vehicles;
- gentle driverless decay for abandoned local vehicles;
- destroyed-tire mobility loss separate from slow puncture/run-flat behavior;
- explicit telemetry for SQA validation.

## Boundaries

- SQF-first only.
- Wheeled vehicles first. Tracked vehicles need a separate Phase 2 follow-up
  contact model and are not changed by this design.
- Local-player/local-vehicle only.
- No native extension changes.
- No broad `CfgVehicles` tire/friction patches.
- No multiplayer authority or synchronization changes.
- No forced upright correction, teleporting, or direct wheel animation control.

## System Relationship

Terrain Tire remains the traction authority. It produces recommendations that
other systems consume.

ABS remains the service-brake layer. Terrain Tire may reduce braking traction or
add destroyed-tire drag, but it does not replace ABS state transitions.

Slope Assist remains the longitudinal slope/rollback layer. Terrain Tire may
reduce slope traction on loose terrain or damaged tires. Gentle driverless decay
must not fight WA-001 slope rolling; default decay is capped at `0.15 m/s^2`.

Controlled Slip remains the lateral release layer. Terrain Tire influences how
early and how strongly slip is allowed, but Controlled Slip owns its bounded
lateral correction.

Vehicle Stability, Roll Stability, and Sway Bar Assist remain stability layers.
Terrain Tire informs their multipliers; rollover safety can suppress drive-style
assists when a vehicle is not wheel-supported.

Per-Vehicle Settings may tune Terrain Tire and assist values per class, but
safety rules such as upside-down suppression are not bypassed by profiles.

## Rollover And Contact Safety

The first implementation uses a conservative SQF proxy because Arma does not
provide a universal runtime per-wheel contact API in the current project
boundary.

Inputs:

- `isTouchingGround`;
- `vectorUp`;
- pitch/bank from `BIS_fnc_getPitchBank`;
- model-space velocity;
- wheel hitpoint damage proxy data;
- elapsed time and last grounded timestamp.

Output fields:

- `wheelSupportState`: `SUPPORTED`, `AIRBORNE_GRACE`, `AIRBORNE`,
  `SIDE_UNSUPPORTED`, `FLIPPED`, or `UNKNOWN`;
- `rolloverSuppressed`: boolean;
- `mobilityLimiter`: `0..1`.

Rules:

- Upside-down vehicles suppress drive/traction assists immediately.
- Airborne vehicles suppress terrain/tire drive correction after a `0.50s`
  grace window.
- Side-resting vehicles suppress drive unless orientation suggests plausible
  recovery toward wheels.
- Supported vehicles preserve existing behavior.

## Driverless Decay

When a local vehicle is abandoned, FIXICS should not preserve stale drive state.

Default behavior:

- enabled globally;
- only applies to local abandoned vehicles;
- capped at `0.15 m/s^2`;
- affects residual model-space longitudinal speed gently;
- does not run when the ACE/FIXICS handbrake owns the vehicle;
- records `driverlessDecay` in telemetry.

SQA must verify that this does not conflict with WA-001 slope rolling before the
cap is raised.

## Destroyed-Tire Mobility

Slow punctures and run-flat behavior remain controlled by tire-air state.
Destroyed tires are a separate state.

Inputs:

- wheel hitpoints from `getAllHitPointsDamage` when available;
- explicit `getHitPointDamage` checks must treat `-1` as missing and fall back
  safely;
- whole-vehicle damage as fallback when wheel hitpoints are unavailable.

Default threshold:

- `FIXICS_destroyedTireThreshold = 0.85`.

Output fields:

- `destroyedTireCount`;
- `destroyedTireRatio`;
- `destroyedTirePenalty`;
- `mobilityLimiter`.

Rules:

- one destroyed tire allows slow emergency movement;
- two or more destroyed tires heavily limit mobility;
- all destroyed tires make the vehicle nearly immobile but not hard locked;
- steering penalty is stronger than acceleration penalty;
- loose terrain amplifies destroyed-tire penalties;
- missing hitpoints do not throw errors and do not create false destroyed tires.

## Settings

Add a small global/server CBA settings block under `["FIXICS", "Terrain Tire"]`:

- `FIXICS_rolloverSafetyEnabled`, checkbox, default `true`;
- `FIXICS_airborneGraceWindow`, slider `0..1`, default `0.50`;
- `FIXICS_driverlessDecayEnabled`, checkbox, default `true`;
- `FIXICS_driverlessDecayCap`, slider `0..1`, default `0.15`;
- `FIXICS_destroyedTireThreshold`, slider `0.50..1`, default `0.85`;
- `FIXICS_destroyedTireDebugLogging`, checkbox, default `false`.

## Telemetry

Terrain Tire and runtime telemetry must add:

- `wheelSupportState`;
- `rolloverSuppressed`;
- `driverlessDecay`;
- `destroyedTireCount`;
- `destroyedTireRatio`;
- `destroyedTirePenalty`;
- `mobilityLimiter`.

The terminal dashboard can display these later, but the first implementation
only needs to emit them to RPT/exported logs.

## Testing

Static tests must verify:

- new settings are registered with defaults;
- any new function is registered in `CfgFunctions`;
- recommendation outputs are bounded;
- disabled rollover safety returns neutral fields;
- upside-down and airborne states suppress mobility;
- missing hitpoints represented by `-1` are handled safely;
- destroyed tires reduce mobility and steering more than acceleration;
- telemetry tokens exist in handling logs and compact Terrain Tire samples.

Manual SQA validation must verify:

- DEFAULT behavior remains acceptable on normal supported driving;
- airborne grace does not interrupt ordinary offroad bumps;
- flipped vehicles stop receiving FIXICS drive/traction help;
- abandoned flipped vehicles gently decay instead of preserving wheelspin;
- destroyed tires degrade mobility without hard locking vehicles;
- WA-001 slope rolling still works with driverless decay enabled.
