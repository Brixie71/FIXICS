# Vehicle Stability Assistance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add server-global, preset-driven stability assistance for explicitly supported vehicles while preserving longitudinal velocity and existing ABS, slope, direction, and handbrake ownership.

**Architecture:** A pure recommendation function resolves presets and calculates bounded lateral/yaw corrections from model-space motion. A separate local mutation function applies those recommendations only to supported, grounded, player-driven vehicles. The existing driver controller invokes the stability layer after its longitudinal state work is complete.

**Tech Stack:** Arma 3 SQF, CBA settings, HEMTT, PowerShell static integration tests.

---

## File Structure

- Create `addons/main/functions/fn_getVehicleStabilityProfile.sqf`: compatibility registry and bounded preset resolution.
- Create `addons/main/functions/fn_getVehicleStabilityRecommendation.sqf`: pure assistance-mode math with no object mutation.
- Create `addons/main/functions/fn_applyVehicleStability.sqf`: locality, grounded-state, handbrake, threshold, and mutation boundary.
- Modify `addons/main/functions/fn_updateDriverController.sqf`: invoke stability after longitudinal control paths.
- Modify `addons/main/functions/fn_registerSettings.sqf`: server-global preset, mode, custom controls, and debug setting.
- Modify `addons/main/config.cpp`: register the three new functions.
- Modify `addons/main/stringtable.xml`: localized setting names and descriptions.
- Modify `tests/integration/fixics-vehicle-physics-static.ps1`: static contracts and ownership guards.
- Modify `docs/fixes/open-issues.md`: SQA test matrix and current ISSUE-001 status.
- Modify `orchestration/state.md`: implementation checkpoint.

Passive `PlayerSteeringCoefficients` and anti-roll config patches are excluded
from this plan. They require a separate config plan after the source addon and
inherited values for `EMP_Polaris_DAGOR` are captured.

### Task 1: Compatibility Registry And Preset Resolution

**Files:**
- Create: `addons/main/functions/fn_getVehicleStabilityProfile.sqf`
- Modify: `addons/main/config.cpp`
- Test: `tests/integration/fixics-vehicle-physics-static.ps1`

- [ ] **Step 1: Write the failing static contract**

Add assertions requiring:

```powershell
Assert-FileExists 'addons\main\functions\fn_getVehicleStabilityProfile.sqf'
Assert-Contains $Config 'class getVehicleStabilityProfile\s*\{\s*\};' 'Stability profile resolver must be registered.'
Assert-Contains $StabilityProfile '"EMP_Polaris_DAGOR"' 'Initial compatibility registry must contain only the approved DAGOR class.'
Assert-Contains $StabilityProfile '"REALISTIC_STABLE"' 'Profile resolver must support the realistic preset.'
Assert-Contains $StabilityProfile '"RALLY"' 'Profile resolver must support the rally preset.'
Assert-Contains $StabilityProfile '"CUSTOM"' 'Profile resolver must support the custom preset.'
Assert-Contains $StabilityProfile 'missionNamespace getVariable' 'Custom profile must read synchronized CBA values.'
```

Also fail if the file contains `isKindOf "Car_F"` or `isKindOf "LandVehicle"`.

- [ ] **Step 2: Run the test and verify RED**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: FAIL because the resolver file and registration do not exist.

- [ ] **Step 3: Implement the resolver**

Use this public contract:

```sqf
/*
 * Arguments:
 *   0: Vehicle <OBJECT>
 * Return:
 *   [supported, activationSpeedKmh, slipThreshold, yawStrength,
 *    lateralStrength, countersteerStrength, maximumCorrection] <ARRAY>
 */
```

The registry must use exact class names:

```sqf
private _supportedClasses = ["EMP_Polaris_DAGOR"];
if !((typeOf _vehicle) in _supportedClasses) exitWith {
    [false, 0, 0, 0, 0, 0, 0]
};
```

Resolve preset index `0` as `REALISTIC_STABLE`, `1` as `RALLY`, and `2` as
`CUSTOM`. Clamp all custom values:

