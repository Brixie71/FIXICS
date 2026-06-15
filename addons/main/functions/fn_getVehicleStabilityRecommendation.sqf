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
params [
    ["_mode", "OFF", [""]],
    ["_longitudinalSpeed", 0, [0]],
    ["_lateralSpeed", 0, [0]],
    ["_yawRate", 0, [0]],
    ["_steeringInput", 0, [0]],
    ["_deltaTime", 0, [0]],
    ["_profile", [], [[]]]
];

_mode = toUpper _mode;
if !(_mode in ["OFF", "YAW", "YAW_LATERAL", "COUNTERSTEER"]) then {
    _mode = "OFF";
};

if (
    !finite _longitudinalSpeed
    || {!finite _lateralSpeed}
    || {!finite _yawRate}
    || {!finite _steeringInput}
    || {!finite _deltaTime}
) exitWith {
    [false, 0, 0, 0, "OFF"]
};

if ((count _profile) < 7) exitWith {
    [false, _longitudinalSpeed, _lateralSpeed, 0, _mode]
};

_profile params [
    ["_supported", false, [false]],
    ["_activationSpeedKmh", 0, [0]],
    ["_slipThreshold", 0, [0]],
    ["_yawStrength", 0, [0]],
    ["_lateralStrength", 0, [0]],
    ["_countersteerStrength", 0, [0]],
    ["_maximumCorrection", 0, [0]]
];

private _profileValues = [
    _activationSpeedKmh,
    _slipThreshold,
    _yawStrength,
    _lateralStrength,
    _countersteerStrength,
    _maximumCorrection
];
if ((_profileValues findIf {!finite _x}) >= 0) exitWith {
    [false, _longitudinalSpeed, _lateralSpeed, 0, _mode]
};

_activationSpeedKmh = (_activationSpeedKmh max 0) min 160;
_slipThreshold = (_slipThreshold max 0) min 1;
_yawStrength = (_yawStrength max 0) min 1;
_lateralStrength = (_lateralStrength max 0) min 1;
_countersteerStrength = (_countersteerStrength max 0) min 0.5;
_maximumCorrection = (_maximumCorrection max 0) min 0.5;
_steeringInput = (_steeringInput max -1) min 1;
_deltaTime = (_deltaTime max 0) min 1;

private _slipRatio = (abs _lateralSpeed) / ((abs _longitudinalSpeed) max 1);
if (
    !_supported
    || {_mode isEqualTo "OFF"}
    || {(abs _longitudinalSpeed) * 3.6 < _activationSpeedKmh}
    || {_slipRatio < _slipThreshold}
) exitWith {
    [false, _longitudinalSpeed, _lateralSpeed, 0, _mode]
};

private _recommendedLateralSpeed = _lateralSpeed;
private _yawCorrection = 0;

switch (_mode) do {
    case "YAW": {
        _yawCorrection = (
            -_yawRate * _yawStrength * _deltaTime
        ) max -_maximumCorrection min _maximumCorrection;
    };
    case "YAW_LATERAL": {
        _recommendedLateralSpeed = _lateralSpeed * (
            1 - ((_lateralStrength * _deltaTime) min 0.5)
        );
        _yawCorrection = (
            -_yawRate * _yawStrength * _deltaTime
        ) max -_maximumCorrection min _maximumCorrection;
    };
    case "COUNTERSTEER": {
        private _countersteer = -_yawRate
            * _countersteerStrength
            * _deltaTime;
        _yawCorrection = (
            _countersteer max -_maximumCorrection
        ) min _maximumCorrection;
    };
};

private _applied = (
    _recommendedLateralSpeed != _lateralSpeed
    || {_yawCorrection != 0}
);

[
    _applied,
    _longitudinalSpeed,
    _recommendedLateralSpeed,
    _yawCorrection,
    _mode
]
