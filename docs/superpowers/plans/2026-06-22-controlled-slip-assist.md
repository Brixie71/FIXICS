# Controlled Slip Assist Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a conservative SQF Controlled Slip Assist for registered cars/light vehicles so high-speed full-lock steering can produce controlled lateral scrub before trip rollover.

**Architecture:** Add one pure recommendation function and integrate it through the existing local stability/runtime assist path. The feature reads speed, steering demand, lateral demand, roll risk, terrain, and current sway/stability state, then returns bounded telemetry and a bounded lateral release recommendation. It does not patch tire config, force orientation, change ABS, or alter ACE handbrake/Drive-Reverse semantics.

**Tech Stack:** Arma 3 SQF, CBA settings, HEMTT, PowerShell static/integration tests.

---

## File Structure

- Create `addons/main/functions/fn_getControlledSlipRecommendation.sqf`
  - Pure math only. No vehicle mutation, no globals.
- Modify `addons/main/config.cpp`
  - Register `getControlledSlipRecommendation` in `CfgFunctions`.
- Modify `addons/main/functions/fn_registerSettings.sqf`
  - Add conservative global CBA settings.
- Modify `addons/main/functions/fn_applyVehicleStability.sqf`
  - Build controlled-slip state/settings, call pure recommendation, reduce lateral damping when appropriate, record stability decision telemetry.
- Modify `addons/main/functions/fn_coordinateVehicleAssists.sqf`
  - Propagate controlled-slip decision fields into Runtime Assist state.
- Modify `addons/main/functions/fn_logVehicleHandlingConfig.sqf`
  - Add controlled-slip fields to handling evidence and compact runtime samples.
- Modify `addons/main/stringtable.xml`
  - Add settings labels/tooltips.
- Modify `tests/integration/fixics-vehicle-physics-static.ps1`
  - Add static contracts for registration, settings, telemetry, and integration.
- Create `tests/unit/fixics-controlled-slip-recommendation.ps1`
  - Unit checks for pure recommendation behavior.
- Modify `tools/check.ps1`
  - Run the new unit test.
- Modify `docs/vehicle-behavior/sqa-evidence-matrix.md`
  - Add Controlled Slip Assist SQA rows.
- Modify `governance/audit/validation-log.md`
  - Record red/green/full validation.
- Modify `orchestration/state.md`
  - Record implementation completion/handoff state.

---

### Task 1: Static Contract For Controlled Slip Assist

**Files:**
- Modify: `tests/integration/fixics-vehicle-physics-static.ps1`

- [ ] **Step 1: Add failing static assertions**

Add assertions requiring:

```powershell
Assert-Contains $Config 'class getControlledSlipRecommendation\s*\{\s*\};' 'Controlled Slip recommendation function must be registered.'
```

In the settings contract section, add CBA setting specs:

```powershell
@{
    Variable = 'FIXICS_controlledSlipEnabled'
    ControlType = 'CHECKBOX'
    NamespaceDefault = 'true'
    Payload = 'true'
    DefaultIndex = 0
},
@{
    Variable = 'FIXICS_controlledSlipActivationSpeedKmh'
    ControlType = 'SLIDER'
    NamespaceDefault = '55'
    Payload = '[20, 140, 55, 0]'
    DefaultIndex = 2
},
@{
    Variable = 'FIXICS_controlledSlipSteeringThreshold'
    ControlType = 'SLIDER'
    NamespaceDefault = '0.65'
    Payload = '[0.1, 1, 0.65, 2]'
    DefaultIndex = 2
},
@{
    Variable = 'FIXICS_controlledSlipStrength'
    ControlType = 'SLIDER'
    NamespaceDefault = '0.16'
    Payload = '[0, 0.5, 0.16, 2]'
    DefaultIndex = 2
},
@{
    Variable = 'FIXICS_controlledSlipMaximumRelease'
    ControlType = 'SLIDER'
    NamespaceDefault = '0.22'
    Payload = '[0.01, 0.6, 0.22, 2]'
    DefaultIndex = 2
},
@{
    Variable = 'FIXICS_controlledSlipTerrainInfluence'
    ControlType = 'CHECKBOX'
    NamespaceDefault = 'true'
    Payload = 'true'
    DefaultIndex = 0
},
@{
    Variable = 'FIXICS_controlledSlipDebugLogging'
    ControlType = 'CHECKBOX'
    NamespaceDefault = 'false'
    Payload = 'false'
    DefaultIndex = 0
}
```

