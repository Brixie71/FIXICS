# ABS Braking Module Implementation Plan

> Superseded for player-driven vehicles by `2026-06-07-driver-state-controller.md`. Do not complete the old monitor-integration task; the fast controller owns player ABS execution.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add adjustable FIXICS vehicle physics addon settings and a local ABS-like braking helper for ground vehicles.

**Architecture:** `FIXICS_fnc_monitorVehicleAutobrake` stays the local coordinator. Existing slope settings become CBA sliders, and a new `FIXICS_fnc_applyABSBraking` helper applies conservative velocity-level braking modulation only while the local player driver is braking against current motion.

**Tech Stack:** Arma 3 SQF, HEMTT, ACE3, CBA settings, PowerShell static regression test.

---

## File Structure

- `tests/integration/fixics-vehicle-physics-static.ps1`: static regression for function registration, settings, stringtable labels, monitor integration, and ABS helper implementation shape.
- `addons/main/config.cpp`: register `applyABSBraking` in `CfgFunctions`.
- `addons/main/functions/fn_registerSettings.sqf`: initialize defaults and register CBA sliders/checkboxes.
- `addons/main/stringtable.xml`: user-facing addon setting labels/tooltips.
- `addons/main/functions/fn_applyABSBraking.sqf`: new local ABS-like braking helper.
- `addons/main/functions/fn_monitorVehicleAutobrake.sqf`: call ABS helper for local unlocked land vehicles after slope handling.
- `docs/superpowers/specs/2026-06-07-abs-braking-module-design.md`: approved design reference.
- `governance/audit/validation-log.md`: validation evidence.

The workspace is not a git repository, so this plan does not include commit steps.

### Task 1: Static Regression For Settings And ABS Module

**Files:**
- Modify: `tests/integration/fixics-vehicle-physics-static.ps1`

- [x] **Step 1: Write the failing static regression**

Add these assertions to `tests/integration/fixics-vehicle-physics-static.ps1`:

```powershell
Assert-FileExists 'addons\main\functions\fn_applyABSBraking.sqf'
Assert-Contains $Config 'class applyABSBraking\s*\{\s*\};' 'applyABSBraking must be registered in CfgFunctions.'

@(
    'STR_FIXICS_SETTING_SLOPE_MINIMUM',
    'STR_FIXICS_SETTING_SLOPE_ROLLBACK_MAX_SPEED',
    'STR_FIXICS_SETTING_SLOPE_ROLLBACK_ACCELERATION',
    'STR_FIXICS_SETTING_SLOPE_COAST_BREAKAWAY',
    'STR_FIXICS_SETTING_SLOPE_DRIVE_ACCELERATION',
    'STR_FIXICS_SETTING_SLOPE_DRIVE_MAX_SPEED',
    'STR_FIXICS_SETTING_STATIONARY_BRAKE_BYPASS',
    'STR_FIXICS_SETTING_ABS_ENABLED',
    'STR_FIXICS_SETTING_ABS_BRAKE_STRENGTH',
    'STR_FIXICS_SETTING_ABS_RELEASE_BIAS',
    'STR_FIXICS_SETTING_ABS_LOW_SPEED_CUTOFF',
    'STR_FIXICS_SETTING_ABS_SLOPE_COMPENSATION',
    'STR_FIXICS_SETTING_ABS_DEBUG_LOGGING'
) | ForEach-Object {
    Assert-Contains $Stringtable $_ "Stringtable must define $_."
}
```

Add settings assertions inside the existing `$SettingsFile` block:

