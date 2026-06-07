# Local Vehicle Slope Rolling - Design Spec

## Purpose

Implement the first FIXICS ground-vehicle physics behavior: local vehicles should roll down slopes unless a deliberate handbrake or active driver brake is holding them.

This is a local-only v1. Multiplayer synchronization, server-admin settings, and class-by-class vehicle tuning are out of scope until the behavior is proven in local Eden/VR testing.

## Requirements

- ACE3 is a hard dependency for FIXICS.
- Public addon functions use the `FIXICS_fnc_*` prefix.
- Runtime namespace keys use the `FIXICS_*` prefix.
- Existing `FIXICS_fnc_*` function registrations are migrated to `FIXICS_fnc_*`.
- All ground vehicles based on `LandVehicle` should be allowed to roll on slopes when not held.
- Empty vehicles, driver-occupied vehicles, and passenger-only vehicles all follow the same slope-rolling rule.
- A vehicle stays held only when `FIXICS_handbrakeEnabled` is true, the driver is actively using Arma's handbrake input, or W/S drive input is active above the near-stationary threshold.
- The normal brake/reverse input must stop holding the vehicle once speed is near zero, so shifting from forward to reverse does not become a persistent idle handbrake.
- When a local vehicle is on a slope and the FIXICS ACE handbrake is not set, FIXICS applies downhill rollback assist independent of the current Drive/Reverse state.
- The built-in handbrake key remains a temporary hold while pressed, but W/S input must not act as a persistent near-zero handbrake or be overridden by rollback assist.
- FIXICS must not disable Arma's normal braking on flat or near-flat ground; `disableBrakes true` is only appropriate once terrain slope meets `FIXICS_slopeRollbackMinimumSlope`.
- When `FIXICS_handbrakeEnabled` is true, the ACE handbrake is a hard local lock that zeroes vehicle velocity and must not be bypassed by `W` or `S` throttle input.
- When the driver releases `S` after reversing uphill, the vehicle must receive a downhill coasting breakaway instead of remaining stationary under Arma's idle brake.
- Slope acceleration applies while the vehicle is coasting/stationary and while the driver is accelerating with `W` or `S`.
- Driver acceleration is modified relative to vehicle orientation: downhill drive intent gains acceleration, uphill drive intent loses acceleration, and cross-slope drive receives little or no longitudinal assist.
- FIXICS must not apply slope drive assist while `W` or `S` is being used as an active brake against existing movement.
- ACE interaction exposes handbrake controls for vehicles.
- A CBA setting controls whether FIXICS disables Arma's automatic idle autobrake while vehicles are stationary.

## Approach

Use Bohemia's PhysX `disableBrakes` command to disable idle autobrake on local `LandVehicle` objects. Because Arma can re-enable braking during normal driver input and gearbox transitions, FIXICS also applies a capped downhill velocity assist while the vehicle is local, grounded, on a slope, and not held by the FIXICS ACE handbrake or temporary built-in handbrake key.

The vehicle monitor runs as a scheduled local loop. It scans nearby/all local land vehicles at a conservative interval, checks the FIXICS handbrake state, applies `disableBrakes true` only on meaningful slopes when the vehicle should be free to roll, and then calls the slope helper so terrain slope can win even if the engine is sitting in the Drive/Reverse transition.

For coasting or stationary vehicles, the helper applies downhill velocity directly and uses a small breakaway delta near zero speed so reverse-release on a hill does not stay stuck. For active driver acceleration, the helper projects the slope onto the vehicle's forward/reverse drive axis with `vectorDir`: downhill drive intent receives a positive velocity delta, uphill drive intent receives a negative velocity delta, and active braking exits without assist so normal braking remains intact.

ACE interactions are registered on the client with `ace_interact_menu_fnc_createAction` and `ace_interact_menu_fnc_addActionToClass`. They toggle the vehicle variable `FIXICS_handbrakeEnabled`.

## Interfaces

