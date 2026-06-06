# Local Vehicle Slope Rolling Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build local-only slope rolling for `LandVehicle` objects with ACE3 handbrake interactions and migrate public function prefixes to `FIXICS_fnc_*`.

**Architecture:** A post-init entry point starts a local scheduled vehicle monitor and registers ACE client interactions. The monitor disables idle PhysX autobrake on local land vehicles unless `FIXICS_handbrakeEnabled` is true, enforces the ACE handbrake as a hard lock, and applies a local downhill rollback assist so Drive/Reverse transition state does not hold a vehicle at near-zero speed.

**Tech Stack:** Arma 3 SQF, HEMTT, ACE3 interaction menu, PowerShell static regression test.

**Follow-up setting:** `FIXICS_disableIdleAutobrake` is a CBA checkbox setting that defaults on. It keeps Arma's idle autobrake disabled while stationary unless the FIXICS ACE handbrake is set or the local driver is actively braking.

**Follow-up rollback tuning:** `FIXICS_fnc_applySlopeRollback` uses the same near-stationary threshold as the decision helper. W/S input only blocks rollback while the vehicle is above that threshold; the built-in handbrake key and ACE handbrake still hold immediately.

---

### Task 1: Static Regression Test

**Files:**
- Create: `tests/integration/fixics-vehicle-physics-static.ps1`

- [x] **Step 1: Write the failing test**

Create a PowerShell test that reads addon source and asserts:

- `CfgFunctions` tag is `FIXICS`.
- `requiredAddons[]` includes `ace_interact_menu`.
- No addon source contains `BASEARMA_fnc_`.
- New vehicle physics function files exist.
- Stringtable contains FIXICS handbrake labels.

- [x] **Step 2: Run test to verify it fails**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: non-zero exit because the feature does not exist yet.

### Task 2: Prefix Migration

**Files:**
- Modify: `addons/main/config.cpp`
- Modify: `addons/main/functions/fn_init.sqf`
- Modify: `addons/main/functions/fn_hello.sqf`
- Modify: `addons/main/functions/fn_vrHello.sqf`
- Modify: `addons/main/missions/HelloWorld.VR/mission.sqm`

- [x] **Step 1: Change `CfgFunctions` tag**

Set the tag from `BASEARMA` to `FIXICS`.

- [x] **Step 2: Update existing calls and comments**

Replace existing public references with `FIXICS_fnc_init`, `FIXICS_fnc_hello`, and `FIXICS_fnc_vrHello`.

### Task 3: ACE Handbrake Interface

**Files:**
- Create: `addons/main/functions/fn_registerAceInteractions.sqf`
- Create: `addons/main/functions/fn_setVehicleHandbrake.sqf`
- Modify: `addons/main/config.cpp`
- Modify: `addons/main/stringtable.xml`

- [x] **Step 1: Add ACE dependency**

Add `ace_interact_menu` to `requiredAddons[]`.

- [x] **Step 2: Register functions**

Add `registerAceInteractions` and `setVehicleHandbrake` to `CfgFunctions`.

- [x] **Step 3: Implement handbrake state setter**

`FIXICS_fnc_setVehicleHandbrake` sets `FIXICS_handbrakeEnabled` locally and applies `disableBrakes false` when set, `disableBrakes true` when released.

- [x] **Step 4: Register ACE actions**

`FIXICS_fnc_registerAceInteractions` adds `Set Handbrake` and `Release Handbrake` actions to `LandVehicle` external actions and driver self actions.

### Task 4: Local Vehicle Autobrake Monitor

**Files:**
- Create: `addons/main/functions/fn_shouldVehicleRoll.sqf`
- Create: `addons/main/functions/fn_monitorVehicleAutobrake.sqf`
- Modify: `addons/main/config.cpp`
- Modify: `addons/main/functions/fn_init.sqf`

- [x] **Step 1: Register functions**

Add `shouldVehicleRoll` and `monitorVehicleAutobrake` to `CfgFunctions`.

- [x] **Step 2: Implement decision helper**

`FIXICS_fnc_shouldVehicleRoll` returns true for local `LandVehicle` objects unless `FIXICS_handbrakeEnabled` is true, the local player driver is pressing `CarHandBrake`, or the local player driver is pressing `CarBack` above the near-stationary threshold.

- [x] **Step 3: Implement scheduled monitor**

`FIXICS_fnc_monitorVehicleAutobrake` loops every second, processes local `LandVehicle` objects, and applies `disableBrakes true` only when `FIXICS_fnc_shouldVehicleRoll` returns true.