```sqf
private _activationSpeed = (_customActivationSpeed max 10) min 160;
private _slipThreshold = (_customSlipThreshold max 0.05) min 0.8;
private _yawStrength = (_customYawStrength max 0) min 1;
private _lateralStrength = (_customLateralStrength max 0) min 1;
private _countersteerStrength = (_customCountersteerStrength max 0) min 0.5;
private _maximumCorrection = (_customMaximumCorrection max 0.01) min 0.5;
```

Initial fixed profiles:

```sqf
// Realistic Stable
[true, 35, 0.12, 0.22, 0.12, 0.08, 0.12]

// Rally
[true, 50, 0.2, 0.12, 0.05, 0.04, 0.08]
```

- [ ] **Step 4: Run the test and verify GREEN**

Run the vehicle-physics static test. Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add addons/main/config.cpp addons/main/functions/fn_getVehicleStabilityProfile.sqf tests/integration/fixics-vehicle-physics-static.ps1
git commit -m "Add vehicle stability profile resolver"
```

### Task 2: Pure Stability Recommendation Math

**Files:**
- Create: `addons/main/functions/fn_getVehicleStabilityRecommendation.sqf`
- Modify: `addons/main/config.cpp`
- Test: `tests/integration/fixics-vehicle-physics-static.ps1`

- [ ] **Step 1: Write the failing static contract**

Require the function and registration, then assert that it:

```powershell
Assert-Contains $Recommendation '"OFF"' 'Recommendation must support disabled assistance.'
Assert-Contains $Recommendation '"YAW"' 'Recommendation must support yaw damping.'
Assert-Contains $Recommendation '"YAW_LATERAL"' 'Recommendation must support yaw and lateral damping.'
Assert-Contains $Recommendation '"COUNTERSTEER"' 'Recommendation must support bounded countersteering.'
Assert-Contains $Recommendation 'finite' 'Recommendation must reject non-finite inputs.'
Assert-Contains $Recommendation '_longitudinalSpeed' 'Recommendation must carry longitudinal speed unchanged.'
```

Fail if the pure function contains `setVelocity`, `setVelocityModelSpace`,
`setDir`, `setVectorDirAndUp`, or `disableBrakes`.

- [ ] **Step 2: Run the test and verify RED**

Expected: FAIL because the recommendation function is absent.

- [ ] **Step 3: Implement the pure function**

Use this contract:

```sqf
/*
 * Arguments:
 *   0: Assistance mode <STRING>
 *   1: Longitudinal speed <NUMBER>
 *   2: Lateral speed <NUMBER>
 *   3: Yaw rate in degrees per second <NUMBER>
 *   4: Normalized steering input, -1 to 1 <NUMBER>
 *   5: Delta time <NUMBER>
 *   6: Profile from FIXICS_fnc_getVehicleStabilityProfile <ARRAY>
 * Return:
 *   [applied, longitudinalSpeed, lateralSpeed, yawCorrection, mode] <ARRAY>
 */
```

Normalize and clamp input values. Compute slip ratio without division by zero:

```sqf
private _slipRatio = (abs _lateralSpeed) / ((abs _longitudinalSpeed) max 1);
```

Return unchanged values when below thresholds or mode is `OFF`. Mode behavior:

```sqf
case "YAW": {
    _yawCorrection = (-_yawRate * _yawStrength * _deltaTime)
        max -_maximumCorrection min _maximumCorrection;
};
case "YAW_LATERAL": {
    _lateralSpeed = _lateralSpeed * (1 - ((_lateralStrength * _deltaTime) min 0.5));
    _yawCorrection = (-_yawRate * _yawStrength * _deltaTime)
        max -_maximumCorrection min _maximumCorrection;
};
case "COUNTERSTEER": {
    private _countersteer = -_yawRate * _countersteerStrength * _deltaTime;
    _yawCorrection = (_countersteer max -_maximumCorrection) min _maximumCorrection;
};
```

The returned longitudinal value must always equal the input longitudinal value.

- [ ] **Step 4: Run the test and verify GREEN**

Run the vehicle-physics static test. Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add addons/main/config.cpp addons/main/functions/fn_getVehicleStabilityRecommendation.sqf tests/integration/fixics-vehicle-physics-static.ps1
git commit -m "Add bounded stability recommendation math"
```

### Task 3: Server-Global Settings And Localization

