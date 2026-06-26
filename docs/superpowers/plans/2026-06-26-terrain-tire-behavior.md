# Terrain Tire Behavior Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a SQF-first Terrain Tire Behavior layer that produces terrain, traction, tire-pressure, drag, steering, mass, and wheelspin recommendations for registered FIXICS ground vehicles.

**Architecture:** Add one pure recommendation function and route its bounded output through Runtime Assist and the existing local stability/controller path. Terrain Tire Behavior does not directly own vehicle mutation; it feeds Controlled Slip, ABS, Slope Assist, Vehicle Stability, Roll Stability, and telemetry with reusable multipliers.

**Tech Stack:** Arma 3 SQF, CBA settings, HEMTT layout, PowerShell validation tests, FIXICS local-player vehicle controller.

---

## File Structure

- Create `addons/main/functions/fn_getTerrainTireRecommendation.sqf`
  - Pure math and state recommendation only.
  - No direct `setVelocity`, `addForce`, or vehicle mutation.
- Create `tests/unit/fixics-terrain-tire-recommendation.ps1`
  - Text-level unit/static contract for terrain classification, bounds, tire pressure, and telemetry keys.
- Modify `addons/main/config.cpp`
  - Register `getTerrainTireRecommendation`.
- Modify `addons/main/functions/fn_registerSettings.sqf`
  - Add Terrain Tire Behavior global setting if needed.
  - Add approved tire-pressure settings.
- Modify `addons/main/functions/fn_coordinateVehicleAssists.sqf`
  - Accept and expose terrain/tire recommendation fields.
- Modify `addons/main/functions/fn_getRuntimeAssistRecommendation.sqf`
  - Include terrain/tire multipliers in Runtime Assist output.
- Modify `addons/main/functions/fn_applyVehicleStability.sqf`
  - Sample Terrain Tire Behavior and apply only bounded existing-path effects.
- Modify `addons/main/functions/fn_logVehicleHandlingConfig.sqf`
  - Add terrain/tire telemetry fields.
- Modify `addons/main/stringtable.xml`
  - Add user-facing labels and tooltips for settings.
- Modify `tests/integration/fixics-vehicle-physics-static.ps1`
  - Add function/settings/telemetry contract checks.
- Modify `tools/check.ps1`
  - Include the new unit test.
- Modify `docs/vehicle-behavior/sqa-evidence-matrix.md`
  - Add Terrain Tire Behavior QA rows.
- Modify `governance/audit/validation-log.md`
  - Record automated validation.
- Modify `orchestration/state.md`
  - Record current state and SQA handoff.

---

### Task 1: Static Contract And Unit Test

**Files:**
- Create: `tests/unit/fixics-terrain-tire-recommendation.ps1`
- Modify: `tools/check.ps1`

- [ ] **Step 1: Create the failing unit/static contract test**

Create `tests/unit/fixics-terrain-tire-recommendation.ps1` with:

```powershell
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$functionPath = Join-Path $repoRoot "addons\main\functions\fn_getTerrainTireRecommendation.sqf"

if (-not (Test-Path $functionPath)) {
    throw "Missing Terrain Tire recommendation function: $functionPath"
}

$content = Get-Content -Raw $functionPath

$requiredTokens = @(
    "FIXICS_fnc_getTerrainTireRecommendation",
    "terrainGripClass",
    "tractionMultiplier",
    "accelerationTractionMultiplier",
    "brakingTractionMultiplier",
    "turningTractionMultiplier",
    "slopeTractionMultiplier",
    "wheelspinEstimate",
    "tireAirState",
    "tireDeflationState",
    "tireDragPenalty",
    "tireSteeringPenalty",
    "massModifier",
    "terrainTireTelemetryVersion",
    "PAVED",
    "DIRT",
    "GRASS",
    "SAND",
    "ROCK",
    "UNKNOWN"
)

foreach ($token in $requiredTokens) {
    if ($content -notmatch [regex]::Escape($token)) {
        throw "Terrain Tire recommendation function missing token: $token"
    }
}

$boundedPatterns = @(
    "\bmax\b",
    "\bmin\b",
    "linearConversion",
    "deflationRate",
    "minimumMobility",
    "dragStrength",
    "steeringPenalty"
)

foreach ($pattern in $boundedPatterns) {
    if ($content -notmatch $pattern) {
        throw "Terrain Tire recommendation function missing bounded math marker: $pattern"
    }
}

Write-Host "Terrain Tire recommendation contract passed."
```