```powershell
@(
    '"FIXICS_slopeRollbackMinimumSlope"',
    '"FIXICS_slopeRollbackMaxSpeed"',
    '"FIXICS_slopeRollbackAcceleration"',
    '"FIXICS_slopeCoastBreakawayVelocity"',
    '"FIXICS_slopeDriveAcceleration"',
    '"FIXICS_slopeDriveMaxSpeedKmh"',
    '"FIXICS_stationaryBrakeBypassSpeedKmh"',
    '"FIXICS_absEnabled"',
    '"FIXICS_absBrakeStrength"',
    '"FIXICS_absReleaseBias"',
    '"FIXICS_absLowSpeedCutoffKmh"',
    '"FIXICS_absSlopeCompensation"',
    '"FIXICS_absDebugLogging"'
) | ForEach-Object {
    Assert-Contains $Settings $_ "Settings registration must define $_."
}
Assert-Contains $Settings '"SLIDER"' 'Physics tuning settings must use CBA sliders.'
```

Add monitor assertions inside the existing `$MonitorFile` block:

```powershell
Assert-Contains $Monitor 'FIXICS_fnc_applyABSBraking' 'Vehicle monitor must apply ABS braking after slope handling.'
Assert-Contains $Monitor 'FIXICS_fnc_applySlopeRollback;\s*\[_x\]\s+call\s+FIXICS_fnc_applyABSBraking' 'ABS must run after slope assist so braking wins over slope acceleration.'
```

Add a new ABS file block:

```powershell
$AbsFile = Join-Path $RepoRoot 'addons\main\functions\fn_applyABSBraking.sqf'
if (Test-Path -LiteralPath $AbsFile) {
    $Abs = Get-Content -Raw -LiteralPath $AbsFile
    Assert-Contains $Abs 'FIXICS_absEnabled' 'ABS helper must honor the enabled setting.'
    Assert-Contains $Abs 'FIXICS_handbrakeEnabled' 'ABS helper must respect the ACE handbrake.'
    Assert-Contains $Abs 'inputAction "CarHandBrake"' 'ABS helper must respect the built-in handbrake input.'
    Assert-Contains $Abs 'inputAction "CarForward"' 'ABS helper must inspect forward input.'
    Assert-Contains $Abs 'inputAction "CarBack"' 'ABS helper must inspect reverse/brake input.'
    Assert-Contains $Abs 'vectorDir _vehicle' 'ABS helper must derive the vehicle forward axis.'
    Assert-Contains $Abs 'velocity _vehicle' 'ABS helper must read current vehicle velocity.'
    Assert-Contains $Abs 'private _isForwardBraking' 'ABS helper must classify S braking while moving forward.'
    Assert-Contains $Abs 'private _isReverseBraking' 'ABS helper must classify W braking while moving backward.'
    Assert-Contains $Abs 'FIXICS_absLowSpeedCutoffKmh' 'ABS helper must taper out below low speed.'
    Assert-Contains $Abs 'FIXICS_absBrakeStrength' 'ABS helper must use braking strength tuning.'
    Assert-Contains $Abs 'FIXICS_absReleaseBias' 'ABS helper must use release bias tuning.'
    Assert-Contains $Abs 'FIXICS_absSlopeCompensation' 'ABS helper must use slope compensation tuning.'
    Assert-Contains $Abs 'FIXICS_absDebugLogging' 'ABS helper must expose optional diagnostics.'
    Assert-Contains $Abs 'setVelocity' 'ABS helper must apply velocity-level brake modulation.'
}
```

- [x] **Step 2: Run regression to verify red**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: non-zero exit with missing `fn_applyABSBraking.sqf`, missing function registration, missing stringtable keys, missing ABS settings, and missing monitor integration.

### Task 2: Add Stringtable Keys

**Files:**
- Modify: `addons/main/stringtable.xml`
- Test: `tests/integration/fixics-vehicle-physics-static.ps1`

- [x] **Step 1: Add setting names and tooltips**

Add these keys inside `<Package name="Main">`:

