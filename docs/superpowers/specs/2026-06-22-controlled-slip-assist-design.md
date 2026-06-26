# Controlled Slip Assist - Research And Design

## Status

Requirements captured and approved by SQA on 2026-06-22 in
`docs/requirements/controlled-slip-assist-requirements.md`. This document
defines the design contract. Implementation requires a separate approved plan.

## Problem

SQA telemetry from full-strength front/rear sway bar testing showed that
Roll Stability Assist and Sway Bar Assist are active, but a high-speed full
left/right steering input can still push the `B_LSV_01_unarmed_F` into extreme
bank angles.

The important observation is that the vehicle can remain too planted while the
driver asks for a large direction change at speed. If lateral grip stays high
until the body is already rolling, the vehicle may trip into rollover instead
of sliding outward and scrubbing energy.

Controlled Slip Assist is the next car-first layer: it should let the vehicle
release grip in a bounded, recoverable way before rollover energy becomes too
large.

## Goal

Add a local-player, SQF-first Controlled Slip Assist for registered cars/light
vehicles.

The player-facing goal is:

- full-lock high-speed steering should produce controlled lateral scrub before
  trip rollover;
- the vehicle should still feel heavy and risky;
- sliding should be recoverable, not ice-like;
- terrain should affect when slip begins;
- Roll Stability, Sway Bar, Vehicle Stability, ABS, Drive/Reverse, and ACE
  handbrake behavior must remain aligned.

## Non-Goals

- Do not implement multiplayer authority or synchronization.
- Do not patch broad `CfgVehicles` tire or friction classes in this phase.
- Do not add native extension authority.
- Do not force the vehicle upright.
- Do not make rollover impossible.
- Do not remove or replace Roll Stability Assist.
- Do not change accepted ABS, service braking, ACE handbrake, or Drive/Reverse
  transition behavior.
- Do not treat GTA IV, Driver 3, or WRC as technical implementation sources.

## Research Basis

Real tire behavior is the design target: tires have a grip limit. When steering
demand, speed, and lateral load exceed that limit, the tire slips instead of
generating unlimited lateral force. For a tall or narrow vehicle, a controlled
slide can be safer than staying fully planted until the chassis trips over.

The approved feel references are:

- GTA IV: visible weight transfer, heavy body movement, inertia, and recoverable
  sliding;
- Driver 3: heavier momentum and less twitchy steering response;
- WRC and rally games: terrain-sensitive grip, slip angle, braking while
  turning, and controlled recovery.

Arma 3 does not expose a true real-time tire model through SQF. FIXICS must
approximate with available runtime state, bounded model-space velocity
adjustments, CBA settings, and telemetry.

## Initial Scope

Cars/light vehicles first:

- `B_LSV_01_unarmed_F`
- `EMP_Polaris_DAGOR`
- `LOP_IA_Offroad`
- `B_G_Offroad_01_F`

Trucks and heavier classes are deferred. They need different mass, rollover,
and speed assumptions.

## Architecture

Add a pure recommendation function, tentatively:

- `FIXICS_fnc_getControlledSlipRecommendation`

The function receives a compact state snapshot and settings, then returns a
bounded recommendation. It should not mutate the vehicle directly.

The local stability/controller path remains the mutation owner:

1. Driver controller completes longitudinal state work.
2. Vehicle Stability and Roll Stability calculate their current corrections.
3. Controlled Slip Assist calculates whether grip should be released.
4. Runtime Assist records the decision and final priority.
5. Handling telemetry records the evidence.

Controlled Slip Assist should communicate with existing systems through
explicit state fields, not hidden global side effects.

## Eligibility

Controlled Slip Assist may recommend a correction only when:

- the vehicle is not null;
- the vehicle is local;
- the local player is the driver;
- the vehicle is a supported registered light vehicle;
- the FIXICS handbrake is not engaged;
- the vehicle is grounded or within a short grounded grace period;
- speed is above the configured activation speed;
- steering demand exceeds the configured threshold;
- terrain classification is available or defaults safely;
- elapsed time is finite and bounded.

When eligibility fails, it must return no correction and telemetry must explain
the reason.

## Inputs

The implementation should use already available measurements where possible:

- vehicle class;
- speed in km/h;
- model-space velocity;
- steering input from `CarLeft` and `CarRight`;
- yaw rate;
- lateral speed;
- longitudinal speed;
- bank and bank rate;
- pitch if already sampled;
- surface type and terrain class;
- ground contact;
- active Stability Assist mode;
- active Roll Stability preset;
- Sway Bar enabled/strength values;
- Runtime Assist terrain and mass modifiers.

## Slip Estimate

The first implementation should use an approximation, not a claimed real slip
angle:

- `steeringDemand`: normalized absolute steering input, 0 to 1.
- `lateralDemand`: lateral speed divided by forward speed, bounded.
- `rollRisk`: normalized bank and bank-rate severity.
- `terrainGripClass`: paved, dirt, grass, or unknown.
- `gripReleaseFactor`: 0 to 1.

