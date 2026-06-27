# Per-Vehicle Settings Design

## Summary

Per-Vehicle Settings adds a class-based profile resolver for Phase 1 FIXICS ground vehicle systems. The resolver returns a single effective profile per vehicle by combining global CBA defaults, optional preset values, parent-class overrides, and exact-class overrides. The profile is read when the local driver enters or when diagnostics request a reset.

## Profile Input

Two CBA edit boxes define profile entries:

```sqf
[
    ["B_LSV_01_unarmed_F", "LIGHT_OFFROAD", [["FIXICS_absBrakeStrength", 0.55]]]
]
```

The first field is a vehicle or parent classname. The second field is a preset. The third field is an optional key/value override array.

## Lookup Order

1. Global CBA settings.
2. Parent class profile, if configured.
3. Exact classname profile, if configured.

Exact class profiles win over parent class profiles. `DEFAULT` preserves global settings exactly. `CUSTOM` applies only explicit overrides.

## Presets

- `DEFAULT`: no profile override.
- `LIGHT_OFFROAD`: mild slip and terrain sensitivity.
- `MRAP`: heavier, more stable, less agile.
- `TRUCK`: longer braking and heavier damping.
- `TRACKED`: reserved stub; no track physics is added in Phase 1.
- `CUSTOM`: explicit overrides only.

## Runtime Integration

Approved systems read effective values from the vehicle profile where practical:

- ABS.
- Slope rolling.
- Stability, roll, and sway bar.
- Controlled Slip.
- Terrain Tire.
- Runtime Assist.

Native advisory enablement remains global.

## Diagnostics And ACE

`FIXICS_fnc_dumpVehicleProfile` logs the active profile to RPT and optionally shows a hint when profile debug logging is enabled. ACE receives a read-only "View FIXICS Vehicle Profile" action.

## Telemetry

Handling telemetry records:

- `vehicleProfileId`
- `vehicleProfileSource`
- `vehicleProfileOverridesApplied`

## Safety

No vehicle config patching is used. No generated output is edited. No multiplayer authority behavior is changed.
