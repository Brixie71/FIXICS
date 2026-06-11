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
missionNamespace setVariable ["FIXICS_nativeDriverAssistEnabled", false, false];
missionNamespace setVariable ["FIXICS_driverAssistDebugLogging", false, false];
missionNamespace setVariable ["FIXICS_slopeRollbackMinimumSlope", 0.035, false];
missionNamespace setVariable ["FIXICS_slopeRollbackMaxSpeed", 2.2, false];
missionNamespace setVariable ["FIXICS_slopeRollbackAcceleration", 0.55, false];
missionNamespace setVariable ["FIXICS_slopeCoastBreakawayVelocity", 0.18, false];
missionNamespace setVariable ["FIXICS_slopeDriveAcceleration", 0.22, false];
missionNamespace setVariable ["FIXICS_slopeDriveMaxSpeedKmh", 120, false];
missionNamespace setVariable ["FIXICS_stationaryBrakeBypassSpeedKmh", 1, false];
missionNamespace setVariable ["FIXICS_absEnabled", true, false];
missionNamespace setVariable ["FIXICS_absBrakeStrength", 0.45, false];
missionNamespace setVariable ["FIXICS_absReleaseBias", 0.35, false];
missionNamespace setVariable ["FIXICS_absLowSpeedCutoffKmh", 3, false];
missionNamespace setVariable ["FIXICS_absSlopeCompensation", 0.25, false];
missionNamespace setVariable ["FIXICS_absDebugLogging", false, false];
missionNamespace setVariable ["FIXICS_driverControllerEnabled", true, false];
missionNamespace setVariable ["FIXICS_handbrakeInputMode", 0, false];
missionNamespace setVariable ["FIXICS_directionChangeThresholdKmh", 2, false];
missionNamespace setVariable ["FIXICS_directionLaunchVelocity", 0.35, false];
missionNamespace setVariable ["FIXICS_directionNeutralPulseSeconds", 0.08, false];
missionNamespace setVariable ["FIXICS_driverControllerInterval", 0.03, false];

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

[
    "FIXICS_nativeDriverAssistEnabled",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_NATIVE_DRIVER_ASSIST",
        localize "STR_FIXICS_SETTING_NATIVE_DRIVER_ASSIST_TOOLTIP"
    ],
    ["FIXICS", "Driver Controller"],
    false,
    1,
    {},
    false
] call CBA_fnc_addSetting;

[
    "FIXICS_driverAssistDebugLogging",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_DRIVER_ASSIST_DEBUG_LOGGING",
        localize "STR_FIXICS_SETTING_DRIVER_ASSIST_DEBUG_LOGGING_TOOLTIP"
    ],
    ["FIXICS", "Driver Controller"],
    false,
    1,
    {},
    false
] call CBA_fnc_addSetting;

