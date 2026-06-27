# Native Terrain Tire Advisory Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add optional `terrainTireV2` advisory math to the existing `FIXICSPhysics_x64.dll` while preserving SQF fallback.

**Architecture:** Extend the existing native command dispatcher and CMake tests. Add one SQF bridge gated by `FIXICS_nativeTerrainTireEnabled`; SQF validates native output and remains the gameplay mutation authority.

**Tech Stack:** C++17, CMake, Visual Studio Build Tools 2022, Arma SQF, CBA settings, HEMTT.

---

### Task 1: Native Tests

**Files:**
- Modify: `native/fixics_physics/tests/FIXICSPhysicsTests.cpp`

- [ ] Add helper `callTerrainTireV2`.
- [ ] Add test for paved supported vehicle output.
- [ ] Add test for flipped vehicle output with `rolloverSuppressed=true`.
- [ ] Add test for destroyed tire threshold output.
- [ ] Add test for invalid/non-finite input returning safe false payload.
- [ ] Run `powershell -ExecutionPolicy Bypass -File tools\build-native.ps1`.
- [ ] Expected result before implementation: native test failure.

### Task 2: Native Implementation

**Files:**
- Modify: `native/fixics_physics/src/FIXICSPhysics.cpp`
- Modify: `native/fixics_physics/README.md`

- [ ] Add `TerrainTireInput` and `TerrainTireResult`.
- [ ] Add strict numeric parsing for `terrainTireV2`.
- [ ] Implement bounded terrain, support-state, destroyed-tire, and mobility math.
- [ ] Add `terrainTireV2` to `schema`.
- [ ] Dispatch `command == "terrainTireV2"`.
- [ ] Document the command in the native README.
- [ ] Run native build and tests.

### Task 3: SQF Bridge

**Files:**
- Create: `addons/main/functions/fn_getNativeTerrainTire.sqf`
- Modify: `addons/main/config.cpp`

- [ ] Register `class getNativeTerrainTire {};`.
- [ ] Implement `FIXICS_fnc_getNativeTerrainTire`.
- [ ] Gate on `FIXICS_nativeTerrainTireEnabled`, default false.
- [ ] Call `"FIXICSPhysics" callExtension ["terrainTireV2", [...]]`.
- [ ] Parse with `parseSimpleArray`.
- [ ] Validate all types and bounds.
- [ ] Return `[]` on disabled, invalid, missing, or failed native output.

### Task 4: SQF Integration

**Files:**
- Modify: `addons/main/functions/fn_getTerrainTireRecommendation.sqf`
- Modify: `addons/main/functions/fn_registerSettings.sqf`
- Modify: `addons/main/stringtable.xml`

- [ ] Add `FIXICS_nativeTerrainTireEnabled` CBA setting under `["FIXICS", "Terrain Tire"]`, default false.
- [ ] In `fn_getTerrainTireRecommendation.sqf`, try native advisory first only when enabled.
- [ ] If native output is valid, use it to populate the same hashmap fields.
- [ ] If native output is invalid or disabled, use existing SQF calculation unchanged.
- [ ] Add telemetry reason `native-terrain-tire` or `sqf-fallback`.

### Task 5: Static Tests And Validation

**Files:**
- Modify: `tests/integration/fixics-vehicle-physics-static.ps1`

- [ ] Require native source contains `terrainTireV2`.
- [ ] Require native tests contain terrain tire cases.
- [ ] Require SQF bridge registration.
- [ ] Require default setting is false.
- [ ] Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools\build-native.ps1
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
powershell -ExecutionPolicy Bypass -File tools\check.ps1
git diff --check
```

### Task 6: SQA Handoff

**Files:**
- Modify: `orchestration/state.md`

- [ ] Record native Terrain Tire advisory implementation.
- [ ] Hand SQA two test modes:
  - `FIXICS_nativeTerrainTireEnabled=false`
  - `FIXICS_nativeTerrainTireEnabled=true`
- [ ] Ask SQA to compare telemetry and gameplay feel on the same vehicle/surface matrix.
