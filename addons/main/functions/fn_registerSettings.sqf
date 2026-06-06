/*
 * FIXICS_fnc_registerSettings
 *
 * Registers FIXICS addon settings through CBA.
 *
 * Arguments:
 *   None
 *
 * Return: <BOOL> true when settings are registered or already available
 * Locality: any
 *
 * Example:
 *   [] call FIXICS_fnc_registerSettings;
 */

if (missionNamespace getVariable ["FIXICS_settingsRegistered", false]) exitWith {
    true
};

missionNamespace setVariable ["FIXICS_settingsRegistered", true, false];
missionNamespace setVariable ["FIXICS_disableIdleAutobrake", true, false];
missionNamespace setVariable ["FIXICS_nativeSlopeControlEnabled", false, false];

[
    "FIXICS_disableIdleAutobrake",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_DISABLE_IDLE_AUTOBRAKE",
        localize "STR_FIXICS_SETTING_DISABLE_IDLE_AUTOBRAKE_TOOLTIP"
    ],
    "FIXICS",
    true,
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_nativeSlopeControlEnabled",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_NATIVE_SLOPE_CONTROL",
        localize "STR_FIXICS_SETTING_NATIVE_SLOPE_CONTROL_TOOLTIP"
    ],
    "FIXICS",
    false,
    1
] call CBA_fnc_addSetting;

true