- `FIXICS_fnc_init`: post-init entry point.
- `FIXICS_fnc_hello`: starter load confirmation.
- `FIXICS_fnc_vrHello`: VR mission smoke-test message.
- `FIXICS_fnc_registerAceInteractions`: registers ACE vehicle handbrake actions.
- `FIXICS_fnc_registerSettings`: registers CBA addon settings.
- `FIXICS_fnc_setVehicleHandbrake`: sets or clears `FIXICS_handbrakeEnabled`.
- `FIXICS_fnc_monitorVehicleAutobrake`: local scheduled monitor.
- `FIXICS_fnc_shouldVehicleRoll`: pure decision helper for testable state rules.
- `FIXICS_fnc_applySlopeRollback`: local helper that derives downhill direction from `surfaceNormal`, computes slope angle in degrees, and applies capped coasting or drive-axis slope velocity.
- `FIXICS_fnc_applyHandbrakeLock`: local helper that enforces the persistent ACE handbrake by keeping autobrake enabled and zeroing vehicle velocity.
- `FIXICS_disableIdleAutobrake`: global CBA checkbox setting, default `true`.
- `FIXICS_stationaryBrakeBypassSpeedKmh`: local threshold used by the brake/reverse bypass, default `1`.
- `FIXICS_slopeRollbackMinimumSlope`: minimum terrain-normal horizontal component before assist applies, default `0.035`.
- `FIXICS_slopeRollbackMaxSpeed`: maximum assisted downhill speed, default `2.2` m/s.
- `FIXICS_slopeRollbackAcceleration`: per-tick rollback acceleration coefficient, default `0.55`.
- `FIXICS_slopeCoastBreakawayVelocity`: minimum near-zero coasting downhill velocity delta, default `0.18` m/s.
- `FIXICS_slopeDriveAcceleration`: per-tick drive-axis slope acceleration coefficient, default `0.22`.
- `FIXICS_slopeDriveMaxSpeedKmh`: maximum downhill drive-assist speed, default `120` km/h.

## Validation

Automated:

- Static regression test verifies the prefix migration, ACE dependency, function registration, string keys, and expected vehicle-physics functions.
- `.\tools\check.ps1` validates HEMTT config, SQF compilation, and stringtable.

Manual:

- Eden or VR slope test with ACE loaded.
- Test empty, driver-occupied, and passenger-only land vehicles on a slope.
- Confirm vehicles roll when FIXICS handbrake is released/unset.
- Confirm vehicles stay when FIXICS handbrake is set.
- Confirm built-in driver braking still slows the vehicle, but W/S input does not become a persistent near-zero hold.
- Confirm vehicles roll downhill without requiring the driver to double-tap S or W after stopping on a slope.
- Confirm flat-ground W/S release returns to normal Arma stopping behavior and opposite input can engage Drive/Reverse.
- Confirm reversing uphill with `S`, then releasing `S`, causes downhill coasting instead of stationary hold.
- Confirm driving downhill accelerates more than flat ground, while driving uphill loses acceleration relative to the same vehicle on flat ground.
- Confirm pressing `S` to brake while moving forward and pressing `W` to brake while moving backward still preserves normal braking behavior.

## Assumptions

- ACE interaction component dependency is `ace_interact_menu`.
- Arma's built-in handbrake key behavior remains authoritative while held; FIXICS does not replace normal throttle or brake input.
- A true Drive/Reverse gearbox bypass is not exposed through ordinary SQF and may require config-class experimentation or a native extension if the local rollback assist is insufficient.
- V1 does not add custom keybinds or multiplayer state authority.
- The workspace is not a git repository, so design and plan artifacts cannot be committed from this session.

## Beyond SQF Exception

If SQA confirms the local SQF mitigation still cannot overcome Arma's stationary brake or Drive/Reverse transition behavior, Phase 1 may use the documented evaluation exception `FIXICS-EXC-2026-06-07-VEHICLE-PHYSICS-BEYOND-SQF`.

The evaluation order is:

1. Collect SQF diagnostics and vehicle-class evidence.
2. Test targeted `CfgVehicles` / vehicle handling config-class patches.
3. Research native extensions only if config-class work cannot reach the required behavior.

The evaluation is documented in `docs/superpowers/specs/2026-06-07-vehicle-physics-beyond-sqf-evaluation.md`. Implementation beyond SQF requires a separate user-approved plan.

Current escalation status:

- The broad `Car_F` / `Tank_F` handling config patch was tested by SQA, made behavior worse, and was removed.
- `FIXICS_fnc_logVehicleHandlingConfig` remains available so SQA can record effective vehicle-class handling values during manual slope tests.
- Native work has escalated to a local Windows x64 `FIXICSPhysics_x64.dll`, built from source with `tools/build-native.ps1`, plus an optional SQF bridge. Release packaging is not approved yet.
