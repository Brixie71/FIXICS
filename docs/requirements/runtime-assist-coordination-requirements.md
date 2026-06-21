# Runtime Assist Coordination - Requirements Packet

## Objective

Design and implement a Runtime Assist Coordination layer for FIXICS Phase 1 ground vehicles.

The coordination layer should let ABS, slope rolling, driver intent, Vehicle Stability Assistance, Roll Stability Assist, terrain effects, presets, and native advisory math communicate through one explicit layer instead of competing implicitly.

## Current System State

- Phase: Phase 1 - Ground Vehicle Physics.
- Implemented systems:
  - ACE/FIXICS persistent handbrake.
  - Local idle autobrake bypass and slope rolling.
  - Local player driver controller.
  - ABS-like service braking.
  - Reverse/Drive neutral handoff.
  - Optional native slope-control bridge, disabled by default.
  - Optional Native Driver Assist v2 advisory math, disabled by default.
  - Vehicle Stability Assistance for registered vehicle classes.
  - Roll Stability Assist with presets.
  - Vehicle Behavior Evidence Registry.
- Relevant open issue:
  - ISSUE-001 - High-speed sharp-turn steering lock.
- Known constraints:
  - Local-player only for first implementation.
  - Multiplayer authority remains out of scope.
  - Native assist remains advisory only.
  - Broad config-class patches remain out of scope.
  - SQA performs manual Arma validation.

## Files To Load

Load only exact paths.

| Purpose | File |
|---|---|
| Session state | `orchestration/state.md` |
| Requirements packet | `docs/requirements/runtime-assist-coordination-requirements.md` |
| Evidence registry | `docs/vehicle-behavior/README.md` |
| Evidence matrix | `docs/vehicle-behavior/sqa-evidence-matrix.md` |
| Open issue | `docs/fixes/open-issues.md` |
| Current roll design | `docs/superpowers/specs/2026-06-20-roll-stability-assist-design.md` |
| Current steering/stability design | `docs/superpowers/specs/2026-06-15-adaptive-player-steering-design.md` |
| Vehicle config reference | `docs/reference/vehicle-config-ref.md` |
| Engine limits | `docs/reference/known-engine-limits.md` |

## SQA Questions And Answers

| Question | SQA Answer | Decision Impact |
|---|---|---|
| Should Runtime Assist Coordination include implementation after the packet and plan are approved? | Yes. | Create requirements, design, plan, then execute after approval. |
| What is the first coordination target? | All systems together. | Design a coordinator for ABS, slope, driver intent, stability, roll, terrain, presets, and native advisory. |
| Should coordination be a new layer or existing functions only? | New layer function, one-to-many relationship. | Add a dedicated coordinator layer that existing functions communicate through. |
| Which system has priority when multiple systems want to modify velocity? | Stability Assist and Roll Stability. | Stability/roll corrections have priority in conflict resolution, after hard safety gates such as handbrake. |
| Should Roll Stability run when Stability Assist mode is Off? | Yes. | Roll Stability remains independent of stability assist mode. |
| Should ABS reduce or disable slope acceleration while braking downhill? | Reduce, not fully disable. Vehicle should roll again after brake release. | Add braking behavior that dampens slope acceleration while service braking is active, then restores roll/coast after release. |
| Should slope assist add speed while stability or roll assist is correcting? | Yes. | Slope assist remains active, but must coordinate with stability/roll corrections. |
| Should terrain affect assist strength in this phase? | Yes. | Terrain becomes a runtime coordination input, not only telemetry. |
| Should presets become global handling profiles? | No. Each system keeps separate presets. | Coordinator reads subsystem presets; it does not merge them into one global preset. |
| Should first implementation remain local-player only? | Yes. | No multiplayer authority work. |
| Should multiplayer/server authority remain out of scope? | Yes. | Server sync is deferred. |
| Should native assist remain advisory only? | Yes. | Native code cannot own mutation. |
| Should there be new CBA settings? | Yes, global FIXICS settings. | Add conservative global coordination settings if implementation plan approves. |
| Should defaults be conservative or strong? | Conservative defaults. | Effects should be safe by default, stronger only through tuning. |
| Which vehicles are in scope? | All currently registered vehicles. | Validate on registered Vehicle Stability/Roll Stability classes. |
| Desired success behavior? | Real-car feel, smoother braking while turning, reduced high-speed steering overshoot, reduced rollover, controlled sliding, vehicle-mass-aware behavior. | Design for realistic stability, not arcade grip or forced upright behavior. |
| Should new telemetry lines show assist suppression/override? | Yes. | Coordinator must emit telemetry for interactions and priority decisions. |
| Should SQA use 30/60/90/120 km/h paved/dirt/grass matrix? | Yes. | Manual QA matrix stays consistent with ISSUE-001. |
| Should the Evidence Matrix update during this work? | Yes. | Implementation should update `docs/vehicle-behavior/sqa-evidence-matrix.md` during the work. |
| Any hard must-not-change behaviors? | Keep systems aligned; preserve ACE handbrake, normal braking, Drive/Reverse transition, and existing ABS feel. | Implementation must not regress known accepted behavior. |

## Research Notes

### Real-World Vehicle Behavior

