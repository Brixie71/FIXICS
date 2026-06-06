/*
 * FIXICS_fnc_applySlopeRollback
 *
 * Adds a small downhill velocity assist when a local land vehicle is not under throttle input.
 *
 * Arguments:
 *   0: Vehicle to update <OBJECT>
 *
 * Return: <BOOL> true when rollback assist was applied
 * Locality: local machine; vehicle velocity changes only apply where the vehicle is local
 *
 * Example:
 *   [_vehicle] call FIXICS_fnc_applySlopeRollback;
 */

params [
    ["_vehicle", objNull, [objNull]]
];

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
if (hasInterface && {!isNull _driver} && {_driver == player}) then {
    private _isHandbraking = (inputAction "CarHandBrake") > 0;
    if (_isHandbraking) exitWith {
        false
    };

    private _stationaryBrakeBypassSpeedKmh = missionNamespace getVariable ["FIXICS_stationaryBrakeBypassSpeedKmh", 1];
    private _isStationary = (abs (speed _vehicle)) <= _stationaryBrakeBypassSpeedKmh;
    private _hasDriveInput = ((inputAction "CarForward") > 0) || { (inputAction "CarBack") > 0 };
    if (_hasDriveInput && {!_isStationary}) exitWith {
        false
    };
};

private _normal = surfaceNormal (getPosASL _vehicle);
private _downhill = [_normal # 0, _normal # 1, 0];
private _slope = sqrt (((_downhill # 0) * (_downhill # 0)) + ((_downhill # 1) * (_downhill # 1)));
private _minimumSlope = missionNamespace getVariable ["FIXICS_slopeRollbackMinimumSlope", 0.035];
if (_slope < _minimumSlope) exitWith {
    false
};

_downhill = _downhill vectorMultiply (1 / _slope);

private _velocity = velocity _vehicle;
private _downhillSpeed = ((_velocity # 0) * (_downhill # 0)) + ((_velocity # 1) * (_downhill # 1));
private _maxRollbackSpeed = missionNamespace getVariable ["FIXICS_slopeRollbackMaxSpeed", 2.2];
if (_downhillSpeed >= _maxRollbackSpeed) exitWith {
    false
};

private _rollbackAcceleration = missionNamespace getVariable ["FIXICS_slopeRollbackAcceleration", 0.55];
private _nativeSlopeControl = [
    _downhill,
    _velocity,
    _slope,
    _maxRollbackSpeed,
    _rollbackAcceleration
] call FIXICS_fnc_getNativeSlopeControl;

if ((count _nativeSlopeControl) > 0) exitWith {
    _nativeSlopeControl params [
        ["_nativeApplied", true, [false]],
        ["_nativeDeltaX", 0, [0]],
        ["_nativeDeltaY", 0, [0]],
        ["_nativeDeltaZ", 0, [0]]
    ];
    if (!_nativeApplied) exitWith {
        false
    };
    _vehicle setVelocity [
        (_velocity # 0) + _nativeDeltaX,
        (_velocity # 1) + _nativeDeltaY,
        (_velocity # 2) + _nativeDeltaZ
    ];
    true
};

private _delta = (_rollbackAcceleration * (_slope max 0.15)) min (_maxRollbackSpeed - _downhillSpeed);
if (_delta <= 0) exitWith {
    false
};

_vehicle setVelocity [
    (_velocity # 0) + ((_downhill # 0) * _delta),
    (_velocity # 1) + ((_downhill # 1) * _delta),
    _velocity # 2
];

true
