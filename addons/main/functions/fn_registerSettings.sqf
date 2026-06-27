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
missionNamespace setVariable ["FIXICS_nativeTerrainTireEnabled", false, false];
missionNamespace setVariable ["FIXICS_multiplayerCompatibilityEnabled", true, false];
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
missionNamespace setVariable ["FIXICS_stabilityPreset", 0, false];
missionNamespace setVariable ["FIXICS_stabilityAssistMode", 0, false];
missionNamespace setVariable ["FIXICS_stabilityActivationSpeedKmh", 35, false];
missionNamespace setVariable ["FIXICS_stabilitySlipThreshold", 0.12, false];
missionNamespace setVariable ["FIXICS_stabilityYawStrength", 0.22, false];
missionNamespace setVariable ["FIXICS_stabilityLateralStrength", 0.12, false];
missionNamespace setVariable ["FIXICS_stabilityCountersteerStrength", 0.08, false];
missionNamespace setVariable ["FIXICS_stabilityMaximumCorrection", 0.12, false];
missionNamespace setVariable ["FIXICS_rollStabilityPreset", 0, false];
missionNamespace setVariable ["FIXICS_rollStabilityEnabled", true, false];
missionNamespace setVariable ["FIXICS_swayBarEnabled", true, false];
missionNamespace setVariable ["FIXICS_frontSwayBarEnabled", true, false];
missionNamespace setVariable ["FIXICS_frontSwayBarStrength", 0.5, false];
missionNamespace setVariable ["FIXICS_rearSwayBarEnabled", true, false];
missionNamespace setVariable ["FIXICS_rearSwayBarStrength", 0.5, false];
missionNamespace setVariable ["FIXICS_controlledSlipEnabled", true, false];
missionNamespace setVariable ["FIXICS_controlledSlipActivationSpeedKmh", 55, false];
missionNamespace setVariable ["FIXICS_controlledSlipSteeringThreshold", 0.65, false];
missionNamespace setVariable ["FIXICS_controlledSlipStrength", 0.16, false];
missionNamespace setVariable ["FIXICS_controlledSlipMaximumRelease", 0.22, false];
missionNamespace setVariable ["FIXICS_controlledSlipTerrainInfluence", true, false];
missionNamespace setVariable ["FIXICS_controlledSlipDebugLogging", false, false];
missionNamespace setVariable ["FIXICS_terrainTireEnabled", true, false];
missionNamespace setVariable ["FIXICS_tirePressureEnabled", true, false];
missionNamespace setVariable ["FIXICS_tireDeflationRate", 0.025, false];
missionNamespace setVariable ["FIXICS_tireMinimumMobility", 0.35, false];
missionNamespace setVariable ["FIXICS_tireDragStrength", 0.35, false];
missionNamespace setVariable ["FIXICS_tireSteeringPenalty", 0.30, false];
missionNamespace setVariable ["FIXICS_tireDebugLogging", false, false];
missionNamespace setVariable ["FIXICS_rolloverSafetyEnabled", true, false];
missionNamespace setVariable ["FIXICS_airborneGraceWindow", 0.50, false];
missionNamespace setVariable ["FIXICS_driverlessDecayEnabled", true, false];
missionNamespace setVariable ["FIXICS_driverlessDecayCap", 0.15, false];
missionNamespace setVariable ["FIXICS_destroyedTireThreshold", 0.85, false];
missionNamespace setVariable ["FIXICS_destroyedTireDebugLogging", false, false];
missionNamespace setVariable ["FIXICS_weatherTerrainEnabled", true, false];
missionNamespace setVariable ["FIXICS_weatherSaturationTime", 30, false];
missionNamespace setVariable ["FIXICS_weatherDryingTime", 180, false];
missionNamespace setVariable ["FIXICS_hydroplaningEnabled", true, false];
missionNamespace setVariable ["FIXICS_hydroplaningSpeedKmh", 70, false];
missionNamespace setVariable ["FIXICS_windHandlingEnabled", true, false];
missionNamespace setVariable ["FIXICS_windHandlingStrength", 0.05, false];
missionNamespace setVariable ["FIXICS_weatherDebugLogging", false, false];
missionNamespace setVariable ["FIXICS_rollActivationBankDeg", 18, false];
missionNamespace setVariable ["FIXICS_rollActivationRateDeg", 45, false];
missionNamespace setVariable ["FIXICS_rollStrength", 0.08, false];
missionNamespace setVariable ["FIXICS_rollMaximumCorrection", 0.08, false];
missionNamespace setVariable ["FIXICS_rollAirborneGraceSeconds", 0.35, false];
missionNamespace setVariable ["FIXICS_stabilityDebugLogging", false, false];
missionNamespace setVariable ["FIXICS_runtimeAssistCoordinatorEnabled", true, false];
missionNamespace setVariable ["FIXICS_runtimeAssistTerrainInfluenceEnabled", true, false];
missionNamespace setVariable ["FIXICS_runtimeAssistTerrainInfluenceStrength", 0.25, false];
missionNamespace setVariable ["FIXICS_runtimeAssistBrakingSlopeRetention", 0.35, false];
missionNamespace setVariable ["FIXICS_runtimeAssistMassDampingStrength", 0.15, false];
missionNamespace setVariable ["FIXICS_runtimeAssistMaximumComposedCorrection", 0.25, false];
missionNamespace setVariable ["FIXICS_runtimeAssistDebugLogging", false, false];
missionNamespace setVariable ["FIXICS_vehicleProfileExactOverrides", "[]", false];
missionNamespace setVariable ["FIXICS_vehicleProfileParentOverrides", "[]", false];
missionNamespace setVariable ["FIXICS_vehicleProfileDebugLogging", false, false];

