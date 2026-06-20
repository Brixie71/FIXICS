# Roll Stability Assist Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a separate, server-global Roll Stability Assist layer that reduces rollover energy while preserving existing yaw/lateral stability modes.

**Architecture:** Keep yaw/lateral recommendation logic unchanged. Add a small pure roll recommendation function, call it from `FIXICS_fnc_applyVehicleStability` after the existing lateral correction path, and expose explicit CBA settings. The first implementation only changes model-space vertical velocity and never mutates orientation.

**Tech Stack:** Arma 3 SQF, CBA settings, HEMTT, PowerShell static tests.

---

## File Map

- Modify `addons/main/config.cpp`: register the new roll recommendation function.
- Create `addons/main/functions/fn_getRollStabilityRecommendation.sqf`: pure bounded roll correction math.
- Modify `addons/main/functions/fn_applyVehicleStability.sqf`: sample bank/bank-rate, manage ground grace, call roll recommendation, apply vertical correction.
- Modify `addons/main/functions/fn_registerSettings.sqf`: add roll settings defaults and CBA controls.
- Modify `addons/main/stringtable.xml`: add setting labels/tooltips.
- Modify `tests/integration/fixics-vehicle-physics-static.ps1`: static contracts for settings, function registration, controller guards, and safe mutation boundaries.
- Create `tests/unit/fixics-roll-stability-recommendation.ps1`: source-derived unit contract for pure roll math.
- Modify `tools/check.ps1` only if it does not already run all unit tests through the existing stability test chain.
- Modify `orchestration/state.md`: record that Roll Stability Assist is implemented and awaiting SQA validation.

---

### Task 1: Add Static Contract For Roll Assist Surface

**Files:**
- Modify: `tests/integration/fixics-vehicle-physics-static.ps1`
- Test: `tests/integration/fixics-vehicle-physics-static.ps1`

- [ ] **Step 1: Write failing static assertions**

Add assertions for the new function file and config registration near existing stability assertions:

```powershell
Assert-Contains $Config 'class getRollStabilityRecommendation\s*\{\s*\};' 'getRollStabilityRecommendation must be registered in CfgFunctions.'
Assert-FileExists 'addons\main\functions\fn_getRollStabilityRecommendation.sqf'
```

Add setting assertions near existing stability setting checks:

```powershell
@(
    'FIXICS_rollStabilityEnabled',
    'FIXICS_rollActivationBankDeg',
    'FIXICS_rollActivationRateDeg',
    'FIXICS_rollStrength',
    'FIXICS_rollMaximumCorrection',
    'FIXICS_rollAirborneGraceSeconds'
) | ForEach-Object {
    Assert-Contains $RegisterSettings $_ "Roll Stability setting $_ must be registered."
    Assert-Contains $Stringtable $_ "Roll Stability setting $_ must have localized text."
}
```

Add controller safety assertions:

```powershell
Assert-Contains $StabilityController 'FIXICS_fnc_getRollStabilityRecommendation' 'Stability controller must call the pure roll recommendation function.'
Assert-Contains $StabilityController '_vehicle call BIS_fnc_getPitchBank' 'Stability controller must sample bank with the vehicle object directly.'
Assert-Contains $StabilityController 'FIXICS_rollLastGroundedAt' 'Stability controller must track recent ground contact for roll grace.'
Assert-Contains $StabilityController 'FIXICS_rollPreviousBank' 'Stability controller must store prior bank for bank-rate calculation.'
Assert-Contains $StabilityController '_velocity set \[2, _recommendedVertical\];' 'Roll assist may only apply its vertical recommendation at model-space index 2.'
if ($StabilityController -match 'setVectorDirAndUp|setDir') {
    Add-Failure 'Roll Stability Assist must not mutate vehicle orientation.'
}
```

Update mutation count expectations so the controller may contain two array `set` operations and two `setVelocityModelSpace` calls:

```powershell
if ($ArraySetMatches.Count -ne 2) {
    $ContractFailures.Add('Stability controller must contain exactly two array set operations: lateral and roll vertical.')
}
if ($VelocityMutationMatches.Count -ne 2) {
    $ContractFailures.Add('Stability controller must contain exactly two model-space velocity mutations: lateral and roll vertical.')
}
if ($Content -match '\w+\s+set\s+\[\s*1\s*,') {
    $ContractFailures.Add('Stability controller must not mutate longitudinal vector index 1.')
}
```