Add stability/telemetry field assertions:

```powershell
@(
    'controlledSlipEnabled',
    'controlledSlipEligible',
    'controlledSlipApplied',
    'controlledSlipReason',
    'controlledSlipSteeringDemand',
    'controlledSlipLateralDemand',
    'controlledSlipRollRisk',
    'controlledSlipTerrainClass',
    'controlledSlipTerrainMultiplier',
    'controlledSlipGripReleaseFactor',
    'controlledSlipCorrection',
    'controlledSlipTelemetryVersion=1'
) | ForEach-Object {
    Assert-Contains $StabilityController $_ "Stability controller must expose controlled slip telemetry field $_."
}
```

- [ ] **Step 2: Run red check**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: FAIL with missing Controlled Slip registration, settings, and telemetry fields.

---

### Task 2: Pure Recommendation Function And Unit Test

**Files:**
- Create: `addons/main/functions/fn_getControlledSlipRecommendation.sqf`
- Create: `tests/unit/fixics-controlled-slip-recommendation.ps1`
- Modify: `tools/check.ps1`
- Modify: `addons/main/config.cpp`

- [ ] **Step 1: Write unit test**

Create `tests/unit/fixics-controlled-slip-recommendation.ps1` with source-derived checks that require:

```powershell
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$Source = Get-Content -Raw -LiteralPath (Join-Path $RepoRoot 'addons\main\functions\fn_getControlledSlipRecommendation.sqf')

$Failures = New-Object System.Collections.Generic.List[string]
function RequirePattern($Pattern, $Message) {
    if ($Source -notmatch $Pattern) {
        $Failures.Add($Message)
    }
}

RequirePattern 'params\s*\[\s*\["_state",\s*createHashMap' 'Function must accept state hashmap.'
RequirePattern 'params\s*\[\s*\["_settings",\s*createHashMap' 'Function must accept settings hashmap.'
RequirePattern 'controlledSlipEligible' 'Recommendation must return eligibility telemetry.'
RequirePattern 'controlledSlipApplied' 'Recommendation must return applied telemetry.'
RequirePattern 'controlledSlipReason' 'Recommendation must return reason telemetry.'
RequirePattern 'steeringDemand' 'Recommendation must read steering demand.'
RequirePattern 'lateralDemand' 'Recommendation must calculate lateral demand.'
RequirePattern 'rollRisk' 'Recommendation must calculate roll risk.'
RequirePattern 'terrainClass' 'Recommendation must read terrain class.'
RequirePattern 'gripReleaseFactor' 'Recommendation must return grip release factor.'
RequirePattern 'maximumRelease' 'Recommendation must clamp release with maximumRelease.'
RequirePattern 'invalid' 'Invalid input must fail closed.'
RequirePattern 'below-speed-threshold' 'Low speed must fail closed.'
RequirePattern 'below-steering-threshold' 'Low steering demand must fail closed.'

if ($Failures.Count -gt 0) {
    Write-Host 'FIXICS controlled slip recommendation unit test failed:'
    $Failures | ForEach-Object { Write-Host " - $_" }
    exit 1
}

Write-Host 'FIXICS controlled slip recommendation unit test passed.'
```

- [ ] **Step 2: Run red unit test**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\unit\fixics-controlled-slip-recommendation.ps1
```

Expected: FAIL because the function does not exist yet.

- [ ] **Step 3: Implement pure function**

Create `addons/main/functions/fn_getControlledSlipRecommendation.sqf`:

```sqf
/*
 * FIXICS_fnc_getControlledSlipRecommendation
 *
 * Calculates bounded controlled lateral slip release recommendation.
 *
 * Arguments:
 *   0: State hashmap <HASHMAP>
 *   1: Settings hashmap <HASHMAP>
 *
 * Return: HashMap telemetry and recommendation values
 */
params [
    ["_state", createHashMap, [createHashMap]],
    ["_settings", createHashMap, [createHashMap]]
];

private _safeNumber = {
    params ["_map", "_key", "_default"];
    private _value = _map getOrDefault [_key, _default];
    if !(_value isEqualType 0) exitWith {_default};
    if (!finite _value) exitWith {_default};
    _value
};

private _result = createHashMapFromArray [
    ["controlledSlipEligible", false],
    ["controlledSlipApplied", false],
    ["controlledSlipReason", "invalid"],
    ["controlledSlipSteeringDemand", 0],
    ["controlledSlipLateralDemand", 0],
    ["controlledSlipRollRisk", 0],
    ["controlledSlipTerrainClass", "unknown"],
    ["controlledSlipTerrainMultiplier", 1],
    ["controlledSlipGripReleaseFactor", 0],
    ["controlledSlipCorrection", 0]
];

