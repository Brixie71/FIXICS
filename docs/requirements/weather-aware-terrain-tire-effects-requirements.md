# Weather-Aware Terrain Tire Effects - Requirements Packet

## Objective

Add Weather-Aware Terrain Tire Effects to FIXICS Phase 1 wheeled vehicle
handling.

The feature extends Terrain Tire Behavior with rain wetness, terrain saturation,
hydroplaning risk, storm penalties, and minimal wind lateral handling while
preserving existing ABS, slope, stability, roll, sway, controlled slip,
handbrake, per-vehicle profile, and native fallback boundaries.

## Current System State

- Phase: Phase 1 - Ground Vehicle Physics.
- Relevant systems:
  - Terrain Tire Behavior Phase 2.
  - Runtime Assist Coordinator.
  - Controlled Slip Assist.
  - Vehicle Stability, Roll Stability, Sway Bar Assist.
  - ABS and Drive/Reverse controller.
  - Native `terrainTireV2` advisory, disabled by default.
- Relevant open issues:
  - ISSUE-001 high-speed steering/rollover behavior remains open pending SQA
    matrix completion.
  - RHS HMMWV heavy ABS snap is a minor backlog item.
- Known constraints:
  - SQF-first for weather behavior.
  - Wheeled vehicles first.
  - Tracked vehicles deferred.
  - No yaw moment, steering input modification, or gust timing in this pass.
  - No config tire/friction patches.
  - No multiplayer authority change.

## Files To Load

Load only exact paths.

| Purpose | File |
|---|---|
| Terrain Tire function | `addons/main/functions/fn_getTerrainTireRecommendation.sqf` |
| Stability/Terrain integration | `addons/main/functions/fn_applyVehicleStability.sqf` |
| Runtime coordinator | `addons/main/functions/fn_coordinateVehicleAssists.sqf` |
| Telemetry | `addons/main/functions/fn_logVehicleHandlingConfig.sqf` |
| Settings | `addons/main/functions/fn_registerSettings.sqf` |
| Stringtable | `addons/main/stringtable.xml` |
| Static tests | `tests/integration/fixics-vehicle-physics-static.ps1` |
| Project state | `orchestration/state.md` |

## SQA Questions And Answers

| Question | SQA Answer | Decision Impact |
|---|---|---|
| Feature name? | Weather-Aware Terrain Tire Effects. | Use this name in docs and handoff. |
| Settings category? | Terrain Tire settings. | Add settings under `["FIXICS", "Terrain Tire"]`. |
| Enabled by default? | Yes, conservative. | Default `FIXICS_weatherTerrainEnabled=true`. |
| Vehicle scope? | Wheeled vehicles first. | Keep tracked vehicles deferred. |
| Weather affects all traction channels? | Yes. | Apply to acceleration, braking, turning, slope, and controlled slip through Terrain Tire multipliers. |
| Saturation timer? | Yes. | Rain wetness changes gradually. |
| Saturation default? | 30 seconds. | Use `FIXICS_weatherSaturationTime=30`. |
| Drying timer? | Yes, 180 seconds. | Use `FIXICS_weatherDryingTime=180`. |
| Drying constraint? | Drying timer only runs when `rainDensity == 0`. | Active rain never dries the surface. |
| Hydroplaning? | Yes on wet paved roads. | Add hydroplaning risk field and multiplier. |
| Hydroplaning threshold? | 70 km/h. | Use `FIXICS_hydroplaningSpeedKmh=70`. |
| Wet dirt/grass? | Shift toward mud-like traction. | Reduce grip as saturation increases. |
| Wet sand? | Improve traction slightly through compaction. | Increase sand grip moderately when wet. |
| Wind first pass? | Minimal only. | Lateral delta + vehicle profile scaling + telemetry only. |
| Wind profile scaling? | Yes. | Scale using vehicle class/profile/family approximation. |
| Wind mutation path? | Existing stability paths only. | No direct steering/yaw simulation. |
| Storm behavior? | Heavy rain + wind + stronger wetness penalties. | Use rain/overcast/wind combined reason. |
| New settings? | Yes. | Add eight CBA settings. |
| Telemetry? | Yes. | Add eleven fields. |
| SQA validation focus? | Saturation, hydroplaning, wind/slope interaction, drying pause under rain. | Handoff matrix must include these checks. |

## Constraints

- Do not change unrelated behavior.
- Do not touch generated output.
- Do not claim manual Arma behavior unless SQA verifies it in-game.
- Preserve ACE3 and CBA dependency boundaries.
- Preserve SQF fallback when native Terrain Tire is disabled.
- Keep wind minimal: lateral delta/profile scale/telemetry only.
- Do not implement yaw moment, steering input changes, or gust timing.
- Drying only occurs when `rainDensity == 0`.

## Approval Gates

Stop before implementation if this expands into:

- native extension changes;
- config patches;
- multiplayer authority;
- yaw/steering wind simulation;
- stuck/mud system;
- tracked vehicle behavior.

## Expected Output

- New settings under Terrain Tire.
- Weather-aware Terrain Tire recommendation fields.
- Weather telemetry in one-shot and continuous logs.
- Runtime Assist propagation.
- Static tests and HEMTT validation pass.

## Validation Commands

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
powershell -ExecutionPolicy Bypass -File tools\check.ps1
git diff --check
```
