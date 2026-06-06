/*
 * FIXICS_fnc_logVehicleHandlingConfig
 *
 * Logs selected vehicle handling config values for SQA slope-rollback evidence.
 *
 * Arguments:
 *   0: Vehicle to inspect <OBJECT>
 *
 * Return: <BOOL> true when evidence was logged
 * Locality: any
 *
 * Example:
 *   [vehicle player] call FIXICS_fnc_logVehicleHandlingConfig;
 */

params [
    ["_vehicle", objNull, [objNull]]
];

if (isNull _vehicle) exitWith {
    diag_log "[FIXICS_fnc_logVehicleHandlingConfig] ERROR: null vehicle.";
    false
};

private _config = configOf _vehicle;
if (!isClass _config) exitWith {
    diag_log format ["[FIXICS_fnc_logVehicleHandlingConfig] ERROR: missing CfgVehicles class for %1.", typeOf _vehicle];
    false
};

private _values = [
    ["typeOf", typeOf _vehicle],
    ["simulation", getText (_config >> "simulation")],
    ["brakeIdleSpeed", getNumber (_config >> "brakeIdleSpeed")],
    ["dampingRateZeroThrottleClutchEngaged", getNumber (_config >> "dampingRateZeroThrottleClutchEngaged")],
    ["dampingRateZeroThrottleClutchDisengaged", getNumber (_config >> "dampingRateZeroThrottleClutchDisengaged")],
    ["changeGearType", getText (_config >> "changeGearType")],
    ["changeGearMinEffectivity", getArray (_config >> "changeGearMinEffectivity")],
    ["latency", getNumber (_config >> "latency")],
    ["switchTime", getNumber (_config >> "switchTime")],
    ["antiRollbarForceCoef", getNumber (_config >> "antiRollbarForceCoef")],
    ["antiRollbarSpeedMin", getNumber (_config >> "antiRollbarSpeedMin")],
    ["antiRollbarSpeedMax", getNumber (_config >> "antiRollbarSpeedMax")]
];

diag_log format ["[FIXICS] Vehicle handling evidence: %1", _values];

true