```xml
        <Key ID="STR_FIXICS_SETTING_SLOPE_MINIMUM">
            <Original>Minimum slope for rolling</Original>
        </Key>
        <Key ID="STR_FIXICS_SETTING_SLOPE_MINIMUM_TOOLTIP">
            <Original>Terrain slope threshold before FIXICS disables idle autobrake or applies slope assist.</Original>
        </Key>
        <Key ID="STR_FIXICS_SETTING_SLOPE_ROLLBACK_MAX_SPEED">
            <Original>Rollback max speed</Original>
        </Key>
        <Key ID="STR_FIXICS_SETTING_SLOPE_ROLLBACK_MAX_SPEED_TOOLTIP">
            <Original>Maximum assisted downhill coasting speed in meters per second.</Original>
        </Key>
        <Key ID="STR_FIXICS_SETTING_SLOPE_ROLLBACK_ACCELERATION">
            <Original>Rollback acceleration</Original>
        </Key>
        <Key ID="STR_FIXICS_SETTING_SLOPE_ROLLBACK_ACCELERATION_TOOLTIP">
            <Original>How strongly FIXICS accelerates unpowered vehicles downhill.</Original>
        </Key>
        <Key ID="STR_FIXICS_SETTING_SLOPE_COAST_BREAKAWAY">
            <Original>Coast breakaway velocity</Original>
        </Key>
        <Key ID="STR_FIXICS_SETTING_SLOPE_COAST_BREAKAWAY_TOOLTIP">
            <Original>Minimum downhill velocity nudge used near zero speed on slopes.</Original>
        </Key>
        <Key ID="STR_FIXICS_SETTING_SLOPE_DRIVE_ACCELERATION">
            <Original>Drive slope acceleration</Original>
        </Key>
        <Key ID="STR_FIXICS_SETTING_SLOPE_DRIVE_ACCELERATION_TOOLTIP">
            <Original>How strongly slope angle modifies powered uphill or downhill driving.</Original>
        </Key>
        <Key ID="STR_FIXICS_SETTING_SLOPE_DRIVE_MAX_SPEED">
            <Original>Drive assist max speed</Original>
        </Key>
        <Key ID="STR_FIXICS_SETTING_SLOPE_DRIVE_MAX_SPEED_TOOLTIP">
            <Original>Maximum vehicle speed in kilometers per hour where downhill drive assist may add speed.</Original>
        </Key>
        <Key ID="STR_FIXICS_SETTING_STATIONARY_BRAKE_BYPASS">
            <Original>Stationary brake bypass speed</Original>
        </Key>
        <Key ID="STR_FIXICS_SETTING_STATIONARY_BRAKE_BYPASS_TOOLTIP">
            <Original>Speed below which brake/reverse input stops being treated as a persistent idle hold.</Original>
        </Key>
        <Key ID="STR_FIXICS_SETTING_ABS_ENABLED">
            <Original>Enable ABS braking</Original>
        </Key>
        <Key ID="STR_FIXICS_SETTING_ABS_ENABLED_TOOLTIP">
            <Original>Applies FIXICS velocity-level anti-lock braking while the local driver is actively braking.</Original>
        </Key>
        <Key ID="STR_FIXICS_SETTING_ABS_BRAKE_STRENGTH">
            <Original>ABS brake strength</Original>
        </Key>
        <Key ID="STR_FIXICS_SETTING_ABS_BRAKE_STRENGTH_TOOLTIP">
            <Original>Maximum longitudinal speed reduction applied by the ABS helper each monitor tick.</Original>
        </Key>
        <Key ID="STR_FIXICS_SETTING_ABS_RELEASE_BIAS">
            <Original>ABS release bias</Original>
        </Key>
        <Key ID="STR_FIXICS_SETTING_ABS_RELEASE_BIAS_TOOLTIP">
            <Original>Fraction of requested braking released to reduce lock-like stopping.</Original>
        </Key>
        <Key ID="STR_FIXICS_SETTING_ABS_LOW_SPEED_CUTOFF">
            <Original>ABS low speed cutoff</Original>
        </Key>
        <Key ID="STR_FIXICS_SETTING_ABS_LOW_SPEED_CUTOFF_TOOLTIP">
            <Original>Speed below which FIXICS ABS stops modulating so braking cannot become an idle handbrake.</Original>
        </Key>
        <Key ID="STR_FIXICS_SETTING_ABS_SLOPE_COMPENSATION">
            <Original>ABS slope compensation</Original>
        </Key>
        <Key ID="STR_FIXICS_SETTING_ABS_SLOPE_COMPENSATION_TOOLTIP">
            <Original>Additional braking authority used when braking downhill.</Original>
        </Key>
        <Key ID="STR_FIXICS_SETTING_ABS_DEBUG_LOGGING">
            <Original>ABS debug logging</Original>
        </Key>
        <Key ID="STR_FIXICS_SETTING_ABS_DEBUG_LOGGING_TOOLTIP">
            <Original>Writes ABS braking decisions to the RPT log for SQA diagnostics.</Original>
        </Key>
```

