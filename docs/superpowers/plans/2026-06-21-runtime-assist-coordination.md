# Runtime Assist Coordination Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a local-player Runtime Assist Coordinator that lets ABS, slope rollback, driver intent, Vehicle Stability Assistance, Roll Stability Assist, terrain effects, presets, telemetry, and native advisory math resolve through one ordered layer.

**Architecture:** Keep accepted subsystem ownership intact. Add one pure recommendation helper and one coordinator/mutation boundary, then route the driver controller through it after existing ABS/slope/stability recommendation work is available. The coordinator applies conservative terrain/mass modifiers, keeps roll/stability priority above ABS/slope composition, and records why assists were applied, reduced, or suppressed.

**Tech Stack:** Arma 3 SQF, CBA settings, ACE/CBA runtime dependencies, HEMTT, PowerShell static/unit tests, FIXICS telemetry logs.

---

## File Map

- Modify `addons/main/config.cpp`: register new coordinator functions.
- Create `addons/main/functions/fn_getRuntimeAssistRecommendation.sqf`: pure bounded coordination math.
- Create `addons/main/functions/fn_coordinateVehicleAssists.sqf`: local mutation/arbitration boundary and telemetry state writer.
- Modify `addons/main/functions/fn_updateDriverController.sqf`: call the coordinator finalizer instead of calling stability directly.
- Modify `addons/main/functions/fn_applyVehicleStability.sqf`: expose recommendation state for coordinator telemetry while preserving existing mutation behavior until the coordinator takes over.
- Modify `addons/main/functions/fn_applyABSBraking.sqf`: store the latest ABS recommendation metadata for coordinator telemetry.
- Modify `addons/main/functions/fn_applySlopeRollback.sqf`: support coordinator damping while service braking and store slope metadata.
- Modify `addons/main/functions/fn_registerSettings.sqf`: add conservative global coordinator settings.
- Modify `addons/main/functions/fn_logVehicleHandlingConfig.sqf`: add coordinator telemetry fields to one-shot and continuous logs.
- Modify `addons/main/stringtable.xml`: add labels and tooltips for coordinator settings.
- Modify `tests/integration/fixics-vehicle-physics-static.ps1`: static contracts for registration, purity, settings, integration, telemetry, and ownership boundaries.
- Create `tests/unit/fixics-runtime-assist-recommendation.ps1`: source-derived and mirrored behavior checks for the pure recommendation helper.
- Modify `tools/check.ps1`: run the new unit test.
- Modify `docs/vehicle-behavior/sqa-evidence-matrix.md`: add SQA matrix rows/templates for coordinator validation.
- Modify `governance/audit/validation-log.md`: record validation results.
- Modify `orchestration/state.md`: record implementation state and next SQA gate.

---

### Task 1: Add Static Contract For Coordinator Surface

**Files:**
- Modify: `tests/integration/fixics-vehicle-physics-static.ps1`
- Test: `tests/integration/fixics-vehicle-physics-static.ps1`

- [ ] **Step 1: Add expected files and registrations**

Add these assertions near the existing `CfgFunctions` assertions:

```powershell
Assert-FileExists 'addons\main\functions\fn_getRuntimeAssistRecommendation.sqf'
Assert-FileExists 'addons\main\functions\fn_coordinateVehicleAssists.sqf'
Assert-Contains $Config 'class getRuntimeAssistRecommendation\s*\{\s*\};' 'Runtime assist recommendation must be registered in CfgFunctions.'
Assert-Contains $Config 'class coordinateVehicleAssists\s*\{\s*\};' 'Runtime assist coordinator must be registered in CfgFunctions.'
```

- [ ] **Step 2: Add settings and localization contracts**

Add after current stability/roll setting checks:

```powershell
$RegisterSettingsPath = Join-Path $RepoRoot 'addons\main\functions\fn_registerSettings.sqf'
$RegisterSettings = Get-Content -Raw -LiteralPath $RegisterSettingsPath

@(
    'FIXICS_runtimeAssistCoordinatorEnabled',
    'FIXICS_runtimeAssistTerrainInfluenceEnabled',
    'FIXICS_runtimeAssistTerrainInfluenceStrength',
    'FIXICS_runtimeAssistBrakingSlopeRetention',
    'FIXICS_runtimeAssistMassDampingStrength',
    'FIXICS_runtimeAssistMaximumComposedCorrection',
    'FIXICS_runtimeAssistDebugLogging'
) | ForEach-Object {
    Assert-Contains $RegisterSettings $_ "Runtime Assist setting $_ must be registered."
    Assert-Contains $Stringtable $_ "Runtime Assist setting $_ must have localized text."
}

Assert-Contains $RegisterSettings 'missionNamespace setVariable \["FIXICS_runtimeAssistCoordinatorEnabled", true, false\]' 'Runtime Assist coordinator must default enabled.'
Assert-Contains $RegisterSettings 'missionNamespace setVariable \["FIXICS_runtimeAssistBrakingSlopeRetention", 0\.35, false\]' 'Runtime Assist braking slope retention must default conservative.'
Assert-Contains $RegisterSettings '\["FIXICS", "Runtime Assist"\]' 'Runtime Assist settings must use their own FIXICS Global category.'
```

- [ ] **Step 3: Add pure recommendation contract**

Add:

```powershell
$RuntimeRecommendationFile = Join-Path $RepoRoot 'addons\main\functions\fn_getRuntimeAssistRecommendation.sqf'
if (Test-Path -LiteralPath $RuntimeRecommendationFile) {
    $RuntimeRecommendation = Get-Content -Raw -LiteralPath $RuntimeRecommendationFile
    Assert-Contains $RuntimeRecommendation '\bparams\b' 'Runtime recommendation must declare parameters.'
    Assert-Contains $RuntimeRecommendation 'priorityWinner' 'Runtime recommendation must expose a priority winner.'
    Assert-Contains $RuntimeRecommendation 'terrainMultiplier' 'Runtime recommendation must expose terrain multiplier.'
    Assert-Contains $RuntimeRecommendation 'massMultiplier' 'Runtime recommendation must expose mass multiplier.'
    Assert-Contains $RuntimeRecommendation 'slopeRetention' 'Runtime recommendation must expose braking slope retention.'
    Assert-Contains $RuntimeRecommendation 'suppressedAssists' 'Runtime recommendation must expose suppressed or reduced assists.'
    Assert-Contains $RuntimeRecommendation 'finalCorrection' 'Runtime recommendation must expose final correction summary.'
    Assert-Contains $RuntimeRecommendation '\bfinite\b' 'Runtime recommendation must reject non-finite numeric inputs.'
    if ($RuntimeRecommendation -match '\b(setVelocity|setVelocityModelSpace|setDir|setVectorDirAndUp|disableBrakes|setVariable|publicVariable|remoteExec|remoteExecCall|callExtension)\b') {
        Add-Failure 'Runtime recommendation must remain pure and must not mutate objects, network state, brakes, or native extension state.'
    }
}
```

- [ ] **Step 4: Add coordinator mutation boundary contract**

Add:

