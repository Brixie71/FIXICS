# Controlled Slip Assist - Requirements Packet

## Objective

Design and implement a car-first Controlled Slip Assist layer for FIXICS Phase 1 ground vehicles.

The goal is to reduce high-speed full-lock rollover by allowing controlled lateral scrub before the vehicle trips over, while preserving accepted ABS, Drive/Reverse, ACE handbrake, Roll Stability, Sway Bar, Vehicle Stability, terrain, and Runtime Assist behavior.

## Current System State

- Phase: Phase 1 - Ground Vehicle Physics.
- Implemented systems:
  - ACE/FIXICS persistent handbrake.
  - Local idle autobrake bypass and slope rolling.
  - Local player driver controller.
  - ABS-like service braking.
  - Reverse/Drive neutral handoff.
  - Vehicle Stability Assistance for registered vehicle classes.
  - Roll Stability Assist with presets.
  - Front/rear Sway Bar Assist settings.
  - Runtime Assist Coordinator.
  - Vehicle handling telemetry and Evidence Registry.
  - Optional native assist remains advisory only.
- Relevant open issue:
  - ISSUE-001 - High-speed sharp-turn steering lock and rollover tendency.
- Known constraints:
  - Local-player only for first implementation.
  - Cars/light vehicles first.
  - Multiplayer authority remains out of scope.
  - Native assist remains advisory only.
  - Broad config-class patches remain out of scope.
  - SQA performs manual Arma validation.

## Files To Load

Load only exact paths.

| Purpose | File |
|---|---|
| Session state | `orchestration/state.md` |
| Open issue | `docs/fixes/open-issues.md` |
| Evidence matrix | `docs/vehicle-behavior/sqa-evidence-matrix.md` |
| Runtime Assist design | `docs/superpowers/specs/2026-06-21-runtime-assist-coordination-design.md` |
| Runtime Assist plan | `docs/superpowers/plans/2026-06-21-runtime-assist-coordination.md` |
| Roll Stability design | `docs/superpowers/specs/2026-06-20-roll-stability-assist-design.md` |
| Steering/stability design | `docs/superpowers/specs/2026-06-15-adaptive-player-steering-design.md` |
| Vehicle config reference | `docs/reference/vehicle-config-ref.md` |
| Engine limits | `docs/reference/known-engine-limits.md` |
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
| Should this use real-life tire behavior research or only tune around Arma behavior? | Use real tire behavior as the design target, but implement against Arma exposed behavior. | Research guides feel and thresholds; SQF/config boundaries control implementation. |
| Which game references are approved for feel? | GTA IV physics, Driver 3 physics, and WRC rally physics. | Use these as handling feel references only, not implementation sources. |
| What vehicle class comes first? | Cars first, then slowly move up to trucks. | Scope initial design and QA to light vehicles/cars. |
| Should the goal be more grip? | No. The goal is controlled lateral scrub before rollover. | Avoid sticky tire behavior and avoid grip inflation. |
| Should vehicle rollover still be possible? | Yes. It should be reduced, not impossible. | Do not force upright orientation or make assists absolute. |
| Should terrain matter? | Yes. | Paved, dirt, and grass modify slip thresholds/strength. |
| Should this communicate with Roll Stability and Sway Bar settings? | Yes. | Controlled Slip Assist must coordinate with existing roll/stability/sway systems. |
| Should config tire changes be first? | No. Start with SQF Controlled Slip Assist; config tire research comes later if evidence supports it. | Keep implementation reversible and avoid broad config regression risk. |
| Should this remain local-player only? | Yes, by current Phase 1 boundary. | No multiplayer authority work. |
| Should native assist own this behavior? | No. Native remains advisory only. | SQF owns first implementation. |
| Which vehicles are initial scope? | `B_LSV_01_unarmed_F`, `EMP_Polaris_DAGOR`, `LOP_IA_Offroad`, and `B_G_Offroad_01_F`. | Use currently registered light vehicle classes first. |
| What telemetry is required? | Add controlled slip fields. | Logs must prove eligibility, applied state, slip estimate, steering demand, terrain class, and grip release factor. |

## Research Notes

### Real Tire Behavior Target