- [x] **Step 2: Run regression**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: stringtable-key failures are gone; function, settings, and monitor failures remain.

### Task 3: Register Settings

**Files:**
- Modify: `addons/main/functions/fn_registerSettings.sqf`
- Test: `tests/integration/fixics-vehicle-physics-static.ps1`

- [x] **Step 1: Initialize defaults**

Add default variables after the current slope defaults:

```sqf
missionNamespace setVariable ["FIXICS_slopeRollbackMinimumSlope", 0.035, false];
missionNamespace setVariable ["FIXICS_slopeRollbackMaxSpeed", 2.2, false];
missionNamespace setVariable ["FIXICS_slopeRollbackAcceleration", 0.55, false];
missionNamespace setVariable ["FIXICS_stationaryBrakeBypassSpeedKmh", 1, false];
missionNamespace setVariable ["FIXICS_absEnabled", true, false];
missionNamespace setVariable ["FIXICS_absBrakeStrength", 0.45, false];
missionNamespace setVariable ["FIXICS_absReleaseBias", 0.35, false];
missionNamespace setVariable ["FIXICS_absLowSpeedCutoffKmh", 3, false];
missionNamespace setVariable ["FIXICS_absSlopeCompensation", 0.25, false];
missionNamespace setVariable ["FIXICS_absDebugLogging", false, false];
```

- [x] **Step 2: Add slider settings**

Add CBA slider registrations after the native slope checkbox. Use category arrays so settings are grouped:

```sqf
[
    "FIXICS_slopeRollbackMinimumSlope",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_SLOPE_MINIMUM",
        localize "STR_FIXICS_SETTING_SLOPE_MINIMUM_TOOLTIP"
    ],
    ["FIXICS", "Slope"],
    [0, 0.2, 0.035, 3],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_slopeRollbackMaxSpeed",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_SLOPE_ROLLBACK_MAX_SPEED",
        localize "STR_FIXICS_SETTING_SLOPE_ROLLBACK_MAX_SPEED_TOOLTIP"
    ],
    ["FIXICS", "Slope"],
    [0.2, 10, 2.2, 1],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_slopeRollbackAcceleration",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_SLOPE_ROLLBACK_ACCELERATION",
        localize "STR_FIXICS_SETTING_SLOPE_ROLLBACK_ACCELERATION_TOOLTIP"
    ],
    ["FIXICS", "Slope"],
    [0, 2, 0.55, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_slopeCoastBreakawayVelocity",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_SLOPE_COAST_BREAKAWAY",
        localize "STR_FIXICS_SETTING_SLOPE_COAST_BREAKAWAY_TOOLTIP"
    ],
    ["FIXICS", "Slope"],
    [0, 1, 0.18, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_slopeDriveAcceleration",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_SLOPE_DRIVE_ACCELERATION",
        localize "STR_FIXICS_SETTING_SLOPE_DRIVE_ACCELERATION_TOOLTIP"
    ],
    ["FIXICS", "Slope"],
    [0, 1, 0.22, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_slopeDriveMaxSpeedKmh",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_SLOPE_DRIVE_MAX_SPEED",
        localize "STR_FIXICS_SETTING_SLOPE_DRIVE_MAX_SPEED_TOOLTIP"
    ],
    ["FIXICS", "Slope"],
    [10, 240, 120, 0],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_stationaryBrakeBypassSpeedKmh",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_STATIONARY_BRAKE_BYPASS",
        localize "STR_FIXICS_SETTING_STATIONARY_BRAKE_BYPASS_TOOLTIP"
    ],
    ["FIXICS", "Slope"],
    [0, 5, 1, 1],
    1
] call CBA_fnc_addSetting;
```

