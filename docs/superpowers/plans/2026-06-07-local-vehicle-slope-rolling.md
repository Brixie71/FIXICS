# Local Vehicle Slope Rolling Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build local-only slope rolling for `LandVehicle` objects with ACE3 handbrake interactions and migrate public function prefixes to `FIXICS_fnc_*`.

**Architecture:** A post-init entry point starts a local scheduled vehicle monitor and registers ACE client interactions. The monitor disables idle PhysX autobrake on local land vehicles unless `FIXICS_handbrakeEnabled` is true or the local player driver is actively braking.

**Tech Stack:** Arma 3 SQF, HEMTT, ACE3 interaction menu, PowerShell static regression test.

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

`FIXICS_fnc_shouldVehicleRoll` returns true for local `LandVehicle` objects unless `FIXICS_handbrakeEnabled` is true or the local player driver is actively pressing `CarBack` or `CarHandBrake`.

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
