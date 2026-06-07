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
missionNamespace setVariable ["FIXICS_vehicleAutobrakeMonitorLastUpdate", diag_tickTime - 0.25, false];

while { missionNamespace getVariable ["FIXICS_vehicleAutobrakeMonitorRunning", false] } do {
    private _now = diag_tickTime;
    private _lastUpdate = missionNamespace getVariable ["FIXICS_vehicleAutobrakeMonitorLastUpdate", _now - 0.25];
    private _deltaTime = ((_now - _lastUpdate) max 0.001) min 0.5;
    missionNamespace setVariable ["FIXICS_vehicleAutobrakeMonitorLastUpdate", _now, false];

    {
        if ((_x isKindOf "LandVehicle") && { local _x }) then {
            private _driver = driver _x;
            private _isPlayerDriven = missionNamespace getVariable ["FIXICS_driverControllerEnabled", true]
                && {missionNamespace getVariable ["FIXICS_vehicleControlsRegistered", false]}
                && {hasInterface}
                && {!isNull _driver}
                && {_driver == player};

            if (!_isPlayerDriven) then {
                private _brakeControlOwner = _x getVariable ["FIXICS_brakeControlOwner", ""];
                if (_x getVariable ["FIXICS_handbrakeEnabled", false]) then {
                    if (_brakeControlOwner == "monitor") then {
                        _x setVariable ["FIXICS_brakeControlOwner", "handbrake", false];
                    };
                    [_x] call FIXICS_fnc_applyHandbrakeLock;
                } else {
                    private _shouldRoll = [_x] call FIXICS_fnc_shouldVehicleRoll;
                    if (_shouldRoll) then {
                        if (_brakeControlOwner == "") then {
                            _x setVariable ["FIXICS_priorBrakesDisabled", brakesDisabled _x, false];
                            _x setVariable ["FIXICS_brakeControlOwner", "monitor", false];
                            _brakeControlOwner = "monitor";
                        };
                        if (_brakeControlOwner == "monitor") then {
                            _x disableBrakes true;
                            [_x, _deltaTime] call FIXICS_fnc_applySlopeRollback;
                        };
                    } else {
                        if (_brakeControlOwner == "monitor") then {
                            private _priorBrakesDisabled = _x getVariable ["FIXICS_priorBrakesDisabled", false];
                            _x disableBrakes _priorBrakesDisabled;
                            _x setVariable ["FIXICS_brakeControlOwner", "", false];
                            _x setVariable ["FIXICS_priorBrakesDisabled", nil, false];
                        };
                    };
                };
            };
        };
    } forEach vehicles;

    sleep 0.25;
};

true
