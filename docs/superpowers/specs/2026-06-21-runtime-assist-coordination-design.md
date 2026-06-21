# Runtime Assist Coordination - Research And Design

## Status

Requirements captured and approved by SQA on 2026-06-21. This document defines
the design contract. Implementation requires a separate approved plan.

## Problem

FIXICS Phase 1 now has several accepted local vehicle behavior systems:

- ACE/FIXICS persistent handbrake;
- local driver controller;
- ABS-like service braking;
- Drive/Reverse neutral handoff;
- slope rollback and coasting assistance;
- Vehicle Stability Assistance;
- Roll Stability Assist;
- optional native advisory math;
- vehicle behavior telemetry and evidence registry.

These systems currently protect their own boundaries, but they do not share one
explicit arbitration point. As handling features grow, independent velocity
corrections can compete: slope assist may add speed while stability is reducing
slip, braking may suppress slope rolling too strongly, and roll correction may
need to remain active even when yaw/lateral assistance is off.

The Runtime Assist Coordinator is the local-player layer that turns those
independent systems into one ordered decision.

## Goal

Add one local coordination layer that lets existing assist systems communicate
through a shared runtime decision without rewriting accepted behavior.

The player-facing goal is realistic stable handling:

- smoother braking while turning;
- less high-speed steering overshoot;
- reduced rollover tendency;
- controlled sliding instead of forced grip;
- behavior influenced by terrain, speed, vehicle mass, and current assist
  settings;
- slope rolling resumes after service brake release.

## Non-Goals

- Do not implement multiplayer authority or synchronization.
- Do not make the native extension authoritative.
- Do not patch broad `CfgVehicles` parents.
- Do not directly force Arma's hidden gearbox state.
- Do not simulate full real ESC, ABS, traction control, EPS, or ADAS.
- Do not force vehicles upright.
- Do not remove accepted ACE handbrake, service braking, ABS, or
  Drive/Reverse behavior.
- Do not merge all subsystem presets into one global preset.

## Research Basis

Real vehicle stability systems compare driver intent with vehicle response and
intervene when yaw, slip, braking, or roll conditions indicate loss of control.
Useful transferable concepts for FIXICS are:

- driver intent and vehicle response should be compared before correction;
- ABS should preserve controllable braking, not become a persistent handbrake;
- stability support should reduce loss of control, not increase cornering
  performance artificially;
- roll control should reduce rollover energy without snapping orientation;
- tires and surfaces have limited force budgets, so sliding should remain
  possible;
- mass, speed, surface, slope, and load transfer affect the strength of a safe
  correction.

GTA IV remains only a feel reference: heavier body motion, inertia, suspension
travel, and recoverable sliding are desirable, but it is not an implementation
source.

Arma 3 exposes enough state for an approximation, but not the same control
surfaces as a real vehicle. FIXICS must work through local SQF/config
boundaries: read input and vehicle state, calculate bounded recommendations,
apply limited model-space/world velocity corrections, and record telemetry.

Sources:

- https://www.nhtsa.gov/equipment/electronic-stability-control
- https://community.bistudio.com/wiki/Arma_3:_Cars_Config_Guidelines
- https://community.bistudio.com/wiki/Arma_3:_Vehicle_Handling_Configuration
- https://www.bosch-mobility.com/en/solutions/driving-safety/electronic-stability-program/

## Architecture

Add a new coordinator function, tentatively:

- `FIXICS_fnc_coordinateVehicleAssists`

The coordinator is a one-to-many layer. It receives the local vehicle state and
the recommendations or eligibility results from assist systems, then returns one
bounded decision for the current update.

Subsystems remain separate:

- ABS owns service-braking feel.
- Slope rollback owns downhill/coasting acceleration.
- Driver controller owns Drive, Reverse, Coast, Service Brake, Neutral, and
  Handbrake state.
- Vehicle Stability Assistance owns yaw/lateral correction recommendations.
- Roll Stability Assist owns bank/bank-rate correction recommendations.
- Native assist may advise values but cannot mutate state directly.
- Terrain handling provides modifiers, not a new ownership model.

The implementation plan may choose exact call signatures, but the design
requires the coordinator to be explicit and testable. It should not hide
coordination inside unrelated subsystem functions.

## Eligibility

The coordinator may produce a mutation decision only when:

- the vehicle is not null;
- the vehicle is local;
- the local player is the driver;
- the vehicle class is currently registered for the affected assist systems;
- multiplayer authority is not required;
- the persistent FIXICS handbrake is released, except for explicit handbrake
  hard-lock reporting;
- elapsed time is valid and bounded.

When eligibility fails, the coordinator must return a no-mutation decision and
clear stale transient state that could affect the next valid update.

Roll Stability remains independently eligible when Stability Assist mode is
Off, as long as its own global setting is enabled.

## Inputs

Each update should collect a compact state snapshot:

- vehicle object and class;
- locality and player-driver ownership;
- speed;
- `velocityModelSpace` and world velocity;
- driver intent: forward, reverse, brake, steering left/right, handbrake;
- controller state: Drive, Reverse, Coast, Service Brake, Neutral, Handbrake;
- grounded state and airborne grace values;
- pitch, bank, yaw-rate, bank-rate;
- slope direction and slope severity;
- terrain or surface classification;
- vehicle mass from runtime/config where available;
- current ABS, stability, roll, slope, and native-assist settings;
- subsystem presets, kept separate.

The coordinator should prefer already-computed subsystem state when available to
avoid duplicate measurement and drift.

## Priority Rules

