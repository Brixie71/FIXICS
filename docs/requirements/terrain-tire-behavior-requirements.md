# Terrain Tire Behavior - Requirements Packet

## Objective

Design and implement a new Terrain Tire Behavior layer for FIXICS Phase 1 ground
vehicles.

The layer should model how terrain, tire condition, tire pressure, acceleration,
braking, steering, slope rolling, and vehicle mass affect available traction. It
must feed existing FIXICS systems through Runtime Assist instead of replacing
Controlled Slip, ABS, Slope Assist, Vehicle Stability, Roll Stability, or Sway
Bar Assist.

## Current System State

- Phase: Phase 1 - Ground Vehicle Physics.
- Relevant implemented systems:
  - ACE/FIXICS persistent handbrake.
  - Local idle autobrake bypass and slope rolling.
  - Local player driver controller.
  - ABS-like service braking.
  - Reverse/Drive neutral handoff.
  - Vehicle Stability Assistance.
  - Roll Stability Assist.
  - Sway Bar Assist.
  - Runtime Assist Coordinator.
  - Controlled Slip Assist.
  - Vehicle handling telemetry and Evidence Registry.
- Relevant open issues:
  - ISSUE-001 - High-speed sharp-turn steering lock and rollover tendency.
- Known constraints:
  - Local-player only for first implementation.
  - SQF-first.
  - Multiplayer authority remains out of scope.
  - Native assist remains advisory only.
  - Broad tire/friction config patches are deferred.
  - Wet/mud terrain is deferred until exposed clearly enough by Arma surface data.
  - SQA performs manual Arma validation.

## Files To Load

Load only exact paths.

| Purpose | File |
|---|---|
| Session state | `orchestration/state.md` |
| Open issue | `docs/fixes/open-issues.md` |
| Controlled Slip requirements | `docs/requirements/controlled-slip-assist-requirements.md` |
| Controlled Slip design | `docs/superpowers/specs/2026-06-22-controlled-slip-assist-design.md` |
| Runtime Assist requirements | `docs/requirements/runtime-assist-coordination-requirements.md` |
| Runtime Assist design | `docs/superpowers/specs/2026-06-21-runtime-assist-coordination-design.md` |
| Vehicle config reference | `docs/reference/vehicle-config-ref.md` |
| Engine limits | `docs/reference/known-engine-limits.md` |
| PhysX command reference | `docs/reference/physx-command-ref.md` |
| Evidence matrix | `docs/vehicle-behavior/sqa-evidence-matrix.md` |
| Stability controller | `addons/main/functions/fn_applyVehicleStability.sqf` |
| Runtime coordinator | `addons/main/functions/fn_coordinateVehicleAssists.sqf` |
| Runtime math | `addons/main/functions/fn_getRuntimeAssistRecommendation.sqf` |
| Handling telemetry | `addons/main/functions/fn_logVehicleHandlingConfig.sqf` |
| Settings | `addons/main/functions/fn_registerSettings.sqf` |
| Stringtable | `addons/main/stringtable.xml` |
| Static tests | `tests/integration/fixics-vehicle-physics-static.ps1` |

## SQA Questions And Answers