private _enabled = _settings getOrDefault ["enabled", true];
if (!_enabled) exitWith {
    _result set ["controlledSlipReason", "disabled"];
    _result
};

private _speedKmh = [_state, "speedKmh", 0] call _safeNumber;
private _steeringDemand = abs ([_state, "steeringDemand", 0] call _safeNumber);
private _lateralSpeed = [_state, "lateralSpeed", 0] call _safeNumber;
private _longitudinalSpeed = abs ([_state, "longitudinalSpeed", 0] call _safeNumber);
private _bank = abs ([_state, "bank", 0] call _safeNumber);
private _bankRate = abs ([_state, "bankRate", 0] call _safeNumber);
private _activationSpeedKmh = ([_settings, "activationSpeedKmh", 55] call _safeNumber) max 0 min 180;
private _steeringThreshold = ([_settings, "steeringThreshold", 0.65] call _safeNumber) max 0 min 1;
private _strength = ([_settings, "strength", 0.16] call _safeNumber) max 0 min 0.5;
private _maximumRelease = ([_settings, "maximumRelease", 0.22] call _safeNumber) max 0 min 0.6;
private _terrainInfluence = _settings getOrDefault ["terrainInfluence", true];
private _terrainClass = _state getOrDefault ["terrainClass", "unknown"];

private _lateralDemand = (abs _lateralSpeed) / (_longitudinalSpeed max 1);
_lateralDemand = _lateralDemand max 0 min 1;
private _rollRisk = ((_bank / 45) max (_bankRate / 180)) max 0 min 1;
private _terrainMultiplier = switch (_terrainClass) do {
    case "paved": {0.75};
    case "dirt": {1};
    case "grass": {1.15};
    default {0.9};
};
if (!_terrainInfluence) then {
    _terrainMultiplier = 1;
};

_result set ["controlledSlipSteeringDemand", _steeringDemand max 0 min 1];
_result set ["controlledSlipLateralDemand", _lateralDemand];
_result set ["controlledSlipRollRisk", _rollRisk];
_result set ["controlledSlipTerrainClass", _terrainClass];
_result set ["controlledSlipTerrainMultiplier", _terrainMultiplier];

if (_speedKmh < _activationSpeedKmh) exitWith {
    _result set ["controlledSlipReason", "below-speed-threshold"];
    _result
};
if (_steeringDemand < _steeringThreshold) exitWith {
    _result set ["controlledSlipReason", "below-steering-threshold"];
    _result
};

private _releaseDemand = ((_steeringDemand - _steeringThreshold) / ((1 - _steeringThreshold) max 0.001)) max 0 min 1;
private _gripReleaseFactor = (_releaseDemand * (0.35 + (_rollRisk * 0.65)) * _terrainMultiplier) max 0 min 1;
private _correction = (_lateralSpeed * _strength * _gripReleaseFactor) max -_maximumRelease min _maximumRelease;

_result set ["controlledSlipEligible", true];
_result set ["controlledSlipGripReleaseFactor", _gripReleaseFactor];
_result set ["controlledSlipCorrection", _correction];
_result set ["controlledSlipApplied", (abs _correction) > 0.0001];
_result set ["controlledSlipReason", ["eligible-no-correction", "controlled-slip"] select ((abs _correction) > 0.0001)];

_result
```

- [ ] **Step 4: Register function**

In `addons/main/config.cpp`, add:

```cpp
class getControlledSlipRecommendation {};
```

under FIXICS main functions.

- [ ] **Step 5: Add unit test to check script**

In `tools/check.ps1`, run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\unit\fixics-controlled-slip-recommendation.ps1
```

following the existing unit test pattern.

