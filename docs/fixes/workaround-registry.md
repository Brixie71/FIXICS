# Workaround Registry

## Purpose

This file records active scripted FIXICS workarounds where Arma 3 does not expose a documented direct control surface for the desired behavior. Each entry states why the workaround exists, what it cannot fully solve, and what would make it removable.

## Registry Rules

1. Every active workaround needs an entry here before Phase 1 can close.
2. Every entry needs a concrete removal condition.
3. When a workaround is removed, move it to `Retired Workarounds` with the retirement date and reason.
4. Reference the `EL-` record from `docs/reference/known-engine-limits.md`.
5. Use `FIXICS_fnc_*` names only.

## Active Workarounds

### WA-002 - Local driver-state braking and direction controller

- **Functions**         : `FIXICS_fnc_getDriverInputIntent`, `FIXICS_fnc_updateDriverController`, `FIXICS_fnc_applyABSBraking`
- **Fix log entries**   : FIX-002, FIX-003, FIX-004
- **Engine limit**      : EL-001 - No documented direct gearbox state setter
- **Failure class**     : gearbox or direction transition; braking or ABS anomaly
- **Phase**             : Phase 1
- **Approved**          : 2026-06-07, SQA
- **VR verified**       : 2026-06-07, pass for FIX-004 Reverse-to-Drive behavior

#### What it does
The local driver controller interprets accelerator, brake, reverse, and ACE handbrake state, then applies bounded service braking and launch correction during direction changes. ABS settings control brake strength, release bias, low-speed cutoff, and slope compensation. The persistent handbrake remains the ACE interaction state only.

#### What it achieves
Reverse-to-Drive no longer waits for natural coast-down before responding to Drive input, and service braking can be adjusted without using the persistent FIXICS handbrake.

| Metric | Before | After | Ideal | Gap |
|---|---|---|---|---|
| Reverse-to-Drive response | Waited for near-zero speed before Drive | Responds with a short controlled delay | Native gearbox state switch | Still an SQF approximation |
| Persistent handbrake source | Could be confused with brake/reverse behavior | ACE handbrake only | Native separated handbrake/brake model | Engine drivetrain still exists underneath |

#### Remaining gap
The workaround cannot directly set the engine gearbox state. It corrects model-space velocity and brake state locally, so it may still need multiplayer authority work before server deployment.

#### Removal condition
Remove or redesign this workaround if Bohemia documents a reliable runtime command or config-backed API to set ground vehicle gearbox state directly, or if a vetted native extension provides equivalent control without fighting normal vehicle simulation.

#### Review triggers
Review when adding multiplayer support, native extension control, non-car ground vehicle classes, or class-specific gearbox config patches.

### WA-001 - Local slope rolling and ACE handbrake separation

- **Functions**         : `FIXICS_fnc_setVehicleHandbrake`, `FIXICS_fnc_shouldVehicleRoll`, `FIXICS_fnc_monitorVehicleAutobrake`, `FIXICS_fnc_applySlopeRollback`, `FIXICS_fnc_applyHandbrakeLock`
- **Fix log entries**   : FIX-001
- **Engine limit**      : EL-002 - No documented runtime per-wheel friction setter
- **Failure class**     : slope/autobrake behavior
- **Phase**             : Phase 1
- **Approved**          : 2026-06-07, SQA
- **VR verified**       : 2026-06-07, partial

#### What it does
FIXICS monitors local ground vehicles, keeps the ACE handbrake as the only persistent handbrake, and applies bounded slope-roll velocity correction when the vehicle should coast. It also keeps service braking separate from handbrake state so near-zero speed does not automatically become a persistent handbrake.

#### What it achieves
Empty or coasting vehicles can roll on slopes when the ACE handbrake is released, instead of requiring W or S input before rolling begins.

| Metric | Before | After | Ideal | Gap |
|---|---|---|---|---|
| Stationary slope behavior | Engine brake/autobrake could hold vehicle | Local correction starts slope roll | Pure PhysX gravity roll | SQF correction can only approximate native wheel behavior |
| Handbrake ownership | Engine brake state could look persistent | ACE interaction owns persistent state | Native separated brake and handbrake | Engine low-speed brake behavior still exists |

#### Remaining gap
The workaround does not change native tire friction, drivetrain, or PhysX contact resolution. It is local-first and must be reworked for multiplayer locality and authority.

#### Removal condition
Remove or redesign this workaround if Arma 3 exposes documented runtime controls for stationary autobrake, per-wheel friction, or slope gravity behavior that allow vehicles to coast naturally without per-frame velocity correction.

#### Review triggers
Review before multiplayer rollout, native extension work, class-specific traction tuning, or any change to vehicle locality ownership.

## Retired Workarounds

No retired workarounds are recorded.
