/*
 * FIXICS_fnc_registerVehicleControls
 *
 * Registers the local player driver controller.
 *
 * Arguments:
 *   None
 *
 * Return: <BOOL> true when the controller is registered
 * Locality: client with interface
 *
 * Example:
 *   [] call FIXICS_fnc_registerVehicleControls;
 */

if (!hasInterface) exitWith {
    false
};

if (missionNamespace getVariable ["FIXICS_vehicleControlsRegistered", false]) exitWith {
    true
};

missionNamespace setVariable ["FIXICS_vehicleControlsRegistered", true, false];

private _handle = [
    {
        [] call FIXICS_fnc_updateDriverController;
    },
    0,
    []
] call CBA_fnc_addPerFrameHandler;

missionNamespace setVariable ["FIXICS_vehicleControlsPfhHandle", _handle, false];

true
