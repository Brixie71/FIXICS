# FIXICSPhysics Native Extension

This folder contains source for the optional `FIXICSPhysics` native extension.

The approved local Windows x64 binary is `FIXICSPhysics_x64.dll` in the repository root. Build outputs such as `.dll`, `_x64.dll`, `.so`, and `_x64.so` must stay out of `native/`.

## Boundary

This is native-assisted gameplay control, not a direct replacement for Arma's PhysX vehicle simulation.

Arma calls the extension through `callExtension`. The extension returns a slope rollback recommendation, and SQF remains responsible for mutating the vehicle with engine commands such as `setVelocity`. The extension does not own Arma objects, wheels, gearbox state, or hidden PhysX internals.

## Current Interface

Extension name:

```text
FIXICSPhysics
```

Exported Arma interfaces:

- `RVExtensionVersion`
- `RVExtension`
- `RVExtensionArgs`

Supported calls:

```sqf
"FIXICSPhysics" callExtension "version";
"FIXICSPhysics" callExtension "ping";
"FIXICSPhysics" callExtension ["schema", []];
"FIXICSPhysics" callExtension ["slopeControl", [_downhillX, _downhillY, _velocityX, _velocityY, _slope, _maxRollbackSpeed, _rollbackAcceleration]];
```

`slopeControl` returns:

```sqf
[applied, deltaX, deltaY, deltaZ]
```

The SQF bridge is `FIXICS_fnc_getNativeSlopeControl`. It is gated by the CBA setting `FIXICS_nativeSlopeControlEnabled`, which defaults to `false`.

## Build Notes

This source is intentionally not wired into HEMTT. Build the local Windows x64 DLL with:

```powershell
.\tools\build-native.ps1
```

The script uses Visual Studio Build Tools 2022, CMake, and outputs:

```text
FIXICSPhysics_x64.dll
```

A later release build plan must decide:

- Windows DLL and Linux SO naming;
- signed release packaging;
- BattlEye behavior;
- whether clients, servers, or both need the binary.

Do not call this extension in a per-frame loop. `callExtension` blocks Arma until the extension returns.
