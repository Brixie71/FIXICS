# Terrain Tire Behavior Phase 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add SQF-first Terrain Tire Phase 2 behavior for terrain transitions, rollover/contact safety, driverless decay, destroyed-tire mobility loss, and SQA telemetry.

**Architecture:** Extend the existing pure Terrain Tire recommendation function and existing local driver/stability/controller path. Rollover/contact safety acts as a guard above drive-style assists; ABS, slope, stability, roll, sway, controlled slip, handbrake, and per-vehicle profiles keep their current ownership.

**Tech Stack:** Arma 3 SQF, CBA settings, HEMTT static checks, PowerShell integration tests.

---

### Task 1: Static Contract Tests

**Files:**
- Modify: `tests/integration/fixics-vehicle-physics-static.ps1`

- [ ] **Step 1: Add setting contract assertions**

Add static checks that require the following CBA settings in
`addons/main/functions/fn_registerSettings.sqf`:

```powershell
@(
    @{
        Variable = 'FIXICS_rolloverSafetyEnabled'
        ControlType = 'CHECKBOX'
        Category = '["FIXICS","Terrain Tire"]'
        Payload = 'true'
        NamespaceDefault = 'true'
    },
    @{
        Variable = 'FIXICS_airborneGraceWindow'
        ControlType = 'SLIDER'
        Category = '["FIXICS","Terrain Tire"]'
        Payload = '[0,1,0.5,2]'
        DefaultIndex = 2
        NamespaceDefault = '0.5'
    },
    @{
        Variable = 'FIXICS_driverlessDecayEnabled'
        ControlType = 'CHECKBOX'
        Category = '["FIXICS","Terrain Tire"]'
        Payload = 'true'
        NamespaceDefault = 'true'
    },
    @{
        Variable = 'FIXICS_driverlessDecayCap'
        ControlType = 'SLIDER'
        Category = '["FIXICS","Terrain Tire"]'
        Payload = '[0,1,0.15,2]'
        DefaultIndex = 2
        NamespaceDefault = '0.15'
    },
    @{
        Variable = 'FIXICS_destroyedTireThreshold'
        ControlType = 'SLIDER'
        Category = '["FIXICS","Terrain Tire"]'
        Payload = '[0.5,1,0.85,2]'
        DefaultIndex = 2
        NamespaceDefault = '0.85'
    },
    @{
        Variable = 'FIXICS_destroyedTireDebugLogging'
        ControlType = 'CHECKBOX'
        Category = '["FIXICS","Terrain Tire"]'
        Payload = 'false'
        NamespaceDefault = 'false'
    }
) | ForEach-Object {
    Assert-CbaSetting $RegisterSettings $_
}
```

- [ ] **Step 2: Add Terrain Tire Phase 2 token assertions**

Require `fn_getTerrainTireRecommendation.sqf` to expose:

```powershell
@(
    'wheelSupportState',
    'rolloverSuppressed',
    'driverlessDecay',
    'destroyedTireCount',
    'destroyedTireRatio',
    'destroyedTirePenalty',
    'mobilityLimiter',
    'getHitPointDamage',
    '-1'
) | ForEach-Object {
    Assert-Contains $TerrainTireRecommendation $_ "Terrain Tire Phase 2 must include token $_."
}
```

- [ ] **Step 3: Add telemetry token assertions**

Require `fn_logVehicleHandlingConfig.sqf` to include:

```powershell
@(
    'wheelSupportState',
    'rolloverSuppressed',
    'driverlessDecay',
    'destroyedTireCount',
    'destroyedTireRatio',
    'destroyedTirePenalty',
    'mobilityLimiter'
) | ForEach-Object {
    Assert-Contains $HandlingConfigLog $_ "Handling telemetry must include Terrain Tire Phase 2 token $_."
}
```

- [ ] **Step 4: Run failing static test**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: FAIL until implementation adds settings and telemetry.

### Task 2: Settings And Stringtable

**Files:**
- Modify: `addons/main/functions/fn_registerSettings.sqf`
- Modify: `addons/main/stringtable.xml`

- [ ] **Step 1: Register missionNamespace defaults**

Add near existing Terrain Tire defaults:

```sqf
missionNamespace setVariable ["FIXICS_rolloverSafetyEnabled", true, false];
missionNamespace setVariable ["FIXICS_airborneGraceWindow", 0.50, false];
missionNamespace setVariable ["FIXICS_driverlessDecayEnabled", true, false];
missionNamespace setVariable ["FIXICS_driverlessDecayCap", 0.15, false];
missionNamespace setVariable ["FIXICS_destroyedTireThreshold", 0.85, false];
missionNamespace setVariable ["FIXICS_destroyedTireDebugLogging", false, false];
```

- [ ] **Step 2: Add CBA settings**

Add settings under `["FIXICS", "Terrain Tire"]` using CHECKBOX/SLIDER payloads:

