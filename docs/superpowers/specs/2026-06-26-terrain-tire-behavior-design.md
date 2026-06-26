# Terrain Tire Behavior - Research And Design

## Status

Requirements captured from SQA on 2026-06-26 in
`docs/requirements/terrain-tire-behavior-requirements.md`. This document defines
the design contract. Implementation requires a separate approved plan.

## Problem

Controlled Slip Assist improved the high-speed rollover path, but SQA reported
that its activation still feels narrow: slip appears mainly at high velocity and
around a 25 to 30 degree vehicle angle. The next behavior gap is broader than
Controlled Slip alone.

FIXICS needs a shared model for how tires interact with terrain, acceleration,
braking, turning, slope rolling, mass, and damage. Without that layer, paved,
grass, sand, dirt, and rock can feel too similar, and tire damage cannot express
run-flat-style degraded mobility.

## Goal

Add a new local-player, SQF-first Terrain Tire Behavior layer for registered
FIXICS vehicles.

The player-facing goal is:

- paved surfaces feel grippy but can trip rollover if abused;
- loose surfaces allow earlier wheelspin and controlled sliding;
- rough/rock terrain can produce unstable traction changes;
- vehicle mass makes acceleration and traction loss feel heavier;
- damaged tires progressively deflate and remain movable with degraded
  run-flat-style behavior;
- existing ABS, Slope Assist, Controlled Slip, Stability, Roll Stability, Sway
  Bar, Drive/Reverse, and ACE handbrake behavior stay aligned.

## Non-Goals

- Do not implement multiplayer authority or synchronization.
- Do not make the native extension authoritative.
- Do not patch broad `CfgVehicles` tire/friction values.
- Do not add wet or mud behavior in the first version.
- Do not claim true per-wheel tire simulation.
- Do not make damaged tires invincible.
- Do not remove Arma's own tire damage behavior.
- Do not replace Controlled Slip Assist.
- Do not change accepted ACE handbrake, service braking, ABS, or Drive/Reverse
  behavior.

## Research Basis

FIXICS reference docs record the available Arma boundary:

- `surfaceType` and `surfaceNormal` can classify terrain and slope.
- `speed`, `velocityModelSpace`, `velocity`, `angularVelocity`, `getMass`, and
  vehicle damage state can feed traction math.
- local velocity/force commands can approximate runtime behavior, but there is
  no accepted documented runtime per-wheel friction setter in the project.
- tire and suspension config values exist, including `frictionVsSlipGraph`,
  `latStiffX`, `latStiffY`, suspension values, and anti-roll values, but config
  patches are deferred until SQA approves a separate config plan.

Run-flat tire research supports the degraded-mobility direction: run-flat and
military/security tire systems are meant to keep a vehicle movable after air
loss, but at reduced speed, limited range, and degraded handling. FIXICS should
model that as drag, lower clean grip, steering penalty, and minimum mobility,
not as simple extra traction.

Sources used:

- `docs/reference/physx-command-ref.md`
- `docs/reference/vehicle-config-ref.md`
- `docs/reference/known-engine-limits.md`
- Bohemia Community Wiki sources referenced by the repository docs:
  - `https://community.bohemia.net/wiki/Arma_3_Cars_Config_Guidelines`
  - `https://community.bohemia.net/wiki/Arma_3:_Vehicle_Handling_Configuration`
  - `https://community.bohemia.net/wiki/surfaceType`
  - `https://community.bohemia.net/wiki/surfaceNormal`
- Run-flat behavior reference:
  - `https://en.wikipedia.org/wiki/Run-flat_tire`
  - `https://en.wikipedia.org/wiki/Flat_tire`

## Architecture

Add a pure recommendation function, tentatively:

- `FIXICS_fnc_getTerrainTireRecommendation`

The function receives a compact state snapshot and settings, then returns
bounded recommendations. It must not mutate the vehicle directly.

The Runtime Assist Coordinator remains the communication point:

