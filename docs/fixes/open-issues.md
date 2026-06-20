# Open Issues

## Purpose

This file tracks SQA-reported bugs that are not yet resolved. Move fixed and verified items to `docs/fixes/fix-log.md`; do not keep resolved milestones here.

Phase 1 cannot close while any `HIGH` or `CRITICAL` `ground-vehicle` issue is open.

## Priority Levels

| Priority | Meaning |
|---|---|
| `CRITICAL` | Crashes the game, corrupts mission state, or makes the vehicle unusable |
| `HIGH` | Consistent physics behavior that materially affects gameplay |
| `MEDIUM` | Noticeable issue that does not block normal gameplay |
| `LOW` | Minor anomaly, edge case, or cosmetic issue |

## Status Values

| Status | Meaning |
|---|---|
| `OPEN` | Filed, not assigned |
| `RESEARCHING` | CODEX is analyzing root cause |
| `AWAITING APPROVAL` | Plan presented, waiting for SQA |
| `IN PROGRESS` | SQA approved implementation |
| `BLOCKED` | Cannot proceed; reason is documented |
| `RESOLVED` | Verified and ready to move to fix log |
| `WONT FIX` | SQA declined the issue |

## Open Issues

### ISSUE-001 - High-speed sharp-turn steering lock

- **Priority** : HIGH
- **Area**     : ground-vehicle steering
- **Status**   : IN PROGRESS
- **Reported** : SQA, 2026-06-12

At high speed, a sharp steering input can appear to lock the steering response while the vehicle continues forward and oversteers. SQA described moderate rally-style turns as acceptable, with the problem appearing on sharper left or right turns.

This issue is not currently attributed to ABS braking or Native Driver Assist v2. Root-cause research and a separate approved design are required before implementation.

#### Research Direction

Bohemia documents `PlayerSteeringCoefficients` as a player-only steering-sensitivity configuration with independent controls for steering build-up, speed sensitivity, nonlinear response near maximum steering angle, caster-like recentering, and maximum steering angle at 100 km/h.

The first investigation should therefore compare the affected vehicle classes' inherited `PlayerSteeringCoefficients` before adding scripted steering or changing tire grip. Tire parameters such as `latStiffX`, `latStiffY`, and `frictionVsSlipGraph` affect the lateral force available after steering input reaches the wheels; they do not directly repair a keyboard-input response curve.

Approved research artifact: `docs/superpowers/specs/2026-06-15-adaptive-player-steering-design.md`.

#### Diagnostic Harness

Run the following from the debug console while seated in the test vehicle:

```sqf
[vehicle player, 30, 0.1] call FIXICS_fnc_startSteeringDiagnostics;
```

Close the console and drive the sharp-turn test during the 30-second capture.
The RPT stream records live left/right input magnitude, speed, model-space
velocity, heading change, and surface type. Use
`FIXICS_fnc_logVehicleHandlingConfig` once per vehicle class to record its
inherited `PlayerSteeringCoefficients`. It can also record three minutes of
runtime evidence:

```sqf
[vehicle player, 180, 0.1] call FIXICS_fnc_logVehicleHandlingConfig;
```

Both functions are read-only.

#### Vehicle Stability Assistance Evidence Matrix

The canonical evidence format now lives in `docs/vehicle-behavior/sqa-evidence-matrix.md`. Keep the table below as the issue-specific acceptance matrix, but record reusable telemetry evidence and recommended next actions in the Evidence Registry.

SQA manual validation is required for `EMP_Polaris_DAGOR` before ISSUE-001 can be marked resolved. Test each speed and surface combination with Off, Yaw damping, Yaw + lateral damping, and Countersteering assistance modes under both Realistic Stable and Rally presets.

| Speed | Paved | Dirt | Grass |
|---|---|---|---|
| 30 km/h | Pending SQA | Pending SQA | Pending SQA |
| 60 km/h | Pending SQA | Pending SQA | Pending SQA |
| 90 km/h | Pending SQA | Pending SQA | Pending SQA |
| 120 km/h | Pending SQA | Pending SQA | Pending SQA |

For each run, record body roll, rollover tendency, lateral slip, recovery behavior, braking behavior, handbrake behavior, and Drive/Reverse transition behavior. Automated checks only validate script and configuration contracts; they do not prove in-game rollover or controlled sliding behavior.

#### Stability Assistance Boundary

The first release applies only bounded lateral damping through the guarded local stability controller. Direct yaw/countersteering mutation remains a diagnostic recommendation until SQA provides in-game evidence that it is needed and safe. Passive config changes, including `PlayerSteeringCoefficients`, anti-roll, tire, or inherited vehicle patching, remain pending SQA evidence and a separate approved config plan.

Resolved Phase 1 milestones are recorded in `docs/fixes/fix-log.md`. Active approximations are recorded in `docs/fixes/workaround-registry.md`.
