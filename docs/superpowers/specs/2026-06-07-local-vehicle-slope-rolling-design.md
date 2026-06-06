# Local Vehicle Slope Rolling - Design Spec

## Purpose

Implement the first FIXICS ground-vehicle physics behavior: local vehicles should roll down slopes unless a deliberate handbrake or active driver brake is holding them.

This is a local-only v1. Multiplayer synchronization, server-admin settings, and class-by-class vehicle tuning are out of scope until the behavior is proven in local Eden/VR testing.

## Requirements

- ACE3 is a hard dependency for FIXICS.
- Public addon functions use the `FIXICS_fnc_*` prefix.
- Runtime namespace keys use the `FIXICS_*` prefix.
- Existing `BASEARMA_fnc_*` function registrations are migrated to `FIXICS_fnc_*`.
- All ground vehicles based on `LandVehicle` should be allowed to roll on slopes when not held.
- Empty vehicles, driver-occupied vehicles, and passenger-only vehicles all follow the same slope-rolling rule.
- A vehicle stays held only when `FIXICS_handbrakeEnabled` is true or the driver is actively using Arma's built-in brake input.
- ACE interaction exposes handbrake controls for vehicles.

## Approach

Use Bohemia's PhysX `disableBrakes` command to disable idle autobrake on local `LandVehicle` objects. This avoids scripted downhill force in v1 and lets the engine handle actual rolling.

The vehicle monitor runs as a scheduled local loop. It scans nearby/all local land vehicles at a conservative interval, checks the FIXICS handbrake state, and applies `disableBrakes true` only when the vehicle should be free to roll.

ACE interactions are registered on the client with `ace_interact_menu_fnc_createAction` and `ace_interact_menu_fnc_addActionToClass`. They toggle the vehicle variable `FIXICS_handbrakeEnabled`.

## Interfaces

- `FIXICS_fnc_init`: post-init entry point.
- `FIXICS_fnc_hello`: starter load confirmation.
- `FIXICS_fnc_vrHello`: VR mission smoke-test message.
- `FIXICS_fnc_registerAceInteractions`: registers ACE vehicle handbrake actions.
- `FIXICS_fnc_setVehicleHandbrake`: sets or clears `FIXICS_handbrakeEnabled`.
- `FIXICS_fnc_monitorVehicleAutobrake`: local scheduled monitor.
- `FIXICS_fnc_shouldVehicleRoll`: pure decision helper for testable state rules.

## Validation

Automated:

- Static regression test verifies the prefix migration, ACE dependency, function registration, string keys, and expected vehicle-physics functions.
- `.\tools\check.ps1` validates HEMTT config, SQF compilation, and stringtable.

Manual:

- Eden or VR slope test with ACE loaded.
- Test empty, driver-occupied, and passenger-only land vehicles on a slope.
- Confirm vehicles roll when FIXICS handbrake is released/unset.
- Confirm vehicles stay when FIXICS handbrake is set.
- Confirm built-in driver braking still stops or holds the vehicle.

## Assumptions

- ACE interaction component dependency is `ace_interact_menu`.
- Arma's built-in brake key behavior remains authoritative; FIXICS does not replace it.
- V1 does not add custom downhill force, custom keybinds, multiplayer state authority, or server settings.
- The workspace is not a git repository, so design and plan artifacts cannot be committed from this session.