```powershell
$RuntimeCoordinatorFile = Join-Path $RepoRoot 'addons\main\functions\fn_coordinateVehicleAssists.sqf'
if (Test-Path -LiteralPath $RuntimeCoordinatorFile) {
    $RuntimeCoordinator = Get-Content -Raw -LiteralPath $RuntimeCoordinatorFile
    Assert-Contains $RuntimeCoordinator 'driver _vehicle == player' 'Runtime coordinator must require the local player driver.'
    Assert-Contains $RuntimeCoordinator 'local _vehicle' 'Runtime coordinator must require local vehicle ownership.'
    Assert-Contains $RuntimeCoordinator 'FIXICS_handbrakeEnabled' 'Runtime coordinator must respect persistent FIXICS handbrake priority.'
    Assert-Contains $RuntimeCoordinator 'FIXICS_fnc_getRuntimeAssistRecommendation' 'Runtime coordinator must call the pure recommendation helper.'
    Assert-Contains $RuntimeCoordinator 'FIXICS_runtimeAssistLastDecision' 'Runtime coordinator must store last decision telemetry.'
    Assert-Contains $RuntimeCoordinator 'FIXICS_runtimeAssistDebugLogging' 'Runtime coordinator must support explicit debug logging.'
    Assert-Contains $RuntimeCoordinator 'velocityModelSpace _vehicle' 'Runtime coordinator must work in model-space velocity.'
    if ($RuntimeCoordinator -match '\b(setDir|setVectorDirAndUp|remoteExec|remoteExecCall|publicVariable)\b') {
        Add-Failure 'Runtime coordinator must not mutate orientation or network state.'
    }
}
```

- [ ] **Step 5: Add integration contracts**

Add:

```powershell
$DriverControllerFile = Join-Path $RepoRoot 'addons\main\functions\fn_updateDriverController.sqf'
$DriverController = Get-Content -Raw -LiteralPath $DriverControllerFile
Assert-Contains $DriverController 'FIXICS_fnc_coordinateVehicleAssists' 'Driver controller finalizer must route through Runtime Assist Coordinator.'

$AbsFile = Join-Path $RepoRoot 'addons\main\functions\fn_applyABSBraking.sqf'
$Abs = Get-Content -Raw -LiteralPath $AbsFile
Assert-Contains $Abs 'FIXICS_absLastDecision' 'ABS must store last decision metadata for Runtime Assist telemetry.'

$SlopeFile = Join-Path $RepoRoot 'addons\main\functions\fn_applySlopeRollback.sqf'
$Slope = Get-Content -Raw -LiteralPath $SlopeFile
Assert-Contains $Slope 'FIXICS_slopeLastDecision' 'Slope rollback must store last decision metadata for Runtime Assist telemetry.'
Assert-Contains $Slope 'FIXICS_runtimeAssistBrakingSlopeRetention' 'Slope rollback must allow reduced, not disabled, slope acceleration while service braking.'

$HandlingConfigLogFile = Join-Path $RepoRoot 'addons\main\functions\fn_logVehicleHandlingConfig.sqf'
$HandlingConfigLog = Get-Content -Raw -LiteralPath $HandlingConfigLogFile
@(
    'FIXICS_runtimeAssistLastDecision',
    'runtimeAssistPriorityWinner',
    'runtimeAssistTerrainMultiplier',
    'runtimeAssistMassMultiplier',
    'runtimeAssistSuppressedAssists',
    'runtimeAssistFinalCorrection'
) | ForEach-Object {
    Assert-Contains $HandlingConfigLog $_ "Handling telemetry must include $_."
}
```

- [ ] **Step 6: Run static test and confirm failure**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: FAIL for missing coordinator files, registrations, settings, metadata, and telemetry fields.

- [ ] **Step 7: Commit the failing contract**

```powershell
git add tests\integration\fixics-vehicle-physics-static.ps1
git commit -m "test: add runtime assist coordination contract"
```

---

### Task 2: Add Pure Runtime Assist Recommendation Math

**Files:**
- Create: `addons/main/functions/fn_getRuntimeAssistRecommendation.sqf`
- Modify: `addons/main/config.cpp`
- Create: `tests/unit/fixics-runtime-assist-recommendation.ps1`
- Modify: `tools/check.ps1`
- Test: `tests/unit/fixics-runtime-assist-recommendation.ps1`

- [ ] **Step 1: Create failing unit test**

Create `tests/unit/fixics-runtime-assist-recommendation.ps1`:

