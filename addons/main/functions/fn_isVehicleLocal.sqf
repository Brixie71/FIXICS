/*
 * FIXICS_fnc_isVehicleLocal
 *
 * Pure multiplayer authority helper for FIXICS vehicle systems.
 *
 * Arguments:
 *   0: Vehicle <OBJECT>
 *
 * Return: <BOOL> true when the current machine may run existing local vehicle mutations.
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

if (!isMultiplayer) exitWith {
    local _vehicle
};

if !(missionNamespace getVariable ["FIXICS_multiplayerCompatibilityEnabled", true]) exitWith {
    false
};

local _vehicle
