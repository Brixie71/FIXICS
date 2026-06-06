/*
    Function: FIXICS_fnc_hello
    Basic load confirmation for the starter addon.
*/

diag_log "[FIXICS] Main addon loaded.";

if (hasInterface) then {
    [] spawn {
        waitUntil { !isNull player };
        systemChat localize "STR_BASE_ARMA_LOADED";
    };
};