- [ ] **Step 2: Run the new test and confirm it fails**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\unit\fixics-terrain-tire-recommendation.ps1
```

Expected result:

```text
Missing Terrain Tire recommendation function
```

- [ ] **Step 3: Add the unit test to `tools/check.ps1`**

Add this command near the existing unit/static test calls:

```powershell
& powershell -ExecutionPolicy Bypass -File tests\unit\fixics-terrain-tire-recommendation.ps1
```

- [ ] **Step 4: Run `tools/check.ps1` and confirm it fails for the missing function**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools\check.ps1
```

Expected result:

```text
Missing Terrain Tire recommendation function
```

---

### Task 2: Pure Terrain Tire Recommendation Function

**Files:**
- Create: `addons/main/functions/fn_getTerrainTireRecommendation.sqf`
- Test: `tests/unit/fixics-terrain-tire-recommendation.ps1`

- [ ] **Step 1: Create the pure SQF recommendation function**

Create `addons/main/functions/fn_getTerrainTireRecommendation.sqf`:

```sqf
/*
 * Author: FIXICS
 * Calculates terrain, traction, tire-pressure, drag, steering, mass, and wheelspin recommendations.
 *
 * Arguments:
 * 0: State hashmap <HASHMAP>
 * 1: Settings hashmap <HASHMAP>
 *
 * Return Value:
 * Recommendation hashmap <HASHMAP>
 *
 * Locality:
 * Pure calculation. Does not mutate vehicle state.
 */

params [
    ["_state", createHashMap, [createHashMap]],
    ["_settings", createHashMap, [createHashMap]]
];

private _enabled = _settings getOrDefault ["enabled", true];
private _surfaceType = toLowerANSI (_state getOrDefault ["surfaceType", ""]);
private _speedKmh = abs (_state getOrDefault ["speedKmh", 0]);
private _forwardDemand = abs (_state getOrDefault ["forwardDemand", 0]);
private _brakeDemand = abs (_state getOrDefault ["brakeDemand", 0]);
private _steeringDemand = abs (_state getOrDefault ["steeringDemand", 0]);
private _slopeSeverity = abs (_state getOrDefault ["slopeSeverity", 0]);
private _massKg = _state getOrDefault ["massKg", 1500];
private _deltaTime = (_state getOrDefault ["deltaTime", 0.016]) max 0.001 min 0.25;
private _tireDamage = (_state getOrDefault ["tireDamage", 0]) max 0 min 1;
private _previousAir = (_state getOrDefault ["tireAirState", 1]) max 0 min 1;
private _tirePressureEnabled = _settings getOrDefault ["tirePressureEnabled", true];
private _deflationRate = (_settings getOrDefault ["deflationRate", 0.025]) max 0 min 1;
private _minimumMobility = (_settings getOrDefault ["minimumMobility", 0.35]) max 0.05 min 1;
private _dragStrength = (_settings getOrDefault ["dragStrength", 0.35]) max 0 min 1;
private _steeringPenaltySetting = (_settings getOrDefault ["steeringPenalty", 0.30]) max 0 min 1;

private _terrainGripClass = "UNKNOWN";
if (_surfaceType find "concrete" >= 0 || {_surfaceType find "asphalt" >= 0} || {_surfaceType find "road" >= 0} || {_surfaceType find "tarmac" >= 0}) then {
    _terrainGripClass = "PAVED";
} else {
    if (_surfaceType find "dirt" >= 0 || {_surfaceType find "gravel" >= 0} || {_surfaceType find "soil" >= 0}) then {
        _terrainGripClass = "DIRT";
    } else {
        if (_surfaceType find "grass" >= 0 || {_surfaceType find "forest" >= 0}) then {
            _terrainGripClass = "GRASS";
        } else {
            if (_surfaceType find "sand" >= 0 || {_surfaceType find "beach" >= 0}) then {
                _terrainGripClass = "SAND";
            } else {
                if (_surfaceType find "rock" >= 0 || {_surfaceType find "stone" >= 0}) then {
                    _terrainGripClass = "ROCK";
                };
            };
        };
    };
};

private _terrainBase = switch (_terrainGripClass) do {
    case "PAVED": {1.00};
    case "DIRT": {0.78};
    case "GRASS": {0.66};
    case "SAND": {0.52};
    case "ROCK": {0.70};
    default {0.84};
};

private _wheelspinBase = switch (_terrainGripClass) do {
    case "PAVED": {0.08};
    case "DIRT": {0.28};
    case "GRASS": {0.38};
    case "SAND": {0.55};
    case "ROCK": {0.34};
    default {0.18};
};

private _roughness = switch (_terrainGripClass) do {
    case "ROCK": {0.22};
    case "SAND": {0.12};
    case "GRASS": {0.10};
    case "DIRT": {0.08};
    default {0.02};
};

private _massModifier = linearConversion [900, 4500, _massKg, 1.08, 0.72, true];
private _speedDemand = linearConversion [10, 100, _speedKmh, 0, 1, true];
private _accelDemand = (_forwardDemand * (1 - _terrainBase)) max 0 min 1;
private _turnDemand = (_steeringDemand * _speedDemand * (1 - (_terrainBase * 0.65))) max 0 min 1;
private _brakeDemandLoss = (_brakeDemand * _speedDemand * (1 - (_terrainBase * 0.75))) max 0 min 1;

private _newAir = _previousAir;
private _deflationState = "NONE";
if (_tirePressureEnabled && {_tireDamage > 0.05}) then {
    private _loss = _deflationRate * _deltaTime * (0.35 + _tireDamage);
    _newAir = (_previousAir - _loss) max _minimumMobility;
    _deflationState = if (_newAir <= _minimumMobility + 0.001) then {"RUNFLAT"} else {"LEAKING"};
};

private _airLoss = 1 - _newAir;
private _tireDragPenalty = (_airLoss * _dragStrength) max 0 min 0.75;
private _tireSteeringPenalty = (_airLoss * _steeringPenaltySetting) max 0 min 0.65;
private _cleanGripLoss = (_airLoss * 0.35) max 0 min 0.35;

private _tractionMultiplier = (_terrainBase - _cleanGripLoss - (_roughness * _speedDemand * 0.25)) max 0.20 min 1.10;
private _accelerationTractionMultiplier = (_tractionMultiplier * (1 - (_accelDemand * 0.35)) * _massModifier) max 0.15 min 1.10;
private _brakingTractionMultiplier = (_tractionMultiplier * (1 - (_brakeDemandLoss * 0.28))) max 0.20 min 1.05;
private _turningTractionMultiplier = (_tractionMultiplier * (1 - (_turnDemand * 0.34)) * (1 - _tireSteeringPenalty)) max 0.15 min 1.05;
private _slopeTractionMultiplier = (_tractionMultiplier * (1 - (_slopeSeverity * (1 - _terrainBase) * 0.25))) max 0.20 min 1.05;
private _wheelspinEstimate = (_wheelspinBase + _accelDemand + (_airLoss * 0.25) + (_roughness * _speedDemand)) max 0 min 1;

createHashMapFromArray [
    ["enabled", _enabled],
    ["eligible", _enabled],
    ["reason", if (_enabled) then {"ACTIVE"} else {"DISABLED"}],
    ["surfaceType", _surfaceType],
    ["terrainGripClass", _terrainGripClass],
    ["tractionMultiplier", _tractionMultiplier],
    ["accelerationTractionMultiplier", _accelerationTractionMultiplier],
    ["brakingTractionMultiplier", _brakingTractionMultiplier],
    ["turningTractionMultiplier", _turningTractionMultiplier],
    ["slopeTractionMultiplier", _slopeTractionMultiplier],
    ["wheelspinEstimate", _wheelspinEstimate],
    ["tireAirState", _newAir],
    ["tireDeflationState", _deflationState],
    ["tireDragPenalty", _tireDragPenalty],
    ["tireSteeringPenalty", _tireSteeringPenalty],
    ["massModifier", _massModifier],
    ["terrainTireTelemetryVersion", 1],
    ["perWheelMode", "FALLBACK"]
]
```