- [x] **Step 3: Add ABS settings**

Add these CBA settings:

```sqf
[
    "FIXICS_absEnabled",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_ABS_ENABLED",
        localize "STR_FIXICS_SETTING_ABS_ENABLED_TOOLTIP"
    ],
    ["FIXICS", "ABS"],
    true,
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_absBrakeStrength",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_ABS_BRAKE_STRENGTH",
        localize "STR_FIXICS_SETTING_ABS_BRAKE_STRENGTH_TOOLTIP"
    ],
    ["FIXICS", "ABS"],
    [0.05, 2, 0.45, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_absReleaseBias",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_ABS_RELEASE_BIAS",
        localize "STR_FIXICS_SETTING_ABS_RELEASE_BIAS_TOOLTIP"
    ],
    ["FIXICS", "ABS"],
    [0, 1, 0.35, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_absLowSpeedCutoffKmh",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_ABS_LOW_SPEED_CUTOFF",
        localize "STR_FIXICS_SETTING_ABS_LOW_SPEED_CUTOFF_TOOLTIP"
    ],
    ["FIXICS", "ABS"],
    [0, 20, 3, 1],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_absSlopeCompensation",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_ABS_SLOPE_COMPENSATION",
        localize "STR_FIXICS_SETTING_ABS_SLOPE_COMPENSATION_TOOLTIP"
    ],
    ["FIXICS", "ABS"],
    [0, 1, 0.25, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_absDebugLogging",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_ABS_DEBUG_LOGGING",
        localize "STR_FIXICS_SETTING_ABS_DEBUG_LOGGING_TOOLTIP"
    ],
    ["FIXICS", "ABS"],
    false,
    1
] call CBA_fnc_addSetting;
```

- [x] **Step 4: Run regression**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: settings failures are gone; function and monitor failures remain.

### Task 4: Add ABS Function Registration

**Files:**
- Modify: `addons/main/config.cpp`
- Create: `addons/main/functions/fn_applyABSBraking.sqf`
- Test: `tests/integration/fixics-vehicle-physics-static.ps1`

- [x] **Step 1: Register the function**

Add this under `class Main` in `CfgFunctions`:

```cpp
            class applyABSBraking {};
```

- [x] **Step 2: Create minimal ABS function shell**

Create `addons/main/functions/fn_applyABSBraking.sqf`:

```sqf
/*
 * FIXICS_fnc_applyABSBraking
 *
 * Applies local velocity-level ABS-like braking modulation for player-driven land vehicles.
 *
 * Arguments:
 *   0: Vehicle to update <OBJECT>
 *
 * Return: <BOOL> true when ABS changed vehicle velocity
 * Locality: local machine; vehicle velocity changes only apply where the vehicle is local
 *
 * Example:
 *   [_vehicle] call FIXICS_fnc_applyABSBraking;
 */

params [
    ["_vehicle", objNull, [objNull]]
];

false
```

- [x] **Step 3: Run regression**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: function existence and registration failures are gone; ABS implementation and monitor failures remain.

### Task 5: Implement ABS Braking Helper