```powershell
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$FunctionPath = Join-Path $RepoRoot 'addons\main\functions\fn_getRuntimeAssistRecommendation.sqf'
$Failures = New-Object System.Collections.Generic.List[string]

function Add-Failure {
    param ([Parameter(Mandatory = $true)][string]$Message)
    $Failures.Add($Message)
}

function Assert-Contains {
    param (
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$Message
    )
    if ($Content -notmatch $Pattern) {
        Add-Failure $Message
    }
}

function Test-Finite {
    param ([double]$Value)
    return -not ([double]::IsNaN($Value) -or [double]::IsInfinity($Value))
}

function Get-RecommendationMirror {
    param (
        [hashtable]$State,
        [hashtable]$Settings
    )

    foreach ($Name in @('SpeedKmh', 'TerrainFriction', 'MassKg', 'SlopeDelta', 'StabilityDelta', 'RollDelta')) {
        if (-not (Test-Finite ([double]$State[$Name]))) {
            return @{
                Applied = $false
                PriorityWinner = 'invalid'
                TerrainMultiplier = 1.0
                MassMultiplier = 1.0
                SlopeRetention = 1.0
                SuppressedAssists = @('invalid')
                FinalCorrection = 0.0
            }
        }
    }

    [double]$TerrainStrength = [math]::Min([math]::Max([double]$Settings.TerrainInfluenceStrength, 0.0), 1.0)
    [double]$BrakingSlopeRetention = [math]::Min([math]::Max([double]$Settings.BrakingSlopeRetention, 0.0), 1.0)
    [double]$MassDampingStrength = [math]::Min([math]::Max([double]$Settings.MassDampingStrength, 0.0), 1.0)
    [double]$MaximumComposedCorrection = [math]::Min([math]::Max([double]$Settings.MaximumComposedCorrection, 0.0), 0.5)

    $TerrainMultiplier = 1.0
    if ($Settings.TerrainInfluenceEnabled) {
        $TerrainMultiplier = 1.0 - ((1.0 - [double]$State.TerrainFriction) * $TerrainStrength)
        $TerrainMultiplier = [math]::Min([math]::Max($TerrainMultiplier, 0.35), 1.0)
    }

    $MassMultiplier = 1.0 - ([math]::Min([math]::Max(([double]$State.MassKg - 1200.0) / 2800.0, 0.0), 1.0) * $MassDampingStrength)
    $MassMultiplier = [math]::Min([math]::Max($MassMultiplier, 0.45), 1.0)

    $Suppressed = @()
    $SlopeDelta = [double]$State.SlopeDelta
    if ($State.ServiceBraking) {
        $SlopeDelta *= $BrakingSlopeRetention
        $Suppressed += 'slope-reduced-by-service-brake'
    }

    $PriorityWinner = 'none'
    $FinalCorrection = 0.0
    if ([math]::Abs([double]$State.RollDelta) -gt 0.0) {
        $PriorityWinner = 'roll'
        $FinalCorrection = [double]$State.RollDelta
    } elseif ([math]::Abs([double]$State.StabilityDelta) -gt 0.0) {
        $PriorityWinner = 'stability'
        $FinalCorrection = [double]$State.StabilityDelta
    } elseif ([math]::Abs($SlopeDelta) -gt 0.0) {
        $PriorityWinner = 'slope'
        $FinalCorrection = $SlopeDelta
    }

    $FinalCorrection *= $TerrainMultiplier * $MassMultiplier
    $FinalCorrection = [math]::Min([math]::Max($FinalCorrection, -$MaximumComposedCorrection), $MaximumComposedCorrection)

    return @{
        Applied = [math]::Abs($FinalCorrection) -gt 0.0
        PriorityWinner = $PriorityWinner
        TerrainMultiplier = $TerrainMultiplier
        MassMultiplier = $MassMultiplier
        SlopeRetention = if ($State.ServiceBraking) { $BrakingSlopeRetention } else { 1.0 }
        SuppressedAssists = $Suppressed
        FinalCorrection = $FinalCorrection
    }
}

function Assert-Near {
    param ([double]$Actual, [double]$Expected, [string]$Message)
    if ([math]::Abs($Actual - $Expected) -gt 0.000001) {
        Add-Failure "$Message Expected $Expected, got $Actual."
    }
}

$BaseSettings = @{
    TerrainInfluenceEnabled = $true
    TerrainInfluenceStrength = 0.25
    BrakingSlopeRetention = 0.35
    MassDampingStrength = 0.15
    MaximumComposedCorrection = 0.25
}

$RollCase = Get-RecommendationMirror @{
    SpeedKmh = 90.0
    TerrainFriction = 0.8
    MassKg = 1600.0
    ServiceBraking = $false
    SlopeDelta = 0.12
    StabilityDelta = 0.18
    RollDelta = -0.2
} $BaseSettings

if ($RollCase.PriorityWinner -ne 'roll') { Add-Failure 'Roll must win over stability and slope.' }
Assert-Near ([double]$RollCase.FinalCorrection) -0.185714285714286 'Roll final correction mismatch.'

$BrakeCase = Get-RecommendationMirror @{
    SpeedKmh = 50.0
    TerrainFriction = 1.0
    MassKg = 1200.0
    ServiceBraking = $true
    SlopeDelta = 0.2
    StabilityDelta = 0.0
    RollDelta = 0.0
} $BaseSettings

if ($BrakeCase.PriorityWinner -ne 'slope') { Add-Failure 'Slope must remain active under service braking when no roll/stability correction exists.' }
Assert-Near ([double]$BrakeCase.FinalCorrection) 0.07 'Service braking must reduce, not disable, slope correction.'
if (-not ($BrakeCase.SuppressedAssists -contains 'slope-reduced-by-service-brake')) {
    Add-Failure 'Service braking must record slope reduction.'
}

$TerrainCase = Get-RecommendationMirror @{
    SpeedKmh = 80.0
    TerrainFriction = 0.5
    MassKg = 4000.0
    ServiceBraking = $false
    SlopeDelta = 0.3
    StabilityDelta = 0.0
    RollDelta = 0.0
} $BaseSettings

Assert-Near ([double]$TerrainCase.TerrainMultiplier) 0.875 'Terrain multiplier mismatch.'
Assert-Near ([double]$TerrainCase.MassMultiplier) 0.85 'Mass multiplier mismatch.'
Assert-Near ([double]$TerrainCase.FinalCorrection) 0.223125 'Terrain/mass bounded correction mismatch.'

if (-not (Test-Path -LiteralPath $FunctionPath)) {
    Add-Failure 'Missing expected file: addons\main\functions\fn_getRuntimeAssistRecommendation.sqf'
} else {
    $Source = Get-Content -Raw -LiteralPath $FunctionPath
    Assert-Contains $Source '\bparams\s*\[' 'Runtime recommendation must declare parameters.'
    Assert-Contains $Source '_terrainMultiplier' 'Runtime recommendation must calculate terrain multiplier.'
    Assert-Contains $Source '_massMultiplier' 'Runtime recommendation must calculate mass multiplier.'
    Assert-Contains $Source '_slopeRetention' 'Runtime recommendation must calculate slope retention.'
    Assert-Contains $Source '_priorityWinner' 'Runtime recommendation must select a priority winner.'
    Assert-Contains $Source '_suppressedAssists' 'Runtime recommendation must list suppressed or reduced assists.'
    Assert-Contains $Source '_finalCorrection' 'Runtime recommendation must calculate final correction.'
    Assert-Contains $Source '"roll"[\s\S]*?"stability"[\s\S]*?"slope"' 'Priority order must be roll, stability, then slope.'
    Assert-Contains $Source 'slope-reduced-by-service-brake' 'Service braking must reduce slope assist visibly.'
    Assert-Contains $Source '\bfinite\b' 'Runtime recommendation must reject non-finite inputs.'
    if ($Source -match '\b(setVelocity|setVelocityModelSpace|setDir|setVectorDirAndUp|disableBrakes|setVariable|publicVariable|remoteExec|remoteExecCall|callExtension)\b') {
        Add-Failure 'Runtime recommendation must remain pure and must not mutate objects, network state, brakes, or native extension state.'
    }
}

if ($Failures.Count -gt 0) {
    Write-Host 'FIXICS runtime assist recommendation unit test failed:'
    foreach ($Failure in $Failures) {
        Write-Host " - $Failure"
    }
    exit 1
}

Write-Host 'FIXICS runtime assist recommendation unit test passed.'
```

- [ ] **Step 2: Run unit test and confirm failure**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\unit\fixics-runtime-assist-recommendation.ps1
```

Expected: FAIL because `fn_getRuntimeAssistRecommendation.sqf` does not exist.

- [ ] **Step 3: Implement pure recommendation helper**

Create `addons/main/functions/fn_getRuntimeAssistRecommendation.sqf`:

```sqf
/*
 * FIXICS_fnc_getRuntimeAssistRecommendation
 *
 * Pure coordinator math for composing assist recommendations.
 *
 * Arguments:
 *   0: State hashmap <HASHMAP>
 *   1: Settings hashmap <HASHMAP>
 *
 * Return:
 *   HashMap with applied, priorityWinner, terrainMultiplier, massMultiplier,
 *   slopeRetention, suppressedAssists, finalCorrection.
 */
params [
    ["_state", createHashMap, [createHashMap]],
    ["_settings", createHashMap, [createHashMap]]
];

private _safeNumber = {
    params ["_map", "_key", "_default"];
    private _value = _map getOrDefault [_key, _default];
    if !(_value isEqualType 0) exitWith {
        _default
    };
    if (!finite _value) exitWith {
        _default
    };
    _value
};