- [ ] **Step 2: Run the Terrain Tire unit test**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\unit\fixics-terrain-tire-recommendation.ps1
```

Expected result:

```text
Terrain Tire recommendation contract passed.
```

---

### Task 3: Function Registration And Settings

**Files:**
- Modify: `addons/main/config.cpp`
- Modify: `addons/main/functions/fn_registerSettings.sqf`
- Modify: `addons/main/stringtable.xml`
- Test: `tests/integration/fixics-vehicle-physics-static.ps1`

- [ ] **Step 1: Add a failing static test for registration and settings**

In `tests/integration/fixics-vehicle-physics-static.ps1`, add checks equivalent to:

```powershell
$config = Get-Content -Raw (Join-Path $repoRoot "addons\main\config.cpp")
$settings = Get-Content -Raw (Join-Path $repoRoot "addons\main\functions\fn_registerSettings.sqf")
$stringtable = Get-Content -Raw (Join-Path $repoRoot "addons\main\stringtable.xml")

foreach ($token in @(
    "class getTerrainTireRecommendation",
    "FIXICS_terrainTireEnabled",
    "FIXICS_tirePressureEnabled",
    "FIXICS_tireDeflationRate",
    "FIXICS_tireMinimumMobility",
    "FIXICS_tireDragStrength",
    "FIXICS_tireSteeringPenalty",
    "FIXICS_tireDebugLogging"
)) {
    if (($config + $settings + $stringtable) -notmatch [regex]::Escape($token)) {
        throw "Terrain Tire setting or registration missing: $token"
    }
}
```

- [ ] **Step 2: Run the static test and confirm it fails**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected result:

```text
Terrain Tire setting or registration missing
```

- [ ] **Step 3: Register the function in `config.cpp`**

Add the function class in the existing FIXICS function registration block:

```cpp
class getTerrainTireRecommendation {};
```

- [ ] **Step 4: Add CBA settings in `fn_registerSettings.sqf`**

Add settings using the repo's existing CBA setting pattern:

```sqf
[
    "FIXICS_terrainTireEnabled",
    "CHECKBOX",
    [localize "STR_FIXICS_TerrainTireEnabled_Name", localize "STR_FIXICS_TerrainTireEnabled_Tooltip"],
    localize "STR_FIXICS_Settings_Category",
    true,
    true
] call CBA_fnc_addSetting;

