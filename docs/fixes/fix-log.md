# Fix Log

## Purpose

This file records SQA-approved FIXICS fixes and completed milestones. It is permanent project memory for root cause, implementation, verification, and remaining gaps.

Entries are newest first. Missing evidence is recorded as `not recorded`; do not invent measurements.

## Entry Format

```markdown
### FIX-[number] - [Short title]

- **Date**          : YYYY-MM-DD
- **Phase**         : Phase N - [Phase title]
- **Failure class** : [physics-agent.md classification]
- **Function(s)**   : `FIXICS_fnc_name`
- **Files changed** :
  - `path`
- **Bug reported by**: SQA, YYYY-MM-DD
- **Resolution type**: Direct fix | Workaround | Config correction

#### Root Cause
[What was wrong and why.]

#### Fix Summary
[What changed.]

#### Outcome
[Observed behavior after the fix.]

#### Workaround Registry Entry
WA-[number] or N/A.

#### Verification
- `hemtt check`  : pass / fail / not recorded
- Static checks  : pass / fail / not recorded
- VR test date   : YYYY-MM-DD / not recorded
- VR result      : pass / partial / fail / not recorded
- VR notes       : [what was tested and observed]

#### SQA Sign-Off
- Approved by : SQA / pending
- Date        : YYYY-MM-DD / not recorded
- Notes       : [conditions or follow-up items]
```

## Log

### FIX-004 - Reverse-to-Drive input and model-space braking correction

- **Date**          : 2026-06-07
- **Phase**         : Phase 1 - Ground Vehicle Physics
- **Failure class** : gearbox or direction transition
- **Function(s)**   : `FIXICS_fnc_getDriverInputIntent`, `FIXICS_fnc_updateDriverController`, `FIXICS_fnc_applyABSBraking`, `FIXICS_fnc_applySlopeRollback`
- **Files changed** :
  - `addons/main/functions/fn_getDriverInputIntent.sqf`
  - `addons/main/functions/fn_updateDriverController.sqf`
  - `addons/main/functions/fn_applyABSBraking.sqf`
  - `addons/main/functions/fn_applySlopeRollback.sqf`
- **Bug reported by**: SQA, 2026-06-07
- **Resolution type**: Workaround

#### Root Cause
The forward input detector did not consistently treat Arma 3's fast and slow forward actions as Drive intent, and the braking helper could re-read raw input separately from the driver controller. During Reverse-to-Drive transitions, the controller could keep waiting for the vehicle to coast to zero before Drive took effect.

#### Fix Summary
Forward intent now includes the relevant forward action variants. The driver controller owns the direction-change state and passes intent into the ABS braking path. Reverse-to-Drive and Drive-to-Reverse transitions use model-space longitudinal braking, a short neutral pulse, and a bounded launch once the vehicle is slow enough.

#### Outcome
SQA reported that Reverse-to-Drive now responds immediately enough to feel like a real vehicle delay instead of waiting for a full natural coast-down.

#### Workaround Registry Entry
WA-002

#### Verification
- `hemtt check`  : pass
- Static checks  : pass
- VR test date   : 2026-06-07
- VR result      : pass
- VR notes       : SQA verified reverse movement can be interrupted by Drive input with an acceptable delay.

#### SQA Sign-Off
- Approved by : SQA
- Date        : 2026-06-07
- Notes       : "Nice it works now... the delay is reasonable similar to a real Car."

### FIX-003 - ABS braking and driver-state controller

- **Date**          : 2026-06-07
- **Phase**         : Phase 1 - Ground Vehicle Physics
- **Failure class** : braking or ABS anomaly
- **Function(s)**   : `FIXICS_fnc_applyABSBraking`, `FIXICS_fnc_updateDriverController`, `FIXICS_fnc_registerSettings`
- **Files changed** :
  - `addons/main/functions/fn_applyABSBraking.sqf`
  - `addons/main/functions/fn_updateDriverController.sqf`
  - `addons/main/functions/fn_registerSettings.sqf`
  - `addons/main/stringtable.xml`
- **Bug reported by**: SQA, 2026-06-07
- **Resolution type**: Workaround

#### Root Cause
Arma 3's normal brake/reverse handling couples braking, direction change, and low-speed state in ways that do not expose a documented direct gearbox-state setter. FIXICS needed a controllable service-brake path without turning the persistent ACE handbrake into an automatic state.