- [ ] **Step 2: Run the static test and confirm failure**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: FAIL for missing roll function, settings, and controller integration.

- [ ] **Step 3: Commit the failing contract**

```powershell
git add tests\integration\fixics-vehicle-physics-static.ps1
git commit -m "Add roll stability static contract"
```

---

### Task 2: Add Pure Roll Recommendation Function

**Files:**
- Create: `addons/main/functions/fn_getRollStabilityRecommendation.sqf`
- Modify: `addons/main/config.cpp`
- Create: `tests/unit/fixics-roll-stability-recommendation.ps1`
- Test: `tests/unit/fixics-roll-stability-recommendation.ps1`

- [ ] **Step 1: Write source-derived unit test**

Create `tests/unit/fixics-roll-stability-recommendation.ps1`:

```powershell
param ([string]$SqfPath)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ([string]::IsNullOrWhiteSpace($SqfPath)) {
    $SqfPath = Join-Path $RepoRoot 'addons\main\functions\fn_getRollStabilityRecommendation.sqf'
}
$Sqf = Get-Content -Raw -LiteralPath $SqfPath

function Require-Match {
    param([string]$Pattern, [string]$Description)
    if ($Sqf -notmatch $Pattern) {
        throw "SQF source contract missing: $Description"
    }
}

Require-Match 'params\s*\[[\s\S]*?_verticalSpeed[\s\S]*?_bankDeg[\s\S]*?_bankRateDeg[\s\S]*?_deltaTime[\s\S]*?_settings' 'expected function parameters'
Require-Match '!finite\s+_verticalSpeed[\s\S]*?!finite\s+_bankDeg[\s\S]*?!finite\s+_bankRateDeg[\s\S]*?!finite\s+_deltaTime' 'finite guard'
Require-Match '_activationBankDeg\s*=\s*\(_activationBankDeg\s+max\s+5\)\s+min\s+60;' 'bank threshold clamp'
Require-Match '_activationRateDeg\s*=\s*\(_activationRateDeg\s+max\s+5\)\s+min\s+240;' 'bank-rate threshold clamp'
Require-Match '_rollStrength\s*=\s*\(_rollStrength\s+max\s+0\)\s+min\s+0\.5;' 'strength clamp'
Require-Match '_maximumCorrection\s*=\s*\(_maximumCorrection\s+max\s+0\.01\)\s+min\s+0\.4;' 'maximum correction clamp'
Require-Match 'private\s+_bankSeverity\s*=' 'bank severity calculation'
Require-Match 'private\s+_rateSeverity\s*=' 'bank-rate severity calculation'
Require-Match 'private\s+_severity\s*=\s*\(_bankSeverity\s+max\s+_rateSeverity\)\s+min\s+1;' 'bounded severity'
Require-Match '_recommendedVertical\s*=\s*_verticalSpeed\s*\*\s*\(1\s*-\s*_damping\);' 'vertical damping expression'
Require-Match '\[\s*_applied,\s*_recommendedVertical,\s*_correction,\s*_severity\s*\]' 'return tuple'

Write-Host 'FIXICS roll stability recommendation source-derived test passed.'
```

- [ ] **Step 2: Run unit test and confirm failure**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\unit\fixics-roll-stability-recommendation.ps1
```

Expected: FAIL because the SQF file does not exist.

- [ ] **Step 3: Implement the pure function**

Create `addons/main/functions/fn_getRollStabilityRecommendation.sqf`:

```sqf
/*
 * FIXICS_fnc_getRollStabilityRecommendation
 *
 * Pure roll-stability recommendation for model-space vertical velocity.
 *
 * Arguments:
 *   0: Vertical speed <NUMBER>
 *   1: Bank angle in degrees <NUMBER>
 *   2: Bank rate in degrees per second <NUMBER>
 *   3: Delta time <NUMBER>
 *   4: Settings [activationBankDeg, activationRateDeg, strength, maximumCorrection] <ARRAY>
 *
 * Return: [applied, recommendedVertical, correction, severity] <ARRAY>
 */