[
    "FIXICS_tirePressureEnabled",
    "CHECKBOX",
    [localize "STR_FIXICS_TirePressureEnabled_Name", localize "STR_FIXICS_TirePressureEnabled_Tooltip"],
    localize "STR_FIXICS_Settings_Category",
    true,
    true
] call CBA_fnc_addSetting;

[
    "FIXICS_tireDeflationRate",
    "SLIDER",
    [localize "STR_FIXICS_TireDeflationRate_Name", localize "STR_FIXICS_TireDeflationRate_Tooltip"],
    localize "STR_FIXICS_Settings_Category",
    [0, 1, 0.025, 3],
    true
] call CBA_fnc_addSetting;

[
    "FIXICS_tireMinimumMobility",
    "SLIDER",
    [localize "STR_FIXICS_TireMinimumMobility_Name", localize "STR_FIXICS_TireMinimumMobility_Tooltip"],
    localize "STR_FIXICS_Settings_Category",
    [0.05, 1, 0.35, 2],
    true
] call CBA_fnc_addSetting;

[
    "FIXICS_tireDragStrength",
    "SLIDER",
    [localize "STR_FIXICS_TireDragStrength_Name", localize "STR_FIXICS_TireDragStrength_Tooltip"],
    localize "STR_FIXICS_Settings_Category",
    [0, 1, 0.35, 2],
    true
] call CBA_fnc_addSetting;

[
    "FIXICS_tireSteeringPenalty",
    "SLIDER",
    [localize "STR_FIXICS_TireSteeringPenalty_Name", localize "STR_FIXICS_TireSteeringPenalty_Tooltip"],
    localize "STR_FIXICS_Settings_Category",
    [0, 1, 0.30, 2],
    true
] call CBA_fnc_addSetting;

[
    "FIXICS_tireDebugLogging",
    "CHECKBOX",
    [localize "STR_FIXICS_TireDebugLogging_Name", localize "STR_FIXICS_TireDebugLogging_Tooltip"],
    localize "STR_FIXICS_Settings_Category",
    false,
    false
] call CBA_fnc_addSetting;
```

- [ ] **Step 5: Add stringtable keys**

Add English entries for each setting name and tooltip:

```xml
<Key ID="STR_FIXICS_TerrainTireEnabled_Name">
    <English>Terrain Tire Behavior</English>
</Key>
<Key ID="STR_FIXICS_TerrainTireEnabled_Tooltip">
    <English>Enables terrain-aware traction, wheelspin, mass, and tire-pressure recommendations for registered FIXICS vehicles.</English>
</Key>
<Key ID="STR_FIXICS_TirePressureEnabled_Name">
    <English>Tire Pressure Simulation</English>
</Key>
<Key ID="STR_FIXICS_TirePressureEnabled_Tooltip">
    <English>Enables slow tire deflation and degraded run-flat mobility after tire damage.</English>
</Key>
<Key ID="STR_FIXICS_TireDeflationRate_Name">
    <English>Tire Deflation Rate</English>
