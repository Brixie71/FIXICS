/*
 * FIXICS_fnc_applyVehicleStability
 *
 * Applies a bounded lateral stability recommendation to an eligible vehicle.
 *
 * Arguments:
 *   0: Vehicle <OBJECT>
 *   1: Delta time <NUMBER>
 *
 * Return: <BOOL> true when lateral velocity was corrected
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
if (!local _vehicle) exitWith {
    false
};
if (isNull player) exitWith {
    false
};
private _isPlayerDriver = driver _vehicle == player;
if (!_isPlayerDriver) exitWith {
    false
};
if !(isTouchingGround _vehicle) exitWith {
    false
};
if (_vehicle getVariable ["FIXICS_handbrakeEnabled", false]) exitWith {
    false
};

private _profile = [_vehicle] call FIXICS_fnc_getVehicleStabilityProfile;
if ((count _profile) < 7 || {!(_profile # 0)}) exitWith {
    false
};

private _heading = getDir _vehicle;
private _now = diag_tickTime;
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
private _steeringInput = (((inputAction "CarRight") - (inputAction "CarLeft")) / 3) max -1 min 1;

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
        "[FIXICS][Stability] class=%1 preset=%2 mode=%3 speedKmh=%4 slip=%5 yawRate=%6 lateralBefore=%7 lateralAfter=%8 longitudinalBefore=%9 longitudinalAfter=%10 recommendedLongitudinal=%11 unusedYawRecommendation=%12",
        typeOf _vehicle,
        _preset,
        _recommendedMode,
        (abs _longitudinal) * 3.6,
        _slipRatio,
        _yawRate,
        _lateral,
        _recommendedLateral,
        _longitudinal,
        _velocity # 1,
        _recommendedLongitudinal,
        _yawRecommendation
    ];
};

if (!_recommended || {_recommendedLateral == _lateral}) exitWith {
    false
};

_velocity set [0, _recommendedLateral];
_vehicle setVelocityModelSpace _velocity;
true