params [
    ["_verticalSpeed", 0, [0]],
    ["_bankDeg", 0, [0]],
    ["_bankRateDeg", 0, [0]],
    ["_deltaTime", 0, [0]],
    ["_settings", [], [[]]]
];

if (
    !finite _verticalSpeed
    || {!finite _bankDeg}
    || {!finite _bankRateDeg}
    || {!finite _deltaTime}
    || {(count _settings) < 4}
) exitWith {
    [false, _verticalSpeed, 0, 0]
};

_settings params [
    ["_activationBankDeg", 18, [0]],
    ["_activationRateDeg", 45, [0]],
    ["_rollStrength", 0.08, [0]],
    ["_maximumCorrection", 0.08, [0]]
];

if (
    !finite _activationBankDeg
    || {!finite _activationRateDeg}
    || {!finite _rollStrength}
    || {!finite _maximumCorrection}
) exitWith {
    [false, _verticalSpeed, 0, 0]
};

_activationBankDeg = (_activationBankDeg max 5) min 60;
_activationRateDeg = (_activationRateDeg max 5) min 240;
_rollStrength = (_rollStrength max 0) min 0.5;
_maximumCorrection = (_maximumCorrection max 0.01) min 0.4;
_deltaTime = (_deltaTime max 0) min 1;

private _bankSeverity = (((abs _bankDeg) - _activationBankDeg) / _activationBankDeg) max 0;
private _rateSeverity = (((abs _bankRateDeg) - _activationRateDeg) / _activationRateDeg) max 0;
private _severity = (_bankSeverity max _rateSeverity) min 1;

if (_severity <= 0 || {_rollStrength <= 0}) exitWith {
    [false, _verticalSpeed, 0, 0]
};

private _damping = (_rollStrength * _severity * _deltaTime) min _maximumCorrection;
private _recommendedVertical = _verticalSpeed * (1 - _damping);
private _correction = _recommendedVertical - _verticalSpeed;
private _applied = _recommendedVertical != _verticalSpeed;

[
    _applied,
    _recommendedVertical,
    _correction,
    _severity
]
```

- [ ] **Step 4: Register the function**

In `addons/main/config.cpp`, add this beside existing stability functions:

```cpp
class getRollStabilityRecommendation {};
```

- [ ] **Step 5: Verify unit and static tests pass for this layer**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\unit\fixics-roll-stability-recommendation.ps1
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: unit test PASS; static test still FAIL for missing settings/controller integration.

- [ ] **Step 6: Commit**

```powershell
git add addons\main\config.cpp addons\main\functions\fn_getRollStabilityRecommendation.sqf tests\unit\fixics-roll-stability-recommendation.ps1
git commit -m "Add roll stability recommendation math"
```

---

### Task 3: Add CBA Settings And Localization

**Files:**
- Modify: `addons/main/functions/fn_registerSettings.sqf`
- Modify: `addons/main/stringtable.xml`
- Test: `tests/integration/fixics-vehicle-physics-static.ps1`

- [ ] **Step 1: Add default missionNamespace values**

In `fn_registerSettings.sqf`, after existing stability defaults, add:

```sqf
missionNamespace setVariable ["FIXICS_rollStabilityEnabled", true, false];
missionNamespace setVariable ["FIXICS_rollActivationBankDeg", 18, false];
missionNamespace setVariable ["FIXICS_rollActivationRateDeg", 45, false];
missionNamespace setVariable ["FIXICS_rollStrength", 0.08, false];
missionNamespace setVariable ["FIXICS_rollMaximumCorrection", 0.08, false];
missionNamespace setVariable ["FIXICS_rollAirborneGraceSeconds", 0.35, false];
```

- [ ] **Step 2: Register CBA controls**

Add these after the existing stability settings:

```sqf
[
    "FIXICS_rollStabilityEnabled",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_ROLL_STABILITY_ENABLED",
        localize "STR_FIXICS_SETTING_ROLL_STABILITY_ENABLED_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    true,
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_rollActivationBankDeg",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_ROLL_ACTIVATION_BANK",
        localize "STR_FIXICS_SETTING_ROLL_ACTIVATION_BANK_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    [5, 60, 18, 0],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_rollActivationRateDeg",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_ROLL_ACTIVATION_RATE",
        localize "STR_FIXICS_SETTING_ROLL_ACTIVATION_RATE_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    [5, 240, 45, 0],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_rollStrength",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_ROLL_STRENGTH",
        localize "STR_FIXICS_SETTING_ROLL_STRENGTH_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    [0, 0.5, 0.08, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_rollMaximumCorrection",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_ROLL_MAXIMUM_CORRECTION",
        localize "STR_FIXICS_SETTING_ROLL_MAXIMUM_CORRECTION_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    [0.01, 0.4, 0.08, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_rollAirborneGraceSeconds",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_ROLL_AIRBORNE_GRACE",
        localize "STR_FIXICS_SETTING_ROLL_AIRBORNE_GRACE_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    [0, 1, 0.35, 2],
    1
] call CBA_fnc_addSetting;
```

- [ ] **Step 3: Add stringtable keys**

Add keys:

```xml
<Key ID="STR_FIXICS_SETTING_ROLL_STABILITY_ENABLED">
    <Original>Roll stability assist</Original>