</Key>
<Key ID="STR_FIXICS_TireDeflationRate_Tooltip">
    <English>Controls how quickly damaged tires lose simulated pressure.</English>
</Key>
<Key ID="STR_FIXICS_TireMinimumMobility_Name">
    <English>Tire Minimum Mobility</English>
</Key>
<Key ID="STR_FIXICS_TireMinimumMobility_Tooltip">
    <English>Sets the minimum run-flat mobility retained after tire pressure loss.</English>
</Key>
<Key ID="STR_FIXICS_TireDragStrength_Name">
    <English>Tire Drag Strength</English>
</Key>
<Key ID="STR_FIXICS_TireDragStrength_Tooltip">
    <English>Controls rolling drag added by low tire pressure.</English>
</Key>
<Key ID="STR_FIXICS_TireSteeringPenalty_Name">
    <English>Tire Steering Penalty</English>
</Key>
<Key ID="STR_FIXICS_TireSteeringPenalty_Tooltip">
    <English>Controls steering precision loss from low tire pressure.</English>
</Key>
<Key ID="STR_FIXICS_TireDebugLogging_Name">
    <English>Tire Debug Logging</English>
</Key>
<Key ID="STR_FIXICS_TireDebugLogging_Tooltip">
    <English>Logs Terrain Tire Behavior debug data for SQA testing.</English>
</Key>
```

- [ ] **Step 6: Run static test**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected result:

```text
Vehicle physics static checks passed.
```

---

### Task 4: Runtime Assist Integration

**Files:**
- Modify: `addons/main/functions/fn_coordinateVehicleAssists.sqf`
- Modify: `addons/main/functions/fn_getRuntimeAssistRecommendation.sqf`
- Modify: `addons/main/functions/fn_applyVehicleStability.sqf`
- Test: `tests/integration/fixics-vehicle-physics-static.ps1`

- [ ] **Step 1: Add static checks for Runtime Assist terrain/tire fields**

Extend `tests/integration/fixics-vehicle-physics-static.ps1` to require:

```powershell
foreach ($token in @(
    "terrainTireRecommendation",
    "terrainGripClass",
    "tractionMultiplier",
    "accelerationTractionMultiplier",
    "brakingTractionMultiplier",
    "turningTractionMultiplier",
    "slopeTractionMultiplier",
    "wheelspinEstimate",
    "tireDragPenalty",
    "tireSteeringPenalty",
    "massModifier"
)) {
    if ($runtimeAssistContent -notmatch [regex]::Escape($token) -and $coordinatorContent -notmatch [regex]::Escape($token) -and $stabilityContent -notmatch [regex]::Escape($token)) {
        throw "Runtime terrain/tire field missing: $token"
    }
}
```

- [ ] **Step 2: Run static test and confirm it fails**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected result:

```text
Runtime terrain/tire field missing
```

- [ ] **Step 3: Sample terrain/tire state in `fn_applyVehicleStability.sqf`**

In the existing local-player vehicle state area, build state/settings hashmaps:

```sqf
private _terrainTireState = createHashMapFromArray [
    ["surfaceType", surfaceType (getPosWorld _vehicle)],
    ["speedKmh", abs speed _vehicle],
    ["forwardDemand", _forwardInput],
    ["brakeDemand", _brakeInput],
    ["steeringDemand", _steeringDemand],
    ["slopeSeverity", _slopeSeverity],
    ["massKg", getMass _vehicle],
    ["deltaTime", _deltaTime],
    ["tireDamage", damage _vehicle],
    ["tireAirState", _vehicle getVariable ["FIXICS_tireAirState", 1]]
];

private _terrainTireSettings = createHashMapFromArray [
    ["enabled", missionNamespace getVariable ["FIXICS_terrainTireEnabled", true]],
    ["tirePressureEnabled", missionNamespace getVariable ["FIXICS_tirePressureEnabled", true]],
    ["deflationRate", missionNamespace getVariable ["FIXICS_tireDeflationRate", 0.025]],
    ["minimumMobility", missionNamespace getVariable ["FIXICS_tireMinimumMobility", 0.35]],
    ["dragStrength", missionNamespace getVariable ["FIXICS_tireDragStrength", 0.35]],
    ["steeringPenalty", missionNamespace getVariable ["FIXICS_tireSteeringPenalty", 0.30]]
];