**Files:**
- Modify: `addons/main/functions/fn_registerSettings.sqf`
- Modify: `addons/main/stringtable.xml`
- Test: `tests/integration/fixics-vehicle-physics-static.ps1`

- [ ] **Step 1: Write the failing settings contract**

Require these server-global CBA variables:

```text
FIXICS_stabilityPreset
FIXICS_stabilityAssistMode
FIXICS_stabilityActivationSpeedKmh
FIXICS_stabilitySlipThreshold
FIXICS_stabilityYawStrength
FIXICS_stabilityLateralStrength
FIXICS_stabilityCountersteerStrength
FIXICS_stabilityMaximumCorrection
FIXICS_stabilityDebugLogging
```

Require `LIST` controls for preset and assistance mode, `SLIDER` controls for
custom values, `CHECKBOX` for logging, and CBA global flag `1` for every
setting. Require matching `STR_FIXICS_SETTING_STABILITY_*` stringtable keys.

- [ ] **Step 2: Run the test and verify RED**

Expected: FAIL because stability settings and strings are absent.

- [ ] **Step 3: Add defaults and CBA settings**

Use:

```sqf
missionNamespace setVariable ["FIXICS_stabilityPreset", 0, false];
missionNamespace setVariable ["FIXICS_stabilityAssistMode", 0, false];
missionNamespace setVariable ["FIXICS_stabilityActivationSpeedKmh", 35, false];
missionNamespace setVariable ["FIXICS_stabilitySlipThreshold", 0.12, false];
missionNamespace setVariable ["FIXICS_stabilityYawStrength", 0.22, false];
missionNamespace setVariable ["FIXICS_stabilityLateralStrength", 0.12, false];
missionNamespace setVariable ["FIXICS_stabilityCountersteerStrength", 0.08, false];
missionNamespace setVariable ["FIXICS_stabilityMaximumCorrection", 0.12, false];
missionNamespace setVariable ["FIXICS_stabilityDebugLogging", false, false];
```

Map assistance list values to `0=Off`, `1=Yaw damping`,
`2=Yaw + lateral damping`, `3=Countersteering`. Put controls under
`["FIXICS", "Vehicle Stability"]`.

- [ ] **Step 4: Add localized labels and tooltips**

Add explicit descriptions stating that settings are server-global, only
registered vehicles are eligible, and Custom values are ignored by fixed
presets.

- [ ] **Step 5: Run the test and verify GREEN**

Run the vehicle-physics static test and `tools\check.ps1`. Expected: PASS.

- [ ] **Step 6: Commit**

```powershell
git add addons/main/functions/fn_registerSettings.sqf addons/main/stringtable.xml tests/integration/fixics-vehicle-physics-static.ps1
git commit -m "Add global vehicle stability settings"
```

### Task 4: Local Stability Mutation Boundary

**Files:**
- Create: `addons/main/functions/fn_applyVehicleStability.sqf`
- Modify: `addons/main/config.cpp`
- Test: `tests/integration/fixics-vehicle-physics-static.ps1`

- [ ] **Step 1: Write the failing guard and ownership contract**

Require checks for:

```text
local _vehicle
driver _vehicle == player
isTouchingGround _vehicle
FIXICS_handbrakeEnabled
FIXICS_fnc_getVehicleStabilityProfile
FIXICS_fnc_getVehicleStabilityRecommendation
velocityModelSpace
setVelocityModelSpace
```

Require storage of previous heading/time using
`FIXICS_stabilityPreviousHeading` and `FIXICS_stabilityPreviousTime`. Fail if
the function calls ABS, slope rollback, handbrake lock, `disableBrakes`, or
changes model-space index `1`.

- [ ] **Step 2: Run the test and verify RED**

Expected: FAIL because the mutation function is absent.

- [ ] **Step 3: Implement guarded sampling**

Use this contract:

```sqf
/*
 * Arguments:
 *   0: Vehicle <OBJECT>
 *   1: Delta time <NUMBER>
 * Return: <BOOL> true when a bounded correction was applied
 */
```

Normalize aggregated input values from the observed `0..3` range:

```sqf
private _steeringInput = (((inputAction "CarRight") - (inputAction "CarLeft")) / 3) max -1 min 1;
```

Calculate wrapped heading delta and yaw rate:

```sqf
private _headingDelta = ((_heading - _previousHeading + 540) mod 360) - 180;
private _yawRate = _headingDelta / (_deltaTime max 0.001);
```

Map setting indices to mode strings and call the pure recommendation. Preserve
the current model-space longitudinal value before and after mutation:

```sqf
private _velocity = velocityModelSpace _vehicle;
private _longitudinal = _velocity # 1;
_velocity set [0, _recommendedLateral];
_vehicle setVelocityModelSpace _velocity;
```

Do not mutate orientation in this first implementation. Treat the bounded
`yawCorrection` as a diagnostic recommendation only; this prevents
countersteering from becoming unreviewed direct yaw injection.

- [ ] **Step 4: Add optional RPT evidence**

When `FIXICS_stabilityDebugLogging` is true, log class, preset, mode, speed,
slip, yaw rate, lateral before/after, unchanged longitudinal speed, and the
unused bounded yaw recommendation.

- [ ] **Step 5: Run the test and verify GREEN**

Run the vehicle-physics static test. Expected: PASS.

- [ ] **Step 6: Commit**

```powershell
git add addons/main/config.cpp addons/main/functions/fn_applyVehicleStability.sqf tests/integration/fixics-vehicle-physics-static.ps1
git commit -m "Add guarded local stability controller"
```

### Task 5: Driver Controller Integration

**Files:**
- Modify: `addons/main/functions/fn_updateDriverController.sqf`
- Test: `tests/integration/fixics-vehicle-physics-static.ps1`

- [ ] **Step 1: Write the failing integration contract**

Require `FIXICS_fnc_applyVehicleStability` and assert it appears after the
longitudinal state branches. Require every early airborne/handbrake path to
remain before stability application. Assert that existing ABS, slope,
direction-transition, and handbrake patterns remain unchanged.

- [ ] **Step 2: Run the test and verify RED**

Expected: FAIL because the driver controller does not invoke stability.

- [ ] **Step 3: Integrate without duplicating branches**

Create a local finalizer near the top:

```sqf
private _finishUpdate = {
    params ["_result"];
    [_vehicle, _deltaTime] call FIXICS_fnc_applyVehicleStability;
    _result
};
```

Use it only for grounded non-handbrake drive, reverse, coast, service-brake,
and neutral completion paths. Do not invoke it from invalid-vehicle,
airborne, or handbrake exits.

- [ ] **Step 4: Run regression validation**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
powershell -ExecutionPolicy Bypass -File tools\check.ps1
```

Expected: all PASS.

- [ ] **Step 5: Commit**

```powershell
git add addons/main/functions/fn_updateDriverController.sqf tests/integration/fixics-vehicle-physics-static.ps1
git commit -m "Integrate vehicle stability with driver controller"
```

### Task 6: SQA Evidence And Project State

**Files:**
- Modify: `docs/fixes/open-issues.md`
- Modify: `orchestration/state.md`

- [ ] **Step 1: Document the manual matrix**

Record tests for `EMP_Polaris_DAGOR` at 30, 60, 90, and 120 km/h on paved,
dirt, and grass surfaces. For each speed/surface pair test Off, Yaw damping,
Yaw + lateral damping, and Countersteering settings under both Realistic
Stable and Rally presets. Record body roll, rollover, lateral slip, recovery,
braking, handbrake, and Drive/Reverse behavior.

- [ ] **Step 2: Document the implementation boundary**

State explicitly that direct yaw/countersteering mutation and passive config
changes remain pending SQA evidence. The first release applies only bounded
lateral damping.

- [ ] **Step 3: Run final automated verification**

Run all three required repository checks plus:

```powershell
git diff --check
git status --short --branch
```

Expected: checks PASS; only intentional files and pre-existing unrelated
changes remain.

- [ ] **Step 4: Commit**

```powershell
git add docs/fixes/open-issues.md orchestration/state.md
git commit -m "Document stability assistance validation"
```

- [ ] **Step 5: Hand off to SQA**

Build with:

```powershell
powershell -ExecutionPolicy Bypass -File tools\build.ps1
```

Report the build location and request manual SQA results. Do not mark ISSUE-001
resolved until SQA verifies rollover behavior and controlled sliding in-game.