```sqf
[
    "FIXICS_rolloverSafetyEnabled",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_ROLLOVER_SAFETY_ENABLED",
        localize "STR_FIXICS_SETTING_ROLLOVER_SAFETY_ENABLED_TOOLTIP"
    ],
    ["FIXICS", "Terrain Tire"],
    true,
    1
] call CBA_fnc_addSetting;
```

Repeat for the five remaining approved settings with payloads:

```sqf
["FIXICS_airborneGraceWindow", "SLIDER", [...], ["FIXICS", "Terrain Tire"], [0, 1, 0.50, 2], 1]
["FIXICS_driverlessDecayEnabled", "CHECKBOX", [...], ["FIXICS", "Terrain Tire"], true, 1]
["FIXICS_driverlessDecayCap", "SLIDER", [...], ["FIXICS", "Terrain Tire"], [0, 1, 0.15, 2], 1]
["FIXICS_destroyedTireThreshold", "SLIDER", [...], ["FIXICS", "Terrain Tire"], [0.5, 1, 0.85, 2], 1]
["FIXICS_destroyedTireDebugLogging", "CHECKBOX", [...], ["FIXICS", "Terrain Tire"], false, 1]
```

- [ ] **Step 3: Add stringtable labels**

Add localized names/tooltips for:

```xml
STR_FIXICS_SETTING_ROLLOVER_SAFETY_ENABLED
STR_FIXICS_SETTING_ROLLOVER_SAFETY_ENABLED_TOOLTIP
STR_FIXICS_SETTING_AIRBORNE_GRACE_WINDOW
STR_FIXICS_SETTING_AIRBORNE_GRACE_WINDOW_TOOLTIP
STR_FIXICS_SETTING_DRIVERLESS_DECAY_ENABLED
STR_FIXICS_SETTING_DRIVERLESS_DECAY_ENABLED_TOOLTIP
STR_FIXICS_SETTING_DRIVERLESS_DECAY_CAP
STR_FIXICS_SETTING_DRIVERLESS_DECAY_CAP_TOOLTIP
STR_FIXICS_SETTING_DESTROYED_TIRE_THRESHOLD
STR_FIXICS_SETTING_DESTROYED_TIRE_THRESHOLD_TOOLTIP
STR_FIXICS_SETTING_DESTROYED_TIRE_DEBUG_LOGGING
STR_FIXICS_SETTING_DESTROYED_TIRE_DEBUG_LOGGING_TOOLTIP
```

### Task 3: Terrain Tire Recommendation Phase 2

**Files:**
- Modify: `addons/main/functions/fn_getTerrainTireRecommendation.sqf`

- [ ] **Step 1: Extend state/settings inputs**

Read bounded values:

```sqf
private _grounded = _state getOrDefault ["isTouchingGround", true];
private _vectorUp = _state getOrDefault ["vectorUp", [0, 0, 1]];
private _pitch = [_state, "pitch", 0] call _getNumber;
private _bank = [_state, "bank", 0] call _getNumber;
private _lastGroundedAge = [_state, "lastGroundedAge", 999] call _getNumber;
private _driverPresent = _state getOrDefault ["driverPresent", true];
private _wheelDamageValues = _state getOrDefault ["wheelDamageValues", []];
private _rolloverSafetyEnabled = _settings getOrDefault ["rolloverSafetyEnabled", true];
private _airborneGraceWindow = (([_settings, "airborneGraceWindow", 0.50] call _getNumber) max 0) min 1;
private _driverlessDecayEnabled = _settings getOrDefault ["driverlessDecayEnabled", true];
private _driverlessDecayCap = (([_settings, "driverlessDecayCap", 0.15] call _getNumber) max 0) min 1;
private _destroyedTireThreshold = (([_settings, "destroyedTireThreshold", 0.85] call _getNumber) max 0.5) min 1;
```

- [ ] **Step 2: Calculate wheel support state**

Use conservative orientation rules:

```sqf
private _upZ = 1;
if (_vectorUp isEqualType [] && {(count _vectorUp) >= 3}) then {
    _upZ = ((_vectorUp # 2) max -1) min 1;
};
private _wheelSupportState = "SUPPORTED";
if (!_grounded) then {
    _wheelSupportState = ["AIRBORNE", "AIRBORNE_GRACE"] select (_lastGroundedAge <= _airborneGraceWindow);
};
if (_grounded && {_upZ < -0.25}) then {
    _wheelSupportState = "FLIPPED";
};
if (_grounded && {_upZ >= -0.25} && {_upZ < 0.35}) then {
    _wheelSupportState = "SIDE_UNSUPPORTED";
};
private _rolloverSuppressed = _rolloverSafetyEnabled && {
    _wheelSupportState in ["AIRBORNE", "FLIPPED", "SIDE_UNSUPPORTED"]
};
```

- [ ] **Step 3: Calculate destroyed tire count safely**

Treat `-1` as missing and fall back to aggregate damage only when there are no
usable wheel values:

```sqf
private _usableWheelValues = _wheelDamageValues select {_x isEqualType 0 && {_x >= 0}};
private _destroyedTireCount = {_x >= _destroyedTireThreshold} count _usableWheelValues;
private _wheelCount = count _usableWheelValues;
private _perWheelMode = ["FALLBACK", "PER_WHEEL"] select (_wheelCount > 0);
if (_wheelCount == 0 && {_tireDamage >= _destroyedTireThreshold}) then {
    _destroyedTireCount = 1;
    _wheelCount = 4;
};
private _destroyedTireRatio = if (_wheelCount > 0) then {
    (_destroyedTireCount / _wheelCount) max 0 min 1
} else {
    0
};
```

- [ ] **Step 4: Apply mobility limiter**

Compute limiter and penalties:

```sqf
private _destroyedTirePenalty = (_destroyedTireRatio * 0.85) max 0 min 0.85;
private _mobilityLimiter = 1;
if (_rolloverSuppressed) then {
    _mobilityLimiter = 0;
} else {
    _mobilityLimiter = (1 - _destroyedTirePenalty) max 0.08 min 1;
};
```

Apply to acceleration/turning/slope traction and steering penalty:

```sqf
_accelerationTractionMultiplier = (_accelerationTractionMultiplier * _mobilityLimiter) max 0.05 min 1.10;
_turningTractionMultiplier = (_turningTractionMultiplier * (1 - (_destroyedTirePenalty * 0.75))) max 0.03 min 1.05;
_slopeTractionMultiplier = (_slopeTractionMultiplier * _mobilityLimiter) max 0.05 min 1.05;
_tireSteeringPenalty = (_tireSteeringPenalty + (_destroyedTirePenalty * 0.65)) max 0 min 0.95;
```

- [ ] **Step 5: Return new fields**

Add to return hashmap:

```sqf
["wheelSupportState", _wheelSupportState],
["rolloverSuppressed", _rolloverSuppressed],
["driverlessDecay", [0, _driverlessDecayCap] select (!_driverPresent && {_driverlessDecayEnabled})],
["destroyedTireCount", _destroyedTireCount],
["destroyedTireRatio", _destroyedTireRatio],
["destroyedTirePenalty", _destroyedTirePenalty],
["mobilityLimiter", _mobilityLimiter],
["terrainTireTelemetryVersion", 2],
["perWheelMode", _perWheelMode]
```

### Task 4: Controller And Stability Integration

**Files:**
- Modify: `addons/main/functions/fn_updateDriverController.sqf`
- Modify: `addons/main/functions/fn_applyVehicleStability.sqf`
- Modify: `addons/main/functions/fn_coordinateVehicleAssists.sqf`

- [ ] **Step 1: Pass Phase 2 state into Terrain Tire**

In `fn_applyVehicleStability.sqf`, add pitch/bank, vectorUp, ground age, driver
state, and wheel damage values to `_terrainTireState`.

- [ ] **Step 2: Pass Phase 2 settings**

Add approved settings to `_terrainTireSettings` with profile fallback where
appropriate.

- [ ] **Step 3: Suppress drive-style velocity changes**

When Terrain Tire returns `rolloverSuppressed = true`, do not apply controlled
slip lateral release or roll/drive-style corrections from Terrain Tire. Store
the recommendation for telemetry.

- [ ] **Step 4: Driverless decay on release**

In `fn_updateDriverController.sqf` release path, if a local abandoned vehicle is
not handbraked and `FIXICS_driverlessDecayEnabled` is true, reduce model-space
longitudinal speed by at most `FIXICS_driverlessDecayCap * deltaTime`, preserving
sign and never reversing direction.

- [ ] **Step 5: Runtime Assist propagation**

Copy Phase 2 fields from Terrain Tire recommendation into
`FIXICS_runtimeAssistLastDecision` and debug logs.

### Task 5: Telemetry

**Files:**
- Modify: `addons/main/functions/fn_logVehicleHandlingConfig.sqf`

- [ ] **Step 1: Add one-shot evidence fields**

Add Phase 2 fields to `_values`.

- [ ] **Step 2: Add continuous sample variables**

Read Phase 2 fields from `_terrainTireRecommendation`.

- [ ] **Step 3: Extend compact TerrainTireSample**

Add placeholders and arguments for:

```text
wheelSupportState
rolloverSuppressed
driverlessDecay
destroyedTireCount
destroyedTireRatio
destroyedTirePenalty
mobilityLimiter
```

### Task 6: Validation And State

**Files:**
- Modify: `orchestration/state.md`

- [ ] **Step 1: Run validation**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
powershell -ExecutionPolicy Bypass -File tools\check.ps1
git diff --check
```

Expected: all pass.

- [ ] **Step 2: Update project state**

Record that Terrain Tire Phase 2 is implemented and awaiting SQA gameplay
validation.

- [ ] **Step 3: SQA handoff**

Provide exact commands:

```powershell
powershell -ExecutionPolicy Bypass -File tools\build.ps1
python tools\live-vehicle-telemetry.py
```

Arma Debug Console:

```sqf
[vehicle player, 180, 0.1] call FIXICS_fnc_logVehicleHandlingConfig;
```