private _terrainTireRecommendation = [_terrainTireState, _terrainTireSettings] call FIXICS_fnc_getTerrainTireRecommendation;
_vehicle setVariable ["FIXICS_tireAirState", _terrainTireRecommendation getOrDefault ["tireAirState", 1], false];
_vehicle setVariable ["FIXICS_terrainTireRecommendation", _terrainTireRecommendation, false];
```

Use local variable names from the actual file. If `_forwardInput`, `_brakeInput`,
`_steeringDemand`, or `_slopeSeverity` have different names, map the current
equivalent values instead of creating duplicate input handling.

- [ ] **Step 4: Pass recommendation through Runtime Assist**

Add `terrainTireRecommendation` to the Runtime Assist/coordinator input hashmap:

```sqf
["terrainTireRecommendation", _terrainTireRecommendation]
```

In `fn_coordinateVehicleAssists.sqf`, copy safe values into the output:

```sqf
private _terrainTireRecommendation = _input getOrDefault ["terrainTireRecommendation", createHashMap];
private _tractionMultiplier = _terrainTireRecommendation getOrDefault ["tractionMultiplier", 1];
private _turningTractionMultiplier = _terrainTireRecommendation getOrDefault ["turningTractionMultiplier", 1];
private _brakingTractionMultiplier = _terrainTireRecommendation getOrDefault ["brakingTractionMultiplier", 1];
private _slopeTractionMultiplier = _terrainTireRecommendation getOrDefault ["slopeTractionMultiplier", 1];
private _wheelspinEstimate = _terrainTireRecommendation getOrDefault ["wheelspinEstimate", 0];
private _tireDragPenalty = _terrainTireRecommendation getOrDefault ["tireDragPenalty", 0];
private _tireSteeringPenalty = _terrainTireRecommendation getOrDefault ["tireSteeringPenalty", 0];
private _massModifier = _terrainTireRecommendation getOrDefault ["massModifier", 1];
```

Add these fields to the coordinator result hashmap.

- [ ] **Step 5: Apply only conservative bounded effects**

In the existing local mutation path, use Terrain Tire values only as multipliers:

```sqf
private _finalLateralScale = _finalLateralScale * (_terrainTireRecommendation getOrDefault ["turningTractionMultiplier", 1]);
private _finalBrakeScale = _finalBrakeScale * (_terrainTireRecommendation getOrDefault ["brakingTractionMultiplier", 1]);
private _finalSlopeScale = _finalSlopeScale * (_terrainTireRecommendation getOrDefault ["slopeTractionMultiplier", 1]);
```

If those exact scale variables do not exist, apply the same principle at the
nearest existing correction composition point. Do not add a new independent
`setVelocity` path for tire behavior.

- [ ] **Step 6: Run static test**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected result:

```text
Vehicle physics static checks passed.
```

---

### Task 5: Tire Pressure State And Debug Logging

**Files:**
- Modify: `addons/main/functions/fn_applyVehicleStability.sqf`
- Modify: `addons/main/functions/fn_logVehicleHandlingConfig.sqf`
- Test: `tests/integration/fixics-vehicle-physics-static.ps1`

- [ ] **Step 1: Add static checks for tire state persistence and debug logging**

Require these tokens:

```powershell
foreach ($token in @(
    "FIXICS_tireAirState",
    "FIXICS_terrainTireRecommendation",
    "FIXICS_tireDebugLogging",
    "tireDeflationState",
    "perWheelMode"
)) {
    if (($stabilityContent + $telemetryContent) -notmatch [regex]::Escape($token)) {
        throw "Tire pressure runtime or telemetry token missing: $token"
    }
}
```

- [ ] **Step 2: Run static test and confirm it fails if tokens are missing**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected result before implementation:

```text
Tire pressure runtime or telemetry token missing
```

- [ ] **Step 3: Persist tire air state**

After calling `FIXICS_fnc_getTerrainTireRecommendation`, persist only the air
state and recommendation snapshot:

```sqf
_vehicle setVariable ["FIXICS_tireAirState", _terrainTireRecommendation getOrDefault ["tireAirState", 1], false];
_vehicle setVariable ["FIXICS_terrainTireRecommendation", _terrainTireRecommendation, false];
```

- [ ] **Step 4: Add optional debug logging**

In the local update path, add:

```sqf
if (missionNamespace getVariable ["FIXICS_tireDebugLogging", false]) then {
    diag_log format [
        "[FIXICS][TerrainTire] vehicle=%1 surface=%2 class=%3 traction=%4 wheelspin=%5 air=%6 deflation=%7 drag=%8 steeringPenalty=%9 massModifier=%10",
        typeOf _vehicle,
        _terrainTireRecommendation getOrDefault ["surfaceType", ""],
        _terrainTireRecommendation getOrDefault ["terrainGripClass", "UNKNOWN"],
        _terrainTireRecommendation getOrDefault ["tractionMultiplier", 1],
        _terrainTireRecommendation getOrDefault ["wheelspinEstimate", 0],
        _terrainTireRecommendation getOrDefault ["tireAirState", 1],
        _terrainTireRecommendation getOrDefault ["tireDeflationState", "NONE"],
        _terrainTireRecommendation getOrDefault ["tireDragPenalty", 0],
        _terrainTireRecommendation getOrDefault ["tireSteeringPenalty", 0],
        _terrainTireRecommendation getOrDefault ["massModifier", 1]
    ];
};
```

- [ ] **Step 5: Run static test**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected result:

```text
Vehicle physics static checks passed.
```

---

### Task 6: Telemetry And Evidence Matrix

**Files:**
- Modify: `addons/main/functions/fn_logVehicleHandlingConfig.sqf`
- Modify: `docs/vehicle-behavior/sqa-evidence-matrix.md`
- Test: `tests/integration/fixics-vehicle-physics-static.ps1`

- [ ] **Step 1: Add telemetry static checks**

Require:

```powershell
foreach ($token in @(
    "terrainTireEnabled",
    "terrainTireEligible",
    "terrainTireReason",
    "surfaceType",
    "terrainGripClass",
    "tractionMultiplier",
    "wheelspinEstimate",
    "tireAirState",
    "tireDeflationState",
    "tireDragPenalty",
    "massModifier",
    "terrainTireTelemetryVersion"
)) {
    if ($telemetryContent -notmatch [regex]::Escape($token)) {
        throw "Terrain Tire telemetry field missing: $token"
    }
}
```

- [ ] **Step 2: Add telemetry fields to handling log**

Read the stored recommendation:

```sqf
private _terrainTireRecommendation = _vehicle getVariable ["FIXICS_terrainTireRecommendation", createHashMap];
```

Append compact log fields using the file's existing format pattern:

```sqf
["terrainTireEnabled", missionNamespace getVariable ["FIXICS_terrainTireEnabled", true]],
["terrainTireEligible", _terrainTireRecommendation getOrDefault ["eligible", false]],
["terrainTireReason", _terrainTireRecommendation getOrDefault ["reason", "MISSING"]],
["surfaceType", _terrainTireRecommendation getOrDefault ["surfaceType", surfaceType (getPosWorld _vehicle)]],
["terrainGripClass", _terrainTireRecommendation getOrDefault ["terrainGripClass", "UNKNOWN"]],
["tractionMultiplier", _terrainTireRecommendation getOrDefault ["tractionMultiplier", 1]],
["wheelspinEstimate", _terrainTireRecommendation getOrDefault ["wheelspinEstimate", 0]],
["tireAirState", _terrainTireRecommendation getOrDefault ["tireAirState", _vehicle getVariable ["FIXICS_tireAirState", 1]]],
["tireDeflationState", _terrainTireRecommendation getOrDefault ["tireDeflationState", "NONE"]],
["tireDragPenalty", _terrainTireRecommendation getOrDefault ["tireDragPenalty", 0]],
["tireSteeringPenalty", _terrainTireRecommendation getOrDefault ["tireSteeringPenalty", 0]],
["massModifier", _terrainTireRecommendation getOrDefault ["massModifier", 1]],
["terrainTireTelemetryVersion", _terrainTireRecommendation getOrDefault ["terrainTireTelemetryVersion", 1]]
```

- [ ] **Step 3: Update SQA evidence matrix**

Add a Terrain Tire Behavior matrix section:

```markdown
## Terrain Tire Behavior Matrix

