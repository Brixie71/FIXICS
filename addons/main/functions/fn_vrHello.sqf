/*
    Function: FIXICS_fnc_vrHello
    Shows a visible sample message for the bundled VR test mission.
*/

if (!hasInterface) exitWith {};

[] spawn {
    waitUntil { !isNull player };
    waitUntil { time > 0 };

    hint localize "STR_FIXICS_VR_HINT";
    systemChat localize "STR_FIXICS_VR_CHAT";

    [
        format [
            "<t size='2.2' color='#49C7F2'>%1</t><br/><t size='1.3'>%2</t>",
            localize "STR_FIXICS_NAME",
            localize "STR_FIXICS_VR_TITLE"
        ],
        0,
        0.35,
        5,
        1,
        0,
        9001
    ] spawn BIS_fnc_dynamicText;
};
