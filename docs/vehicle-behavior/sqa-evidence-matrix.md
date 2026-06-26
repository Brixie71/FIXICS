# SQA Evidence Matrix

## Purpose

The SQA evidence matrix connects telemetry logs to manual observations and recommended next actions.

Each row should describe one test run or one tightly scoped group of equivalent runs.

## Recommended Next Actions

| Action | Meaning |
|---|---|
| `collect-more-telemetry` | Current evidence is insufficient for a behavior or config decision. |
| `runtime-assist-tuning` | Evidence points to ABS, slope, stability, roll, or controller tuning. |
| `config-research` | Evidence points to class-specific tire, suspension, anti-roll, mass, center-of-mass, steering, or gearbox research. |
| `no-change` | Current behavior is acceptable for the tested scope. |
| `blocked` | Work cannot proceed without SQA clarification, new classification approval, or missing telemetry. |

## Matrix

| Date | SQA tester | Vehicle class | Terrain or surface | Speed band | Input pattern | Active preset | Assist mode | Roll preset | Telemetry log path | Observed behavior | Classification | Recommended next action |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 2026-06-20 | SQA | `B_LSV_01_unarmed_F` | SQA rollover test surface | High-speed sharp turn | Sudden left/right steering | `not recorded` | `Yaw + Lateral Damping` | `Aggressive SQA` | `diagnostics/vehicle-telemetry_2026-06-20_194337.log` | SQA confirmed rollover assist works when settings are maxed; controlled sliding remains possible but rollover can still occur under severe steering. | `rollover-risk`, `terrain-interaction` | `runtime-assist-tuning` |
| 2026-06-21 | SQA | `registered vehicles` | Paved road | 30/60/90/120 km/h | Brake while turning, sharp left/right, coast after brake release | subsystem presets separate | selected by SQA | selected by SQA | `pending SQA telemetry` | Runtime Assist Coordinator validation row. Record priority winner, suppressed assists, terrain multiplier, mass multiplier, and final correction. | `runtime-assist-coordination` | `collect-more-telemetry` |
| 2026-06-21 | SQA | `registered vehicles` | Dirt | 30/60/90/120 km/h | Brake while turning, sharp left/right, coast after brake release | subsystem presets separate | selected by SQA | selected by SQA | `pending SQA telemetry` | Runtime Assist terrain influence validation row. Confirm controlled sliding remains possible and rollover assist remains bounded. | `runtime-assist-coordination`, `terrain-interaction` | `collect-more-telemetry` |
| 2026-06-21 | SQA | `registered vehicles` | Grass | 30/60/90/120 km/h | Brake while turning, sharp left/right, coast after brake release | subsystem presets separate | selected by SQA | selected by SQA | `pending SQA telemetry` | Runtime Assist low-friction validation row. Confirm assist strength is reduced without disabling braking, slope roll, or roll stability. | `runtime-assist-coordination`, `terrain-interaction` | `collect-more-telemetry` |
| 2026-06-22 | SQA | `registered light vehicles` | Paved | 30/60/90/120 km/h | Full left/right steering, braking while turning, recovery after slide | subsystem presets separate | selected by SQA | selected by SQA | `pending SQA telemetry` | Controlled Slip Assist paved validation row. Record controlled slip eligibility, grip release factor, roll bank, bank rate, and recovery behavior. | `controlled-slip-assist`, `rollover-risk` | `collect-more-telemetry` |
| 2026-06-22 | SQA | `registered light vehicles` | Dirt | 30/60/90/120 km/h | Full left/right steering, braking while turning, recovery after slide | subsystem presets separate | selected by SQA | selected by SQA | `pending SQA telemetry` | Controlled Slip Assist dirt validation row. Confirm earlier controlled scrub than paved without ice-like behavior. | `controlled-slip-assist`, `terrain-interaction` | `collect-more-telemetry` |
| 2026-06-22 | SQA | `registered light vehicles` | Grass | 30/60/90/120 km/h | Full left/right steering, braking while turning, recovery after slide | subsystem presets separate | selected by SQA | selected by SQA | `pending SQA telemetry` | Controlled Slip Assist grass validation row. Confirm loose terrain behavior and bounded correction. | `controlled-slip-assist`, `terrain-interaction` | `collect-more-telemetry` |

## Terrain Tire Behavior Matrix

| Date | SQA tester | Vehicle class | Terrain or surface | Test focus | Required telemetry | SQA result | Recommended next action |
|---|---|---|---|---|---|---|---|
| pending | SQA | `registered light vehicles` | Paved/asphalt | Baseline grip, braking, steering, and wheelspin reference. | `terrainTireEnabled`, `terrainTireEligible`, `surfaceType`, `terrainGripClass`, `tractionMultiplier`, `accelerationTractionMultiplier`, `brakingTractionMultiplier`, `turningTractionMultiplier`, `wheelspinEstimate`, `terrainTireTelemetryVersion` | Pending SQA results. | `collect-more-telemetry` |
| pending | SQA | `registered light vehicles` | Dirt | Reduced traction and controlled wheelspin compared with paved/asphalt. | `terrainTireReason`, `surfaceType`, `terrainGripClass`, `tractionMultiplier`, `accelerationTractionMultiplier`, `brakingTractionMultiplier`, `turningTractionMultiplier`, `slopeTractionMultiplier`, `wheelspinEstimate`, `perWheelMode` | Pending SQA results. | `collect-more-telemetry` |
| pending | SQA | `registered light vehicles` | Grass | Low-friction steering and braking without ice-like behavior. | `terrainTireEligible`, `terrainGripClass`, `tractionMultiplier`, `turningTractionMultiplier`, `slopeTractionMultiplier`, `wheelspinEstimate`, `massModifier`, `terrainTireTelemetryVersion` | Pending SQA results. | `collect-more-telemetry` |
| pending | SQA | `registered light vehicles` | Sand | High wheelspin, stronger acceleration loss, and bounded mobility. | `surfaceType`, `terrainGripClass`, `tractionMultiplier`, `accelerationTractionMultiplier`, `wheelspinEstimate`, `tireDragPenalty`, `massModifier`, `perWheelMode` | Pending SQA results. | `collect-more-telemetry` |
| pending | SQA | `registered light vehicles` | Rock/rough | Rough-surface traction loss, steering response, and slope retention. | `terrainGripClass`, `tractionMultiplier`, `turningTractionMultiplier`, `slopeTractionMultiplier`, `wheelspinEstimate`, `tireSteeringPenalty`, `massModifier`, `terrainTireTelemetryVersion` | Pending SQA results. | `collect-more-telemetry` |
| pending | SQA | `registered light vehicles` | Tire damage / one tire hit | Tire air loss, deflation state, drag penalty, steering penalty, and fallback per-wheel behavior. | `tireAirState`, `tireDeflationState`, `tireDragPenalty`, `tireSteeringPenalty`, `tractionMultiplier`, `turningTractionMultiplier`, `perWheelMode`, `terrainTireTelemetryVersion` | Pending SQA results. | `collect-more-telemetry` |

## Rules

- Use repository-relative telemetry log paths when logs are available in the workspace.
- Use `not recorded` for unknown values.
- Do not mark a behavior resolved from this matrix alone. Manual SQA acceptance remains required.
