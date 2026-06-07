/*
 * FIXICS_fnc_shouldVehicleRoll
 *
 * Decides whether the local vehicle monitor should allow a vehicle to roll.
 *
 * Arguments:
 *   0: Vehicle to evaluate <OBJECT>
 *
 * Return: <BOOL> true when the vehicle should have idle autobrake disabled
 * Locality: local machine
 *
 * Example:
 *   [_vehicle] call FIXICS_fnc_shouldVehicleRoll;
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
private _inputBlocksRolling = false;
if (hasInterface && {!isNull _driver} && {_driver == player}) then {
    private _stationaryBrakeBypassSpeedKmh = missionNamespace getVariable ["FIXICS_stationaryBrakeBypassSpeedKmh", 1];
    private _isStationary = (abs (speed _vehicle)) <= _stationaryBrakeBypassSpeedKmh;
    private _isHandbraking = (inputAction "CarHandBrake") > 0;
    private _isBraking = (inputAction "CarBack") > 0;
    _inputBlocksRolling = _isHandbraking || {_isBraking && {!_isStationary}};
};

if (_inputBlocksRolling) exitWith {
    false
};

private _normal = surfaceNormal (getPosASL _vehicle);
private _downhill = [_normal # 0, _normal # 1, 0];
private _slope = sqrt (((_downhill # 0) * (_downhill # 0)) + ((_downhill # 1) * (_downhill # 1)));
private _minimumSlope = missionNamespace getVariable ["FIXICS_slopeRollbackMinimumSlope", 0.035];
if (_slope < _minimumSlope) exitWith {
    false
};

missionNamespace getVariable ["FIXICS_disableIdleAutobrake", true]
