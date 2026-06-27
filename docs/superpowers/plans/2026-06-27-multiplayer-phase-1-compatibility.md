# Multiplayer Phase 1 Compatibility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a conservative multiplayer compatibility slice that introduces authority checks, synced handbrake/profile state, and telemetry ownership without adding new physics mutations.

**Architecture:** Existing vehicle physics systems keep their current behavior, but all mutation-capable paths route authority through `FIXICS_fnc_isVehicleLocal`. Multiplayer uses vehicle locality as the only physics authority rule; server-global settings and profile data override client-local profile overrides in MP. Native DLL advisory calls remain client-only and are suppressed on dedicated servers.

**Tech Stack:** Arma 3 SQF, ACE interaction, CBA settings/events, HEMTT, PowerShell static tests.

---

### Task 1: Static Contract Tests

**Files:**
- Modify: `tests/integration/fixics-vehicle-physics-static.ps1`

- [ ] Add assertions that `FIXICS_fnc_isVehicleLocal` is registered in `config.cpp`.
- [ ] Add assertions that mutation-capable functions call `FIXICS_fnc_isVehicleLocal`.
- [ ] Add assertions that native bridges contain `!hasInterface && {isMultiplayer}` guards before `callExtension`.
- [ ] Add assertions that MP setting `FIXICS_multiplayerCompatibilityEnabled` exists and defaults true.

### Task 2: Authority Helper And Setting

**Files:**
- Create: `addons/main/functions/fn_isVehicleLocal.sqf`
- Modify: `addons/main/config.cpp`
- Modify: `addons/main/functions/fn_registerSettings.sqf`
- Modify: `addons/main/stringtable.xml`

- [ ] Implement `FIXICS_fnc_isVehicleLocal` with no mutation.
- [ ] Return false for null/non-land vehicles.
- [ ] In SP, return `local _vehicle`.
- [ ] In MP with `FIXICS_multiplayerCompatibilityEnabled=false`, return false.
- [ ] In MP, return true only when `local _vehicle`.
- [ ] Register the helper in `CfgFunctions`.
- [ ] Add CBA setting `FIXICS_multiplayerCompatibilityEnabled`, default true, global/server.

### Task 3: Wire Existing Mutation Paths

**Files:**
- Modify: `addons/main/functions/fn_updateDriverController.sqf`
- Modify: `addons/main/functions/fn_applyABSBraking.sqf`
- Modify: `addons/main/functions/fn_applySlopeRollback.sqf`
- Modify: `addons/main/functions/fn_applyVehicleStability.sqf`
- Modify: `addons/main/functions/fn_coordinateVehicleAssists.sqf`
- Modify: `addons/main/functions/fn_monitorVehicleAutobrake.sqf`

- [ ] Replace direct `local _vehicle` authority gates in mutation-capable systems with `[_vehicle] call FIXICS_fnc_isVehicleLocal`.
- [ ] Keep existing driver checks intact.
- [ ] Do not add any new `setVelocity*` call.
- [ ] Keep abandoned vehicle monitor limited to current behavior plus authority helper.

### Task 4: Handbrake And Profile Sync Boundaries

**Files:**
- Modify: `addons/main/functions/fn_registerAceInteractions.sqf`
- Modify: `addons/main/functions/fn_setVehicleHandbrake.sqf`
- Modify: `addons/main/functions/fn_getVehicleProfile.sqf`

- [ ] Enforce driver-only ACE handbrake use in MP.
- [ ] Ensure handbrake state remains globally stored via `setVariable` public flag where already used.
- [ ] In MP, resolve vehicle profiles from server/global CBA values only.
- [ ] Clear/re-read cached vehicle profile when forced refresh is requested.

### Task 5: Native And Telemetry Ownership

**Files:**
- Modify: `addons/main/functions/fn_getNativeSlopeControl.sqf`
- Modify: `addons/main/functions/fn_getNativeDriverAssist.sqf`
- Modify: `addons/main/functions/fn_getNativeTerrainTire.sqf`
- Modify: `addons/main/functions/fn_logVehicleHandlingConfig.sqf`

- [ ] Suppress native DLL calls on dedicated server instances.
- [ ] Keep native advisory client-only in MP.
- [ ] Keep telemetry owned by driver client or local vehicle owner.
- [ ] Do not introduce `remoteExecCall`.

### Task 6: Validation And State

**Files:**
- Modify: `README.md`
- Modify: `orchestration/state.md`

- [ ] Document the MP compatibility slice and acceptance gate.
- [ ] Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
powershell -ExecutionPolicy Bypass -File tools\check.ps1
```

- [ ] Report that dedicated server 2+ player SQA validation remains manual and pending.