#### Fix Summary
Added adjustable ABS settings and a local driver-state controller. Braking uses a service-brake behavior distinct from the persistent ACE handbrake. The ACE handbrake remains the only persistent FIXICS handbrake state.

#### Outcome
SQA reported the ABS braking feel as smooth and controllable during vehicle testing.

#### Workaround Registry Entry
WA-002

#### Verification
- `hemtt check`  : pass
- Static checks  : pass
- VR test date   : 2026-06-07
- VR result      : pass
- VR notes       : SQA accepted ABS feel during live vehicle testing.

#### SQA Sign-Off
- Approved by : SQA
- Date        : 2026-06-07
- Notes       : ABS feel accepted; later direction-transition tuning continued under FIX-004.

### FIX-002 - Direction-change neutral pulse

- **Date**          : 2026-06-07
- **Phase**         : Phase 1 - Ground Vehicle Physics
- **Failure class** : gearbox or direction transition
- **Function(s)**   : `FIXICS_fnc_updateDriverController`, `FIXICS_fnc_registerSettings`
- **Files changed** :
  - `addons/main/functions/fn_updateDriverController.sqf`
  - `addons/main/functions/fn_registerSettings.sqf`
  - `addons/main/stringtable.xml`
- **Bug reported by**: SQA, 2026-06-07
- **Resolution type**: Workaround

#### Root Cause
Immediate direction-launch behavior could fight the engine's own low-speed drivetrain transition. The vehicle needed a short neutral handoff before launch correction.

#### Fix Summary
Added configurable direction-change threshold, launch velocity, and neutral-pulse timing. The controller holds service braking through the transition and releases into the requested direction after the pulse.

#### Outcome
This reduced the worst direction-change conflict, but later SQA testing found forward input while reversing still needed stronger input detection and braking coordination. FIX-004 supersedes that remaining gap.

#### Workaround Registry Entry
WA-002

#### Verification
- `hemtt check`  : pass
- Static checks  : pass
- VR test date   : not recorded
- VR result      : partial
- VR notes       : Automated checks passed; SQA later reported remaining Reverse-to-Drive delay.

#### SQA Sign-Off
- Approved by : SQA
- Date        : 2026-06-07
- Notes       : Approved as an iteration; final direction-transition behavior recorded in FIX-004.

### FIX-001 - ACE handbrake and local slope rolling

- **Date**          : 2026-06-07
- **Phase**         : Phase 1 - Ground Vehicle Physics
- **Failure class** : slope/autobrake behavior
- **Function(s)**   : `FIXICS_fnc_setVehicleHandbrake`, `FIXICS_fnc_shouldVehicleRoll`, `FIXICS_fnc_monitorVehicleAutobrake`, `FIXICS_fnc_applySlopeRollback`, `FIXICS_fnc_applyHandbrakeLock`
- **Files changed** :
  - `addons/main/config.cpp`
  - `addons/main/functions/fn_setVehicleHandbrake.sqf`
  - `addons/main/functions/fn_shouldVehicleRoll.sqf`
  - `addons/main/functions/fn_monitorVehicleAutobrake.sqf`
  - `addons/main/functions/fn_applySlopeRollback.sqf`
  - `addons/main/functions/fn_applyHandbrakeLock.sqf`
  - `addons/main/functions/fn_registerSettings.sqf`
  - `addons/main/stringtable.xml`
- **Bug reported by**: SQA, 2026-06-07
- **Resolution type**: Workaround

#### Root Cause
Empty or coasting ground vehicles could remain effectively held by engine brake/autobrake behavior on slopes unless the driver engaged game inputs. The project found no documented direct SQF command to replace the engine's internal stationary slope behavior with normal gravity rolling.

#### Fix Summary
Added an ACE interaction as the only persistent FIXICS handbrake and applied local slope-roll correction when the handbrake is not set. The monitor keeps service braking separate from persistent handbrake state and reapplies brake disabling around near-stationary slope cases.

#### Outcome
Vehicles can roll on slopes under local correction unless the ACE handbrake is set. Further driver-control, ABS, and direction-transition tuning continued in later fixes.

#### Workaround Registry Entry
WA-001

#### Verification
- `hemtt check`  : pass
- Static checks  : pass
- VR test date   : 2026-06-07
- VR result      : partial
- VR notes       : SQA accepted the local-only iteration enough to proceed, then reported follow-up direction and ABS issues.

#### SQA Sign-Off
- Approved by : SQA
- Date        : 2026-06-07
- Notes       : Phase 1 remains in progress; multiplayer authority is deferred.