</Key>
<Key ID="STR_FIXICS_SETTING_ROLL_STABILITY_ENABLED_TOOLTIP">
    <Original>Server-global rollover mitigation for registered vehicles. Targets dangerous bank and bank-rate without changing steering modes.</Original>
</Key>
<Key ID="STR_FIXICS_SETTING_ROLL_ACTIVATION_BANK">
    <Original>Roll activation bank</Original>
</Key>
<Key ID="STR_FIXICS_SETTING_ROLL_ACTIVATION_BANK_TOOLTIP">
    <Original>Bank angle in degrees where Roll Stability Assist may begin damping rollover energy.</Original>
</Key>
<Key ID="STR_FIXICS_SETTING_ROLL_ACTIVATION_RATE">
    <Original>Roll activation rate</Original>
</Key>
<Key ID="STR_FIXICS_SETTING_ROLL_ACTIVATION_RATE_TOOLTIP">
    <Original>Bank-rate threshold in degrees per second where Roll Stability Assist may begin damping rapid roll buildup.</Original>
</Key>
<Key ID="STR_FIXICS_SETTING_ROLL_STRENGTH">
    <Original>Roll strength</Original>
</Key>
<Key ID="STR_FIXICS_SETTING_ROLL_STRENGTH_TOOLTIP">
    <Original>How strongly Roll Stability Assist reduces dangerous model-space vertical motion once bank or bank-rate thresholds are crossed.</Original>
</Key>
<Key ID="STR_FIXICS_SETTING_ROLL_MAXIMUM_CORRECTION">
    <Original>Roll maximum correction</Original>
</Key>
<Key ID="STR_FIXICS_SETTING_ROLL_MAXIMUM_CORRECTION_TOOLTIP">
    <Original>Maximum roll correction per update. Lower values feel smoother; higher values intervene more sharply.</Original>
</Key>
<Key ID="STR_FIXICS_SETTING_ROLL_AIRBORNE_GRACE">
    <Original>Roll airborne grace</Original>
</Key>
<Key ID="STR_FIXICS_SETTING_ROLL_AIRBORNE_GRACE_TOOLTIP">
    <Original>Short time after ground contact where Roll Stability Assist may continue during a rollover transition.</Original>
