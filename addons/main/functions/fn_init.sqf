/*
    Function: FIXICS_fnc_init
    Runs after mission initialization.
*/

[] call FIXICS_fnc_hello;
[] call FIXICS_fnc_registerSettings;

if (hasInterface) then {
    [] call FIXICS_fnc_registerAceInteractions;
    [] call FIXICS_fnc_registerVehicleControls;
};

[] spawn FIXICS_fnc_monitorVehicleAutobrake;
