# Driver State Controller - Design Spec

## Purpose

Replace the slow, implicit player-driving behavior with a local controller that treats Drive, Service Brake, Reverse, Coast, and Handbrake as explicit states.

The controller fixes three related failures:

- Opposite W/S input no longer waits for Arma to reach exact zero before changing direction.
- Active W/S intent takes priority over downhill slope assistance.
- ABS settings affect player braking because the fast controller calls the ABS helper directly.

## Requirements

- Keep ACE3 and CBA as hard dependencies.
- Keep `FIXICS_handbrakeEnabled` as the only persistent FIXICS handbrake state.
- Keep ACE Set Handbrake and Release Handbrake interactions intact.
- Support the `CarHandBrake` action as either Hold or Toggle through a CBA setting.
- Preserve normal service braking.
- Use a configurable threshold to change from braking to the requested direction.
- Apply a small configurable launch velocity after the direction transition.
- Apply slope assistance while driving only when it accelerates the requested direction downhill.
- Keep empty, passenger-only, AI-driven, and controller-disabled vehicles on the slow monitor.
- Keep this phase local-only.

## States

- `COAST`: no W/S input; normal brakes are disabled only when slope rolling is allowed.
- `DRIVE`: forward input owns longitudinal intent.
- `REVERSE`: reverse input owns longitudinal intent.
- `SERVICE_BRAKE`: input opposes current longitudinal motion, or both W/S inputs are active.
- `NEUTRAL`: a short zero-velocity gearbox handoff after opposite-input braking.
- `HANDBRAKE`: persistent ACE/FIXICS handbrake or temporary Hold input.

## Direction Transition

The controller reads `velocityModelSpace`, where positive Y is forward. Opposite input enters `SERVICE_BRAKE` and calls `FIXICS_fnc_applyABSBraking` with a low-speed override. If ABS is disabled or cannot apply, the controller uses a direct longitudinal service-brake fallback.

When speed reaches `FIXICS_directionChangeThresholdKmh`, the controller latches the requested direction, clamps model-space Y velocity to exactly zero, and enters `NEUTRAL` for `FIXICS_directionNeutralPulseSeconds`. While the same W/S input remains held, each controller update preserves zero longitudinal velocity so Arma's automatic gearbox can observe a neutral stop. When the pulse expires, the controller applies `FIXICS_directionLaunchVelocity` in the requested direction.

Releasing or changing the requested W/S input cancels the latched transition immediately. The transition is symmetric for Reverse-to-Drive and Drive-to-Reverse.

ABS and slope corrections are normalized to a 0.25-second reference interval, so changing the controller interval does not multiply the configured effect.

## Handbrake Modes

- Hold: `CarHandBrake` is a temporary hard lock while the action is held. It does not change `FIXICS_handbrakeEnabled`.
- Toggle: the rising edge of `CarHandBrake` calls `FIXICS_fnc_setVehicleHandbrake`, so keyboard and ACE interactions use the same persistent state.

Releasing a Toggle handbrake still treats the pressed key as temporary until the action is released, avoiding a one-frame conflict with Arma's built-in handbrake input.

## Ownership

`FIXICS_fnc_registerVehicleControls` installs a CBA per-frame handler. `FIXICS_fnc_updateDriverController` throttles itself with `FIXICS_driverControllerInterval`.

The 0.25-second monitor skips a local player-driven vehicle while the controller is enabled. It remains responsible for other local land vehicles and restores normal brakes when they should not roll.

## Settings

- `FIXICS_driverControllerEnabled`: default `true`.
- `FIXICS_handbrakeInputMode`: `0` Hold, `1` Toggle; default Hold.
- `FIXICS_directionChangeThresholdKmh`: default `2`.
- `FIXICS_directionLaunchVelocity`: default `0.35` m/s.
- `FIXICS_directionNeutralPulseSeconds`: default `0.08` seconds.
- `FIXICS_driverControllerInterval`: default `0.03` seconds.

## Supported Boundary

No new native binary is required. The existing extension can recommend slope deltas but cannot intercept Arma input processing or replace the gearbox. Input ownership and direction transitions remain in supported SQF/CBA APIs.

SQF cannot consume the native W/S or handbrake actions. FIXICS therefore corrects longitudinal velocity on each controller update while Arma still processes its drivetrain input. Manual testing across vehicle classes remains required because PhysX configuration can affect how strongly the native drivetrain competes with the correction.

Multiplayer locality transfer is deferred. The current local-only controller does not retry restoration after a controlled vehicle becomes non-local; multiplayer authority work must add an ownership-transfer protocol.

References:

- Bohemia `setVelocityModelSpace`: https://community.bohemia.net/wiki/setVelocityModelSpace
- Bohemia input actions: https://community.bohemia.net/wiki/inputAction/actions/bindings
- CBA per-frame handler: https://cbateam.github.io/CBA_A3/docs/files/common/fnc_addPerFrameHandler-sqf.html
- CBA settings: https://cbateam.github.io/CBA_A3/docs/files/settings/fnc_addSetting-sqf.html

## Validation

Automated validation covers registration, settings, state names, monitor ownership, model-space velocity use, handbrake edge detection, ABS integration, grounded operation, and downhill-only powered slope assist.

Manual SQA validation must cover flat and sloped W/S reversals, Hold and Toggle handbrake modes, ACE handbrake actions, controller disable handoff, and ABS tuning.