- [ ] **Step 6: Verify green**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\unit\fixics-controlled-slip-recommendation.ps1
powershell -ExecutionPolicy Bypass -File tools\check.ps1
```

Expected: unit test passes; `tools/check.ps1` compiles 25 SQF files and passes.

---

### Task 3: Settings And Stringtable

**Files:**
- Modify: `addons/main/functions/fn_registerSettings.sqf`
- Modify: `addons/main/stringtable.xml`
- Test: `tests/integration/fixics-vehicle-physics-static.ps1`

- [ ] **Step 1: Register defaults**

Add mission namespace defaults:

```sqf
missionNamespace setVariable ["FIXICS_controlledSlipEnabled", true, false];
missionNamespace setVariable ["FIXICS_controlledSlipActivationSpeedKmh", 55, false];
missionNamespace setVariable ["FIXICS_controlledSlipSteeringThreshold", 0.65, false];
missionNamespace setVariable ["FIXICS_controlledSlipStrength", 0.16, false];
missionNamespace setVariable ["FIXICS_controlledSlipMaximumRelease", 0.22, false];
missionNamespace setVariable ["FIXICS_controlledSlipTerrainInfluence", true, false];
missionNamespace setVariable ["FIXICS_controlledSlipDebugLogging", false, false];
```

- [ ] **Step 2: Add CBA settings**

Add settings under `["FIXICS", "Vehicle Stability"]`:

```sqf
[
    "FIXICS_controlledSlipEnabled",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_CONTROLLED_SLIP_ENABLED",
        localize "STR_FIXICS_SETTING_CONTROLLED_SLIP_ENABLED_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    true,
    1
] call CBA_fnc_addSetting;
```

Repeat for the sliders and debug checkbox using the payloads from Task 1.

- [ ] **Step 3: Add stringtable entries**

Add labels/tooltips:

```xml
<Key ID="STR_FIXICS_SETTING_CONTROLLED_SLIP_ENABLED">
    <Original>Enable controlled slip assist</Original>
</Key>
<Key ID="STR_FIXICS_SETTING_CONTROLLED_SLIP_ENABLED_TOOLTIP">
    <Original>Allows bounded lateral scrub during high-speed steering so eligible cars can slide before trip rollover. This is not tire config simulation.</Original>
