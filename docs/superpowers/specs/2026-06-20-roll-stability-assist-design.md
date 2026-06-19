# Roll Stability Assist - Research And Design

## Status

Architecture approved by SQA on 2026-06-20. Implementation requires a
separate approved plan.

## Problem

Vehicle Stability mode `Yaw + Lateral Damping` reduces yaw and pitch
instability, but telemetry still shows rollover events. The remaining failure
is roll buildup and airborne/tumbling recovery, not ordinary steering response.

Recent SQA telemetry from `B_LSV_01_unarmed_F` showed:

- baseline mode `0` yaw-rate absolute maximum near `281 deg/s`;
- mode `2` yaw-rate absolute maximum near `119 deg/s`;
- baseline pitch absolute maximum near `72 deg`;
- mode `2` pitch absolute maximum near `38 deg`;
- mode `2` still reached bank near `179 deg`;
- most extreme bank events occurred airborne or during a tumble after roll
  had already started.

The current stability layer is therefore useful but incomplete. More yaw or
lateral damping would risk suppressing controlled sliding while still failing
to target the roll-specific failure mode.

## Research Basis

Automotive stability systems compare driver intent with vehicle response and
use yaw-rate, lateral acceleration, steering, and wheel-speed data to detect
loss of control. Roll stability systems extend that idea into rollover
prevention by detecting excessive roll conditions and reducing the energy that
feeds rollover.

Useful concepts for FIXICS:

- detect roll risk from bank angle and bank-rate growth;
- intervene only above meaningful speed and danger thresholds;
- keep yaw/slip control separate from roll protection;
- avoid improving cornering performance artificially;
- avoid fighting intentional controlled slides unless roll risk is present.

Sources:

- https://www.nhtsa.gov/
- https://community.bosch-mobility.com/
- https://community.bohemia.net/wiki/Arma_3:_Diagnostics_Exe
- https://community.bohemia.net/wiki/velocityModelSpace

## Goal

Add Roll Stability Assist as a separate, server-global runtime layer that
reduces rollover tendency without replacing the existing yaw/lateral stability
modes.

## Non-Goals

- Do not force the vehicle upright.
- Do not use `setVectorDirAndUp`, `setDir`, or teleport-style correction.
- Do not apply a broad config patch to all vehicles.
- Do not globally increase tire grip.
- Do not change ABS, handbrake, slope rolling, or direction-transition
  ownership.
- Do not claim real ESC, ESP, or active rollover protection behavior.

## Settings

Add one explicit global enable setting:

- `FIXICS_rollStabilityEnabled`, default `true`.

Add bounded tuning settings:

- `FIXICS_rollActivationBankDeg`, default `18`, range `5..60`.
- `FIXICS_rollActivationRateDeg`, default `45`, range `5..240`.
- `FIXICS_rollStrength`, default `0.08`, range `0..0.5`.
- `FIXICS_rollMaximumCorrection`, default `0.08`, range `0.01..0.4`.
- `FIXICS_rollAirborneGraceSeconds`, default `0.35`, range `0..1`.

All settings are server-global through CBA, matching the existing vehicle
stability settings.

## Compatibility Boundary

Roll Stability Assist applies only to vehicles supported by
`FIXICS_fnc_getVehicleStabilityProfile`. The first supported boundary remains
the existing compatibility registry. Additional vehicle families require SQA
approval and telemetry.

## Runtime Eligibility

The controller may run only when:

- the vehicle is not null;
- the vehicle is local;
- the local player is the driver;
- the vehicle is supported by the stability profile;
- `FIXICS_rollStabilityEnabled` is true;
- `FIXICS_handbrakeEnabled` is false;
- speed is at or above the stability activation speed;
- the vehicle is grounded or within the configured airborne grace window after
  last ground contact.

The airborne grace exists because telemetry shows rollovers often begin at
ground contact and continue briefly after leaving the ground. This is a narrow
continuation window, not full airborne flight control.

## Detection

Each update samples:

- bank angle from `_vehicle call BIS_fnc_getPitchBank`;
- bank rate from the previous bank sample and elapsed time;
- ground contact from `isTouchingGround`;
- model-space velocity from `velocityModelSpace`;
- speed from model-space longitudinal velocity;
- existing handbrake and profile state.

Roll risk is active when either condition is true:

- `abs bank >= FIXICS_rollActivationBankDeg`;
- `abs bankRate >= FIXICS_rollActivationRateDeg`.

The controller clears stored bank samples when eligibility fails, except for
the grounded timestamp required for airborne grace.

## Correction Model

Roll Stability Assist uses a bounded model-space velocity correction. It
preserves longitudinal velocity and avoids orientation mutation.

The first implementation corrects only the model-space vertical component:

1. Determine roll severity from normalized bank and bank-rate excess.
2. Convert severity into a correction strength bounded by delta time,
   `FIXICS_rollStrength`, and `FIXICS_rollMaximumCorrection`.
3. Reduce destabilizing vertical model-space velocity by that bounded amount.
4. Leave model-space longitudinal velocity unchanged.
5. Leave existing lateral damping to the selected stability mode.

This keeps the feature conservative. It attempts to reduce rollover energy
instead of steering or snapping the vehicle upright.

## Interaction With Existing Stability Modes

Roll Stability Assist is independent of `FIXICS_stabilityAssistMode`.

- `Off`: yaw/lateral/countersteer assistance remains off, but roll assist may
  run if its setting is enabled.
- `Yaw`: yaw damping remains unchanged; roll assist runs separately.
- `Yaw + Lateral Damping`: lateral damping remains unchanged; roll assist
  targets bank/bank-rate.
- `Countersteering`: countersteer remains unchanged; roll assist targets
  bank/bank-rate.

This separation lets SQA compare yaw/lateral handling against roll control
without changing multiple concepts at once.

## Diagnostics

When `FIXICS_stabilityDebugLogging` is true, roll corrections should log:

- class;
- preset;
- mode;
- speed;
- bank;
- bankRate;
- grounded state;
- airborne grace state;
- vertical velocity before and after;
- correction amount.

The existing vehicle telemetry logger already records the key measurements
needed for manual validation.

## Testing

Automated tests must verify:

- the new CBA settings and stringtable keys exist;
- defaults and bounds are present;
- roll assist does not use orientation mutation commands;
- roll assist preserves longitudinal velocity;
- roll assist exits when unsupported, non-local, no player driver, handbrake
  enabled, disabled by setting, below speed, and outside airborne grace;
- roll assist can activate on bank threshold;
- roll assist can activate on bank-rate threshold;
- existing yaw/lateral/countersteer behavior remains tested separately.

Manual SQA validation must compare:

- mode `2` with roll assist off;
- mode `2` with roll assist on;
- high-speed sharp turns on flat paved road;
- slope and terrain transitions;
- airborne/landing/tumbling events;
- controlled sliding feel;
- braking while turning;
- Drive/Reverse transitions;
- persistent ACE/FIXICS handbrake.

Primary telemetry metrics:

- `bank`;
- `bankRate`;
- `yawRate`;
- `pitch`;
- `isTouchingGround`;
- rollover count;
- high bank count over `45 deg` and `90 deg`;
- airborne sample count.

## Approval Boundary

This spec approves the architecture only. Implementation requires a separate
plan and SQA approval before code changes begin.
