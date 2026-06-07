/*
 * FIXICS_fnc_applyABSBraking
 *
 * Applies local velocity-level ABS-like braking modulation for player-driven land vehicles.
 *
 * Arguments:
 *   0: Vehicle to update <OBJECT>
 *   1: Ignore normal low-speed cutoff for a direction transition <BOOL>
 *   2: Elapsed time since the previous update <NUMBER> (default: 0.25)
 *
 * Return: <BOOL> true when ABS changed vehicle velocity
 * Locality: local machine; vehicle velocity changes only apply where the vehicle is local
 *
 * Example:
 *   [_vehicle] call FIXICS_fnc_applyABSBraking;
 */

params [
    ["_vehicle", objNull, [objNull]],
    ["_ignoreLowSpeedCutoff", false, [true]],
    ["_deltaTime", 0.25, [0]]
];

if (!(missionNamespace getVariable ["FIXICS_absEnabled", true])) exitWith {
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
private _lowSpeedCutoffKmh = missionNamespace getVariable ["FIXICS_absLowSpeedCutoffKmh", 3];
if (!_ignoreLowSpeedCutoff && {_speedKmh <= _lowSpeedCutoffKmh}) exitWith {
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
private _normalZ = ((_normal # 2) max -1) min 1;
private _slopeAngleDegrees = acos _normalZ;
private _slope = sin _slopeAngleDegrees;
private _downhill = [_normal # 0, _normal # 1, 0];
private _downhillLength = sqrt (((_downhill # 0) * (_downhill # 0)) + ((_downhill # 1) * (_downhill # 1)));
if (_downhillLength > 0) then {
    _downhill = _downhill vectorMultiply (1 / _downhillLength);
};

private _downhillAlignment = 0;
if (_downhillLength > 0) then {
    _downhillAlignment = ((_downhill # 0) * (_forward # 0)) + ((_downhill # 1) * (_forward # 1));
};

private _slopeCompensation = missionNamespace getVariable ["FIXICS_absSlopeCompensation", 0.25];
private _brakeDirection = if (_isForwardBraking) then {
    -1
} else {
    1
};
private _downhillBrakeLoad = if (_isForwardBraking) then {
    _downhillAlignment max 0
} else {
    (-_downhillAlignment) max 0
};

private _brakeStrength = missionNamespace getVariable ["FIXICS_absBrakeStrength", 0.45];
private _releaseBias = missionNamespace getVariable ["FIXICS_absReleaseBias", 0.35];
private _timeScale = ((_deltaTime max 0.001) min 0.25) / 0.25;
private _effectiveBrake = _brakeStrength
    * (1 - _releaseBias)
    * (1 + (_downhillBrakeLoad * _slopeCompensation))
    * _timeScale;
private _delta = _effectiveBrake min (abs _longitudinalSpeed);
if (_delta <= 0) exitWith {
    false
};

_vehicle setVelocity [
    (_velocity # 0) + ((_forward # 0) * _brakeDirection * _delta),
    (_velocity # 1) + ((_forward # 1) * _brakeDirection * _delta),
    _velocity # 2
];

if (missionNamespace getVariable ["FIXICS_absDebugLogging", false]) then {
    diag_log format [
        "FIXICS ABS: type=%1 speedKmh=%2 longitudinalMps=%3 delta=%4 slope=%5 downhillLoad=%6",
        typeOf _vehicle,
        _speedKmh,
        _longitudinalSpeed,
        _delta,
        _slope,
        _downhillBrakeLoad
    ];
};

true