- [x] **Step 4: Start from post-init**

`FIXICS_fnc_init` calls load confirmation, starts ACE interaction registration on interface clients, and spawns the monitor.

### Task 5: Validation

**Files:**
- Read: `tests/integration/fixics-vehicle-physics-static.ps1`
- Read: `tools/check.ps1`

- [x] **Step 1: Run static regression**

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: exit code 0.

- [x] **Step 2: Run HEMTT check**

```powershell
.\tools\check.ps1
```

Expected: exit code 0 if ACE/HEMTT dependencies are available locally.

- [x] **Step 3: Record manual gap**

If Arma is not launched, report that manual slope behavior still requires SQA validation in Eden/VR with ACE loaded.

### Task 6: Gear-Independent Near-Zero Rollback

**Files:**
- Modify: `tests/integration/fixics-vehicle-physics-static.ps1`
- Modify: `addons/main/functions/fn_applySlopeRollback.sqf`
- Modify: `docs/superpowers/specs/2026-06-07-local-vehicle-slope-rolling-design.md`
- Modify: `governance/audit/validation-log.md`

- [x] **Step 1: Write the failing regression**

Add static assertions that `FIXICS_fnc_applySlopeRollback` calculates near-stationary state, uses `FIXICS_stationaryBrakeBypassSpeedKmh`, lets W/S input block rollback only above that threshold, keeps `CarHandBrake` as an immediate temporary hold, and uses the stronger `FIXICS_slopeRollbackAcceleration` default of `0.55`.

- [x] **Step 2: Run regression to verify red**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: non-zero exit with missing near-stationary rollback and acceleration-default checks.

- [x] **Step 3: Implement gear-independent rollback**

Update `fn_applySlopeRollback.sqf` so `CarHandBrake` exits immediately, W/S input exits only when `abs (speed _vehicle)` is above `FIXICS_stationaryBrakeBypassSpeedKmh`, and the default rollback acceleration is `0.55`.

- [x] **Step 4: Run regression to verify green**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: exit code 0.

- [x] **Step 5: Run HEMTT check and record validation**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools\check.ps1
```

Expected: exit code 0 if HEMTT dependencies are available locally.

### Task 7: Config-Class Vehicle Handling Escalation

**Files:**
- Modify: `tests/integration/fixics-vehicle-physics-static.ps1`
- Modify: `addons/main/config.cpp`
- Create: `addons/main/functions/fn_logVehicleHandlingConfig.sqf`
- Modify: `docs/superpowers/specs/2026-06-07-vehicle-physics-beyond-sqf-evaluation.md`
- Modify: `governance/audit/validation-log.md`

- [x] **Step 1: Write the failing regression**

Add static assertions that:

- `requiredAddons[]` includes `A3_Soft_F` and `A3_Armor_F`.
- `CfgVehicles` patches `Car_F` and `Tank_F`.
- both classes set `brakeIdleSpeed = 0.01`.
- both classes set `dampingRateZeroThrottleClutchEngaged = 0.25`.
- both classes set `dampingRateZeroThrottleClutchDisengaged = 0.25`.
- `FIXICS_fnc_logVehicleHandlingConfig` exists, is registered, uses `configOf _vehicle`, and logs the relevant handling values.

- [x] **Step 2: Run regression to verify red**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: non-zero exit with missing config patch and diagnostic function checks.

- [x] **Step 3: Implement config-class experiment**

Update `addons/main/config.cpp` with:

- `A3_Soft_F` and `A3_Armor_F` in `requiredAddons[]`.
- `class logVehicleHandlingConfig {};` under `CfgFunctions`.
- `class CfgVehicles` patches for `Car_F` and `Tank_F`.

Create `fn_logVehicleHandlingConfig.sqf` to log `typeOf`, `simulation`, `brakeIdleSpeed`, zero-throttle damping, gearbox, and anti-rollbar values.

- [x] **Step 4: Run regression and HEMTT check**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
powershell -ExecutionPolicy Bypass -File tools\check.ps1
```

Expected: both commands exit code 0.

- [x] **Step 5: Record SQA retest instructions**

Document the debug-console command:

```sqf
[vehicle player] call FIXICS_fnc_logVehicleHandlingConfig;
```

Record that native-extension work remains out of scope unless this config-class experiment fails in SQA testing.

### Task 8: Native-Assisted Gameplay-Control Scaffold