[
    "FIXICS_vehicleProfileExactOverrides",
    "EDITBOX",
    [
        localize "STR_FIXICS_SETTING_VEHICLE_PROFILE_EXACT",
        localize "STR_FIXICS_SETTING_VEHICLE_PROFILE_EXACT_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Profiles"],
    "[]",
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_vehicleProfileParentOverrides",
    "EDITBOX",
    [
        localize "STR_FIXICS_SETTING_VEHICLE_PROFILE_PARENT",
        localize "STR_FIXICS_SETTING_VEHICLE_PROFILE_PARENT_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Profiles"],
    "[]",
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_vehicleProfileDebugLogging",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_VEHICLE_PROFILE_DEBUG",
        localize "STR_FIXICS_SETTING_VEHICLE_PROFILE_DEBUG_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Profiles"],
    false,
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_multiplayerCompatibilityEnabled",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_MULTIPLAYER_COMPATIBILITY",
        localize "STR_FIXICS_SETTING_MULTIPLAYER_COMPATIBILITY_TOOLTIP"
    ],
    ["FIXICS", "Multiplayer"],
    true,
    1
] call CBA_fnc_addSetting;

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

[
    "FIXICS_stabilityPreset",
    "LIST",
    [
        localize "STR_FIXICS_SETTING_STABILITY_PRESET",
        localize "STR_FIXICS_SETTING_STABILITY_PRESET_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    [
        [0, 1, 2],
        [
            localize "STR_FIXICS_SETTING_STABILITY_PRESET_REALISTIC_STABLE",
            localize "STR_FIXICS_SETTING_STABILITY_PRESET_RALLY",
            localize "STR_FIXICS_SETTING_STABILITY_PRESET_CUSTOM"
        ],
        0
    ],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_stabilityAssistMode",
    "LIST",
    [
        localize "STR_FIXICS_SETTING_STABILITY_ASSIST_MODE",
        localize "STR_FIXICS_SETTING_STABILITY_ASSIST_MODE_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    [
        [0, 1, 2, 3],
        [
            localize "STR_FIXICS_SETTING_STABILITY_ASSIST_OFF",
            localize "STR_FIXICS_SETTING_STABILITY_ASSIST_YAW",
            localize "STR_FIXICS_SETTING_STABILITY_ASSIST_YAW_LATERAL",
            localize "STR_FIXICS_SETTING_STABILITY_ASSIST_COUNTERSTEER"
        ],
        0
    ],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_stabilityActivationSpeedKmh",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_STABILITY_ACTIVATION_SPEED",
        localize "STR_FIXICS_SETTING_STABILITY_ACTIVATION_SPEED_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    [10, 160, 35, 0],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_stabilitySlipThreshold",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_STABILITY_SLIP_THRESHOLD",
        localize "STR_FIXICS_SETTING_STABILITY_SLIP_THRESHOLD_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    [0.05, 0.8, 0.12, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_stabilityYawStrength",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_STABILITY_YAW_STRENGTH",
        localize "STR_FIXICS_SETTING_STABILITY_YAW_STRENGTH_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    [0, 1, 0.22, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_stabilityLateralStrength",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_STABILITY_LATERAL_STRENGTH",
        localize "STR_FIXICS_SETTING_STABILITY_LATERAL_STRENGTH_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    [0, 1, 0.12, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_stabilityCountersteerStrength",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_STABILITY_COUNTERSTEER_STRENGTH",
        localize "STR_FIXICS_SETTING_STABILITY_COUNTERSTEER_STRENGTH_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    [0, 0.5, 0.08, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_stabilityMaximumCorrection",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_STABILITY_MAXIMUM_CORRECTION",
        localize "STR_FIXICS_SETTING_STABILITY_MAXIMUM_CORRECTION_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    [0.01, 0.5, 0.12, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_rollStabilityPreset",
    "LIST",
    [
        localize "STR_FIXICS_SETTING_ROLL_PRESET",
        localize "STR_FIXICS_SETTING_ROLL_PRESET_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    [
        [0, 1, 2, 3],
        [
            localize "STR_FIXICS_SETTING_ROLL_PRESET_REALISTIC_STABLE",
            localize "STR_FIXICS_SETTING_ROLL_PRESET_OFFROAD_ASSIST",
            localize "STR_FIXICS_SETTING_ROLL_PRESET_AGGRESSIVE_SQA",
            localize "STR_FIXICS_SETTING_ROLL_PRESET_CUSTOM"
        ],
        0
    ],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_rollStabilityEnabled",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_ROLL_STABILITY_ENABLED",
        localize "STR_FIXICS_SETTING_ROLL_STABILITY_ENABLED_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    true,
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_swayBarEnabled",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_SWAY_BAR_ENABLED",
        localize "STR_FIXICS_SETTING_SWAY_BAR_ENABLED_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    true,
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_frontSwayBarEnabled",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_FRONT_SWAY_BAR_ENABLED",
        localize "STR_FIXICS_SETTING_FRONT_SWAY_BAR_ENABLED_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    true,
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_frontSwayBarStrength",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_FRONT_SWAY_BAR_STRENGTH",
        localize "STR_FIXICS_SETTING_FRONT_SWAY_BAR_STRENGTH_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    [0, 1, 0.5, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_rearSwayBarEnabled",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_REAR_SWAY_BAR_ENABLED",
        localize "STR_FIXICS_SETTING_REAR_SWAY_BAR_ENABLED_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    true,
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_rearSwayBarStrength",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_REAR_SWAY_BAR_STRENGTH",
        localize "STR_FIXICS_SETTING_REAR_SWAY_BAR_STRENGTH_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    [0, 1, 0.5, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_controlledSlipEnabled",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_CONTROLLED_SLIP_ENABLED",
        localize "STR_FIXICS_SETTING_CONTROLLED_SLIP_ENABLED_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    true,
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_controlledSlipActivationSpeedKmh",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_CONTROLLED_SLIP_ACTIVATION_SPEED",
        localize "STR_FIXICS_SETTING_CONTROLLED_SLIP_ACTIVATION_SPEED_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    [20, 140, 55, 0],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_controlledSlipSteeringThreshold",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_CONTROLLED_SLIP_STEERING_THRESHOLD",
        localize "STR_FIXICS_SETTING_CONTROLLED_SLIP_STEERING_THRESHOLD_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    [0.1, 1, 0.65, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_controlledSlipStrength",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_CONTROLLED_SLIP_STRENGTH",
        localize "STR_FIXICS_SETTING_CONTROLLED_SLIP_STRENGTH_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    [0, 0.5, 0.16, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_controlledSlipMaximumRelease",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_CONTROLLED_SLIP_MAXIMUM_RELEASE",
        localize "STR_FIXICS_SETTING_CONTROLLED_SLIP_MAXIMUM_RELEASE_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    [0.01, 0.6, 0.22, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_controlledSlipTerrainInfluence",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_CONTROLLED_SLIP_TERRAIN_INFLUENCE",
        localize "STR_FIXICS_SETTING_CONTROLLED_SLIP_TERRAIN_INFLUENCE_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    true,
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_controlledSlipDebugLogging",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_CONTROLLED_SLIP_DEBUG_LOGGING",
        localize "STR_FIXICS_SETTING_CONTROLLED_SLIP_DEBUG_LOGGING_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    false,
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_terrainTireEnabled",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_TERRAIN_TIRE_ENABLED",
        localize "STR_FIXICS_SETTING_TERRAIN_TIRE_ENABLED_TOOLTIP"
    ],
    ["FIXICS", "Terrain Tire"],
    true,
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_tirePressureEnabled",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_TIRE_PRESSURE_ENABLED",
        localize "STR_FIXICS_SETTING_TIRE_PRESSURE_ENABLED_TOOLTIP"
    ],
    ["FIXICS", "Terrain Tire"],
    true,
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_nativeTerrainTireEnabled",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_NATIVE_TERRAIN_TIRE",
        localize "STR_FIXICS_SETTING_NATIVE_TERRAIN_TIRE_TOOLTIP"
    ],
    ["FIXICS", "Terrain Tire"],
    false,
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_tireDeflationRate",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_TIRE_DEFLATION_RATE",
        localize "STR_FIXICS_SETTING_TIRE_DEFLATION_RATE_TOOLTIP"
    ],
    ["FIXICS", "Terrain Tire"],
    [0, 1, 0.025, 3],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_tireMinimumMobility",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_TIRE_MINIMUM_MOBILITY",
        localize "STR_FIXICS_SETTING_TIRE_MINIMUM_MOBILITY_TOOLTIP"
    ],
    ["FIXICS", "Terrain Tire"],
    [0.05, 1, 0.35, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_tireDragStrength",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_TIRE_DRAG_STRENGTH",
        localize "STR_FIXICS_SETTING_TIRE_DRAG_STRENGTH_TOOLTIP"
    ],
    ["FIXICS", "Terrain Tire"],
    [0, 1, 0.35, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_tireSteeringPenalty",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_TIRE_STEERING_PENALTY",
        localize "STR_FIXICS_SETTING_TIRE_STEERING_PENALTY_TOOLTIP"
    ],
    ["FIXICS", "Terrain Tire"],
    [0, 1, 0.30, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_tireDebugLogging",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_TIRE_DEBUG_LOGGING",
        localize "STR_FIXICS_SETTING_TIRE_DEBUG_LOGGING_TOOLTIP"
    ],
    ["FIXICS", "Terrain Tire"],
    false,
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_rolloverSafetyEnabled",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_ROLLOVER_SAFETY_ENABLED",
        localize "STR_FIXICS_SETTING_ROLLOVER_SAFETY_ENABLED_TOOLTIP"
    ],
    ["FIXICS", "Terrain Tire"],
    true,
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_airborneGraceWindow",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_AIRBORNE_GRACE_WINDOW",
        localize "STR_FIXICS_SETTING_AIRBORNE_GRACE_WINDOW_TOOLTIP"
    ],
    ["FIXICS", "Terrain Tire"],
    [0, 1, 0.50, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_driverlessDecayEnabled",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_DRIVERLESS_DECAY_ENABLED",
        localize "STR_FIXICS_SETTING_DRIVERLESS_DECAY_ENABLED_TOOLTIP"
    ],
    ["FIXICS", "Terrain Tire"],
    true,
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_driverlessDecayCap",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_DRIVERLESS_DECAY_CAP",
        localize "STR_FIXICS_SETTING_DRIVERLESS_DECAY_CAP_TOOLTIP"
    ],
    ["FIXICS", "Terrain Tire"],
    [0, 1, 0.15, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_destroyedTireThreshold",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_DESTROYED_TIRE_THRESHOLD",
        localize "STR_FIXICS_SETTING_DESTROYED_TIRE_THRESHOLD_TOOLTIP"
    ],
    ["FIXICS", "Terrain Tire"],
    [0.5, 1, 0.85, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_destroyedTireDebugLogging",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_DESTROYED_TIRE_DEBUG_LOGGING",
        localize "STR_FIXICS_SETTING_DESTROYED_TIRE_DEBUG_LOGGING_TOOLTIP"
    ],
    ["FIXICS", "Terrain Tire"],
    false,
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_weatherTerrainEnabled",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_WEATHER_TERRAIN_ENABLED",
        localize "STR_FIXICS_SETTING_WEATHER_TERRAIN_ENABLED_TOOLTIP"
    ],
    ["FIXICS", "Terrain Tire"],
    true,
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_weatherSaturationTime",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_WEATHER_SATURATION_TIME",
        localize "STR_FIXICS_SETTING_WEATHER_SATURATION_TIME_TOOLTIP"
    ],
    ["FIXICS", "Terrain Tire"],
    [5, 120, 30, 0],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_weatherDryingTime",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_WEATHER_DRYING_TIME",
        localize "STR_FIXICS_SETTING_WEATHER_DRYING_TIME_TOOLTIP"
    ],
    ["FIXICS", "Terrain Tire"],
    [30, 600, 180, 0],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_hydroplaningEnabled",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_HYDROPLANING_ENABLED",
        localize "STR_FIXICS_SETTING_HYDROPLANING_ENABLED_TOOLTIP"
    ],
    ["FIXICS", "Terrain Tire"],
    true,
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_hydroplaningSpeedKmh",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_HYDROPLANING_SPEED",
        localize "STR_FIXICS_SETTING_HYDROPLANING_SPEED_TOOLTIP"
    ],
    ["FIXICS", "Terrain Tire"],
    [40, 140, 70, 0],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_windHandlingEnabled",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_WIND_HANDLING_ENABLED",
        localize "STR_FIXICS_SETTING_WIND_HANDLING_ENABLED_TOOLTIP"
    ],
    ["FIXICS", "Terrain Tire"],
    true,
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_windHandlingStrength",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_WIND_HANDLING_STRENGTH",
        localize "STR_FIXICS_SETTING_WIND_HANDLING_STRENGTH_TOOLTIP"
    ],
    ["FIXICS", "Terrain Tire"],
    [0, 0.25, 0.05, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_weatherDebugLogging",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_WEATHER_DEBUG_LOGGING",
        localize "STR_FIXICS_SETTING_WEATHER_DEBUG_LOGGING_TOOLTIP"
    ],
    ["FIXICS", "Terrain Tire"],
    false,
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_rollActivationBankDeg",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_ROLL_ACTIVATION_BANK",
        localize "STR_FIXICS_SETTING_ROLL_ACTIVATION_BANK_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    [5, 60, 18, 0],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_rollActivationRateDeg",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_ROLL_ACTIVATION_RATE",
        localize "STR_FIXICS_SETTING_ROLL_ACTIVATION_RATE_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    [5, 240, 45, 0],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_rollStrength",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_ROLL_STRENGTH",
        localize "STR_FIXICS_SETTING_ROLL_STRENGTH_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    [0, 0.5, 0.08, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_rollMaximumCorrection",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_ROLL_MAXIMUM_CORRECTION",
        localize "STR_FIXICS_SETTING_ROLL_MAXIMUM_CORRECTION_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    [0.01, 0.4, 0.08, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_rollAirborneGraceSeconds",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_ROLL_AIRBORNE_GRACE",
        localize "STR_FIXICS_SETTING_ROLL_AIRBORNE_GRACE_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    [0, 1, 0.35, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_stabilityDebugLogging",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_STABILITY_DEBUG_LOGGING",
        localize "STR_FIXICS_SETTING_STABILITY_DEBUG_LOGGING_TOOLTIP"
    ],
    ["FIXICS", "Vehicle Stability"],
    false,
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_runtimeAssistCoordinatorEnabled",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_RUNTIME_COORDINATOR_ENABLED",
        localize "STR_FIXICS_SETTING_RUNTIME_COORDINATOR_ENABLED_TOOLTIP"
    ],
    ["FIXICS", "Runtime Assist"],
    true,
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_runtimeAssistTerrainInfluenceEnabled",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_RUNTIME_TERRAIN_ENABLED",
        localize "STR_FIXICS_SETTING_RUNTIME_TERRAIN_ENABLED_TOOLTIP"
    ],
    ["FIXICS", "Runtime Assist"],
    true,
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_runtimeAssistTerrainInfluenceStrength",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_RUNTIME_TERRAIN_STRENGTH",
        localize "STR_FIXICS_SETTING_RUNTIME_TERRAIN_STRENGTH_TOOLTIP"
    ],
    ["FIXICS", "Runtime Assist"],
    [0, 1, 0.25, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_runtimeAssistBrakingSlopeRetention",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_RUNTIME_BRAKING_SLOPE_RETENTION",
        localize "STR_FIXICS_SETTING_RUNTIME_BRAKING_SLOPE_RETENTION_TOOLTIP"
    ],
    ["FIXICS", "Runtime Assist"],
    [0, 1, 0.35, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_runtimeAssistMassDampingStrength",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_RUNTIME_MASS_DAMPING",
        localize "STR_FIXICS_SETTING_RUNTIME_MASS_DAMPING_TOOLTIP"
    ],
    ["FIXICS", "Runtime Assist"],
    [0, 1, 0.15, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_runtimeAssistMaximumComposedCorrection",
    "SLIDER",
    [
        localize "STR_FIXICS_SETTING_RUNTIME_MAX_CORRECTION",
        localize "STR_FIXICS_SETTING_RUNTIME_MAX_CORRECTION_TOOLTIP"
    ],
    ["FIXICS", "Runtime Assist"],
    [0, 0.5, 0.25, 2],
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_runtimeAssistDebugLogging",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_RUNTIME_DEBUG_LOGGING",
        localize "STR_FIXICS_SETTING_RUNTIME_DEBUG_LOGGING_TOOLTIP"
    ],
    ["FIXICS", "Runtime Assist"],
    false,
    1
] call CBA_fnc_addSetting;

true