**Files:**
- Modify: `addons/main/functions/fn_applyABSBraking.sqf`
- Test: `tests/integration/fixics-vehicle-physics-static.ps1`

- [ ] **Step 1: Replace shell with implementation**

Replace the body after `params` with:

```sqf
if !(missionNamespace getVariable ["FIXICS_absEnabled", true]) exitWith {
    false
};

if (isNull _vehicle) exitWith {
    false
};

if (!(_vehicle isKindOf "LandVehicle")) exitWith {
    false
};

if (!(local _vehicle)) exitWith {
    false
};

if (!isTouchingGround _vehicle) exitWith {
    false
};

if (_vehicle getVariable ["FIXICS_handbrakeEnabled", false]) exitWith {
    false
};

private _driver = driver _vehicle;
if (!(hasInterface && {!isNull _driver} && {_driver == player})) exitWith {
    false
};

if ((inputAction "CarHandBrake") > 0) exitWith {
    false
};

private _hasForwardInput = (inputAction "CarForward") > 0;
private _hasBackInput = (inputAction "CarBack") > 0;
if (_hasForwardInput && {_hasBackInput}) exitWith {
    false
};

private _velocity = velocity _vehicle;
private _vehicleForward = vectorDir _vehicle;
private _forward = [_vehicleForward # 0, _vehicleForward # 1, 0];
private _forwardLength = sqrt (((_forward # 0) * (_forward # 0)) + ((_forward # 1) * (_forward # 1)));
if (_forwardLength <= 0) exitWith {
    false
};

_forward = _forward vectorMultiply (1 / _forwardLength);

private _longitudinalSpeed = ((_velocity # 0) * (_forward # 0)) + ((_velocity # 1) * (_forward # 1));
private _speedKmh = abs (speed _vehicle);
private _lowSpeedCutoff = missionNamespace getVariable ["FIXICS_absLowSpeedCutoffKmh", 3];
if (_speedKmh <= _lowSpeedCutoff) exitWith {
    false
};

private _stationarySpeedKmh = missionNamespace getVariable ["FIXICS_stationaryBrakeBypassSpeedKmh", 1];
private _stationarySpeedMps = _stationarySpeedKmh / 3.6;
private _isForwardBraking = _hasBackInput && {_longitudinalSpeed > _stationarySpeedMps};
private _isReverseBraking = _hasForwardInput && {_longitudinalSpeed < -_stationarySpeedMps};
private _isBraking = _isForwardBraking || {_isReverseBraking};
if (!_isBraking) exitWith {
    false
};

private _normal = surfaceNormal (getPosASL _vehicle);
private _downhill = [_normal # 0, _normal # 1, 0];
private _slope = sqrt (((_downhill # 0) * (_downhill # 0)) + ((_downhill # 1) * (_downhill # 1)));
private _slopeCompensation = missionNamespace getVariable ["FIXICS_absSlopeCompensation", 0.25];
private _downhillAlignment = 0;
if (_slope > 0) then {
    _downhill = _downhill vectorMultiply (1 / _slope);
    _downhillAlignment = ((_forward # 0) * (_downhill # 0)) + ((_forward # 1) * (_downhill # 1));
};

private _brakeDirection = if (_isForwardBraking) then {-1} else {1};
private _downhillBrakeLoad = 0;
if (_isForwardBraking) then {
    _downhillBrakeLoad = _downhillAlignment max 0;
} else {
    _downhillBrakeLoad = (-_downhillAlignment) max 0;
};

private _brakeStrength = missionNamespace getVariable ["FIXICS_absBrakeStrength", 0.45];
private _releaseBias = missionNamespace getVariable ["FIXICS_absReleaseBias", 0.35];
private _effectiveBrake = _brakeStrength * (1 - _releaseBias) * (1 + (_downhillBrakeLoad * _slopeCompensation));
private _speedMagnitude = abs _longitudinalSpeed;
private _deltaMagnitude = _effectiveBrake min _speedMagnitude;
if (_deltaMagnitude <= 0) exitWith {
    false
};

private _delta = _brakeDirection * _deltaMagnitude;
_vehicle setVelocity [
    (_velocity # 0) + ((_forward # 0) * _delta),
    (_velocity # 1) + ((_forward # 1) * _delta),
    _velocity # 2
];

if (missionNamespace getVariable ["FIXICS_absDebugLogging", false]) then {
    diag_log format [
        "[FIXICS_fnc_applyABSBraking] vehicle=%1 speedKmh=%2 longitudinal=%3 delta=%4 slope=%5 downhillBrakeLoad=%6",
        typeOf _vehicle,
        _speedKmh,
        _longitudinalSpeed,
        _delta,
        _slope,
        _downhillBrakeLoad
    ];
};

true
```

