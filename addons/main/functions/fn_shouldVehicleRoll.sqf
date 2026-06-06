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

if (_vehicle getVariable ["FIXICS_handbrakeEnabled", false]) exitWith {
    false
};

private _driver = driver _vehicle;
if (hasInterface && {!isNull _driver} && {_driver == player}) then {
    private _stationaryBrakeBypassSpeedKmh = missionNamespace getVariable ["FIXICS_stationaryBrakeBypassSpeedKmh", 1];
    private _isStationary = (abs (speed _vehicle)) <= _stationaryBrakeBypassSpeedKmh;
    private _isHandbraking = (inputAction "CarHandBrake") > 0;
    if (_isHandbraking) exitWith {
        false
    };

    private _isBraking = (inputAction "CarBack") > 0;
    if (_isBraking && {!_isStationary}) exitWith {
        false
    };
};

if (missionNamespace getVariable ["FIXICS_disableIdleAutobrake", true]) exitWith {
    true
};

true
