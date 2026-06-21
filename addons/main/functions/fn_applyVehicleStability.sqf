/*
 * FIXICS_fnc_applyVehicleStability
 *
 * Applies bounded lateral and roll stability recommendations to an eligible vehicle.
 *
 * Arguments:
 *   0: Vehicle <OBJECT>
 *   1: Delta time <NUMBER>
 *
 * Return: <BOOL> true when lateral or vertical velocity was corrected
 * Locality: local player driver machine
 *
 * Engine note:
 *   Model-space index 1 remains owned by the driver controller.
 *
 * Example:
 *   [_vehicle, _deltaTime] call FIXICS_fnc_applyVehicleStability;
 */
params [
    ["_vehicle", objNull, [objNull]],
    ["_deltaTime", 0, [0]]
];

if (isNull _vehicle) exitWith {
    false
};

private _clearYawSample = {
    params ["_sampleVehicle"];

    _sampleVehicle setVariable [
        "FIXICS_stabilityPreviousHeading",
        nil,
        false
    ];
    _sampleVehicle setVariable [
        "FIXICS_stabilityPreviousTime",
        nil,
        false
    ];
    _sampleVehicle setVariable [
        "FIXICS_rollPreviousBank",
        nil,
        false
    ];
    _sampleVehicle setVariable [
        "FIXICS_rollPreviousTime",
        nil,
        false
    ];
};

private _clearYawOnlySample = {
    params ["_sampleVehicle"];

    _sampleVehicle setVariable [
        "FIXICS_stabilityPreviousHeading",
        nil,
        false
    ];
    _sampleVehicle setVariable [
        "FIXICS_stabilityPreviousTime",
        nil,
        false
    ];
};

private _clearRollSample = {
    params ["_sampleVehicle"];

    _sampleVehicle setVariable [
        "FIXICS_rollPreviousBank",
        nil,
        false
    ];
    _sampleVehicle setVariable [
        "FIXICS_rollPreviousTime",
        nil,
        false
    ];
};

if (!local _vehicle) exitWith {
    [_vehicle] call _clearYawSample;
    false
};
if (isNull player) exitWith {
    [_vehicle] call _clearYawSample;
    false
};
private _isPlayerDriver = driver _vehicle == player;
if (!_isPlayerDriver) exitWith {
    [_vehicle] call _clearYawSample;
    false
};
if (_vehicle getVariable ["FIXICS_handbrakeEnabled", false]) exitWith {
    [_vehicle] call _clearYawSample;
    false
};