</Key>
```

- [ ] **Step 4: Run static test**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: settings assertions PASS; controller integration still FAIL.

- [ ] **Step 5: Commit**

```powershell
git add addons\main\functions\fn_registerSettings.sqf addons\main\stringtable.xml
git commit -m "Add roll stability settings"
```

---

### Task 4: Integrate Roll Assist Into Stability Controller

**Files:**
- Modify: `addons/main/functions/fn_applyVehicleStability.sqf`
- Test: `tests/integration/fixics-vehicle-physics-static.ps1`

- [ ] **Step 1: Replace yaw-only clear helper with stability sample clear helper**

Update helper name and content:

```sqf
private _clearStabilitySamples = {
    params ["_sampleVehicle"];

    _sampleVehicle setVariable ["FIXICS_stabilityPreviousHeading", nil, false];
    _sampleVehicle setVariable ["FIXICS_stabilityPreviousTime", nil, false];
    _sampleVehicle setVariable ["FIXICS_rollPreviousBank", nil, false];
    _sampleVehicle setVariable ["FIXICS_rollPreviousTime", nil, false];
};
```

Use `_clearStabilitySamples` in every existing guard that currently calls `_clearYawSample`.

- [ ] **Step 2: Keep recent ground contact before airborne rejection**

Before airborne checks, add:

```sqf
private _now = diag_tickTime;
private _isGrounded = isTouchingGround _vehicle;
if (_isGrounded) then {
    _vehicle setVariable ["FIXICS_rollLastGroundedAt", _now, false];
};
```

Do not exit solely because airborne. Instead, yaw/lateral correction remains grounded-only, while roll assist may use grace.

- [ ] **Step 3: Keep existing yaw/lateral path grounded-only**

Wrap the existing recommendation and lateral mutation in:

```sqf
private _lateralApplied = false;
if (_isGrounded) then {
    // existing yaw/lateral recommendation and lateral setVelocityModelSpace path
};
```

Return logic must wait until after roll assist so roll can apply even when lateral did not.

- [ ] **Step 4: Add roll sample and eligibility after lateral path**

Add after the existing lateral path:

```sqf
private _rollApplied = false;
private _rollEnabled = missionNamespace getVariable ["FIXICS_rollStabilityEnabled", true];
private _lastGroundedAt = _vehicle getVariable ["FIXICS_rollLastGroundedAt", _now];
private _airborneGrace = (missionNamespace getVariable ["FIXICS_rollAirborneGraceSeconds", 0.35]) max 0 min 1;
private _withinRollGrace = _isGrounded || {(_now - _lastGroundedAt) <= _airborneGrace};