1. Driver controller gathers driver intent and vehicle state.
2. Terrain Tire Behavior classifies surface, mass, tire pressure, and traction.
3. Runtime Assist shares terrain/tire recommendations with ABS, Slope Assist,
   Controlled Slip, Vehicle Stability, Roll Stability, and Sway Bar paths.
4. Existing local controller/stability paths remain the mutation owners.
5. Telemetry records terrain/tire state and final multipliers.

This keeps tire behavior reusable. Controlled Slip can consume the traction and
surface results, but does not own terrain/tire modeling.

## Eligibility

Terrain Tire Behavior may recommend modifiers only when:

- the vehicle is not null;
- the vehicle is local;
- the local player is the driver;
- the vehicle class is registered for FIXICS vehicle assists;
- elapsed time is finite and bounded;
- the feature is enabled;
- the vehicle is a ground vehicle in the current Phase 1 boundary.

When eligibility fails, it returns neutral multipliers:

- traction multiplier `1`;
- wheelspin estimate `0`;
- drag penalty `0`;
- steering penalty `0`;
- mass modifier `1`;
- no tire deflation change.

## Terrain Classification

The first implementation should classify surfaces into:

- `PAVED`
- `DIRT`
- `GRASS`
- `SAND`
- `ROCK`
- `UNKNOWN`

Classification should be conservative and string-match known `surfaceType`
patterns where possible. Unknown surfaces must fall back safely rather than
creating extreme traction changes.

Initial behavior:

| Terrain | Clean Grip | Wheelspin | Sliding | Rollover/Trip Risk |
|---|---:|---:|---:|---:|
| Paved | Highest | Lowest | Lowest | Highest |
| Dirt | Medium | Medium | Medium | Medium |
| Grass | Low-medium | Medium-high | High | Lower than paved |
| Sand | Low | High | High | Lower, but sluggish |
| Rock | Unstable | Medium | Variable | Variable |
| Unknown | Conservative | Conservative | Conservative | Conservative |

Wet/mud is explicitly deferred.

## Traction Model

The recommendation should output bounded values:

- `terrainGripClass`;
- `tractionMultiplier`;
- `accelerationTractionMultiplier`;
- `brakingTractionMultiplier`;
- `turningTractionMultiplier`;
- `slopeTractionMultiplier`;
- `wheelspinEstimate`;
- `dragPenalty`;
- `steeringPenalty`;
- `massModifier`.

The first version should not attempt a real tire-force simulation. It should use
driver demand and observed motion:

- acceleration demand increases wheelspin on loose terrain;
- braking demand reduces available clean grip on loose terrain but must not
  break accepted ABS behavior;
- steering demand reduces clean grip earlier on loose terrain;
- slope severity changes traction needed to roll or climb;
- higher mass reduces abrupt acceleration and correction strength.

## Tire Pressure And Damage Model

Add progressive tire-pressure state managed by SQF:

- tire pressure starts at `1`;
- a qualifying tire hit or damage increase marks a tire or vehicle tire state as
  leaking;
- leaking pressure decreases over time by `FIXICS_tireDeflationRate`;
- pressure bottoms at a minimum mobility floor controlled by
  `FIXICS_tireMinimumMobility`;
- pressure loss increases drag and steering penalty;
- pressure loss reduces clean grip and top-end mobility;
- Arma's own tire damage is still respected.

Per-wheel tracking is preferred if hitpoint data is reliable. If it is not
available or not stable across classes, implementation should fall back to a
whole-vehicle tire pressure state and make that fallback visible in telemetry.

## Run-Flat Behavior

Run-flat behavior means continued degraded mobility, not immunity.

When tire pressure is low:

- vehicle can still move if Arma's own damage state permits it;
- acceleration becomes sluggish;
- drag increases;
- steering becomes less precise;
- top-end speed should be indirectly reduced through drag/mobility multipliers;
- clean grip decreases;
- loose surfaces worsen the effect.

The behavior must be bounded so SQA can tune it without making vehicles either
undrivable or unaffected by tire damage.

## Interaction With Existing Systems

### Runtime Assist Coordinator

