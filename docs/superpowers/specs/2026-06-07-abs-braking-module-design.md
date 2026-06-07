# ABS Braking Module - Design Spec

> Superseded for player-driven vehicles by `2026-06-07-driver-state-controller-design.md`. The ABS helper remains in use, but the fast driver controller now owns its execution instead of the 0.25-second vehicle monitor.

## Purpose

Add a local-only FIXICS ABS-like braking module for `LandVehicle` objects and expose the current physics tuning values through CBA addon settings.

This is not a native PhysX replacement and not a literal per-wheel hydraulic ABS implementation. Arma SQF does not expose wheel speed, brake pressure, or tire slip per wheel. FIXICS will approximate ABS at the vehicle-velocity layer while preserving the existing ACE handbrake and slope-rolling behavior.

## Research Summary

Real ABS is a braking feedback controller. It monitors wheel rotation, estimates wheel slip against vehicle motion, and modulates brake pressure through reduce, hold, and reapply phases so wheels do not lock under braking. The goal is controllability and usable braking inside the tire-road grip limit.

Useful references:

- NHTSA interpretation of ABS as automatic rotational wheel-slip control during braking: https://www.nhtsa.gov/interpretations/1210corrforweb
- Bosch wheel-speed sensor documentation: https://www.bosch-mobility.com/en/solutions/sensors/wheel-speed-sensor/
- Continental ABS pressure-control behavior on changing road conditions: https://www.continental.com/en-us/press/press-releases/latest-abs-generation-from-continental/
- Bohemia `disableBrakes`: https://community.bohemia.net/wiki/disableBrakes
- Bohemia `setVelocity`: https://community.bohemia.net/wiki/setVelocity
- CBA `CBA_fnc_addSetting`: https://cbateam.github.io/CBA_A3/docs/files/settings/fnc_addSetting-sqf.html

## Requirements

- Keep ACE3 and CBA as hard dependencies already declared by FIXICS.
- Keep the ACE handbrake as the only persistent handbrake.
- Do not alter Arma Drive/Reverse input semantics beyond the existing slope assist.
- Add CBA addon settings for the existing slope tuning values.
- Add CBA addon settings for ABS behavior.
- ABS applies only when the local player driver is actively braking.
- ABS must not apply while the FIXICS ACE handbrake is set.
- ABS must not apply while the built-in handbrake input is pressed.
- ABS must not apply while the vehicle is coasting without brake input.
- ABS must preserve the existing slope coasting and slope acceleration module.
- ABS should reduce harsh lock-like stopping by limiting how much longitudinal velocity can be removed per monitor tick.
- ABS should taper out below a low-speed cutoff so braking does not become another persistent idle handbrake.
- ABS must be local-only in this phase. Multiplayer authority and server policy are out of scope until local behavior is validated.

## Settings

Existing slope values become visible CBA settings:

- `FIXICS_slopeRollbackMinimumSlope`: slider, default `0.035`, range `0` to `0.2`.
- `FIXICS_slopeRollbackMaxSpeed`: slider, default `2.2`, range `0.2` to `10`, units m/s.
- `FIXICS_slopeRollbackAcceleration`: slider, default `0.55`, range `0` to `2`.
- `FIXICS_slopeCoastBreakawayVelocity`: slider, default `0.18`, range `0` to `1`, units m/s.
- `FIXICS_slopeDriveAcceleration`: slider, default `0.22`, range `0` to `1`.
- `FIXICS_slopeDriveMaxSpeedKmh`: slider, default `120`, range `10` to `240`, units km/h.
- `FIXICS_stationaryBrakeBypassSpeedKmh`: slider, default `1`, range `0` to `5`, units km/h.

New ABS values:

- `FIXICS_absEnabled`: checkbox, default `true`.
- `FIXICS_absBrakeStrength`: slider, default `0.45`, range `0.05` to `2`.
- `FIXICS_absReleaseBias`: slider, default `0.35`, range `0` to `1`.
- `FIXICS_absLowSpeedCutoffKmh`: slider, default `3`, range `0` to `20`, units km/h.
- `FIXICS_absSlopeCompensation`: slider, default `0.25`, range `0` to `1`.
- `FIXICS_absDebugLogging`: checkbox, default `false`.

All settings are global CBA settings with no mission restart required. The first implementation keeps tuning conservative because it is easier for SQA to increase effect than to diagnose overcorrection.

## Architecture

`FIXICS_fnc_monitorVehicleAutobrake` remains the local scheduled coordinator. For each local unlocked `LandVehicle`, it keeps the current idle-autobrake and slope helper flow, then calls a new `FIXICS_fnc_applyABSBraking` helper.

`FIXICS_fnc_applyABSBraking` is intentionally narrow. It detects whether the local player driver is braking against current longitudinal motion: `S` while moving forward, or `W` while moving backward. It exits for non-local vehicles, empty vehicles, non-player drivers, handbrake states, low speed, and disabled settings.

When active, ABS computes the vehicle forward axis with `vectorDir`, extracts longitudinal speed from `velocity _vehicle`, calculates a maximum allowed speed reduction for the current monitor tick, and applies a reduced longitudinal velocity with `setVelocity`. It does not directly command wheel brakes or modify class-level vehicle config.

## Data Flow

1. Monitor sees a local `LandVehicle`.
2. If `FIXICS_handbrakeEnabled` is true, monitor applies the hard handbrake lock and exits that vehicle branch.
3. If the vehicle should roll, monitor applies `disableBrakes true`.
4. Monitor applies slope rollback/drive assist.
5. Monitor applies ABS braking only if the local driver is braking against actual motion.
6. ABS reads settings from `missionNamespace`.
7. ABS writes only one velocity correction with `setVelocity`.

## Validation

Automated:

- Static regression verifies new function registration, settings registration, stringtable keys, and monitor integration.
- Static regression verifies ABS uses `vectorDir`, `velocity _vehicle`, brake-direction classification, low-speed cutoff, release bias, slope compensation, and `setVelocity`.
- `tools/check.ps1` validates HEMTT config, SQF compilation, and stringtable.

Manual:

- Flat forward braking from moderate speed.
- Flat reverse braking from moderate speed.
- Downhill braking.
- Uphill braking.
- Coasting on a slope with no brake input.
- ACE handbrake set and released.
- Built-in handbrake key held.
- ABS disabled through addon settings.
- ABS strength adjusted low, default, and high.

## Out Of Scope

- Per-wheel lock detection.
- True hydraulic brake pressure modulation.
- Wheel-specific ABS, traction control, or ESC.
- Native extension changes.
- Config-class brake torque patches.
- Multiplayer authority, remote execution, or server-forced policy beyond CBA global settings.
- Visual dashboards or UI overlays.