if (_rollEnabled && {_withinRollGrace}) then {
    private _pitchBank = _vehicle call BIS_fnc_getPitchBank;
    private _bank = _pitchBank # 1;
    private _previousBank = _vehicle getVariable ["FIXICS_rollPreviousBank", _bank];
    private _previousBankTime = _vehicle getVariable ["FIXICS_rollPreviousTime", _now];
    private _bankDelta = _bank - _previousBank;
    private _bankElapsed = (_now - _previousBankTime) max 0.001;
    private _bankRate = _bankDelta / _bankElapsed;

    _vehicle setVariable ["FIXICS_rollPreviousBank", _bank, false];
    _vehicle setVariable ["FIXICS_rollPreviousTime", _now, false];

    private _rollVelocity = velocityModelSpace _vehicle;
    private _rollLongitudinal = _rollVelocity # 1;
    private _rollVertical = _rollVelocity # 2;
    private _rollSpeedKmh = (abs _rollLongitudinal) * 3.6;

    if (_rollSpeedKmh >= (_profile # 1)) then {
        private _rollRecommendation = [
            _rollVertical,
            _bank,
            _bankRate,
            _deltaTime,
            [
                missionNamespace getVariable ["FIXICS_rollActivationBankDeg", 18],
                missionNamespace getVariable ["FIXICS_rollActivationRateDeg", 45],
                missionNamespace getVariable ["FIXICS_rollStrength", 0.08],
                missionNamespace getVariable ["FIXICS_rollMaximumCorrection", 0.08]
            ]
        ] call FIXICS_fnc_getRollStabilityRecommendation;

        _rollRecommendation params [
            ["_recommendedRoll", false, [false]],
            ["_recommendedVertical", _rollVertical, [0]],
            ["_rollCorrection", 0, [0]],
            ["_rollSeverity", 0, [0]]
        ];

        if (_recommendedRoll && {_recommendedVertical != _rollVertical}) then {
            _rollVelocity set [2, _recommendedVertical];
            _vehicle setVelocityModelSpace _rollVelocity;
            _rollApplied = true;

            if (missionNamespace getVariable ["FIXICS_stabilityDebugLogging", false]) then {
                diag_log format [
                    "[FIXICS][RollStability] class=%1 speedKmh=%2 bank=%3 bankRate=%4 grounded=%5 grace=%6 verticalBefore=%7 verticalAfter=%8 correction=%9 severity=%10",
                    typeOf _vehicle,
                    _rollSpeedKmh,
                    _bank,
                    _bankRate,
                    _isGrounded,
                    _withinRollGrace,
                    _rollVertical,
                    (velocityModelSpace _vehicle) # 2,
                    _rollCorrection,
                    _rollSeverity
                ];
            };
        };
    };
} else {
    _vehicle setVariable ["FIXICS_rollPreviousBank", nil, false];
    _vehicle setVariable ["FIXICS_rollPreviousTime", nil, false];
};
```

- [ ] **Step 5: Return combined result**

End function with:

```sqf
_lateralApplied || {_rollApplied}
```

- [ ] **Step 6: Run static test**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: PASS.

- [ ] **Step 7: Commit**

```powershell
git add addons\main\functions\fn_applyVehicleStability.sqf tests\integration\fixics-vehicle-physics-static.ps1
git commit -m "Integrate roll stability assist"
```

---

### Task 5: Wire Roll Unit Test Into Check Gate

**Files:**
- Modify: `tools/check.ps1` if needed
- Test: `tools/check.ps1`

- [ ] **Step 1: Inspect whether `tools/check.ps1` runs all `tests\unit\*.ps1`**

Run:

```powershell
Get-Content -Path tools\check.ps1
```

If it already runs every unit test, make no change.

- [ ] **Step 2: Add explicit unit test invocation if needed**

If needed, add:

```powershell
& powershell -ExecutionPolicy Bypass -File tests\unit\fixics-roll-stability-recommendation.ps1
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
```

- [ ] **Step 3: Run check gate**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools\check.ps1
```

Expected: PASS and includes roll recommendation source-derived test output.

- [ ] **Step 4: Commit if `tools/check.ps1` changed**

```powershell
git add tools\check.ps1
git commit -m "Run roll stability unit test in check gate"
```

Skip commit if no file changed.

---

### Task 6: Update State And Validate Full Gate

**Files:**
- Modify: `orchestration/state.md`
- Test: full required validation

- [ ] **Step 1: Update state**

Add under current Phase 1 systems:

```markdown
- Roll Stability Assist, server-global and enabled by default, awaiting SQA manual validation.
```

Add under Last Decision:

```markdown
- Roll Stability Assist was implemented as a separate vertical model-space damping layer after SQA telemetry showed mode 2 reduced yaw/pitch but did not prevent rollovers.
```

- [ ] **Step 2: Run full validation**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
powershell -ExecutionPolicy Bypass -File tools\check.ps1
git diff --check
```

Expected:

- governance static test PASS;
- vehicle physics static test PASS;
- HEMTT/check gate PASS;
- no whitespace errors from `git diff --check`.

- [ ] **Step 3: Commit state**

```powershell
git add orchestration\state.md
git commit -m "Record roll stability assist state"
```

---

### Task 7: Manual SQA Handoff

**Files:**
- No code changes

- [ ] **Step 1: Provide SQA test setup**

Tell SQA to use:

```sqf
[vehicle player, 180, 0.1] call FIXICS_fnc_logVehicleHandlingConfig;
```

Settings for first comparison:

```text
Vehicle Stability > Assistance mode: Yaw + lateral damping
Vehicle Stability > Roll stability assist: Enabled
```

Run exporter:

```powershell
powershell -ExecutionPolicy Bypass -File tools\export-vehicle-telemetry.ps1 -IncludeEvidenceHeader
```

- [ ] **Step 2: Compare telemetry**

Compare against previous mode `2` logs:

- `bank` absolute max;
- `bankRate` absolute max;
- `yawRate` absolute max;
- `isTouchingGround=false` count;
- samples where `abs bank > 45`;
- samples where `abs bank > 90`;
- SQA subjective controlled-slide feel.

- [ ] **Step 3: Completion report**

Report:

```text
Done      : Roll Stability Assist implemented as separate layer.
Validated : governance static, vehicle physics static, tools\check.ps1, git diff --check.
Logged    : orchestration state updated; manual SQA telemetry pending.
Next      : SQA in-game validation with roll assist enabled and disabled.
```

---

## Self-Review

- Spec coverage: all approved settings, eligibility, detection, correction, diagnostics, tests, and manual validation are covered.
- Scope: one runtime roll assist layer only; no native extension, no config patch, no ABS/handbrake/slope changes.
- Placeholders: none.
- Type consistency: setting names, function names, and SQF variable names match across tasks.