**Files:**
- Modify: `tests/integration/fixics-vehicle-physics-static.ps1`
- Modify: `addons/main/config.cpp`
- Modify: `addons/main/functions/fn_applySlopeRollback.sqf`
- Modify: `addons/main/functions/fn_registerSettings.sqf`
- Modify: `addons/main/stringtable.xml`
- Create: `addons/main/functions/fn_getNativeSlopeControl.sqf`
- Create: `native/fixics_physics/src/FIXICSPhysics.cpp`
- Create: `native/fixics_physics/README.md`
- Modify: `governance/policies/scope-control.md`
- Modify: `docs/superpowers/specs/2026-06-07-native-extension-pre-research.md`
- Modify: `docs/superpowers/specs/2026-06-07-vehicle-physics-beyond-sqf-evaluation.md`
- Modify: `governance/audit/validation-log.md`

- [x] **Step 1: Write the failing regression**

Add static assertions that:

- the failed `A3_Soft_F` / `A3_Armor_F` config-class experiment is removed;
- `CfgVehicles` no longer patches `Car_F` or `Tank_F`;
- `FIXICS_fnc_getNativeSlopeControl` exists and is registered;
- `FIXICS_fnc_applySlopeRollback` consults the optional native bridge;
- native source exists under `native/fixics_physics/`;
- native source exports `RVExtensionVersion` and `RVExtensionArgs`;
- native source implements `slopeControl`;
- no native binaries are committed.

- [x] **Step 2: Run regression to verify red**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: non-zero exit with missing native bridge/source and failed config patch still present.

- [x] **Step 3: Roll back failed config-class patch**

Remove `A3_Soft_F`, `A3_Armor_F`, and the broad `CfgVehicles` `Car_F` / `Tank_F` handling patch from `addons/main/config.cpp`.

- [x] **Step 4: Add native-assisted bridge**

Create `FIXICS_fnc_getNativeSlopeControl`, register it in `CfgFunctions`, add the disabled-by-default `FIXICS_nativeSlopeControlEnabled` CBA setting, and make `FIXICS_fnc_applySlopeRollback` use native deltas only when the bridge returns a valid recommendation.

- [x] **Step 5: Add native source scaffold**

Create source-only `native/fixics_physics/src/FIXICSPhysics.cpp` with `RVExtensionVersion`, `RVExtension`, `RVExtensionArgs`, `version`, `ping`, `schema`, and `slopeControl` support.

- [x] **Step 6: Run regression and HEMTT check**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
powershell -ExecutionPolicy Bypass -File tools\check.ps1
```

Expected: both commands exit code 0. Native source is not compiled by HEMTT.

### Task 9: Local Windows x64 Native Binary

**Files:**
- Modify: `tests/integration/fixics-vehicle-physics-static.ps1`
- Create: `native/fixics_physics/CMakeLists.txt`
- Create: `tools/build-native.ps1`
- Create: `FIXICSPhysics_x64.dll`
- Modify: `native/fixics_physics/README.md`
- Modify: `governance/guardrails/generated-files.md`
- Modify: `governance/policies/scope-control.md`
- Modify: `docs/superpowers/specs/2026-06-07-native-extension-pre-research.md`
- Modify: `docs/superpowers/specs/2026-06-07-vehicle-physics-beyond-sqf-evaluation.md`
- Modify: `governance/audit/validation-log.md`

- [x] **Step 1: Write the failing regression**

Require:

- `native/fixics_physics/CMakeLists.txt`;
- `tools/build-native.ps1`;
- root `FIXICSPhysics_x64.dll`;
- CMake output name `FIXICSPhysics_x64`;
- build script loading `VsDevCmd.bat`;
- non-empty approved DLL;
- no DLLs stored under `native/`.

- [x] **Step 2: Run regression to verify red**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: non-zero exit before build files and DLL exist.

- [x] **Step 3: Add native build files**

Create `native/fixics_physics/CMakeLists.txt` and `tools/build-native.ps1`. The build script must discover Visual Studio Build Tools with `vswhere`, load `VsDevCmd.bat -arch=x64`, configure CMake for x64, build Release, and verify `FIXICSPhysics_x64.dll`.

- [x] **Step 4: Build the DLL**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools\build-native.ps1
```

Expected: `FIXICSPhysics_x64.dll` appears in the repository root.

- [x] **Step 5: Run validation**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
powershell -ExecutionPolicy Bypass -File tools\check.ps1
powershell -ExecutionPolicy Bypass -File tools\build-native.ps1
```

Expected: all commands exit code 0.