Real tires do not create unlimited lateral force. As steering demand, speed, and lateral load increase, the tire reaches a grip limit and begins to slip. Past that limit, a recoverable slide is safer than staying planted until the vehicle trips into rollover.

FIXICS should approximate this behavior:

- full steering at high speed should not mean full lateral grip forever;
- lateral scrub should increase before dangerous bank angles;
- sliding should be recoverable, not ice-like;
- terrain should alter when grip releases;
- heavy or tall vehicles should require more conservative thresholds later.

### Game Feel References

- GTA IV: weight transfer, suspension motion, body roll, inertia, and recoverable sliding.
- Driver 3: heavier arcade-realistic momentum and less twitchy response.
- WRC/rally games: slip angle, surface grip, braking while turning, and controlled slide recovery.

These are feel references. They do not define implementation algorithms.

### Arma 3 Boundary

Arma exposes vehicle state and limited mutation surfaces, but not direct per-wheel tire slip, brake pressure, steering rack control, or true active suspension control through SQF.

First implementation should therefore:

- read speed, steering input, lateral velocity, yaw rate, bank, bank rate, ground contact, and surface;
- calculate a bounded grip release factor;
- allow controlled lateral scrub before rollover;
- coordinate with Roll Stability, Sway Bar, Vehicle Stability, and Runtime Assist;
- avoid broad `CfgVehicles` tire/friction patches until SQA approves config research.

## Constraints

- Do not change unrelated behavior.
- Do not touch generated output.
- Do not claim manual Arma behavior unless SQA verifies it in-game.
- Preserve ACE3 and CBA dependency boundaries.
- Preserve ACE handbrake hard-lock behavior.
- Preserve normal service braking and ABS feel.
- Preserve accepted Drive/Reverse transition behavior.
- Preserve Roll Stability and Sway Bar settings.
- Keep first implementation local-player only.
- Keep native assist advisory only.
- Do not patch broad tire/friction config classes in this phase.
- Do not force vehicle orientation upright.

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
   - Write a design spec for Controlled Slip Assist.
   - Define real tire behavior target and game-feel references.
   - Define Arma implementation boundaries.
   - Define terrain modifiers and telemetry.
2. Implementation plan:
   - Add static tests first.
   - Add pure controlled-slip recommendation math.
   - Integrate through the existing local stability/runtime assist path.
   - Add conservative global settings.
   - Expand telemetry.
3. Validation:
   - Run required static checks and `tools/check.ps1`.
   - Build with `tools/build.ps1` when SQA needs a test artifact.
   - Update evidence matrix rows for Controlled Slip Assist.
4. SQA handoff:
   - Test cars/light vehicles at 30/60/90/120 km/h.
   - Test paved, dirt, and grass.
   - Focus on full-lock steering, rollover tendency, controlled sliding, braking while turning, and recovery.

## Expected Output

- Files created:
  - Design spec under `docs/superpowers/specs/`.
  - Implementation plan under `docs/superpowers/plans/`.
  - Optional pure recommendation function under `addons/main/functions/`.
- Files likely modified during implementation:
  - `addons/main/config.cpp`
  - `addons/main/functions/fn_registerSettings.sqf`
  - `addons/main/functions/fn_applyVehicleStability.sqf`
  - `addons/main/functions/fn_coordinateVehicleAssists.sqf`
  - `addons/main/functions/fn_getRuntimeAssistRecommendation.sqf`
  - `addons/main/functions/fn_logVehicleHandlingConfig.sqf`
  - `addons/main/stringtable.xml`
  - `tests/integration/fixics-vehicle-physics-static.ps1`
  - `docs/vehicle-behavior/sqa-evidence-matrix.md`
  - `governance/audit/validation-log.md`
  - `orchestration/state.md`
- Tests run:
  - governance static
  - vehicle physics static
  - `tools/check.ps1`
  - `git diff --check`
- Manual SQA focus:
  - registered light vehicles;
  - full left/right steering at speed;
  - controlled slide instead of trip rollover;
  - paved/dirt/grass differences;
  - preserved ABS, handbrake, Drive/Reverse, roll, and sway behavior.

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