private _invalid = createHashMapFromArray [
    ["applied", false],
    ["priorityWinner", "invalid"],
    ["terrainMultiplier", 1],
    ["massMultiplier", 1],
    ["slopeRetention", 1],
    ["suppressedAssists", ["invalid"]],
    ["finalCorrection", 0]
];

private _speedKmh = [_state, "speedKmh", 0] call _safeNumber;
private _terrainFriction = [_state, "terrainFriction", 1] call _safeNumber;
private _massKg = [_state, "massKg", 1200] call _safeNumber;
private _slopeDelta = [_state, "slopeDelta", 0] call _safeNumber;
private _stabilityDelta = [_state, "stabilityDelta", 0] call _safeNumber;
private _rollDelta = [_state, "rollDelta", 0] call _safeNumber;

if (
    !finite _speedKmh
    || {!finite _terrainFriction}
    || {!finite _massKg}
    || {!finite _slopeDelta}
    || {!finite _stabilityDelta}
    || {!finite _rollDelta}
) exitWith {
    _invalid
};

private _terrainInfluenceEnabled = _settings getOrDefault ["terrainInfluenceEnabled", true];
private _terrainInfluenceStrength = ([_settings, "terrainInfluenceStrength", 0.25] call _safeNumber) max 0 min 1;
private _brakingSlopeRetention = ([_settings, "brakingSlopeRetention", 0.35] call _safeNumber) max 0 min 1;
private _massDampingStrength = ([_settings, "massDampingStrength", 0.15] call _safeNumber) max 0 min 1;
private _maximumComposedCorrection = ([_settings, "maximumComposedCorrection", 0.25] call _safeNumber) max 0 min 0.5;

private _terrainMultiplier = 1;
if (_terrainInfluenceEnabled) then {
    _terrainFriction = _terrainFriction max 0 min 1;
    _terrainMultiplier = 1 - ((1 - _terrainFriction) * _terrainInfluenceStrength);
    _terrainMultiplier = _terrainMultiplier max 0.35 min 1;
};

private _massMultiplier = 1 - (((((_massKg - 1200) / 2800) max 0) min 1) * _massDampingStrength);
_massMultiplier = _massMultiplier max 0.45 min 1;

private _serviceBraking = _state getOrDefault ["serviceBraking", false];
private _suppressedAssists = [];
private _slopeRetention = 1;
if (_serviceBraking) then {
    _slopeRetention = _brakingSlopeRetention;
    _slopeDelta = _slopeDelta * _slopeRetention;
    _suppressedAssists pushBack "slope-reduced-by-service-brake";
};

private _priorityWinner = "none";
private _finalCorrection = 0;
if ((abs _rollDelta) > 0) then {
    _priorityWinner = "roll";
    _finalCorrection = _rollDelta;
} else {
    if ((abs _stabilityDelta) > 0) then {
        _priorityWinner = "stability";
        _finalCorrection = _stabilityDelta;
    } else {
        if ((abs _slopeDelta) > 0) then {
            _priorityWinner = "slope";
            _finalCorrection = _slopeDelta;
        };
    };
};

_finalCorrection = _finalCorrection * _terrainMultiplier * _massMultiplier;
_finalCorrection = (_finalCorrection max -_maximumComposedCorrection) min _maximumComposedCorrection;

createHashMapFromArray [
    ["applied", (abs _finalCorrection) > 0],
    ["priorityWinner", _priorityWinner],
    ["terrainMultiplier", _terrainMultiplier],
    ["massMultiplier", _massMultiplier],
    ["slopeRetention", _slopeRetention],
    ["suppressedAssists", _suppressedAssists],
    ["finalCorrection", _finalCorrection]
]
```

- [ ] **Step 4: Register helper**

In `addons/main/config.cpp`, add:

```cpp
class getRuntimeAssistRecommendation {};
```

- [ ] **Step 5: Add unit test to check gate**

In `tools/check.ps1`, after the roll test:

```powershell
& powershell -ExecutionPolicy Bypass -File tests\unit\fixics-runtime-assist-recommendation.ps1
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
```

- [ ] **Step 6: Verify unit test**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\unit\fixics-runtime-assist-recommendation.ps1
```

Expected: PASS.

- [ ] **Step 7: Commit**

```powershell
git add addons\main\config.cpp addons\main\functions\fn_getRuntimeAssistRecommendation.sqf tests\unit\fixics-runtime-assist-recommendation.ps1 tools\check.ps1
git commit -m "feat: add runtime assist recommendation math"
```

---

### Task 3: Add Runtime Assist Settings And Localization

**Files:**
- Modify: `addons/main/functions/fn_registerSettings.sqf`
- Modify: `addons/main/stringtable.xml`
- Test: `tests/integration/fixics-vehicle-physics-static.ps1`

- [ ] **Step 1: Add default missionNamespace values**

In `addons/main/functions/fn_registerSettings.sqf`, after current roll/stability defaults, add:

```sqf
missionNamespace setVariable ["FIXICS_runtimeAssistCoordinatorEnabled", true, false];
missionNamespace setVariable ["FIXICS_runtimeAssistTerrainInfluenceEnabled", true, false];
missionNamespace setVariable ["FIXICS_runtimeAssistTerrainInfluenceStrength", 0.25, false];
missionNamespace setVariable ["FIXICS_runtimeAssistBrakingSlopeRetention", 0.35, false];
missionNamespace setVariable ["FIXICS_runtimeAssistMassDampingStrength", 0.15, false];
missionNamespace setVariable ["FIXICS_runtimeAssistMaximumComposedCorrection", 0.25, false];
missionNamespace setVariable ["FIXICS_runtimeAssistDebugLogging", false, false];
```

- [ ] **Step 2: Register CBA settings**

Add after `FIXICS_stabilityDebugLogging`:

```sqf
[
    "FIXICS_runtimeAssistCoordinatorEnabled",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_RUNTIME_COORDINATOR_ENABLED",
        localize "STR_FIXICS_SETTING_RUNTIME_COORDINATOR_ENABLED_TOOLTIP"
    ],
    ["FIXICS", "Runtime Assist"],
    true,
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_runtimeAssistTerrainInfluenceEnabled",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_RUNTIME_TERRAIN_ENABLED",
        localize "STR_FIXICS_SETTING_RUNTIME_TERRAIN_ENABLED_TOOLTIP"
    ],
    ["FIXICS", "Runtime Assist"],
    true,
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_runtimeAssistTerrainInfluenceStrength",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_RUNTIME_TERRAIN_STRENGTH",
        localize "STR_FIXICS_SETTING_RUNTIME_TERRAIN_STRENGTH_TOOLTIP"
    ],
    ["FIXICS", "Runtime Assist"],
    [0, 1, 0.25, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_runtimeAssistBrakingSlopeRetention",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_RUNTIME_BRAKING_SLOPE_RETENTION",
        localize "STR_FIXICS_SETTING_RUNTIME_BRAKING_SLOPE_RETENTION_TOOLTIP"
    ],
    ["FIXICS", "Runtime Assist"],
    [0, 1, 0.35, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_runtimeAssistMassDampingStrength",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_RUNTIME_MASS_DAMPING",
        localize "STR_FIXICS_SETTING_RUNTIME_MASS_DAMPING_TOOLTIP"
    ],
    ["FIXICS", "Runtime Assist"],
    [0, 1, 0.15, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_runtimeAssistMaximumComposedCorrection",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_RUNTIME_MAX_CORRECTION",
        localize "STR_FIXICS_SETTING_RUNTIME_MAX_CORRECTION_TOOLTIP"
    ],
    ["FIXICS", "Runtime Assist"],
    [0, 0.5, 0.25, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_runtimeAssistDebugLogging",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_RUNTIME_DEBUG_LOGGING",
        localize "STR_FIXICS_SETTING_RUNTIME_DEBUG_LOGGING_TOOLTIP"
    ],
    ["FIXICS", "Runtime Assist"],
    false,
    1
] call CBA_fnc_addSetting;
```

