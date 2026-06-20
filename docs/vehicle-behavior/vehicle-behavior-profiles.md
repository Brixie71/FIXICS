# Vehicle Behavior Profiles

## Purpose

A vehicle behavior profile records what FIXICS knows about one vehicle class or family.

Profiles record evidence and support status only. They do not authorize broad config patches or gameplay behavior changes.

## Support Status Values

| Status | Meaning |
|---|---|
| `observed-only` | Vehicle has appeared in telemetry or SQA notes, but has no approved FIXICS support. |
| `telemetry-supported` | Vehicle can be logged and studied through the Evidence Registry. |
| `runtime-assist-supported` | Vehicle is approved for current runtime assist behavior. |
| `config-experiment-candidate` | Vehicle has enough evidence for a possible class-specific config design. |

## Profile Fields

| Field | Meaning |
|---|---|
| Vehicle class | Exact Arma class name. |
| Family/source | Vanilla, mod source, or vehicle family when known. |
| Support status | One approved support status value. |
| Tested surfaces | Paved, dirt, grass, slope, or other recorded surfaces. |
| Tested speed bands | Speed bands covered by SQA evidence. |
| Tested presets and modes | Stability, roll, ABS, or related presets used in evidence runs. |
| Known config evidence | Relevant inherited config values or `not recorded`. |
| Known classifications | Approved behavior classifications observed for this class. |
| Current recommendation | One next action from the SQA evidence matrix. |

## Initial Profiles

| Vehicle class | Family/source | Support status | Tested surfaces | Tested speed bands | Tested presets and modes | Known config evidence | Known classifications | Current recommendation |
|---|---|---|---|---|---|---|---|---|
| `EMP_Polaris_DAGOR` | Modded DAGOR | `runtime-assist-supported` | Paved, dirt, grass pending matrix completion | 30, 60, 90, 120 km/h pending matrix completion | Realistic Stable, Rally, stability modes pending matrix completion | Player steering coefficients recorded through diagnostics when SQA runs capture | `oversteer`, `rollover-risk` pending confirmation | `collect-more-telemetry` |
| `B_LSV_01_unarmed_F` | Vanilla LSV | `runtime-assist-supported` | SQA LSV/buggy rollover test surfaces | High-speed sharp-turn testing | Roll Stability Aggressive SQA verified as useful starting point | `not recorded` | `rollover-risk` | `runtime-assist-tuning` |
| `LOP_IA_Offroad` | LOP IA Offroad | `runtime-assist-supported` | SQA Offroad rollover validation surfaces | `not recorded` | Stability compatibility added after telemetry | `not recorded` | `rollover-risk` | `collect-more-telemetry` |
| `B_G_Offroad_01_F` | Vanilla Offroad | `runtime-assist-supported` | SQA Offroad rollover validation surfaces | `not recorded` | Stability compatibility added after telemetry | `not recorded` | `rollover-risk` | `collect-more-telemetry` |
