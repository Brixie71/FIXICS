/*
 * FIXICS_fnc_applyHandbrakeLock
 *
 * Enforces the persistent FIXICS ACE handbrake lock on a local land vehicle.
 *
 * Arguments:
 *   0: Vehicle to lock <OBJECT>
 *
 * Return: <BOOL> true when the lock was applied
 * Locality: local machine; vehicle velocity changes only apply where the vehicle is local
 *
 * Example:
 *   [_vehicle] call FIXICS_fnc_applyHandbrakeLock;
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

if (!(_vehicle getVariable ["FIXICS_handbrakeEnabled", false])) exitWith {
    false
};

_vehicle disableBrakes false;
_vehicle setVelocity [0, 0, 0];

true