</Key>
```

Add equivalent entries for activation speed, steering threshold, strength,
maximum release, terrain influence, and debug logging.

- [ ] **Step 4: Verify settings contract**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: settings/stringtable assertions pass.

---

### Task 4: Stability Integration

**Files:**
- Modify: `addons/main/functions/fn_applyVehicleStability.sqf`
- Test: `tests/integration/fixics-vehicle-physics-static.ps1`

- [ ] **Step 1: Build state and settings**

After steering, yaw, bank, and velocity values are available, build:

```sqf
private _controlledSlipState = createHashMapFromArray [
    ["speedKmh", _speedKmh],
    ["steeringDemand", abs _steeringInput],
    ["lateralSpeed", _lateral],
    ["longitudinalSpeed", _longitudinal],
    ["bank", _bank],
    ["bankRate", _bankRate],
    ["terrainClass", _terrainClass]
];
```

Use a small local terrain classifier:

```sqf
private _surface = surfaceType (getPosWorld _vehicle);
private _terrainClass = switch (true) do {
    case (_surface find "#GdtAsphalt" >= 0): {"paved"};
    case (_surface find "#GdtConcrete" >= 0): {"paved"};
    case (_surface find "#GdtDirt" >= 0): {"dirt"};
    case (_surface find "#GdtGrass" >= 0): {"grass"};
    default {"unknown"};
};
```

Settings:

```sqf
private _controlledSlipSettings = createHashMapFromArray [
    ["enabled", missionNamespace getVariable ["FIXICS_controlledSlipEnabled", true]],
    ["activationSpeedKmh", missionNamespace getVariable ["FIXICS_controlledSlipActivationSpeedKmh", 55]],
    ["steeringThreshold", missionNamespace getVariable ["FIXICS_controlledSlipSteeringThreshold", 0.65]],
    ["strength", missionNamespace getVariable ["FIXICS_controlledSlipStrength", 0.16]],
    ["maximumRelease", missionNamespace getVariable ["FIXICS_controlledSlipMaximumRelease", 0.22]],
    ["terrainInfluence", missionNamespace getVariable ["FIXICS_controlledSlipTerrainInfluence", true]]
];
```

- [ ] **Step 2: Call pure recommendation**

```sqf
private _controlledSlipDecision = [
    _controlledSlipState,
    _controlledSlipSettings
] call FIXICS_fnc_getControlledSlipRecommendation;
```

- [ ] **Step 3: Apply bounded lateral release**

If applied, reduce the lateral correction rather than adding grip:

```sqf
private _controlledSlipCorrection = _controlledSlipDecision getOrDefault ["controlledSlipCorrection", 0];
if ((_controlledSlipDecision getOrDefault ["controlledSlipApplied", false]) && {_controlledSlipCorrection != 0}) then {
    _velocity set [0, (_velocity # 0) - _controlledSlipCorrection];
    _stabilityDecision set ["controlledSlipDelta", -_controlledSlipCorrection];
};
```

This must run after ordinary stability recommendation so it can loosen over-planted lateral damping.

- [ ] **Step 4: Store telemetry fields**

Set on `_stabilityDecision`:

```sqf
_stabilityDecision set ["controlledSlipEnabled", missionNamespace getVariable ["FIXICS_controlledSlipEnabled", true]];
_stabilityDecision set ["controlledSlipEligible", _controlledSlipDecision getOrDefault ["controlledSlipEligible", false]];
_stabilityDecision set ["controlledSlipApplied", _controlledSlipDecision getOrDefault ["controlledSlipApplied", false]];
_stabilityDecision set ["controlledSlipReason", _controlledSlipDecision getOrDefault ["controlledSlipReason", "not-evaluated"]];
_stabilityDecision set ["controlledSlipSteeringDemand", _controlledSlipDecision getOrDefault ["controlledSlipSteeringDemand", 0]];
_stabilityDecision set ["controlledSlipLateralDemand", _controlledSlipDecision getOrDefault ["controlledSlipLateralDemand", 0]];
_stabilityDecision set ["controlledSlipRollRisk", _controlledSlipDecision getOrDefault ["controlledSlipRollRisk", 0]];
_stabilityDecision set ["controlledSlipTerrainClass", _controlledSlipDecision getOrDefault ["controlledSlipTerrainClass", "unknown"]];
_stabilityDecision set ["controlledSlipTerrainMultiplier", _controlledSlipDecision getOrDefault ["controlledSlipTerrainMultiplier", 1]];
_stabilityDecision set ["controlledSlipGripReleaseFactor", _controlledSlipDecision getOrDefault ["controlledSlipGripReleaseFactor", 0]];
_stabilityDecision set ["controlledSlipCorrection", _controlledSlipCorrection];
```

- [ ] **Step 5: Extend debug line**

Add all controlled slip fields to the `[FIXICS][Stability]` `diag_log` format and arguments, ending with:

```text
controlledSlipTelemetryVersion=1
```

- [ ] **Step 6: Verify stability static contract**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: controlled-slip integration assertions pass.

---

### Task 5: Runtime Assist And Handling Telemetry

**Files:**
- Modify: `addons/main/functions/fn_coordinateVehicleAssists.sqf`
- Modify: `addons/main/functions/fn_logVehicleHandlingConfig.sqf`
- Test: `tests/integration/fixics-vehicle-physics-static.ps1`

- [ ] **Step 1: Propagate runtime fields**

In `fn_coordinateVehicleAssists.sqf`, copy controlled-slip fields from
`FIXICS_stabilityLastDecision` into `FIXICS_runtimeAssistLastDecision`:

```sqf
_decision set ["controlledSlipEligible", _stabilityDecision getOrDefault ["controlledSlipEligible", false]];
_decision set ["controlledSlipApplied", _stabilityDecision getOrDefault ["controlledSlipApplied", false]];
_decision set ["controlledSlipReason", _stabilityDecision getOrDefault ["controlledSlipReason", "not-evaluated"]];
_decision set ["controlledSlipGripReleaseFactor", _stabilityDecision getOrDefault ["controlledSlipGripReleaseFactor", 0]];
_decision set ["controlledSlipCorrection", _stabilityDecision getOrDefault ["controlledSlipCorrection", 0]];
```

If `controlledSlipApplied` is true and no roll priority is active, allow
`priorityWinner` to report `controlled-slip`.

- [ ] **Step 2: Extend Runtime Assist debug**

Add controlled-slip fields to `[FIXICS][RuntimeAssist]` debug output.

- [ ] **Step 3: Extend handling evidence**

In `fn_logVehicleHandlingConfig.sqf`, add fields to the one-shot evidence array
and continuous sample:

```sqf
["controlledSlipEligible", _runtimeAssistDecision getOrDefault ["controlledSlipEligible", false]],
["controlledSlipApplied", _runtimeAssistDecision getOrDefault ["controlledSlipApplied", false]],
["controlledSlipReason", _runtimeAssistDecision getOrDefault ["controlledSlipReason", "not-evaluated"]],
["controlledSlipGripReleaseFactor", _runtimeAssistDecision getOrDefault ["controlledSlipGripReleaseFactor", 0]],
["controlledSlipCorrection", _runtimeAssistDecision getOrDefault ["controlledSlipCorrection", 0]]
```

Add the same fields to `[FIXICS][RuntimeAssistSample]`.

- [ ] **Step 4: Verify telemetry static contract**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: handling/runtime telemetry assertions pass.

---

### Task 6: Evidence Matrix And State

**Files:**
- Modify: `docs/vehicle-behavior/sqa-evidence-matrix.md`
- Modify: `orchestration/state.md`
- Modify: `governance/audit/validation-log.md`

- [ ] **Step 1: Add evidence rows**

Add three rows for Controlled Slip Assist:

```markdown
| 2026-06-22 | SQA | `registered light vehicles` | Paved | 30/60/90/120 km/h | Full left/right steering, braking while turning, recovery after slide | subsystem presets separate | selected by SQA | selected by SQA | `pending SQA telemetry` | Controlled Slip Assist paved validation row. Record controlled slip eligibility, grip release factor, roll bank, bank rate, and recovery behavior. | `controlled-slip-assist`, `rollover-risk` | `collect-more-telemetry` |
| 2026-06-22 | SQA | `registered light vehicles` | Dirt | 30/60/90/120 km/h | Full left/right steering, braking while turning, recovery after slide | subsystem presets separate | selected by SQA | selected by SQA | `pending SQA telemetry` | Controlled Slip Assist dirt validation row. Confirm earlier controlled scrub than paved without ice-like behavior. | `controlled-slip-assist`, `terrain-interaction` | `collect-more-telemetry` |
| 2026-06-22 | SQA | `registered light vehicles` | Grass | 30/60/90/120 km/h | Full left/right steering, braking while turning, recovery after slide | subsystem presets separate | selected by SQA | selected by SQA | `pending SQA telemetry` | Controlled Slip Assist grass validation row. Confirm loose terrain behavior and bounded correction. | `controlled-slip-assist`, `terrain-interaction` | `collect-more-telemetry` |
```

- [ ] **Step 2: Update state**

Record Controlled Slip Assist implementation status and SQA handoff in
`orchestration/state.md`.

- [ ] **Step 3: Update validation log**

Record red/green unit/static checks and full validation results in
`governance/audit/validation-log.md`.

---

### Task 7: Full Validation And Build

**Files:**
- Validate only

- [ ] **Step 1: Run required validation**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
powershell -ExecutionPolicy Bypass -File tools\check.ps1
git diff --check
```

Expected:

- governance static passed;
- vehicle physics static passed;
- HEMTT compiles 25 SQF files;
- controlled slip unit test passed;
- whitespace check passed with only CRLF warnings if any.

- [ ] **Step 2: Build test artifact**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools\build.ps1
```

Expected:

- HEMTT builds 1 PBO;
- updated artifact at `.hemttout/build/addons/fixics_main.pbo`;
- existing stringtable sort warning may remain.

- [ ] **Step 3: SQA handoff**

Tell SQA to test:

```sqf
missionNamespace setVariable ["FIXICS_controlledSlipDebugLogging", true, false];
missionNamespace setVariable ["FIXICS_stabilityDebugLogging", true, false];
systemChat format [
    "controlledSlip=%1 stabilityDebug=%2",
    missionNamespace getVariable ["FIXICS_controlledSlipDebugLogging", false],
    missionNamespace getVariable ["FIXICS_stabilityDebugLogging", false]
];
```

Then run:

```sqf
[vehicle player, 180, 0.1] call FIXICS_fnc_logVehicleHandlingConfig;
```

Export:

```powershell
powershell -ExecutionPolicy Bypass -File tools\export-vehicle-telemetry.ps1 -IncludeEvidenceHeader
```

Manual QA focus:

- `B_LSV_01_unarmed_F` first;
- full-lock left/right at 60, 90, and 120 km/h;
- compare paved/dirt/grass;
- confirm controlled slide appears before extreme bank;
- confirm it does not feel icy;
- confirm ABS, ACE handbrake, Drive/Reverse, Roll Stability, and Sway Bar behavior remain intact.

---

## Self-Review

- Spec coverage: The plan covers SQF-first implementation, registered light vehicles, real tire behavior as design target, game-feel references as non-technical sources, settings, telemetry, evidence matrix, validation, and SQA handoff.
- Placeholder scan: No incomplete work markers are intentionally left.
- Type consistency: Controlled Slip uses hashmaps for pure recommendation and existing stability/runtime decision propagation, matching current Runtime Assist patterns.
