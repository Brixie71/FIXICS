/*
 * FIXICS_fnc_registerAceInteractions
 *
 * Registers ACE interaction actions for the FIXICS vehicle handbrake.
 *
 * Arguments:
 *   None
 *
 * Return: <BOOL> true when actions are registered or were already registered
 * Locality: client UI
 *
 * Example:
 *   [] call FIXICS_fnc_registerAceInteractions;
 */

if (!hasInterface) exitWith {
    false
};

if (missionNamespace getVariable ["FIXICS_aceInteractionsRegistered", false]) exitWith {
    true
};

missionNamespace setVariable ["FIXICS_aceInteractionsRegistered", true, false];

private _canSetHandbrake = {
    params ["_target", "_player", "_actionParams"];

    (_target isKindOf "LandVehicle")
    && {!(_target getVariable ["FIXICS_handbrakeEnabled", false])}
    && {[_player, _target, []] call ace_common_fnc_canInteractWith}
};

private _canReleaseHandbrake = {
    params ["_target", "_player", "_actionParams"];

    (_target isKindOf "LandVehicle")
    && {_target getVariable ["FIXICS_handbrakeEnabled", false]}
    && {[_player, _target, []] call ace_common_fnc_canInteractWith}
};

private _canSetDriverHandbrake = {
    params ["_target", "_player", "_actionParams"];

    private _vehicle = vehicle _player;
    (_vehicle isKindOf "LandVehicle")
    && {_player == driver _vehicle}
    && {!(_vehicle getVariable ["FIXICS_handbrakeEnabled", false])}
};

private _canReleaseDriverHandbrake = {
    params ["_target", "_player", "_actionParams"];

    private _vehicle = vehicle _player;
    (_vehicle isKindOf "LandVehicle")
    && {_player == driver _vehicle}
    && {_vehicle getVariable ["FIXICS_handbrakeEnabled", false]}
};

private _setHandbrake = {
    params ["_target", "_player", "_actionParams"];

    [_target, true] call FIXICS_fnc_setVehicleHandbrake;
};

private _releaseHandbrake = {
    params ["_target", "_player", "_actionParams"];

    [_target, false] call FIXICS_fnc_setVehicleHandbrake;
};

private _setDriverHandbrake = {
    params ["_target", "_player", "_actionParams"];

    [vehicle _player, true] call FIXICS_fnc_setVehicleHandbrake;
};

private _releaseDriverHandbrake = {
    params ["_target", "_player", "_actionParams"];

    [vehicle _player, false] call FIXICS_fnc_setVehicleHandbrake;
};

private _setAction = [
    "FIXICS_SetHandbrake",
    localize "STR_FIXICS_HAND_BRAKE_SET",
    "",
    _setHandbrake,
    _canSetHandbrake
] call ace_interact_menu_fnc_createAction;

private _releaseAction = [
    "FIXICS_ReleaseHandbrake",
    localize "STR_FIXICS_HAND_BRAKE_RELEASE",
    "",
    _releaseHandbrake,
    _canReleaseHandbrake
] call ace_interact_menu_fnc_createAction;

private _setDriverAction = [
    "FIXICS_SetDriverHandbrake",
    localize "STR_FIXICS_HAND_BRAKE_SET",
    "",
    _setDriverHandbrake,
    _canSetDriverHandbrake
] call ace_interact_menu_fnc_createAction;

private _releaseDriverAction = [
    "FIXICS_ReleaseDriverHandbrake",
    localize "STR_FIXICS_HAND_BRAKE_RELEASE",
    "",
    _releaseDriverHandbrake,
    _canReleaseDriverHandbrake
] call ace_interact_menu_fnc_createAction;

["LandVehicle", 0, ["ACE_MainActions"], _setAction, true] call ace_interact_menu_fnc_addActionToClass;
["LandVehicle", 0, ["ACE_MainActions"], _releaseAction, true] call ace_interact_menu_fnc_addActionToClass;
["LandVehicle", 1, ["ACE_SelfActions"], _setDriverAction, true] call ace_interact_menu_fnc_addActionToClass;
["LandVehicle", 1, ["ACE_SelfActions"], _releaseDriverAction, true] call ace_interact_menu_fnc_addActionToClass;

true