| Question | SQA Answer | Decision Impact |
|---|---|---|
| Should this be a new layer or an upgrade inside Controlled Slip only? | New layer. | Add a separate Terrain Tire Behavior recommendation layer. |
| Feature name? | Terrain Tire Behavior. | Use this name in docs, settings labels, and telemetry. |
| Enabled globally by default? | Yes. | Default global setting should enable the layer conservatively. |
| Apply to all currently registered FIXICS vehicles first? | Yes. | Use the existing registered vehicle boundary. |
| Local-player only? | Yes. | No multiplayer authority or sync work. |
| Affect acceleration, braking, turning, and slope rolling together? | Yes. | Return multipliers that can be consumed by Runtime Assist and subsystem logic. |
| Initial terrain classes? | Asphalt/paved, dirt, grass, sand, rock, unknown/default. | Implement bounded surface classification. |
| Wet/mud? | Defer until Arma exposes it clearly through surface data. | No wet/mud behavior in first version. |
| Paved behavior? | Highest grip, higher rollover risk. | Paved should reduce wheelspin but not hide rollover risk. |
| Dirt/grass/sand behavior? | Lower grip, more wheelspin, more controlled sliding. | Loose surfaces should release traction earlier. |
| Rock behavior? | Unstable grip with sharper traction drops on transitions. | Add unstable traction multiplier behavior for rough/rock classification. |
| Sudden acceleration on loose terrain? | Stronger wheelspin. | Add acceleration demand to wheelspin estimate. |
| Vehicle mass behavior? | Reduce acceleration and make traction loss feel heavier, not just increase slip. | Add mass modifier and sluggishness factor. |
| Damaged tires? | Change behavior alongside Arma's own tire damage model. | Read damage state and add FIXICS tire-pressure state without replacing Arma damage. |
| One bullet hit? | Slow deflation over time, not immediate full failure. | Add progressive deflation state. |
| Deflated tire behavior? | Remain movable like run-flat/military tire behavior: lower top speed, more drag, worse steering, altered traction. | Add run-flat mobility model with minimum mobility cap. |
| Deflation traction meaning? | More ground contact/drag, reduced clean grip; not a simple traction increase. | Separate drag penalty from clean grip multiplier. |
| Per-wheel support? | Per-wheel if Arma exposes data; fallback to whole-vehicle tire damage if not. | Implement with a fallback-safe state model. |
| Tire pressure settings? | Add `FIXICS_tirePressureEnabled`, `FIXICS_tireDeflationRate`, `FIXICS_tireMinimumMobility`, `FIXICS_tireDragStrength`, `FIXICS_tireSteeringPenalty`, `FIXICS_tireDebugLogging`. | Add CBA global settings during implementation. |
| Telemetry fields? | Surface type, terrain grip class, traction multiplier, wheelspin estimate, tire-air state, deflation state, drag penalty, mass modifier. | Expand telemetry and SQA evidence fields. |
| Implementation approach? | SQF-first; config tire/friction patches later only after SQA telemetry proves need. | Do not patch config tire friction in this design. |

## Research Notes

### Arma Boundary

FIXICS reference docs identify Arma terrain and vehicle control surfaces that are
usable for this feature:

- `surfaceType` can classify the ground under or near the vehicle.
- `surfaceNormal` supports slope and terrain-relative calculations.
- `velocity`, `velocityModelSpace`, `speed`, `angularVelocity`, `getMass`, and
  damage state can feed recommendation math.
- `setVelocity`, `setVelocityModelSpace`, `addForce`, and related local vehicle
  mutation commands are available, but should remain bounded and owned by the
  existing local controller path.

The project currently records no documented runtime per-wheel friction setter.
That means first implementation must approximate tire behavior with multipliers,
velocity/force limits, and telemetry rather than direct live tire-friction
control.

### Tire And Run-Flat Behavior Target

Run-flat tires are designed to preserve mobility after pressure loss, but at
reduced speed and limited range. Military/security applications commonly use
support inserts or similar systems to keep a vehicle movable after air loss.

For FIXICS, the useful model is:

- a punctured tire does not immediately make the vehicle unusable;
- pressure loss increases rolling resistance and steering imprecision;
- lower pressure reduces clean grip and safe top-end mobility;
- mobility remains possible through a minimum run-flat factor;
- tire damage should make the vehicle feel degraded, not invincible.

### Terrain Behavior Target

Terrain should change available traction instead of acting as decoration:

- paved/asphalt: high clean grip, lower wheelspin, higher rollover/trip risk;
- dirt: lower clean grip, earlier slip, moderate wheelspin;
- grass: lower predictable grip and increased sliding;
- sand: stronger wheelspin and sluggish acceleration;
- rock/rough: unstable traction with sharper drops during transitions;
- unknown/default: conservative fallback close to dirt/paved midpoint.

## Constraints