- Electronic stability control compares driver intent with actual vehicle motion and intervenes when the vehicle is not following the intended path. It commonly uses steering angle, yaw rate, lateral acceleration, wheel speed, and brake control concepts.
- ESC is distinct from ABS and traction control, but it is built on top of those systems. ABS helps keep braking controllable; ESC uses brake/throttle intervention to reduce loss of control.
- Roll stability and active rollover protection extend horizontal stability control into roll-risk detection. They typically respond to impending rollover by reducing energy through braking, torque reduction, suspension action, or other stabilizing interventions.
- Cornering brake control improves stability while braking in a turn by adjusting braking force and yaw behavior instead of treating braking as purely longitudinal.
- Vehicle dynamics are strongly affected by tires, braking, suspension, steering, mass distribution, center of mass, surface, and speed.
- Load transfer during braking, acceleration, and cornering changes tire loading and therefore available grip. Higher center of mass, mass, track width, wheelbase, and acceleration all matter.

### GTA IV Reference

GTA IV is a useful feel reference because reviewers noted more realistic vehicle handling than earlier GTA games, and the game is known for heavier body motion, suspension travel, inertia, and recoverable sliding. FIXICS should use this only as a feel reference, not as a technical engine target.

Useful takeaway:

- preserve body movement and sliding;
- avoid instant grip inflation;
- avoid forced upright correction;
- let mass and surface matter;
- make assists feel like damping and stability support, not teleporting or snapping.

### Arma 3 Boundary

Arma 3 does not expose the same per-wheel brake pressure, tire slip, steering actuator, or suspension controller surfaces that real ESC/ABS/roll systems use. FIXICS must therefore coordinate at the available SQF/config boundary:

- read driver intent and vehicle state;
- calculate bounded recommendations;
- apply limited model-space/world velocity corrections through existing local authority;
- keep native extension advisory only;
- avoid broad config patches unless future SQA evidence approves them.

### Research Sources

- NHTSA, Electronic Stability Control: `https://www.nhtsa.gov/equipment/electronic-stability-control`
- Bohemia Interactive Community Wiki, Arma 3 Cars Config Guidelines: `https://community.bistudio.com/wiki/Arma_3:_Cars_Config_Guidelines`
- Bohemia Interactive Community Wiki, Arma 3 Vehicle Handling Configuration: `https://community.bistudio.com/wiki/Arma_3:_Vehicle_Handling_Configuration`
- Bosch Mobility, ESP/electronic stability program background: `https://www.bosch-mobility.com/en/solutions/driving-safety/electronic-stability-program/`
- GTA IV reference is limited to SQA feel goals and player-facing handling comparison. It is not a technical implementation source.

## Constraints

- Do not change unrelated behavior.
- Do not touch generated output.
- Do not claim manual Arma behavior unless SQA verifies it in-game.
- Preserve ACE3 and CBA dependency boundaries.
- Keep SQF, config, native, and multiplayer authority boundaries explicit.
- Preserve ACE handbrake hard-lock behavior.
- Preserve normal service braking.
- Preserve accepted Drive/Reverse transition behavior.
- Preserve current ABS feel unless SQA approves tuning.
- Keep Roll Stability independent from Stability Assist mode.

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
   - Write a design spec for a local Runtime Assist Coordinator.
   - Define priority and arbitration rules.
   - Define terrain influence rules.
   - Define telemetry output.
2. Implementation plan:
   - Add static tests first.
   - Add one coordinator function as the communication layer.
   - Integrate existing systems through coordinator calls without rewriting accepted subsystem behavior.
   - Add conservative global settings.
3. Validation:
   - Run required static checks and `tools/check.ps1`.
   - Add SQA matrix rows to the Evidence Registry.
4. SQA handoff:
   - Test registered vehicles at 30/60/90/120 km/h on paved, dirt, and grass.
   - Focus on braking while turning, high-speed steering, rollover reduction, controlled sliding, and slope behavior after brake release.

## Expected Output

- Files created:
  - New design spec under `docs/superpowers/specs/`.
  - New implementation plan under `docs/superpowers/plans/`.
- Files likely modified during implementation:
  - `addons/main/config.cpp`
  - `addons/main/functions/fn_registerSettings.sqf`
  - `addons/main/functions/fn_updateDriverController.sqf`
  - `addons/main/functions/fn_applyVehicleStability.sqf`
  - `addons/main/functions/fn_applyABSBraking.sqf`
  - `addons/main/functions/fn_applySlopeRollback.sqf`
  - new coordinator function under `addons/main/functions/`
  - `addons/main/stringtable.xml`
  - `tests/integration/fixics-vehicle-physics-static.ps1`
  - `docs/vehicle-behavior/sqa-evidence-matrix.md`
  - `governance/audit/validation-log.md`
- Tests run:
  - governance static
  - vehicle physics static
  - `tools/check.ps1`
- Manual SQA focus:
  - registered vehicles;
  - 30/60/90/120 km/h;
  - paved/dirt/grass;
  - braking while turning;
  - high-speed steering;
  - rollover reduction;
  - controlled sliding;
  - slope roll after brake release.

## Validation Commands

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
powershell -ExecutionPolicy Bypass -File tools\check.ps1
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