- [ ] **Step 3: Add stringtable keys**

Add to `addons/main/stringtable.xml`:

```xml
<Key ID="STR_FIXICS_SETTING_RUNTIME_COORDINATOR_ENABLED">
    <Original>Runtime assist coordinator</Original>
</Key>
<Key ID="STR_FIXICS_SETTING_RUNTIME_COORDINATOR_ENABLED_TOOLTIP">
    <Original>Enables the local coordination layer that aligns ABS, slope, stability, roll, terrain, mass, and native advisory decisions.</Original>
</Key>
<Key ID="STR_FIXICS_SETTING_RUNTIME_TERRAIN_ENABLED">
    <Original>Terrain influence</Original>
</Key>
<Key ID="STR_FIXICS_SETTING_RUNTIME_TERRAIN_ENABLED_TOOLTIP">
    <Original>Lets surface conditions reduce assist strength so dirt and grass preserve more controlled sliding than paved roads.</Original>
</Key>
<Key ID="STR_FIXICS_SETTING_RUNTIME_TERRAIN_STRENGTH">
    <Original>Terrain influence strength</Original>
</Key>
<Key ID="STR_FIXICS_SETTING_RUNTIME_TERRAIN_STRENGTH_TOOLTIP">
    <Original>How strongly terrain modifies coordinated assist strength. Conservative defaults keep existing handling familiar.</Original>
</Key>
<Key ID="STR_FIXICS_SETTING_RUNTIME_BRAKING_SLOPE_RETENTION">
    <Original>Braking slope retention</Original>
</Key>
<Key ID="STR_FIXICS_SETTING_RUNTIME_BRAKING_SLOPE_RETENTION_TOOLTIP">
    <Original>How much downhill slope acceleration remains while the service brake is held. Zero fully suppresses slope assist; one leaves it unchanged.</Original>
</Key>
<Key ID="STR_FIXICS_SETTING_RUNTIME_MASS_DAMPING">
    <Original>Mass damping influence</Original>
</Key>
<Key ID="STR_FIXICS_SETTING_RUNTIME_MASS_DAMPING_TOOLTIP">
    <Original>Reduces abrupt correction on heavier vehicles so coordination behaves more like damping than snapping.</Original>
</Key>
<Key ID="STR_FIXICS_SETTING_RUNTIME_MAX_CORRECTION">
    <Original>Maximum composed correction</Original>
</Key>
<Key ID="STR_FIXICS_SETTING_RUNTIME_MAX_CORRECTION_TOOLTIP">
    <Original>Maximum final correction the coordinator can apply per update after priority, terrain, mass, and braking modifiers.</Original>
</Key>
<Key ID="STR_FIXICS_SETTING_RUNTIME_DEBUG_LOGGING">
    <Original>Runtime assist debug logging</Original>
</Key>
<Key ID="STR_FIXICS_SETTING_RUNTIME_DEBUG_LOGGING_TOOLTIP">
    <Original>Writes coordinator priority, suppression, terrain, mass, and final correction decisions to the RPT for SQA evidence.</Original>
</Key>
```

- [ ] **Step 4: Run static test**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: settings/localization assertions PASS; coordinator integration assertions still FAIL.

- [ ] **Step 5: Commit**

```powershell
git add addons\main\functions\fn_registerSettings.sqf addons\main\stringtable.xml
git commit -m "feat: add runtime assist settings"
```

---

### Task 4: Implement Coordinator Mutation Boundary

**Files:**
- Create: `addons/main/functions/fn_coordinateVehicleAssists.sqf`
- Modify: `addons/main/config.cpp`
- Test: `tests/integration/fixics-vehicle-physics-static.ps1`

- [ ] **Step 1: Implement coordinator shell with hard gates**

Create `addons/main/functions/fn_coordinateVehicleAssists.sqf`:

```sqf
/*
 * FIXICS_fnc_coordinateVehicleAssists
 *
 * Applies final local Runtime Assist coordination after subsystem updates.
 *
 * Arguments:
 *   0: Vehicle <OBJECT>
 *   1: Delta time <NUMBER>
 *   2: Driver state <STRING>
 *
 * Return: <BOOL> true when the coordinator changed or recorded a decision
 */
params [
    ["_vehicle", objNull, [objNull]],
    ["_deltaTime", 0, [0]],
    ["_driverState", "", [""]]
];

if (!(missionNamespace getVariable ["FIXICS_runtimeAssistCoordinatorEnabled", true])) exitWith {
    false
};
if (isNull _vehicle) exitWith {
    false
};
if (!(_vehicle isKindOf "LandVehicle")) exitWith {
    false
};
if (!local _vehicle) exitWith {
    false
};
if (!(hasInterface && {driver _vehicle == player})) exitWith {
    false
};

private _decision = createHashMapFromArray [
    ["enabled", true],
    ["eligible", false],
    ["priorityWinner", "none"],
    ["terrainMultiplier", 1],
    ["massMultiplier", 1],
    ["slopeRetention", 1],
    ["suppressedAssists", []],
    ["finalCorrection", 0],
    ["nativeAdvisory", "ignored"]
];

if (_vehicle getVariable ["FIXICS_handbrakeEnabled", false]) exitWith {
    _decision set ["eligible", false];
    _decision set ["priorityWinner", "handbrake"];
    _vehicle setVariable ["FIXICS_runtimeAssistLastDecision", _decision, false];
    false
};
```

- [ ] **Step 2: Add terrain and mass classification**

Append:

```sqf
private _surface = surfaceType (getPosWorld _vehicle);
private _terrainFriction = switch (true) do {
    case (_surface find "#GdtAsphalt" >= 0): {1};
    case (_surface find "#GdtConcrete" >= 0): {1};
    case (_surface find "#GdtDirt" >= 0): {0.82};
    case (_surface find "#GdtGrass" >= 0): {0.68};
    default {0.75};
};

private _massKg = getMass _vehicle;
if (!finite _massKg || {_massKg <= 0}) then {
    _massKg = getNumber (configOf _vehicle >> "mass");
};
if (!finite _massKg || {_massKg <= 0}) then {
    _massKg = 1200;
};
```

