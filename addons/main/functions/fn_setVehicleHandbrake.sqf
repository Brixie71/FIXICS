/*
 * FIXICS_fnc_setVehicleHandbrake
 *
 * Sets or clears the local FIXICS handbrake state for a land vehicle.
 *
 * Arguments:
 *   0: Vehicle to update <OBJECT>
 *   1: Whether the FIXICS handbrake is enabled <BOOL> (default: true)
 *
 * Return: <BOOL> true when state was applied
 * Locality: local machine; vehicle PhysX change only applies when the vehicle is local
 *
 * Example:
 *   [_vehicle, true] call FIXICS_fnc_setVehicleHandbrake;
 */

params [
    ["_vehicle", objNull, [objNull]],
    ["_enabled", true, [true]]
];

if (isNull _vehicle) exitWith {
    diag_log "[FIXICS_fnc_setVehicleHandbrake] ERROR: null vehicle.";
    false
};

if (!(_vehicle isKindOf "LandVehicle")) exitWith {
    false
};

_vehicle setVariable ["FIXICS_handbrakeEnabled", _enabled, true];

if ([_vehicle] call FIXICS_fnc_isVehicleLocal) then {
    private _brakeControlOwner = _vehicle getVariable ["FIXICS_brakeControlOwner", ""];
    if (_enabled) then {
        if (_brakeControlOwner == "") then {
            _vehicle setVariable ["FIXICS_priorBrakesDisabled", brakesDisabled _vehicle, false];
        };
        if (_brakeControlOwner in ["", "monitor", "driver", "handbrake"]) then {
            _vehicle setVariable ["FIXICS_brakeControlOwner", "handbrake", false];
        };
        [_vehicle] call FIXICS_fnc_applyHandbrakeLock;
    } else {
        if (_brakeControlOwner == "handbrake") then {
            private _priorBrakesDisabled = _vehicle getVariable ["FIXICS_priorBrakesDisabled", false];
            _vehicle disableBrakes _priorBrakesDisabled;
            _vehicle setVariable ["FIXICS_brakeControlOwner", "", false];
            _vehicle setVariable ["FIXICS_priorBrakesDisabled", nil, false];
        };
    };
};

if (hasInterface) then {
    systemChat localize ([
        "STR_FIXICS_HAND_BRAKE_STATUS_RELEASED",
        "STR_FIXICS_HAND_BRAKE_STATUS_SET"
    ] select _enabled);
};

true
