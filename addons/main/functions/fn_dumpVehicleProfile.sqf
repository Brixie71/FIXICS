/*
 * FIXICS_fnc_dumpVehicleProfile
 *
 * Logs and optionally displays the active FIXICS vehicle profile.
 *
 * Arguments:
 *   0: Vehicle <OBJECT>
 *   1: Force refresh <BOOL> (default: false)
 *
 * Return: <HASHMAP>
 */

params [
    ["_vehicle", objNull, [objNull]],
    ["_forceRefresh", false, [true]]
];

private _profile = [_vehicle, _forceRefresh] call FIXICS_fnc_getVehicleProfile;
private _message = format [
    "[FIXICS][VehicleProfile] class=%1 profile=%2 source=%3 overrides=%4 parent=%5",
    _profile getOrDefault ["vehicleClass", "unknown"],
    _profile getOrDefault ["vehicleProfileId", "DEFAULT"],
    _profile getOrDefault ["vehicleProfileSource", "global"],
    _profile getOrDefault ["vehicleProfileOverridesApplied", []],
    _profile getOrDefault ["vehicleParentClass", ""]
];

diag_log _message;

if (missionNamespace getVariable ["FIXICS_vehicleProfileDebugLogging", false]) then {
    hint _message;
};

_profile