- [ ] **Step 3: Read subsystem metadata and call pure helper**

Append:

```sqf
private _velocityModel = velocityModelSpace _vehicle;
private _speedKmh = (abs (_velocityModel # 1)) * 3.6;
private _absDecision = _vehicle getVariable ["FIXICS_absLastDecision", createHashMap];
private _slopeDecision = _vehicle getVariable ["FIXICS_slopeLastDecision", createHashMap];
private _stabilityDecision = _vehicle getVariable ["FIXICS_stabilityLastDecision", createHashMap];

private _state = createHashMapFromArray [
    ["speedKmh", _speedKmh],
    ["terrainFriction", _terrainFriction],
    ["massKg", _massKg],
    ["serviceBraking", _driverState == "SERVICE_BRAKE"],
    ["slopeDelta", _slopeDecision getOrDefault ["delta", 0]],
    ["stabilityDelta", _stabilityDecision getOrDefault ["lateralDelta", 0]],
    ["rollDelta", _stabilityDecision getOrDefault ["rollDelta", 0]]
];

private _settings = createHashMapFromArray [
    ["terrainInfluenceEnabled", missionNamespace getVariable ["FIXICS_runtimeAssistTerrainInfluenceEnabled", true]],
    ["terrainInfluenceStrength", missionNamespace getVariable ["FIXICS_runtimeAssistTerrainInfluenceStrength", 0.25]],
    ["brakingSlopeRetention", missionNamespace getVariable ["FIXICS_runtimeAssistBrakingSlopeRetention", 0.35]],
    ["massDampingStrength", missionNamespace getVariable ["FIXICS_runtimeAssistMassDampingStrength", 0.15]],
    ["maximumComposedCorrection", missionNamespace getVariable ["FIXICS_runtimeAssistMaximumComposedCorrection", 0.25]]
];

private _recommendation = [_state, _settings] call FIXICS_fnc_getRuntimeAssistRecommendation;
```

- [ ] **Step 4: Store decision telemetry and keep mutation conservative**

Append:

```sqf
_decision set ["eligible", true];
_decision set ["priorityWinner", _recommendation getOrDefault ["priorityWinner", "none"]];
_decision set ["terrainMultiplier", _recommendation getOrDefault ["terrainMultiplier", 1]];
_decision set ["massMultiplier", _recommendation getOrDefault ["massMultiplier", 1]];
_decision set ["slopeRetention", _recommendation getOrDefault ["slopeRetention", 1]];
_decision set ["suppressedAssists", _recommendation getOrDefault ["suppressedAssists", []]];
_decision set ["finalCorrection", _recommendation getOrDefault ["finalCorrection", 0]];
_decision set ["nativeAdvisory", "advisory-only"];

_vehicle setVariable ["FIXICS_runtimeAssistLastDecision", _decision, false];

if (missionNamespace getVariable ["FIXICS_runtimeAssistDebugLogging", false]) then {
    diag_log format [
        "[FIXICS][RuntimeAssist] class=%1 state=%2 speedKmh=%3 priority=%4 terrain=%5 mass=%6 slopeRetention=%7 suppressed=%8 finalCorrection=%9",
        typeOf _vehicle,
        _driverState,
        _speedKmh,
        _decision get "priorityWinner",
        _decision get "terrainMultiplier",
        _decision get "massMultiplier",
        _decision get "slopeRetention",
        _decision get "suppressedAssists",
        _decision get "finalCorrection"
    ];
};

true
```

This first coordinator implementation records and bounds the decision. Existing subsystem mutations remain the active correction paths until Task 6 moves slope/brake coordination through the decision.

- [ ] **Step 5: Register coordinator**

In `addons/main/config.cpp`, add:

```cpp
class coordinateVehicleAssists {};
```

- [ ] **Step 6: Run static test**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: coordinator file and registration assertions PASS; integration metadata still FAIL until later tasks.

- [ ] **Step 7: Commit**

```powershell
git add addons\main\config.cpp addons\main\functions\fn_coordinateVehicleAssists.sqf
git commit -m "feat: add runtime assist coordinator boundary"
```

---

### Task 5: Route Driver Controller Through Coordinator

**Files:**
- Modify: `addons/main/functions/fn_updateDriverController.sqf`
- Test: `tests/integration/fixics-vehicle-physics-static.ps1`

- [ ] **Step 1: Update finalizer**

Replace `_finishUpdate` body with:

```sqf
private _finishUpdate = {
    params ["_result"];

    private _currentState = _vehicle getVariable ["FIXICS_driverState", ""];
    [_vehicle, _deltaTime] call FIXICS_fnc_applyVehicleStability;
    [_vehicle, _deltaTime, _currentState] call FIXICS_fnc_coordinateVehicleAssists;
    _result
};
```

- [ ] **Step 2: Run static test**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: driver controller coordinator assertion PASS; ABS/slope/telemetry metadata assertions still FAIL.

- [ ] **Step 3: Commit**

```powershell
git add addons\main\functions\fn_updateDriverController.sqf
git commit -m "feat: route driver controller through runtime coordinator"
```

---

### Task 6: Add ABS And Slope Metadata With Reduced Slope While Braking

**Files:**
- Modify: `addons/main/functions/fn_applyABSBraking.sqf`
- Modify: `addons/main/functions/fn_applySlopeRollback.sqf`
- Test: `tests/integration/fixics-vehicle-physics-static.ps1`

- [ ] **Step 1: Store ABS last decision when braking applies**

In `fn_applyABSBraking.sqf`, after `_selectedResult params`, before setting model velocity:

```sqf
private _absDecision = createHashMapFromArray [
    ["applied", _applied],
    ["requestedDirection", _requestedDirection],
    ["targetLongitudinalSpeed", _newLongitudinalSpeed],
    ["delta", _delta],
    ["source", _source],
    ["detail", _detail],
    ["slope", _slope],
    ["downhillBrakeLoad", _downhillBrakeLoad]
];
_vehicle setVariable ["FIXICS_absLastDecision", _absDecision, false];
```

Add before every earlier `exitWith { false }` after vehicle validation if the implementation needs stale metadata cleared:

```sqf
_vehicle setVariable ["FIXICS_absLastDecision", createHashMapFromArray [["applied", false]], false];
```

- [ ] **Step 2: Change slope braking guard from full suppression to reduction**

In `fn_applySlopeRollback.sqf`, replace:

```sqf
if (_isBraking) exitWith {
    false
};
```

with:

```sqf
private _brakingSlopeRetention = missionNamespace getVariable [
    "FIXICS_runtimeAssistBrakingSlopeRetention",
    0.35
];
_brakingSlopeRetention = (_brakingSlopeRetention max 0) min 1;
private _serviceBrakeSlopeScale = [1, _brakingSlopeRetention] select _isBraking;
```

Then multiply both `_driveDelta` and rollback `_delta` by `_serviceBrakeSlopeScale`:

```sqf
private _driveDelta = _driveAcceleration * _effectiveDriveSlope * _timeScale * _serviceBrakeSlopeScale;
```

and:

