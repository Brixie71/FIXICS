/*
 * FIXICS_fnc_dumpVehicleClasses
 *
 * Dumps available public ground vehicle classes for FIXICS profile setup.
 *
 * Arguments:
 *   0: Output mode <STRING> "classes" or "profiles" (default: "profiles")
 *   1: Root class filter <STRING> (default: "LandVehicle")
 *   2: Family filter <STRING> (default: "all")
 *
 * Return: <ARRAY>
 *
 * Example:
 *   ["classes"] call FIXICS_fnc_dumpVehicleClasses;
 *   ["profiles"] call FIXICS_fnc_dumpVehicleClasses;
 *   ["profiles", "Car_F"] call FIXICS_fnc_dumpVehicleClasses;
 *   ["profiles", "LandVehicle", "mrap"] call FIXICS_fnc_dumpVehicleClasses;
 */

params [
    ["_mode", "profiles", [""]],
    ["_rootClass", "LandVehicle", [""]],
    ["_familyFilter", "all", [""]]
];

private _normalizedMode = toLower _mode;
if !(_normalizedMode in ["classes", "profiles"]) then {
    _normalizedMode = "profiles";
};

private _classes = "true" configClasses (configFile >> "CfgVehicles");
private _result = [];
private _normalizedFamily = toLower _familyFilter;
private _classFamily = {
    params ["_className"];

    private _class = toLower _className;
    if (_class find "rhs" == 0) exitWith {"rhs"};
    if (_class find "lop" == 0) exitWith {"lop"};
    if (_class find "b_" == 0 || {_class find "o_" == 0} || {_class find "i_" == 0} || {_class find "c_" == 0}) exitWith {"vanilla"};
    "modded"
};
private _presetForClass = {
    params ["_className"];

    private _class = toLower _className;
    if (_class find "spotting" >= 0
        || {_class find "static" >= 0}
        || {_class find "hmg" >= 0}
        || {_class find "gmg" >= 0}
        || {_class find "mortar" >= 0}
        || {_class find "sam" >= 0}
        || {_class find "radar" >= 0}
        || {_class find "stretcher" >= 0}
        || {_class find "target" >= 0}
        || {_class find "pallet" >= 0}
        || {_class find "boxloader" >= 0}
        || {_class find "cart" >= 0}
        || {_class find "wreck" >= 0}
    ) exitWith {"DEFAULT"};

    if (_class find "tank" >= 0
        || {_class find "tracked" >= 0}
        || {_class find "btr" >= 0}
        || {_class find "bmp" >= 0}
        || {_class find "brdm" >= 0}
        || {_class find "m113" >= 0}
        || {_class find "stryker" >= 0}
        || {_class find "t72" >= 0}
        || {_class find "t55" >= 0}
        || {_class find "t34" >= 0}
        || {_class find "m1a" >= 0}
    ) exitWith {"TRACKED"};

    if (_class find "truck" >= 0
        || {_class find "hemtt" >= 0}
        || {_class find "ural" >= 0}
        || {_class find "kamaz" >= 0}
        || {_class find "zil" >= 0}
        || {_class find "fmtv" >= 0}
        || {_class find "m1078" >= 0}
        || {_class find "m1083" >= 0}
        || {_class find "m977" >= 0}
        || {_class find "van" >= 0}
    ) exitWith {"TRUCK"};

    if (_class find "mrap" >= 0
        || {_class find "m1151" >= 0}
        || {_class find "m1152" >= 0}
        || {_class find "m1025" >= 0}
        || {_class find "m998" >= 0}
        || {_class find "m1220" >= 0}
        || {_class find "m1230" >= 0}
        || {_class find "m1232" >= 0}
        || {_class find "m1240" >= 0}
    ) exitWith {"MRAP"};

    if (_class find "lsv" >= 0
        || {_class find "dagor" >= 0}
        || {_class find "mrzr" >= 0}
        || {_class find "offroad" >= 0}
        || {_class find "landrover" >= 0}
        || {_class find "uaz" >= 0}
        || {_class find "suv" >= 0}
        || {_class find "hatchback" >= 0}
        || {_class find "quadbike" >= 0}
        || {_class find "tigr" >= 0}
    ) exitWith {"LIGHT_OFFROAD"};

    "DEFAULT"
};
private _matchesFamily = {
    params ["_className"];

    private _preset = [_className] call _presetForClass;
    private _sourceFamily = [_className] call _classFamily;
    switch (_normalizedFamily) do {
        case "all": {true};
        case "light": {_preset == "LIGHT_OFFROAD"};
        case "cars": {_preset == "LIGHT_OFFROAD"};
        case "mrap": {_preset == "MRAP"};
        case "trucks": {_preset == "TRUCK"};
        case "tracked": {_preset == "TRACKED"};
        case "ignored": {_preset == "DEFAULT"};
        case "rhs": {_sourceFamily == "rhs"};
        case "lop": {_sourceFamily == "lop"};
        case "vanilla": {_sourceFamily == "vanilla"};
        default {true};
    };
};

{
    private _className = configName _x;
    if (
        (_className isKindOf _rootClass)
        && {getNumber (_x >> "scope") >= 2}
        && {[_className] call _matchesFamily}
    ) then {
        if (_normalizedMode == "classes") then {
            _result pushBackUnique _className;
        } else {
            _result pushBackUnique [_className, [_className] call _presetForClass, []];
        };
    };
} forEach _classes;

_result sort true;

private _tag = ["VehicleProfileTemplate", "VehicleClassDump"] select (_normalizedMode == "classes");
diag_log format [
    "[FIXICS][%1] root=%2 count=%3 data=%4",
    _tag,
    format ["%1 family=%2", _rootClass, _normalizedFamily],
    count _result,
    _result
];

if (hasInterface) then {
    copyToClipboard str _result;
    systemChat format [
        "FIXICS copied %1 %2 to clipboard.",
        count _result,
        ["vehicle profile entries", "vehicle classes"] select (_normalizedMode == "classes")
    ];
};

_result