| Vehicle | Terrain | Speed | Acceleration | Braking Turn | Slope Roll | Tire Damage | Expected Evidence | SQA Result |
|---|---|---:|---|---|---|---|---|---|
| Registered light vehicle | Paved/asphalt | 30/60/90/120 km/h | Low wheelspin, high clean grip | Stable braking, higher rollover risk at full lock | Normal slope traction | Normal | `terrainGripClass=PAVED`, high `tractionMultiplier` | Pending SQA |
| Registered light vehicle | Dirt | 30/60/90/120 km/h | Moderate wheelspin | More controlled slide | Reduced clean traction | Normal | `terrainGripClass=DIRT`, moderate `wheelspinEstimate` | Pending SQA |
| Registered light vehicle | Grass | 30/60/90/120 km/h | Higher wheelspin | More sliding | Lower traction | Normal | `terrainGripClass=GRASS`, lower `tractionMultiplier` | Pending SQA |
| Registered light vehicle | Sand | 30/60/90/120 km/h | High wheelspin, sluggish launch | Wide controlled slide | Weak climb, loose downhill roll | Normal | `terrainGripClass=SAND`, high `wheelspinEstimate` | Pending SQA |
| Registered light vehicle | Rock/rough | 30/60/90/120 km/h | Variable traction | Unstable grip transitions | Variable traction | Normal | `terrainGripClass=ROCK`, roughness reflected in multipliers | Pending SQA |
| Registered light vehicle | Any | 30/60 km/h | Sluggish after puncture | Worse steering precision | More drag | One tire hit | falling `tireAirState`, `tireDeflationState=LEAKING/RUNFLAT` | Pending SQA |
```

- [ ] **Step 4: Run static test**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected result:

```text
Vehicle physics static checks passed.
```

---

### Task 7: Full Validation And SQA Handoff

**Files:**
- Modify: `governance/audit/validation-log.md`
- Modify: `orchestration/state.md`

- [ ] **Step 1: Run required validation**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
powershell -ExecutionPolicy Bypass -File tools\check.ps1
git diff --check
```