- [ ] **Step 2: Run regression**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: ABS implementation failures are gone; monitor integration failure remains.

### Task 6: Integrate ABS Into Monitor

**Files:**
- Modify: `addons/main/functions/fn_monitorVehicleAutobrake.sqf`
- Test: `tests/integration/fixics-vehicle-physics-static.ps1`

- [ ] **Step 1: Call ABS after slope handling**

Change the unlocked vehicle branch to:

```sqf
            } else {
                if ([_x] call FIXICS_fnc_shouldVehicleRoll) then {
                    _x disableBrakes true;
                };
                [_x] call FIXICS_fnc_applySlopeRollback;
                [_x] call FIXICS_fnc_applyABSBraking;
            };
```

- [ ] **Step 2: Run regression**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: exit code 0.

### Task 7: HEMTT Validation And Audit Log

**Files:**
- Modify: `governance/audit/validation-log.md`

- [ ] **Step 1: Run HEMTT check**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools\check.ps1
```

Expected: exit code 0 with HEMTT compiling 13 SQF files and checking 1 stringtable.

- [ ] **Step 2: Record validation evidence**

Append this entry to `governance/audit/validation-log.md` with actual command results:

```markdown
### 2026-06-07 - ABS braking module and adjustable physics settings

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1`
- Result: passed, exit code 0
- Automated coverage: verified CBA physics tuning settings, ABS setting labels, `FIXICS_fnc_applyABSBraking` registration, brake-direction classification, low-speed cutoff, release bias, slope compensation, and monitor integration after slope assist.
- Manual coverage: not run.
- Notes: static regression was first run before implementation and failed for the expected missing ABS module and settings.

- Command: `powershell -ExecutionPolicy Bypass -File tools\check.ps1`
- Result: passed, exit code 0
- Automated coverage: HEMTT loaded FIXICS 0.1.0.0, rapified 2 addon configs, compiled 13 SQF files, checked 1 stringtable.
- Manual coverage: not run.
- Notes: manual Eden/VR retest must cover flat forward braking, flat reverse braking, uphill braking, downhill braking, coasting with no brake input, ACE handbrake, built-in handbrake key, ABS disabled, and ABS strength tuning.
```

### Task 8: Manual SQA Handoff

**Files:**
- Read: `docs/superpowers/specs/2026-06-07-abs-braking-module-design.md`
- Read: `governance/audit/validation-log.md`

- [ ] **Step 1: Report manual test matrix**

Tell SQA to test:

```text
1. Flat forward braking, default ABS.
2. Flat reverse braking, default ABS.
3. Downhill braking, default ABS.
4. Uphill braking, default ABS.
5. Coasting downhill with no brake input.
6. ACE Set Handbrake hard lock.
7. Built-in handbrake key hold.
8. ABS disabled in addon settings.
9. ABS brake strength low, default, and high.
```

- [ ] **Step 2: State native build status**

Report that no native C++ source changed in this ABS plan, so `tools\build-native.ps1` is not required unless a future ABS design moves braking math into `FIXICSPhysics`.