[
    "FIXICS_slopeRollbackMinimumSlope",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_SLOPE_MINIMUM",
        localize "STR_FIXICS_SETTING_SLOPE_MINIMUM_TOOLTIP"
    ],
    ["FIXICS", "Slope"],
    [0, 0.2, 0.035, 3],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_slopeRollbackMaxSpeed",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_SLOPE_ROLLBACK_MAX_SPEED",
        localize "STR_FIXICS_SETTING_SLOPE_ROLLBACK_MAX_SPEED_TOOLTIP"
    ],
    ["FIXICS", "Slope"],
    [0.2, 10, 2.2, 1],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_slopeRollbackAcceleration",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_SLOPE_ROLLBACK_ACCELERATION",
        localize "STR_FIXICS_SETTING_SLOPE_ROLLBACK_ACCELERATION_TOOLTIP"
    ],
    ["FIXICS", "Slope"],
    [0, 2, 0.55, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_slopeCoastBreakawayVelocity",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_SLOPE_COAST_BREAKAWAY",
        localize "STR_FIXICS_SETTING_SLOPE_COAST_BREAKAWAY_TOOLTIP"
    ],
    ["FIXICS", "Slope"],
    [0, 1, 0.18, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_slopeDriveAcceleration",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_SLOPE_DRIVE_ACCELERATION",
        localize "STR_FIXICS_SETTING_SLOPE_DRIVE_ACCELERATION_TOOLTIP"
    ],
    ["FIXICS", "Slope"],
    [0, 1, 0.22, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_slopeDriveMaxSpeedKmh",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_SLOPE_DRIVE_MAX_SPEED",
        localize "STR_FIXICS_SETTING_SLOPE_DRIVE_MAX_SPEED_TOOLTIP"
    ],
    ["FIXICS", "Slope"],
    [10, 240, 120, 0],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_stationaryBrakeBypassSpeedKmh",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_STATIONARY_BRAKE_BYPASS",
        localize "STR_FIXICS_SETTING_STATIONARY_BRAKE_BYPASS_TOOLTIP"
    ],
    ["FIXICS", "Slope"],
    [0, 5, 1, 1],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_absEnabled",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_ABS_ENABLED",
        localize "STR_FIXICS_SETTING_ABS_ENABLED_TOOLTIP"
    ],
    ["FIXICS", "ABS"],
    true,
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_absBrakeStrength",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_ABS_BRAKE_STRENGTH",
        localize "STR_FIXICS_SETTING_ABS_BRAKE_STRENGTH_TOOLTIP"
    ],
    ["FIXICS", "ABS"],
    [0.05, 2, 0.45, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_absReleaseBias",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_ABS_RELEASE_BIAS",
        localize "STR_FIXICS_SETTING_ABS_RELEASE_BIAS_TOOLTIP"
    ],
    ["FIXICS", "ABS"],
    [0, 1, 0.35, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_absLowSpeedCutoffKmh",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_ABS_LOW_SPEED_CUTOFF",
        localize "STR_FIXICS_SETTING_ABS_LOW_SPEED_CUTOFF_TOOLTIP"
    ],
    ["FIXICS", "ABS"],
    [0, 20, 3, 1],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_absSlopeCompensation",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_ABS_SLOPE_COMPENSATION",
        localize "STR_FIXICS_SETTING_ABS_SLOPE_COMPENSATION_TOOLTIP"
    ],
    ["FIXICS", "ABS"],
    [0, 1, 0.25, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_absDebugLogging",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_ABS_DEBUG_LOGGING",
        localize "STR_FIXICS_SETTING_ABS_DEBUG_LOGGING_TOOLTIP"
    ],
    ["FIXICS", "ABS"],
    false,
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_driverControllerEnabled",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_DRIVER_CONTROLLER_ENABLED",
        localize "STR_FIXICS_SETTING_DRIVER_CONTROLLER_ENABLED_TOOLTIP"
    ],
    ["FIXICS", "Driver Controller"],
    true,
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_handbrakeInputMode",
    "LIST",
    [
        localize "STR_FIXICS_SETTING_HANDBRAKE_INPUT_MODE",
        localize "STR_FIXICS_SETTING_HANDBRAKE_INPUT_MODE_TOOLTIP"
    ],
    ["FIXICS", "Driver Controller"],
    [
        [0, 1],
        [
            localize "STR_FIXICS_SETTING_HANDBRAKE_INPUT_HOLD",
            localize "STR_FIXICS_SETTING_HANDBRAKE_INPUT_TOGGLE"
        ],
        0
    ],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_directionChangeThresholdKmh",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_DIRECTION_CHANGE_THRESHOLD",
        localize "STR_FIXICS_SETTING_DIRECTION_CHANGE_THRESHOLD_TOOLTIP"
    ],
    ["FIXICS", "Driver Controller"],
    [0.5, 10, 2, 1],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_directionLaunchVelocity",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_DIRECTION_LAUNCH_VELOCITY",
        localize "STR_FIXICS_SETTING_DIRECTION_LAUNCH_VELOCITY_TOOLTIP"
    ],
    ["FIXICS", "Driver Controller"],
    [0.05, 2, 0.35, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_directionNeutralPulseSeconds",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_DIRECTION_NEUTRAL_PULSE",
        localize "STR_FIXICS_SETTING_DIRECTION_NEUTRAL_PULSE_TOOLTIP"
    ],
    ["FIXICS", "Driver Controller"],
    [0.03, 0.3, 0.08, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_driverControllerInterval",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_DRIVER_CONTROLLER_INTERVAL",
        localize "STR_FIXICS_SETTING_DRIVER_CONTROLLER_INTERVAL_TOOLTIP"
    ],
    ["FIXICS", "Driver Controller"],
    [0.01, 0.1, 0.03, 2],
    1
] call CBA_fnc_addSetting;

true