Runtime Assist should expose Terrain Tire Behavior as an explicit participant.
It should record final terrain/tire multipliers and which systems consumed them.

### Controlled Slip Assist

Controlled Slip should use terrain/tire traction output instead of owning its
own isolated terrain assumptions. Loose terrain can lower activation thresholds
or increase controlled lateral scrub. Paved terrain should delay slip release
but preserve rollover risk.

### Slope Assist

Slope Assist should use slope traction output so sandy/grass/loose terrain can
feel slower to climb and less locked on downhill roll. Service braking still
reduces slope acceleration while held.

### ABS

ABS keeps accepted smooth braking. Terrain Tire Behavior may reduce braking
traction on loose surfaces or damaged tires through bounded multipliers, but it
must not replace ABS braking semantics.

### Vehicle Stability, Roll Stability, And Sway Bar

Stability and Roll remain safety layers. Terrain Tire Behavior should help them
avoid paved over-grip and loose-surface overcorrection. Roll Stability still
wins during emergency rollover risk.

### ACE Handbrake

The ACE/FIXICS handbrake remains a hard lock. Terrain Tire Behavior should
return telemetry but not fight the handbrake.

## Settings

Add the SQA-approved global CBA settings:

- `FIXICS_tirePressureEnabled`: default `true`;
- `FIXICS_tireDeflationRate`: conservative default selected in the plan;
- `FIXICS_tireMinimumMobility`: conservative run-flat mobility floor;
- `FIXICS_tireDragStrength`: conservative drag multiplier;
- `FIXICS_tireSteeringPenalty`: conservative steering penalty cap;
- `FIXICS_tireDebugLogging`: default `false`.

The implementation plan may add a separate global Terrain Tire Behavior enable
setting and terrain influence strength if needed, but it must preserve the six
SQA-approved tire-pressure settings above.

## Telemetry

Telemetry must include:

- `terrainTireEnabled`;
- `terrainTireEligible`;
- `terrainTireReason`;
- `surfaceType`;
- `terrainGripClass`;
- `tractionMultiplier`;
- `accelerationTractionMultiplier`;
- `brakingTractionMultiplier`;
- `turningTractionMultiplier`;
- `slopeTractionMultiplier`;
- `wheelspinEstimate`;
- `tireAirState`;
- `tireDeflationState`;
- `tireDragPenalty`;
- `tireSteeringPenalty`;
- `massModifier`;
- `terrainTireTelemetryVersion`;
- whether per-wheel or whole-vehicle fallback was used.

## Testing

Automated tests must verify:

- function registration;
- pure recommendation function exists;
- invalid inputs fail closed;
- terrain classes return bounded multipliers;
- loose terrain increases wheelspin compared with paved for the same demand;
- mass modifier remains bounded;
- tire deflation rate and minimum mobility are respected;
- tire drag and steering penalties are bounded;
- telemetry field names exist;
- existing ABS, handbrake, Drive/Reverse, Runtime Assist, Controlled Slip,
  Stability, Roll, and Sway contracts remain intact.

Manual SQA validation must verify:

- all registered FIXICS vehicles;
- paved/asphalt, dirt, grass, sand, rock, and unknown/default where available;
- acceleration from stop and rolling acceleration;
- braking while turning;
- slope rolling and slope climbing;
- full-lock turning at speed;
- tire damage from bullet hits;
- slow deflation and run-flat mobility;
- no regression to accepted ABS, handbrake, Drive/Reverse, Stability, Roll, Sway,
  or Controlled Slip behavior.

## Risks

- Too much terrain reduction can make vehicles feel icy.
- Too little terrain influence can make the feature invisible.
- Tire-pressure state may conflict with Arma's own tire damage if not carefully
  gated.
- Surface classification can vary by map and mod terrain.
- Rock and sand classes may not be consistently exposed across terrains.
- Whole-vehicle fallback may feel less precise than per-wheel behavior.
- Drag-based top-speed reduction is an approximation, not true tire deformation.

## Implementation Boundary

This spec approves the design only. The next step is a separate implementation
plan. No gameplay source changes are approved by this document alone.