```sqf
private _delta = (_rollbackAcceleration * (_slope max 0.15) * _timeScale * _serviceBrakeSlopeScale) min _remainingRollbackSpeed;
```

- [ ] **Step 3: Store slope last decision**

Before each successful `setVelocity`, store a decision:

```sqf
_vehicle setVariable [
    "FIXICS_slopeLastDecision",
    createHashMapFromArray [
        ["applied", true],
        ["delta", _delta],
        ["serviceBraking", _isBraking],
        ["slopeScale", _serviceBrakeSlopeScale],
        ["slope", _slope],
        ["surface", surfaceType (getPosWorld _vehicle)]
    ],
    false
];
```

For the drive-input branch, use `_driveDelta` as `"delta"`.

For false exits after vehicle validation, clear stale slope metadata:

```sqf
_vehicle setVariable ["FIXICS_slopeLastDecision", createHashMapFromArray [["applied", false], ["delta", 0]], false];
```

- [ ] **Step 4: Run static test**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: ABS/slope metadata and braking slope retention assertions PASS; telemetry assertions still FAIL.

- [ ] **Step 5: Commit**

```powershell
git add addons\main\functions\fn_applyABSBraking.sqf addons\main\functions\fn_applySlopeRollback.sqf
git commit -m "feat: expose ABS and slope coordination metadata"
```

---

### Task 7: Add Stability And Roll Metadata For Coordinator

**Files:**
- Modify: `addons/main/functions/fn_applyVehicleStability.sqf`
- Test: `tests/integration/fixics-vehicle-physics-static.ps1`

- [ ] **Step 1: Store initial no-op stability decision**

After `_velocity`, `_lateral`, `_longitudinal`, and `_vertical` are defined, add:

```sqf
private _stabilityDecision = createHashMapFromArray [
    ["applied", false],
    ["lateralDelta", 0],
    ["rollDelta", 0],
    ["mode", _mode],
    ["rollApplied", false],
    ["yawRate", 0],
    ["bank", 0],
    ["bankRate", 0]
];
```

- [ ] **Step 2: Update decision after lateral recommendation**

After lateral recommendation is accepted:

```sqf
_stabilityDecision set ["lateralDelta", _recommendedLateral - _lateral];
_stabilityDecision set ["mode", _recommendedMode];
_stabilityDecision set ["yawRate", _diagnosticYawRate];
```

- [ ] **Step 3: Update decision after roll recommendation**

After roll recommendation is accepted:

```sqf
_stabilityDecision set ["rollDelta", _rollCorrection];
_stabilityDecision set ["rollApplied", _rollApplied];
_stabilityDecision set ["bank", _bank];
_stabilityDecision set ["bankRate", _bankRate];
```

- [ ] **Step 4: Store decision before every return**

Before the no-apply exit:

```sqf
_vehicle setVariable ["FIXICS_stabilityLastDecision", _stabilityDecision, false];
```

Before the final `true` return, set:

```sqf
_stabilityDecision set ["applied", _lateralApplied || {_rollApplied}];
_vehicle setVariable ["FIXICS_stabilityLastDecision", _stabilityDecision, false];
```

- [ ] **Step 5: Run static test**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: stability metadata assertions PASS.

- [ ] **Step 6: Commit**

```powershell
git add addons\main\functions\fn_applyVehicleStability.sqf
git commit -m "feat: expose stability coordination metadata"
```

---

### Task 8: Extend Vehicle Handling Telemetry

**Files:**
- Modify: `addons/main/functions/fn_logVehicleHandlingConfig.sqf`
- Test: `tests/integration/fixics-vehicle-physics-static.ps1`

- [ ] **Step 1: Add one-shot telemetry values**

Before `_values`, add:

```sqf
private _runtimeAssistDecision = _vehicle getVariable ["FIXICS_runtimeAssistLastDecision", createHashMap];
```

Add to `_values`:

```sqf
["FIXICS_runtimeAssistLastDecision", _runtimeAssistDecision],
["runtimeAssistPriorityWinner", _runtimeAssistDecision getOrDefault ["priorityWinner", "none"]],
["runtimeAssistTerrainMultiplier", _runtimeAssistDecision getOrDefault ["terrainMultiplier", 1]],
["runtimeAssistMassMultiplier", _runtimeAssistDecision getOrDefault ["massMultiplier", 1]],
["runtimeAssistSuppressedAssists", _runtimeAssistDecision getOrDefault ["suppressedAssists", []]],
["runtimeAssistFinalCorrection", _runtimeAssistDecision getOrDefault ["finalCorrection", 0]]
```

- [ ] **Step 2: Add continuous telemetry sample fields**

Inside the continuous capture loop before `diag_log format`, add:

```sqf
private _runtimeAssistDecision = _vehicle getVariable ["FIXICS_runtimeAssistLastDecision", createHashMap];
private _runtimeAssistPriorityWinner = _runtimeAssistDecision getOrDefault ["priorityWinner", "none"];
private _runtimeAssistTerrainMultiplier = _runtimeAssistDecision getOrDefault ["terrainMultiplier", 1];
private _runtimeAssistMassMultiplier = _runtimeAssistDecision getOrDefault ["massMultiplier", 1];
private _runtimeAssistSuppressedAssists = _runtimeAssistDecision getOrDefault ["suppressedAssists", []];
private _runtimeAssistFinalCorrection = _runtimeAssistDecision getOrDefault ["finalCorrection", 0];
```

Append these values to the format string:

```text
 runtimeAssistPriorityWinner=%34 runtimeAssistTerrainMultiplier=%35 runtimeAssistMassMultiplier=%36 runtimeAssistSuppressedAssists=%37 runtimeAssistFinalCorrection=%38
```

Append these arguments:

```sqf
_runtimeAssistPriorityWinner,
_runtimeAssistTerrainMultiplier,
_runtimeAssistMassMultiplier,
_runtimeAssistSuppressedAssists,
_runtimeAssistFinalCorrection
```

Use the next available `%N` format indices if the current log line already uses those numbers.

- [ ] **Step 3: Run static test**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: telemetry assertions PASS.

- [ ] **Step 4: Commit**

```powershell
git add addons\main\functions\fn_logVehicleHandlingConfig.sqf
git commit -m "feat: log runtime assist coordination telemetry"
```

---

### Task 9: Update Evidence Matrix And State

**Files:**
- Modify: `docs/vehicle-behavior/sqa-evidence-matrix.md`
- Modify: `orchestration/state.md`
- Modify: `governance/audit/validation-log.md`

- [ ] **Step 1: Add coordinator test rows to evidence matrix**

Add these rows under the existing matrix row:

