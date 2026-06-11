/*
    Function: FIXICS_fnc_hello
    Basic load confirmation for the starter addon.
*/

diag_log "[FIXICS] Vehicle Physics Addon Loaded";

if (hasInterface) then {
    [] spawn {
        waitUntil { !isNull player };
        systemChat localize "STR_FIXICS_LOADED";
    };
};
