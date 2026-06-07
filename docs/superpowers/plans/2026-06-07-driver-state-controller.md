# Driver State Controller Implementation Plan

**Goal:** Implement the approved local player driver controller and remove player ABS/slope ownership from the slow vehicle monitor.

**Architecture:** A CBA per-frame handler updates one local player-driven `LandVehicle`. The existing monitor handles all other local vehicles.

## Tasks

- [x] Add failing static regressions for controller registration, settings, states, X modes, direction transition controls, and monitor ownership.
- [x] Register `cba_common`, `FIXICS_fnc_registerVehicleControls`, and `FIXICS_fnc_updateDriverController`.
- [x] Add CBA settings and localized labels for controller enable, Hold/Toggle mode, transition threshold, launch velocity, and update interval.
- [x] Implement `COAST`, `DRIVE`, `REVERSE`, `SERVICE_BRAKE`, and `HANDBRAKE`.
- [x] Route opposite W/S through ABS or service-brake fallback and switch direction at the configured threshold.
- [x] Keep ACE handbrake interactions persistent and add Hold/Toggle behavior to `CarHandBrake`.
- [x] Make player W/S intent authoritative over slope assist.
- [x] Limit powered slope assistance to downhill acceleration in the requested direction.
- [x] Make the slow monitor skip controller-owned vehicles and restore normal brakes when rolling is not allowed.
- [x] Prevent controller velocity changes while the vehicle is airborne.
- [x] Run static regression and HEMTT check.
- [x] Complete focused code re-review and record audit evidence.
- [ ] Hand the manual Arma test matrix to SQA.