Expected result:

```text
Governance static checks passed.
Vehicle physics static checks passed.
Terrain Tire recommendation contract passed.
No git diff whitespace errors.
```

- [ ] **Step 2: Build if SQA needs a packaged test artifact**

Run only if SQA wants to test immediately:

```powershell
powershell -ExecutionPolicy Bypass -File tools\build.ps1
```

Expected result:

```text
HEMTT build succeeds.
```

If Arma is holding `.hemttout\build`, stop and tell SQA to close Arma/unload the
addon before building again.

- [ ] **Step 3: Update validation log**

Add a dated entry to `governance/audit/validation-log.md`:

```markdown
## 2026-06-26 - Terrain Tire Behavior

- Scope: SQF-first Terrain Tire Behavior recommendation, settings, Runtime Assist integration, telemetry, and SQA evidence matrix.
- Validation:
  - `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1` - passed
  - `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1` - passed
  - `powershell -ExecutionPolicy Bypass -File tools\check.ps1` - passed
  - `git diff --check` - passed
- Manual gameplay validation: pending SQA.
```

- [ ] **Step 4: Update project state**

Add to `orchestration/state.md` under Last Decision:

```markdown
- Terrain Tire Behavior implementation was added on 2026-06-26 after SQA approved the requirements and design. It is SQF-first, local-player only, enabled by default, and adds terrain/tire/mass/deflation recommendations plus telemetry for registered FIXICS vehicles. Manual SQA gameplay validation is pending.
```

- [ ] **Step 5: Provide SQA handoff commands**

Give SQA these debug console commands:

```sqf
missionNamespace setVariable ["FIXICS_tireDebugLogging", true, false];
systemChat str (missionNamespace getVariable ["FIXICS_tireDebugLogging", false]);
```

For a 3-minute telemetry capture:

```sqf
[vehicle player, 180, 0.1] call FIXICS_fnc_logVehicleHandlingConfig;
```

Manual QA focus:

```text
1. Paved/asphalt launch, braking turn, full-lock turn.
2. Dirt/grass/sand launch and braking turn.
3. Rock/rough transition if map terrain exposes it.
4. Slope rolling and slope climbing on paved versus loose terrain.
5. Shoot one tire once, then drive at low and medium speed.
6. Confirm tire remains movable but slower, draggier, and less precise.
7. Confirm ABS, Drive/Reverse, ACE handbrake, Roll Stability, Sway Bar, Stability, and Controlled Slip still behave normally.
```

---

## Self-Review Notes

- Spec coverage:
  - New layer: Task 2 and Task 4.
  - Terrain categories: Task 2.
  - Acceleration, braking, turning, slope traction: Task 2 and Task 4.
  - Tire pressure and run-flat behavior: Task 2 and Task 5.
  - CBA settings: Task 3.
  - Telemetry: Task 6.
  - SQA evidence matrix: Task 6.
  - Validation and handoff: Task 7.
- Deferred scope:
  - Wet/mud terrain remains deferred.
  - Config tire/friction patches remain deferred.
  - Multiplayer authority remains deferred.
  - Native extension authority remains deferred.
