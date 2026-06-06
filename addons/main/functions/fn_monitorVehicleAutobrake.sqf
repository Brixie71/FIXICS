/*
 * FIXICS_fnc_monitorVehicleAutobrake
 *
 * Locally disables idle autobrake on land vehicles that should roll on slopes.
 *
 * Arguments:
 *   None
 *
 * Return: <BOOL> true when the monitor exits
 * Locality: local machine
 *
 * Example:
 *   [] spawn FIXICS_fnc_monitorVehicleAutobrake;
 */

if (missionNamespace getVariable ["FIXICS_vehicleAutobrakeMonitorRunning", false]) exitWith {
    false
};

missionNamespace setVariable ["FIXICS_vehicleAutobrakeMonitorRunning", true, false];

while { missionNamespace getVariable ["FIXICS_vehicleAutobrakeMonitorRunning", false] } do {
    {
        if ((_x isKindOf "LandVehicle") && { local _x }) then {
            if (_x getVariable ["FIXICS_handbrakeEnabled", false]) then {
                _x disableBrakes false;
            } else {
                if ([_x] call FIXICS_fnc_shouldVehicleRoll) then {
                    _x disableBrakes true;
                };
            };
        };
    } forEach vehicles;

    sleep 1;
};

true