The coordinator resolves conflicts in this order:

1. **Hard safety gates**
   - FIXICS ACE handbrake hard-lock wins over all motion assists.
   - Invalid locality, no local player driver, unsupported vehicle, or invalid
     elapsed time returns no mutation.
2. **Driver controller state**
   - Drive/Reverse/Neutral/Service Brake state remains the owner of direction
     transition semantics.
   - The coordinator must not reintroduce the old persistent automatic
     handbrake behavior.
3. **Roll Stability Assist**
   - Roll correction has priority when rollover risk is active.
   - It can run even when yaw/lateral stability mode is Off.
   - It must not force orientation upright.
4. **Vehicle Stability Assistance**
   - Yaw/lateral/countersteer recommendations apply after roll risk is handled.
   - Stability support should reduce overshoot and yaw/lateral instability while
     preserving controlled sliding.
5. **ABS service braking**
   - ABS keeps the accepted smooth braking feel.
   - While braking downhill, ABS reduces slope acceleration instead of fully
     disabling it.
   - When brake input is released, slope rolling/coasting can resume.
6. **Slope rollback and terrain**
   - Slope assist may add speed downhill even while stability or roll assist is
     active, but the final correction must respect roll/stability caps.
   - Terrain modifies assist strength in this phase.
7. **Native advisory**
   - Native recommendations can bias calculations only after all local gameplay
     gates pass.
   - Native code never owns mutation.

## Terrain And Mass Influence

Terrain should affect the coordinator as a multiplier, not a replacement for
vehicle physics.

Initial design intent:

- paved or hard surfaces allow the most precise braking/stability response;
- dirt permits more recoverable sliding and softer correction;
- grass/loose terrain permits still more slip and lower correction strength;
- strong slope increases downhill/coasting urgency;
- higher vehicle mass should reduce abrupt correction and favor damping over
  sharp velocity changes.

The exact terrain categories and numeric multipliers belong in the
implementation plan. Defaults must be conservative.

## Braking Behavior

Service braking is not handbraking.

When the player presses the service brake/reverse key against current motion,
the coordinator should:

- keep the accepted ABS braking smoothness;
- reduce slope acceleration while the brake is held;
- avoid treating near-zero speed as a persistent handbrake state;
- allow the vehicle to roll again when the brake is released;
- preserve the accepted Drive/Reverse neutral handoff behavior.

This applies symmetrically for forward motion with reverse/brake input and
reverse motion with forward/brake input.

## Settings And Presets

Add global FIXICS coordination settings only if the implementation plan
identifies exact names and defaults.

Required behavior:

- settings are global through CBA for Phase 1 consistency;
- defaults are conservative;
- each subsystem keeps its own presets;
- the coordinator reads subsystem presets instead of replacing them;
- administrators may tune coordination strength without disabling the accepted
  ABS, stability, roll, or slope systems individually.

Suggested setting groups for the plan:

- global coordinator enable;
- terrain influence enable and strength;
- braking slope-retention factor;
- coordination telemetry/debug enable;
- optional conservative caps for final correction composition.

## Telemetry

Runtime telemetry must show why a correction did or did not happen.

New telemetry fields should include:

- coordinator enabled/disabled;
- coordinator eligibility result;
- selected priority winner;
- suppressed or reduced assists;
- terrain class and terrain multiplier;
- mass modifier;
- ABS slope-retention factor;
- roll recommendation before/after coordination;
- stability recommendation before/after coordination;
- slope recommendation before/after coordination;
- native advisory used or ignored;
- final model-space/world correction summary.

Telemetry should support the SQA matrix:

- 30, 60, 90, and 120 km/h;
- paved, dirt, and grass;
- braking while turning;
- high-speed steering;
- rollover tendency;
- controlled sliding;
- slope roll after brake release.

## Evidence Registry Updates

Implementation must update `docs/vehicle-behavior/sqa-evidence-matrix.md` with
new rows or row templates for the coordinator test matrix.

Do not mark ISSUE-001 resolved from the design or implementation alone.
Resolution requires SQA in-game verification.

## Testing

Automated tests must verify:

- coordinator function registration;
- hard gates fail closed;
- handbrake priority wins;
- roll can remain active while stability mode is Off;
- roll/stability priority is ordered before ABS/slope composition;
- ABS braking reduces, not fully disables, slope acceleration while braking;
- brake release allows slope rolling to resume;
- terrain and mass modifiers are bounded;
- native advisory cannot directly mutate vehicle state;
- telemetry field names are present;
- accepted ABS, handbrake, Drive/Reverse, and roll/stability guard contracts
  remain intact.

Manual SQA validation must verify:

- all currently registered vehicles;
- 30/60/90/120 km/h;
- paved/dirt/grass;
- braking while turning;
- sharp high-speed left/right steering;
- controlled sliding;
- rollover reduction;
- slope roll after brake release;
- ACE handbrake hard-lock;
- Drive/Reverse direction transitions.

## Risks

- Over-coordination could make vehicles feel artificial or over-damped.
- Terrain multipliers could hide class-specific tire or suspension problems.
- Too much slope retention during braking could weaken service braking feel.
- Too little slope retention could preserve the current stationary-on-slope
  issue.
- Native advisory integration could become confusing unless the coordinator logs
  when it is ignored.
- A broad implementation could accidentally duplicate ownership already held by
  ABS, roll stability, or the driver controller.

## Implementation Boundary

This spec approves the design only. The next step is a separate implementation
plan. No gameplay source changes are approved by this document alone.