The assist should activate when steering demand and speed are high enough and
roll/lateral demand indicates that the vehicle is loading up instead of safely
sliding.

## Behavior

Controlled Slip Assist should reduce rollover tendency by allowing lateral
scrub.

Initial behavior:

- on paved surfaces, activate later and less aggressively;
- on dirt, activate earlier and allow more lateral scrub;
- on grass or loose surfaces, activate earliest and allow the most scrub;
- when bank or bank-rate becomes dangerous, allow stronger release;
- do not inject large yaw changes;
- do not reduce service braking authority;
- do not disable Roll Stability Assist;
- do not make the vehicle feel weightless or icy.

The correction should be bounded and reversible. The implementation plan must
choose exact defaults conservatively.

## Interaction With Existing Systems

### Roll Stability Assist

Roll Stability remains the emergency anti-roll layer. Controlled Slip Assist
should try to reduce the energy that causes rollover before Roll Stability has
to fight extreme bank angles.

### Sway Bar Assist

Front/rear sway bar settings remain active. Controlled Slip Assist may read the
combined sway bar strength multiplier to decide how much lateral scrub is
needed, but it must not override the user's sway bar settings.

### Vehicle Stability Assist

Vehicle Stability currently damps yaw/lateral behavior. Controlled Slip Assist
should not simply add more lateral damping. Its purpose is to permit controlled
slip when the vehicle is too planted, so it may reduce or bypass some lateral
damping under high steering and rollover-risk conditions.

### Runtime Assist Coordinator

Runtime Assist should record Controlled Slip Assist as a visible participant:

- whether it was eligible;
- whether it applied;
- whether it reduced stability damping;
- terrain modifier;
- final grip release factor.

Roll priority remains higher during emergency rollover risk.

### ABS And Driver State

ABS keeps the accepted smooth braking behavior. Controlled Slip Assist should
not change service brake semantics, ACE handbrake, or Drive/Reverse transition
logic.

## Settings

Add conservative CBA global/server settings if approved by the implementation
plan:

- `FIXICS_controlledSlipEnabled`: default `true`;
- `FIXICS_controlledSlipActivationSpeedKmh`: conservative default, likely
  around `55`;
- `FIXICS_controlledSlipSteeringThreshold`: default near `0.65`;
- `FIXICS_controlledSlipStrength`: low default, likely `0.12` to `0.20`;
- `FIXICS_controlledSlipMaximumRelease`: bounded cap;
- `FIXICS_controlledSlipTerrainInfluence`: default `true`;
- `FIXICS_controlledSlipDebugLogging`: default `false`.

Exact names and numeric defaults belong in the implementation plan.

## Telemetry

Telemetry must prove why Controlled Slip Assist did or did not act.

Required fields:

- `controlledSlipEnabled`;
- `controlledSlipEligible`;
- `controlledSlipApplied`;
- `controlledSlipReason`;
- `controlledSlipSteeringDemand`;
- `controlledSlipLateralDemand`;
- `controlledSlipRollRisk`;
- `controlledSlipTerrainClass`;
- `controlledSlipTerrainMultiplier`;
- `controlledSlipGripReleaseFactor`;
- `controlledSlipCorrection`;
- `controlledSlipTelemetryVersion`.

Handling dump and Runtime Assist compact telemetry should include the key
fields needed for SQA comparison logs.

## Evidence Matrix Updates

Implementation must update `docs/vehicle-behavior/sqa-evidence-matrix.md` with
Controlled Slip Assist rows for:

- paved;
- dirt;
- grass;
- 30, 60, 90, and 120 km/h;
- full left/right steering;
- braking while turning;
- recovery after slide.

Do not mark ISSUE-001 resolved from automated checks or design alone. SQA
manual acceptance is required.

## Testing

Automated tests must verify:

- function registration;
- pure recommendation function exists;
- invalid inputs fail closed;
- handbrake/locality/driver gates remain intact in the mutating path;
- terrain multipliers are bounded;
- steering threshold and activation speed are enforced;
- correction is bounded;
- telemetry fields exist;
- existing ABS, handbrake, Drive/Reverse, Roll Stability, Sway Bar, and Runtime
  Assist static contracts remain intact.

Manual SQA validation must verify:

- registered light vehicles;
- 30/60/90/120 km/h;
- paved, dirt, and grass;
- full-lock left and right;
- controlled slide instead of immediate trip rollover;
- braking while turning;
- recovery after slide;
- no regression to ABS, ACE handbrake, Drive/Reverse, Roll Stability, and Sway
  Bar behavior.

## Risks

- Too much slip release can make vehicles feel icy.
- Too little slip release will preserve the current rollover problem.
- Reducing lateral damping at the wrong time could increase oversteer.
- Terrain modifiers could mask class-specific tire/suspension problems.
- The approximation could be mistaken for real tire simulation unless telemetry
  and docs stay explicit.

## Implementation Boundary

This spec approves the design only. The next step is a separate implementation
plan. No gameplay source changes are approved by this document alone.