private _profile = [_vehicle] call FIXICS_fnc_getVehicleStabilityProfile;
if ((count _profile) < 7 || {!(_profile # 0)}) exitWith {
    [_vehicle] call _clearYawSample;
    false
};

private _now = diag_tickTime;
private _isGrounded = isTouchingGround _vehicle;
private _rollAirborneGraceSeconds = missionNamespace getVariable [
    "FIXICS_rollAirborneGraceSeconds",
    0.35
];

private _rollPresetIndex = missionNamespace getVariable [
    "FIXICS_rollStabilityPreset",
    0
];
private _rollPreset = [
    "REALISTIC_STABLE",
    "OFFROAD_ASSIST",
    "AGGRESSIVE_SQA",
    "CUSTOM"
] param [
    _rollPresetIndex,
    "REALISTIC_STABLE"
];
private _rollPresetSettings = switch (_rollPreset) do {
    case "OFFROAD_ASSIST": {
        [8, 120, 0.28, 0.22, 0.65]
    };
    case "AGGRESSIVE_SQA": {
        [5, 240, 0.5, 0.4, 1]
    };
    case "CUSTOM": {
        [
            missionNamespace getVariable ["FIXICS_rollActivationBankDeg", 18],
            missionNamespace getVariable ["FIXICS_rollActivationRateDeg", 45],
            missionNamespace getVariable ["FIXICS_rollStrength", 0.08],
            missionNamespace getVariable ["FIXICS_rollMaximumCorrection", 0.08],
            missionNamespace getVariable ["FIXICS_rollAirborneGraceSeconds", 0.35]
        ]
    };
    default {
        [18, 45, 0.08, 0.08, 0.35]
    };
};
_rollPresetSettings params [
    ["_rollActivationBankDeg", 18, [0]],
    ["_rollActivationRateDeg", 45, [0]],
    ["_rollStrength", 0.08, [0]],
    ["_rollMaximumCorrection", 0.08, [0]],
    ["_rollPresetAirborneGraceSeconds", 0.35, [0]]
];
_rollAirborneGraceSeconds = _rollPresetAirborneGraceSeconds;
_rollAirborneGraceSeconds = (_rollAirborneGraceSeconds max 0) min 1;
private _lastGroundedAt = _vehicle getVariable [
    "FIXICS_rollLastGroundedAt",
    (_now - _rollAirborneGraceSeconds - 1)
];
if (_isGrounded) then {
    _lastGroundedAt = _now;
    _vehicle setVariable ["FIXICS_rollLastGroundedAt", _lastGroundedAt, false];
};

private _withinRollGrace = _isGrounded || {
    (_now - _lastGroundedAt) <= _rollAirborneGraceSeconds
};
/*
 * Replaces the old yaw-only airborne guard:
 * if !(isTouchingGround _vehicle) exitWith { [_vehicle] call _clearYawSample; false };
 */
if (!_isGrounded && {!_withinRollGrace}) exitWith {
    [_vehicle] call _clearYawSample;
    false
};
if (!_isGrounded) then {
    [_vehicle] call _clearYawOnlySample;
};

private _diagnosticYawRate = 0;
private _steeringInput = 0;

private _modeIndex = missionNamespace getVariable [
    "FIXICS_stabilityAssistMode",
    0
];
private _mode = ["OFF", "YAW", "YAW_LATERAL", "COUNTERSTEER"] param [
    _modeIndex,
    "OFF"
];

private _velocity = velocityModelSpace _vehicle;
private _lateral = _velocity # 0;
private _longitudinal = _velocity # 1;
private _vertical = _velocity # 2;
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
private _speedKmh = (abs _longitudinal) * 3.6;
private _activationSpeedKmh = _profile # 1;

private _recommended = false;
private _recommendedLongitudinal = _longitudinal;
private _recommendedLateral = _lateral;
private _yawRecommendation = 0;
private _recommendedMode = _mode;
private _lateralApplied = false;

if (_isGrounded) then {
    private _heading = getDir _vehicle;
    private _previousHeading = _vehicle getVariable [
        "FIXICS_stabilityPreviousHeading",
        _heading
    ];
    private _previousTime = _vehicle getVariable [
        "FIXICS_stabilityPreviousTime",
        _now
    ];

    if (!finite _deltaTime || {_deltaTime <= 0}) then {
        _deltaTime = (_now - _previousTime) max 0.001;
    };

    _vehicle setVariable ["FIXICS_stabilityPreviousHeading", _heading, false];
    _vehicle setVariable ["FIXICS_stabilityPreviousTime", _now, false];

    private _headingDelta = ((_heading - _previousHeading + 540) mod 360) - 180;
    private _yawRate = _headingDelta / (_deltaTime max 0.001);
    _diagnosticYawRate = _yawRate;
    _steeringInput = (((inputAction "CarRight") - (inputAction "CarLeft")) / 3) max -1 min 1;

    private _recommendation = [
        _mode,
        _longitudinal,
        _lateral,
        _yawRate,
        _steeringInput,
        _deltaTime,
        _profile
    ] call FIXICS_fnc_getVehicleStabilityRecommendation;

    _recommendation params [
        ["_recommended", false, [false]],
        ["_recommendedLongitudinal", _longitudinal, [0]],
        ["_recommendedLateral", _lateral, [0]],
        ["_yawRecommendation", 0, [0]],
        ["_recommendedMode", _mode, [""]]
    ];

    if (_recommended && {_recommendedLateral != _lateral}) then {
        _velocity set [0, _recommendedLateral];
        _lateralApplied = true;
        _stabilityDecision set ["lateralDelta", _recommendedLateral - _lateral];
    };
    _stabilityDecision set ["mode", _recommendedMode];
    _stabilityDecision set ["yawRate", _diagnosticYawRate];
};

private _rollEnabled = missionNamespace getVariable [
    "FIXICS_rollStabilityEnabled",
    true
];
private _rollEligible = _withinRollGrace
    && {_rollEnabled}
    && {_speedKmh >= _activationSpeedKmh};
private _rollApplied = false;
private _recommendedVertical = _vertical;
private _rollCorrection = 0;
private _rollSeverity = 0;
private _rollReason = "not-evaluated";
private _bank = 0;
private _bankRate = 0;

if (!_rollEligible) then {
    [_vehicle] call _clearRollSample;
    _rollReason = switch (true) do {
        case (!_rollEnabled): {"disabled"};
        case (!_withinRollGrace): {"airborne-grace-expired"};
        case (_speedKmh < _activationSpeedKmh): {"below-speed-threshold"};
        default {"not-eligible"};
    };
} else {
    private _pitchBank = _vehicle call BIS_fnc_getPitchBank;
    _bank = _pitchBank # 1;
    private _previousBank = _vehicle getVariable [
        "FIXICS_rollPreviousBank",
        _bank
    ];
    private _previousRollTime = _vehicle getVariable [
        "FIXICS_rollPreviousTime",
        _now
    ];
    private _rollDeltaTime = (_now - _previousRollTime) max 0.001;
    private _bankDelta = ((_bank - _previousBank + 540) mod 360) - 180;
    _bankRate = _bankDelta / _rollDeltaTime;

    _vehicle setVariable ["FIXICS_rollPreviousBank", _bank, false];
    _vehicle setVariable ["FIXICS_rollPreviousTime", _now, false];
    _stabilityDecision set ["bank", _bank];
    _stabilityDecision set ["bankRate", _bankRate];

    private _rollSettings = [
        _rollActivationBankDeg,
        _rollActivationRateDeg,
        _rollStrength,
        _rollMaximumCorrection
    ];
    private _rollRecommendation = [
        _vertical,
        _bank,
        _bankRate,
        _rollDeltaTime,
        _rollSettings
    ] call FIXICS_fnc_getRollStabilityRecommendation;

    _rollRecommendation params [
        ["_recommendedRoll", false, [false]],
        ["_recommendedVertical", _vertical, [0]],
        ["_rollCorrection", 0, [0]],
        ["_rollSeverity", 0, [0]],
        ["_rollReason", "unknown", [""]]
    ];

    if (_recommendedRoll && {_recommendedVertical != _vertical}) then {
        _velocity set [2, _recommendedVertical];
        _rollApplied = true;
        _stabilityDecision set ["rollDelta", _rollCorrection];
        _stabilityDecision set ["rollApplied", _rollApplied];
        _stabilityDecision set ["rollReason", _rollReason];
    } else {
        _stabilityDecision set ["rollReason", _rollReason];
    };
};

if (!_lateralApplied && {!_rollApplied}) exitWith {
    _vehicle setVariable ["FIXICS_stabilityLastDecision", _stabilityDecision, false];
    false
};

_vehicle setVelocityModelSpace _velocity;
_stabilityDecision set ["applied", _lateralApplied || {_rollApplied}];
_vehicle setVariable ["FIXICS_stabilityLastDecision", _stabilityDecision, false];

private _actualVelocity = velocityModelSpace _vehicle;
private _actualLateral = _actualVelocity # 0;
private _actualLongitudinal = _actualVelocity # 1;
private _actualVertical = _actualVelocity # 2;
private _slipRatio = (abs _lateral) / ((abs _longitudinal) max 1);
if (missionNamespace getVariable ["FIXICS_stabilityDebugLogging", false]) then {
    private _presetIndex = missionNamespace getVariable [
        "FIXICS_stabilityPreset",
        0
    ];
    private _preset = ["REALISTIC_STABLE", "RALLY", "CUSTOM"] param [
        _presetIndex,
        "REALISTIC_STABLE"
    ];

    diag_log format [
        "[FIXICS][Stability] class=%1 preset=%2 mode=%3 speedKmh=%4 slip=%5 yawRate=%6 lateralBefore=%7 lateralAfter=%8 longitudinalBefore=%9 longitudinalAfter=%10 verticalBefore=%11 verticalAfter=%12 recommendedLongitudinal=%13 unusedYawRecommendation=%14 rollApplied=%15 bank=%16 bankRate=%17 rollCorrection=%18 rollSeverity=%19 rollReason=%20",
        typeOf _vehicle,
        _preset,
        _recommendedMode,
        (abs _longitudinal) * 3.6,
        _slipRatio,
        _diagnosticYawRate,
        _lateral,
        _actualLateral,
        _longitudinal,
        _actualLongitudinal,
        _vertical,
        _actualVertical,
        _recommendedLongitudinal,
        _yawRecommendation,
        _rollApplied,
        _bank,
        _bankRate,
        _rollCorrection,
        _rollSeverity,
        _rollReason
    ];
};

true
