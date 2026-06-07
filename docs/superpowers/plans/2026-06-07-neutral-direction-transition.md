# Neutral Direction Transition Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make opposite W/S input complete a reliable Reverse-to-Drive or Drive-to-Reverse gearbox handoff without changing normal ABS braking.

**Architecture:** The existing driver controller latches the requested direction when input opposes motion. ABS remains responsible for deceleration. At the direction threshold, the controller clamps longitudinal model-space velocity to zero, holds a configurable neutral pulse, then launches only if the same input remains held.

**Tech Stack:** Arma 3 SQF, CBA settings/PFH, HEMTT, PowerShell static regression.

---

### Task 1: Add The Failing Neutral-Transition Contract

**Files:**
- Modify: `tests/integration/fixics-vehicle-physics-static.ps1`

- [x] Add assertions for `FIXICS_directionNeutralPulseSeconds`, its stringtable keys, the `NEUTRAL` state, transition target/deadline variables, exact-zero clamping, input cancellation, and delayed launch.
- [x] Reject the old same-update threshold-to-launch pattern.
- [x] Run `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1`.
- [x] Confirm failure is limited to the missing neutral-pulse behavior.

### Task 2: Register The Neutral Pulse Setting

**Files:**
- Modify: `addons/main/functions/fn_registerSettings.sqf`
- Modify: `addons/main/stringtable.xml`

- [x] Initialize `FIXICS_directionNeutralPulseSeconds` to `0.08`.
- [x] Register a CBA slider under `["FIXICS", "Driver Controller"]` with range `0.03` to `0.30`.
- [x] Add localized title and tooltip keys.

### Task 3: Implement The Latched Transition

**Files:**
- Modify: `addons/main/functions/fn_updateDriverController.sqf`

- [x] Store `FIXICS_directionTransitionTarget` and `FIXICS_directionTransitionNeutralUntil` on the controlled vehicle.
- [x] Latch the requested direction when it opposes current motion.
- [x] Continue ABS service braking while the transition target remains held.
- [x] At the threshold, set longitudinal model-space velocity to exactly zero and start the neutral deadline.
- [x] During the neutral pulse, preserve lateral/vertical velocity but force longitudinal velocity to zero.
- [x] After the deadline, launch in the latched direction and clear transition state.
- [x] Cancel and clear transition state when input is released, changed, handbrake is applied, controller ownership is released, or the vehicle becomes airborne.

### Task 4: Verify And Record

**Files:**
- Modify: `governance/audit/validation-log.md`

- [x] Run the static regression and confirm exit code `0`.
- [x] Run `powershell -ExecutionPolicy Bypass -File tools\check.ps1` and confirm all SQF/config/stringtable checks pass.
- [x] Run `git diff --check`.
- [x] Record automated results and the manual SQA matrix.