- Do not change unrelated behavior.
- Do not touch generated output.
- Do not claim manual Arma behavior unless SQA verifies it in-game.
- Preserve ACE3 and CBA dependency boundaries.
- Preserve ACE handbrake hard-lock behavior.
- Preserve accepted ABS feel unless explicitly changed by a later approved plan.
- Preserve accepted Drive/Reverse transition behavior.
- Preserve existing Roll Stability, Sway Bar, Vehicle Stability, and Controlled
  Slip settings.
- Keep first implementation local-player only.
- Keep native assist advisory only.
- Do not patch broad `CfgVehicles` tire/friction classes in this phase.
- Do not force vehicle orientation upright.
- Do not implement wet/mud behavior in the first version.

## Approval Gates

Stop before implementation if the work touches:

- Gameplay behavior.
- Architecture or public interface.
- New dependency or external tool.
- Native extension.
- Broad `CfgVehicles` patch.
- Multiplayer authority or synchronization.
- Material regression risk.
- Direct SQA stop, pause, hold, or abort command.

## Recommended Approach

1. Documentation/research:
   - Write a design spec for Terrain Tire Behavior.
   - Keep Arma limits and run-flat behavior explicit.
   - Define terrain classes, tire-pressure state, and telemetry.
2. Implementation plan:
   - Add tests first for settings, function registration, bounds, and telemetry.
   - Add a pure Terrain Tire Behavior recommendation function.
   - Integrate through Runtime Assist and existing local stability/controller
     paths without broad rewrites.
   - Add conservative CBA settings.
3. Validation:
   - Run required static checks and `tools/check.ps1`.
   - Run `git diff --check`.
   - Build only when SQA needs a test artifact.
4. SQA handoff:
   - Test registered vehicles across asphalt/paved, dirt, grass, sand, rock,
     and unknown/default where available.
   - Focus on acceleration wheelspin, braking traction, turning traction, slope
     rolling, tire damage, and run-flat mobility.

## Expected Output

- Files created:
  - `docs/requirements/terrain-tire-behavior-requirements.md`
  - `docs/superpowers/specs/2026-06-26-terrain-tire-behavior-design.md`
  - implementation plan under `docs/superpowers/plans/` after SQA approves the
    design.
- Files likely modified during implementation:
  - `addons/main/config.cpp`
  - `addons/main/functions/fn_registerSettings.sqf`
  - `addons/main/functions/fn_coordinateVehicleAssists.sqf`
  - `addons/main/functions/fn_getRuntimeAssistRecommendation.sqf`
  - `addons/main/functions/fn_applyVehicleStability.sqf`
  - `addons/main/functions/fn_logVehicleHandlingConfig.sqf`
  - `addons/main/stringtable.xml`
  - `tests/integration/fixics-vehicle-physics-static.ps1`
  - `tools/check.ps1` if a new unit test is added
  - `docs/vehicle-behavior/sqa-evidence-matrix.md`
  - `governance/audit/validation-log.md`
  - `orchestration/state.md`
- Tests run:
  - governance static
  - vehicle physics static
  - `tools/check.ps1`
  - `git diff --check`
- Manual SQA focus:
  - registered vehicles;
  - terrain transitions;
  - acceleration from stop and rolling acceleration;
  - braking while turning;
  - slope rolling on different terrain;
  - damaged tire deflation and run-flat mobility;
  - preserved ABS, handbrake, Drive/Reverse, Stability, Roll, Sway, and
    Controlled Slip behavior.

## Validation Commands

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
powershell -ExecutionPolicy Bypass -File tools\check.ps1
git diff --check
```

## SQA QA Handoff

After implementation, hand the feature to SQA with:

- what changed;
- what did not change;
- expected in-game behavior;
- suggested manual test matrix;
- known limitations;
- follow-up comment path.

## Repeat Cycle

When SQA reports comments:

1. Record the comment.
2. Classify it as bug, tuning, regression, missing requirement, or new feature.
3. Update this packet or the relevant open issue.
4. Recommend the next fix plan.
5. Wait for SQA approval.
6. Implement and validate.
