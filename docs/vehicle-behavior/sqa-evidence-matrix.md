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

## Rules

- Use repository-relative telemetry log paths when logs are available in the workspace.
- Use `not recorded` for unknown values.
- Do not mark a behavior resolved from this matrix alone. Manual SQA acceptance remains required.
