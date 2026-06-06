/*
    Function: FIXICS_fnc_init
    Runs after mission initialization.
*/

[] call FIXICS_fnc_hello;

if (hasInterface) then {
    [] call FIXICS_fnc_registerAceInteractions;
};

[] spawn FIXICS_fnc_monitorVehicleAutobrake;