```markdown
| 2026-06-21 | SQA | `registered vehicles` | Paved road | 30/60/90/120 km/h | Brake while turning, sharp left/right, coast after brake release | subsystem presets separate | selected by SQA | selected by SQA | `pending SQA telemetry` | Runtime Assist Coordinator validation row. Record priority winner, suppressed assists, terrain multiplier, mass multiplier, and final correction. | `runtime-assist-coordination` | `collect-more-telemetry` |
| 2026-06-21 | SQA | `registered vehicles` | Dirt | 30/60/90/120 km/h | Brake while turning, sharp left/right, coast after brake release | subsystem presets separate | selected by SQA | selected by SQA | `pending SQA telemetry` | Runtime Assist terrain influence validation row. Confirm controlled sliding remains possible and rollover assist remains bounded. | `runtime-assist-coordination`, `terrain-interaction` | `collect-more-telemetry` |
| 2026-06-21 | SQA | `registered vehicles` | Grass | 30/60/90/120 km/h | Brake while turning, sharp left/right, coast after brake release | subsystem presets separate | selected by SQA | selected by SQA | `pending SQA telemetry` | Runtime Assist low-friction validation row. Confirm assist strength is reduced without disabling braking, slope roll, or roll stability. | `runtime-assist-coordination`, `terrain-interaction` | `collect-more-telemetry` |
```

- [ ] **Step 2: Update state**

Add under current Phase 1 systems:

```markdown
- Runtime Assist Coordinator, local-player only, coordinating ABS, slope rollback, driver intent, Vehicle Stability Assistance, Roll Stability Assist, terrain, mass, per-system presets, and native advisory telemetry.
```

Add under Last Decision:

```markdown
- Runtime Assist Coordinator implementation was added on 2026-06-21 after SQA approved the requirements packet and design spec. It preserves accepted ABS, ACE handbrake, Drive/Reverse, slope rollback, Vehicle Stability, and Roll Stability behavior while adding explicit telemetry and conservative coordination modifiers.
```

- [ ] **Step 3: Add initial validation log entry**

Add to the top of `governance/audit/validation-log.md`:

```markdown
### 2026-06-21 - Runtime Assist Coordination implementation

- Command: implementation pending validation
- Result: pending
- Automated coverage: pending.
- Manual coverage: not run.
- Notes: will be replaced with exact validation command results before completion.
```

- [ ] **Step 4: Commit docs**

```powershell
git add docs\vehicle-behavior\sqa-evidence-matrix.md orchestration\state.md governance\audit\validation-log.md
git commit -m "docs: add runtime assist coordination QA matrix"
```

---

### Task 10: Run Full Validation And Replace Validation Log Entry

**Files:**
- Modify: `governance/audit/validation-log.md`
- Test: full required validation

- [ ] **Step 1: Run required validation**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
powershell -ExecutionPolicy Bypass -File tools\check.ps1
git diff --check
```

Expected:

- governance static test PASS;
- vehicle physics static and mutation checks PASS;
- HEMTT check PASS;
- stability recommendation unit test PASS;
- roll recommendation unit test PASS;
- runtime assist recommendation unit test PASS;
- stability mutation test PASS;
- `git diff --check` reports no whitespace errors.

- [ ] **Step 2: Replace initial validation log entry**

Replace the pending entry with:

```markdown
### 2026-06-21 - Runtime Assist Coordination implementation

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1`
- Result: passed, exit code 0
- Automated coverage: confirmed governance guidance still passes after Runtime Assist Coordination implementation.
- Manual coverage: not run.
- Notes: implementation awaits SQA in-game validation.

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1`
- Result: passed, exit code 0
- Automated coverage: confirmed coordinator registration, settings, telemetry, purity, and ownership contracts.
- Manual coverage: not run.
- Notes: static checks do not prove gameplay feel.

- Command: `powershell -ExecutionPolicy Bypass -File tools\check.ps1`
- Result: passed, exit code 0
- Automated coverage: HEMTT config/SQF/stringtable validation and unit tests passed, including runtime assist recommendation math.
- Manual coverage: not run.
- Notes: no manual Arma behavior is claimed until SQA verifies it.

- Command: `git diff --check`
- Result: passed, exit code 0
- Automated coverage: confirmed no whitespace errors.
- Manual coverage: not run.
- Notes: final source hygiene check.
```

- [ ] **Step 3: Commit validation log**

```powershell
git add governance\audit\validation-log.md
git commit -m "docs: record runtime assist validation"
```

---

### Task 11: Build And SQA Handoff

**Files:**
- No source change required unless build tooling reports a source issue.

- [ ] **Step 1: Build local test artifact**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools\build.ps1
```

Expected: HEMTT builds the local addon artifact. If Arma holds `.hemttout\build`, report that the build is blocked and do not terminate SQA's active game session automatically.

- [ ] **Step 2: Provide SQA debug command**

Tell SQA to run:

```sqf
[vehicle player, 180, 0.1] call FIXICS_fnc_logVehicleHandlingConfig;
```

Recommended first test settings:

```text
FIXICS > Runtime Assist > Runtime assist coordinator: Enabled
FIXICS > Runtime Assist > Terrain influence: Enabled
FIXICS > Runtime Assist > Braking slope retention: 0.35
FIXICS > Runtime Assist > Mass damping influence: 0.15
FIXICS > Runtime Assist > Maximum composed correction: 0.25
FIXICS > Vehicle Stability > Assistance mode: Yaw + Lateral Damping
FIXICS > Vehicle Stability > Roll preset: Realistic Stable, then Aggressive SQA comparison
```

- [ ] **Step 3: Give manual matrix**

Ask SQA to test all currently registered vehicles:

```text
Speeds: 30, 60, 90, 120 km/h
Surfaces: paved, dirt, grass
Inputs: brake while turning, sharp left/right steering, coast after brake release, Drive-to-Reverse, Reverse-to-Drive, ACE handbrake lock
Observe: priority winner, suppressed assists, terrain multiplier, mass multiplier, final correction, controlled sliding, rollover tendency, braking smoothness, slope roll after brake release
```

- [ ] **Step 4: Completion report**

Report:

```text
Done      : Runtime Assist Coordinator implemented for local-player registered vehicles.
Validated : governance static, vehicle physics static, tools\check.ps1, git diff --check, build result.
Logged    : validation log, project state, and evidence matrix updated.
Next      : SQA in-game QA matrix and telemetry review before tuning.
```

---

## Self-Review

- Spec coverage:
  - New layer function: Task 4.
  - One-to-many coordination: Tasks 2, 4, 5, 6, 7.
  - Stability and roll priority: Tasks 2, 4, 7.
  - Service braking reduces slope assist without disabling roll after release: Task 6.
  - Terrain and mass influence: Tasks 2, 3, 4, 8.
  - Separate subsystem presets: Tasks 3 and 4 read settings without merging presets.
  - Local-player only and native advisory only: Tasks 1 and 4 contracts.
  - Global conservative settings: Task 3.
  - New telemetry lines: Task 8.
  - Evidence matrix update: Task 9.
- Scope:
  - No multiplayer authority.
  - No broad config patch.
  - No native mutation.
  - No direct gearbox forcing.
  - No orientation mutation.
- Completeness scan:
  - No deferred markers.
  - Each code-changing task includes exact snippets and validation commands.
- Type and name consistency:
  - Function names use `FIXICS_fnc_*`.
  - Namespace keys use `FIXICS_*`.
  - CBA setting names match stringtable key intent.
