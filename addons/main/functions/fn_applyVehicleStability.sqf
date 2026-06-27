/*
 * FIXICS_fnc_applyVehicleStability
 *
 * Applies bounded lateral and roll stability recommendations to an eligible vehicle.
 *
 * Arguments:
 *   0: Vehicle <OBJECT>
 *   1: Delta time <NUMBER>
 *
 * Return: <BOOL> true when lateral or vertical velocity was corrected
 * Locality: local player driver machine
 *
 * Engine note:
 *   Model-space index 1 remains owned by the driver controller.
 *
 * Example:
 *   [_vehicle, _deltaTime] call FIXICS_fnc_applyVehicleStability;
 */
params [
    ["_vehicle", objNull, [objNull]],
    ["_deltaTime", 0, [0]]
];

if (isNull _vehicle) exitWith {
    false
};

private _clearYawSample = {
    params ["_sampleVehicle"];

    _sampleVehicle setVariable [
        "FIXICS_stabilityPreviousHeading",
        nil,
        false
    ];
    _sampleVehicle setVariable [
        "FIXICS_stabilityPreviousTime",
        nil,
        false
    ];
    _sampleVehicle setVariable [
        "FIXICS_rollPreviousBank",
        nil,
        false
    ];
    _sampleVehicle setVariable [
        "FIXICS_rollPreviousTime",
        nil,
        false
    ];
};

private _clearYawOnlySample = {
    params ["_sampleVehicle"];

    _sampleVehicle setVariable [
        "FIXICS_stabilityPreviousHeading",
        nil,
        false
    ];
    _sampleVehicle setVariable [
        "FIXICS_stabilityPreviousTime",
        nil,
        false
    ];
};

private _clearRollSample = {
    params ["_sampleVehicle"];

    _sampleVehicle setVariable [
        "FIXICS_rollPreviousBank",
        nil,
        false
    ];
    _sampleVehicle setVariable [
        "FIXICS_rollPreviousTime",
        nil,
        false
    ];
};

private _clearTerrainTireRecommendation = {
    params ["_sampleVehicle"];

    private _neutralTerrainTireRecommendation = createHashMapFromArray [
        ["terrainGripClass", "UNKNOWN"],
        ["tractionMultiplier", 1],
        ["accelerationTractionMultiplier", 1],
        ["brakingTractionMultiplier", 1],
        ["turningTractionMultiplier", 1],
        ["slopeTractionMultiplier", 1],
        ["wheelspinEstimate", 0],
        ["tireDeflationState", "stale-safe"],
        ["tireDragPenalty", 0],
        ["tireSteeringPenalty", 0],
        ["massModifier", 1],
        ["perWheelMode", "aggregate"],
        ["wheelSupportState", "UNKNOWN"],
        ["rolloverSuppressed", false],
        ["driverlessDecay", 0],
        ["destroyedTireCount", 0],
        ["destroyedTireRatio", 0],
        ["destroyedTirePenalty", 0],
        ["mobilityLimiter", 1],
        ["weatherTerrainEnabled", false],
        ["rainLevel", 0],
        ["overcastLevel", 0],
        ["surfaceWetness", 0],
        ["terrainSaturation", _sampleVehicle getVariable ["FIXICS_weatherTerrainSaturation", 0]],
        ["weatherGripMultiplier", 1],
        ["hydroplaningRisk", 0],
        ["windStrength", 0],
        ["windCrossComponent", 0],
        ["windHandlingMultiplier", 0],
        ["weatherReason", "stale-safe"],
        ["tireAirState", _sampleVehicle getVariable ["FIXICS_tireAirState", 1]]
    ];

    _sampleVehicle setVariable [
        "FIXICS_terrainTireRecommendation",
        _neutralTerrainTireRecommendation,
        false
    ];
};

if (!([_vehicle] call FIXICS_fnc_isVehicleLocal)) exitWith {
    [_vehicle] call _clearYawSample;
    [_vehicle] call _clearTerrainTireRecommendation;
    false
};
if (isNull player) exitWith {
    [_vehicle] call _clearYawSample;
    [_vehicle] call _clearTerrainTireRecommendation;
    false
};
private _isPlayerDriver = driver _vehicle == player;
if (!_isPlayerDriver) exitWith {
    [_vehicle] call _clearYawSample;
    [_vehicle] call _clearTerrainTireRecommendation;
    false
};
if (_vehicle getVariable ["FIXICS_handbrakeEnabled", false]) exitWith {
    [_vehicle] call _clearYawSample;
    [_vehicle] call _clearTerrainTireRecommendation;
    false
};

private _vehicleProfile = [_vehicle] call FIXICS_fnc_getVehicleProfile;
private _profileSettings = _vehicleProfile getOrDefault ["settings", createHashMap];
private _getProfileSetting = {
    params ["_key", "_default"];

    _profileSettings getOrDefault [_key, missionNamespace getVariable [_key, _default]]
};

private _profile = [_vehicle] call FIXICS_fnc_getVehicleStabilityProfile;
if ((count _profile) < 7 || {!(_profile # 0)}) exitWith {
    [_vehicle] call _clearYawSample;
    [_vehicle] call _clearTerrainTireRecommendation;
    false
};

private _now = diag_tickTime;
private _isGrounded = isTouchingGround _vehicle;
private _rollAirborneGraceSeconds = missionNamespace getVariable [
    "FIXICS_rollAirborneGraceSeconds",
    0.35
];
_rollAirborneGraceSeconds = ["FIXICS_rollAirborneGraceSeconds", _rollAirborneGraceSeconds] call _getProfileSetting;

private _rollPresetIndex = missionNamespace getVariable [
    "FIXICS_rollStabilityPreset",
    0
];
_rollPresetIndex = ["FIXICS_rollStabilityPreset", _rollPresetIndex] call _getProfileSetting;
private _rollPreset = [
    "REALISTIC_STABLE",
    "OFFROAD_ASSIST",
    "AGGRESSIVE_SQA",
    "CUSTOM"
] param [
    _rollPresetIndex,
    "REALISTIC_STABLE"
];
private _rollPresetSettings = switch (_rollPreset) do {
    case "OFFROAD_ASSIST": {
        [8, 120, 0.28, 0.22, 0.65]
    };
    case "AGGRESSIVE_SQA": {
        [5, 240, 0.5, 0.4, 1]
    };
    case "CUSTOM": {
        [
            ["FIXICS_rollActivationBankDeg", 18] call _getProfileSetting,
            ["FIXICS_rollActivationRateDeg", 45] call _getProfileSetting,
            ["FIXICS_rollStrength", 0.08] call _getProfileSetting,
            ["FIXICS_rollMaximumCorrection", 0.08] call _getProfileSetting,
            ["FIXICS_rollAirborneGraceSeconds", 0.35] call _getProfileSetting
        ]
    };
    default {
        [18, 45, 0.08, 0.08, 0.35]
    };
};
_rollPresetSettings params [
    ["_rollActivationBankDeg", 18, [0]],
    ["_rollActivationRateDeg", 45, [0]],
    ["_rollStrength", 0.08, [0]],
    ["_rollMaximumCorrection", 0.08, [0]],
    ["_rollPresetAirborneGraceSeconds", 0.35, [0]]
];
_rollAirborneGraceSeconds = _rollPresetAirborneGraceSeconds;
_rollAirborneGraceSeconds = (_rollAirborneGraceSeconds max 0) min 1;
private _lastGroundedAt = _vehicle getVariable [
    "FIXICS_rollLastGroundedAt",
    (_now - _rollAirborneGraceSeconds - 1)
];
if (_isGrounded) then {
    _lastGroundedAt = _now;
    _vehicle setVariable ["FIXICS_rollLastGroundedAt", _lastGroundedAt, false];
};

private _withinRollGrace = _isGrounded || {
    (_now - _lastGroundedAt) <= _rollAirborneGraceSeconds
};
private _swayBarEnabled = missionNamespace getVariable [
    "FIXICS_swayBarEnabled",
    true
];
_swayBarEnabled = ["FIXICS_swayBarEnabled", _swayBarEnabled] call _getProfileSetting;
private _frontSwayBarEnabled = missionNamespace getVariable [
    "FIXICS_frontSwayBarEnabled",
    true
];
_frontSwayBarEnabled = ["FIXICS_frontSwayBarEnabled", _frontSwayBarEnabled] call _getProfileSetting;
private _frontSwayBarStrength = (
    ["FIXICS_frontSwayBarStrength", 0.5] call _getProfileSetting
) max 0 min 1;
private _rearSwayBarEnabled = missionNamespace getVariable [
    "FIXICS_rearSwayBarEnabled",
    true
];
_rearSwayBarEnabled = ["FIXICS_rearSwayBarEnabled", _rearSwayBarEnabled] call _getProfileSetting;
private _rearSwayBarStrength = (
    ["FIXICS_rearSwayBarStrength", 0.5] call _getProfileSetting
) max 0 min 1;
private _frontSwayBarContribution = [0, _frontSwayBarStrength] select _frontSwayBarEnabled;
private _rearSwayBarContribution = [0, _rearSwayBarStrength] select _rearSwayBarEnabled;
private _swayBarContributionCount = 0;
if (_frontSwayBarContribution > 0) then {
    _swayBarContributionCount = _swayBarContributionCount + 1;
};
if (_rearSwayBarContribution > 0) then {
    _swayBarContributionCount = _swayBarContributionCount + 1;
};
private _swayBarStrengthMultiplier = if (
    _swayBarEnabled
    && {_swayBarContributionCount > 0}
) then {
    (
        (_frontSwayBarContribution + _rearSwayBarContribution)
        / _swayBarContributionCount
    ) max 0 min 1
} else {
    0
};
/*
 * Replaces the old yaw-only airborne guard:
 * if !(isTouchingGround _vehicle) exitWith { [_vehicle] call _clearYawSample; false };
 */
if (!_isGrounded && {!_withinRollGrace}) exitWith {
    [_vehicle] call _clearYawSample;
    [_vehicle] call _clearTerrainTireRecommendation;
    false
};
if (!_isGrounded) then {
    [_vehicle] call _clearYawOnlySample;
};

private _diagnosticYawRate = 0;
private _steeringInput = (((inputAction "CarRight") - (inputAction "CarLeft")) / 3) max -1 min 1;

private _modeIndex = missionNamespace getVariable [
    "FIXICS_stabilityAssistMode",
    0
];
_modeIndex = ["FIXICS_stabilityAssistMode", _modeIndex] call _getProfileSetting;
private _mode = ["OFF", "YAW", "YAW_LATERAL", "COUNTERSTEER"] param [
    _modeIndex,
    "OFF"
];

private _velocity = velocityModelSpace _vehicle;
private _lateral = _velocity # 0;
private _longitudinal = _velocity # 1;
private _vertical = _velocity # 2;
private _stabilityDecision = createHashMapFromArray [
    ["applied", false],
    ["lateralDelta", 0],
    ["rollDelta", 0],
    ["mode", _mode],
    ["rollApplied", false],
    ["rollReason", "not-evaluated"],
    ["rollEligible", false],
    ["rollPreset", ""],
    ["rollActivationBankDeg", 0],
    ["rollActivationRateDeg", 0],
    ["controlledSlipEnabled", false],
    ["controlledSlipEligible", false],
    ["controlledSlipApplied", false],
    ["controlledSlipReason", "not-evaluated"],
    ["controlledSlipSteeringDemand", 0],
    ["controlledSlipLateralDemand", 0],
    ["controlledSlipRollRisk", 0],
    ["controlledSlipTerrainClass", "unknown"],
    ["controlledSlipTerrainMultiplier", 1],
    ["controlledSlipGripReleaseFactor", 0],
    ["controlledSlipCorrection", 0],
    ["terrainTireRecommendation", createHashMap],
    ["terrainGripClass", "UNKNOWN"],
    ["tractionMultiplier", 1],
    ["accelerationTractionMultiplier", 1],
    ["brakingTractionMultiplier", 1],
    ["turningTractionMultiplier", 1],
    ["slopeTractionMultiplier", 1],
    ["wheelspinEstimate", 0],
    ["tireDeflationState", "unknown"],
    ["tireDragPenalty", 0],
    ["tireSteeringPenalty", 0],
    ["massModifier", 1],
    ["perWheelMode", "aggregate"],
    ["wheelSupportState", "UNKNOWN"],
    ["rolloverSuppressed", false],
    ["driverlessDecay", 0],
    ["destroyedTireCount", 0],
    ["destroyedTireRatio", 0],
    ["destroyedTirePenalty", 0],
    ["mobilityLimiter", 1],
    ["weatherTerrainEnabled", false],
    ["rainLevel", 0],
    ["overcastLevel", 0],
    ["surfaceWetness", 0],
    ["terrainSaturation", 0],
    ["weatherGripMultiplier", 1],
    ["hydroplaningRisk", 0],
    ["windStrength", 0],
    ["windCrossComponent", 0],
    ["windHandlingMultiplier", 0],
    ["weatherReason", "not-evaluated"],
    ["yawRate", 0],
    ["bank", 0],
    ["bankRate", 0]
];
private _speedKmh = (abs _longitudinal) * 3.6;
private _activationSpeedKmh = _profile # 1;
private _surface = surfaceType (getPosWorld _vehicle);
private _terrainClass = switch (true) do {
    case (_surface find "#GdtAsphalt" >= 0): {"paved"};
    case (_surface find "#GdtConcrete" >= 0): {"paved"};
    case (_surface find "#GdtDirt" >= 0): {"dirt"};
    case (_surface find "#GdtGrass" >= 0): {"grass"};
    default {"unknown"};
};
private _terrainNormal = surfaceNormal (getPosWorld _vehicle);
private _slopeSeverity = 1 - (((_terrainNormal # 2) max 0) min 1);
private _terrainDeltaTime = [0.016, _deltaTime] select (finite _deltaTime && {_deltaTime > 0});
private _terrainPitchBank = _vehicle call BIS_fnc_getPitchBank;
private _weatherLastUpdate = _vehicle getVariable ["FIXICS_weatherTerrainLastUpdate", _now];
private _weatherDeltaTime = (_now - _weatherLastUpdate) max 0 min 10;
private _currentRainLevel = rain;
private _currentOvercastLevel = overcast;
private _currentWind = wind;
private _currentWindStr = windStr;
private _weatherSaturation = _vehicle getVariable ["FIXICS_weatherTerrainSaturation", 0];
private _terrainWheelHitpointDamage = [];
private _terrainHitPointDamage = getAllHitPointsDamage _vehicle;
if ((count _terrainHitPointDamage) >= 3) then {
    private _terrainHitPointNames = _terrainHitPointDamage # 0;
    private _terrainHitPointValues = _terrainHitPointDamage # 2;
    for "_index" from 0 to ((count _terrainHitPointNames) - 1) do {
        private _hitPointName = _terrainHitPointNames # _index;
        if (((toLower _hitPointName) find "wheel") >= 0) then {
            _terrainWheelHitpointDamage pushBack (_terrainHitPointValues # _index);
        };
    };
};
private _massKg = getMass _vehicle;
if (!finite _massKg || {_massKg <= 0}) then {
    _massKg = getNumber (configOf _vehicle >> "mass");
};
if (!finite _massKg || {_massKg <= 0}) then {
    _massKg = 1500;
};
private _terrainTireState = createHashMapFromArray [
    ["vehicle", _vehicle],
    ["surfaceType", _surface],
    ["speedKmh", _speedKmh],
    [
        "forwardDemand",
        (
            (inputAction "CarForward")
            max (inputAction "CarFastForward")
            max (inputAction "CarSlowForward")
        ) max 0 min 1
    ],
    ["brakeDemand", (inputAction "CarBack") max 0 min 1],
    ["steeringDemand", abs _steeringInput],
    ["slopeSeverity", _slopeSeverity],
    ["deltaTime", _terrainDeltaTime],
    ["massKg", _massKg],
    ["tireDamage", damage _vehicle],
    ["tireAirState", _vehicle getVariable ["FIXICS_tireAirState", 1]],
    ["isTouchingGround", _isGrounded],
    ["lastGroundedAge", _now - _lastGroundedAt],
    ["driverPresent", !(isNull driver _vehicle)],
    ["vectorUp", vectorUp _vehicle],
    ["pitch", _terrainPitchBank # 0],
    ["bank", _terrainPitchBank # 1],
    ["wheelDamageValues", _terrainWheelHitpointDamage],
    ["rainLevel", _currentRainLevel],
    ["overcastLevel", _currentOvercastLevel],
    ["windVector", _currentWind],
    ["windStrength", _currentWindStr],
    ["vehicleRightVector", vectorDir _vehicle vectorCrossProduct vectorUp _vehicle],
    ["weatherSaturation", _weatherSaturation],
    ["weatherDeltaTime", _weatherDeltaTime]
];
private _terrainTireSettings = createHashMapFromArray [
    ["enabled", ["FIXICS_terrainTireEnabled", true] call _getProfileSetting],
    ["tirePressureEnabled", ["FIXICS_tirePressureEnabled", true] call _getProfileSetting],
    ["deflationRate", ["FIXICS_tireDeflationRate", 0.025] call _getProfileSetting],
    ["minimumMobility", ["FIXICS_tireMinimumMobility", 0.35] call _getProfileSetting],
    ["dragStrength", ["FIXICS_tireDragStrength", 0.35] call _getProfileSetting],
    ["steeringPenalty", ["FIXICS_tireSteeringPenalty", 0.30] call _getProfileSetting],
    ["rolloverSafetyEnabled", ["FIXICS_rolloverSafetyEnabled", true] call _getProfileSetting],
    ["airborneGraceWindow", ["FIXICS_airborneGraceWindow", 0.50] call _getProfileSetting],
    ["driverlessDecayEnabled", ["FIXICS_driverlessDecayEnabled", true] call _getProfileSetting],
    ["driverlessDecayCap", ["FIXICS_driverlessDecayCap", 0.15] call _getProfileSetting],
    ["destroyedTireThreshold", ["FIXICS_destroyedTireThreshold", 0.85] call _getProfileSetting],
    ["weatherTerrainEnabled", ["FIXICS_weatherTerrainEnabled", true] call _getProfileSetting],
    ["weatherSaturationTime", ["FIXICS_weatherSaturationTime", 30] call _getProfileSetting],
    ["weatherDryingTime", ["FIXICS_weatherDryingTime", 180] call _getProfileSetting],
    ["hydroplaningEnabled", ["FIXICS_hydroplaningEnabled", true] call _getProfileSetting],
    ["hydroplaningSpeedKmh", ["FIXICS_hydroplaningSpeedKmh", 70] call _getProfileSetting],
    ["windHandlingEnabled", ["FIXICS_windHandlingEnabled", true] call _getProfileSetting],
    ["windHandlingStrength", ["FIXICS_windHandlingStrength", 0.05] call _getProfileSetting]
];
private _terrainTireRecommendation = [
    _terrainTireState,
    _terrainTireSettings
] call FIXICS_fnc_getTerrainTireRecommendation;
_vehicle setVariable ["FIXICS_tireAirState", _terrainTireRecommendation getOrDefault ["tireAirState", 1], false];
_vehicle setVariable ["FIXICS_weatherTerrainLastUpdate", _now, false];
_vehicle setVariable [
    "FIXICS_weatherTerrainSaturation",
    _terrainTireRecommendation getOrDefault ["terrainSaturation", _weatherSaturation],
    false
];
_vehicle setVariable ["FIXICS_terrainTireRecommendation", _terrainTireRecommendation, false];
private _turningTractionMultiplier = (
    _terrainTireRecommendation getOrDefault ["turningTractionMultiplier", 1]
) max 0.15 min 1;
private _terrainTireFields = [
    ["terrainGripClass", "UNKNOWN"],
    ["tractionMultiplier", 1],
    ["accelerationTractionMultiplier", 1],
    ["brakingTractionMultiplier", 1],
    ["turningTractionMultiplier", 1],
    ["slopeTractionMultiplier", 1],
    ["wheelspinEstimate", 0],
    ["tireDeflationState", "unknown"],
    ["tireDragPenalty", 0],
    ["tireSteeringPenalty", 0],
    ["massModifier", 1],
    ["perWheelMode", "aggregate"],
    ["wheelSupportState", "UNKNOWN"],
    ["rolloverSuppressed", false],
    ["driverlessDecay", 0],
    ["destroyedTireCount", 0],
    ["destroyedTireRatio", 0],
    ["destroyedTirePenalty", 0],
    ["mobilityLimiter", 1],
    ["weatherTerrainEnabled", false],
    ["rainLevel", 0],
    ["overcastLevel", 0],
    ["surfaceWetness", 0],
    ["terrainSaturation", 0],
    ["weatherGripMultiplier", 1],
    ["hydroplaningRisk", 0],
    ["windStrength", 0],
    ["windCrossComponent", 0],
    ["windHandlingMultiplier", 0],
    ["weatherReason", "not-evaluated"]
];
_stabilityDecision set ["terrainTireRecommendation", _terrainTireRecommendation];
{
    _x params ["_field", "_default"];
    _stabilityDecision set [
        _field,
        _terrainTireRecommendation getOrDefault [_field, _default]
    ];
} forEach _terrainTireFields;
if (missionNamespace getVariable ["FIXICS_tireDebugLogging", false]) then {
    diag_log format [
        "[FIXICS][TerrainTire] class=%1 surface=%2 terrain=%3 traction=%4 wheelspin=%5 air=%6 deflation=%7 drag=%8 steeringPenalty=%9 massModifier=%10 perWheelMode=%11",
        typeOf _vehicle,
        _surface,
        _terrainClass,
        _terrainTireRecommendation getOrDefault ["tractionMultiplier", 1],
        _terrainTireRecommendation getOrDefault ["wheelspinEstimate", 0],
        _terrainTireRecommendation getOrDefault ["tireAirState", 1],
        _terrainTireRecommendation getOrDefault ["tireDeflationState", "unknown"],
        _terrainTireRecommendation getOrDefault ["tireDragPenalty", 0],
        _terrainTireRecommendation getOrDefault ["tireSteeringPenalty", 0],
        _terrainTireRecommendation getOrDefault ["massModifier", 1],
        _terrainTireRecommendation getOrDefault ["perWheelMode", "aggregate"]
    ];
};
if (missionNamespace getVariable ["FIXICS_destroyedTireDebugLogging", false]) then {
    diag_log format [
        "[FIXICS][DestroyedTire] class=%1 wheelSupportState=%2 rolloverSuppressed=%3 destroyedTireCount=%4 destroyedTireRatio=%5 destroyedTirePenalty=%6 mobilityLimiter=%7 driverlessDecay=%8",
        typeOf _vehicle,
        _terrainTireRecommendation getOrDefault ["wheelSupportState", "UNKNOWN"],
        _terrainTireRecommendation getOrDefault ["rolloverSuppressed", false],
        _terrainTireRecommendation getOrDefault ["destroyedTireCount", 0],
        _terrainTireRecommendation getOrDefault ["destroyedTireRatio", 0],
        _terrainTireRecommendation getOrDefault ["destroyedTirePenalty", 0],
        _terrainTireRecommendation getOrDefault ["mobilityLimiter", 1],
        _terrainTireRecommendation getOrDefault ["driverlessDecay", 0]
    ];
};
if (missionNamespace getVariable ["FIXICS_weatherDebugLogging", false]) then {
    diag_log format [
        "[FIXICS][WeatherTerrain] class=%1 rainLevel=%2 overcastLevel=%3 surfaceWetness=%4 terrainSaturation=%5 weatherGripMultiplier=%6 hydroplaningRisk=%7 windStrength=%8 windCrossComponent=%9 windHandlingMultiplier=%10 weatherReason=%11",
        typeOf _vehicle,
        _terrainTireRecommendation getOrDefault ["rainLevel", 0],
        _terrainTireRecommendation getOrDefault ["overcastLevel", 0],
        _terrainTireRecommendation getOrDefault ["surfaceWetness", 0],
        _terrainTireRecommendation getOrDefault ["terrainSaturation", 0],
        _terrainTireRecommendation getOrDefault ["weatherGripMultiplier", 1],
        _terrainTireRecommendation getOrDefault ["hydroplaningRisk", 0],
        _terrainTireRecommendation getOrDefault ["windStrength", 0],
        _terrainTireRecommendation getOrDefault ["windCrossComponent", 0],
        _terrainTireRecommendation getOrDefault ["windHandlingMultiplier", 0],
        _terrainTireRecommendation getOrDefault ["weatherReason", "not-evaluated"]
    ];
};

private _recommended = false;
private _recommendedLongitudinal = _longitudinal;
private _recommendedLateral = _lateral;
private _yawRecommendation = 0;
private _recommendedMode = _mode;
private _lateralApplied = false;
private _controlledSlipApplied = false;
private _controlledSlipCorrection = 0;
private _windHandlingMultiplier = _terrainTireRecommendation getOrDefault ["windHandlingMultiplier", 0];
private _windCrossComponent = _terrainTireRecommendation getOrDefault ["windCrossComponent", 0];
if (_isGrounded && {_windHandlingMultiplier > 0} && {!(_terrainTireRecommendation getOrDefault ["rolloverSuppressed", false])}) then {
    private _windDelta = (_windCrossComponent * _windHandlingMultiplier * _terrainDeltaTime) max -0.05 min 0.05;
    _velocity set [0, (_velocity # 0) + _windDelta];
    _lateralApplied = true;
    _stabilityDecision set ["lateralDelta", (_stabilityDecision getOrDefault ["lateralDelta", 0]) + _windDelta];
};

if (_isGrounded) then {
    private _heading = getDir _vehicle;
    private _previousHeading = _vehicle getVariable [
        "FIXICS_stabilityPreviousHeading",
        _heading
    ];
    private _previousTime = _vehicle getVariable [
        "FIXICS_stabilityPreviousTime",
        _now
    ];

    if (!finite _deltaTime || {_deltaTime <= 0}) then {
        _deltaTime = (_now - _previousTime) max 0.001;
    };

    _vehicle setVariable ["FIXICS_stabilityPreviousHeading", _heading, false];
    _vehicle setVariable ["FIXICS_stabilityPreviousTime", _now, false];

    private _headingDelta = ((_heading - _previousHeading + 540) mod 360) - 180;
    private _yawRate = _headingDelta / (_deltaTime max 0.001);
    _diagnosticYawRate = _yawRate;
    _steeringInput = (((inputAction "CarRight") - (inputAction "CarLeft")) / 3) max -1 min 1;
    private _effectiveProfile = +_profile;
    _effectiveProfile set [3, (_effectiveProfile # 3) * _swayBarStrengthMultiplier];
    _effectiveProfile set [4, (_effectiveProfile # 4) * _swayBarStrengthMultiplier];
    _effectiveProfile set [5, (_effectiveProfile # 5) * _swayBarStrengthMultiplier];

    private _recommendation = [
        _mode,
        _longitudinal,
        _lateral,
        _yawRate,
        _steeringInput,
        _deltaTime,
        _effectiveProfile
    ] call FIXICS_fnc_getVehicleStabilityRecommendation;

    _recommendation params [
        ["_recommended", false, [false]],
        ["_recommendedLongitudinal", _longitudinal, [0]],
        ["_recommendedLateral", _lateral, [0]],
        ["_yawRecommendation", 0, [0]],
        ["_recommendedMode", _mode, [""]]
    ];

    if (_recommended && {_recommendedLateral != _lateral}) then {
        _recommendedLateral = _lateral + ((_recommendedLateral - _lateral) * _turningTractionMultiplier);
        _velocity set [0, _recommendedLateral];
        _lateralApplied = true;
        _stabilityDecision set ["lateralDelta", _recommendedLateral - _lateral];
    };
    _stabilityDecision set ["mode", _recommendedMode];
    _stabilityDecision set ["yawRate", _diagnosticYawRate];
};

private _rollEnabled = missionNamespace getVariable [
    "FIXICS_rollStabilityEnabled",
    true
];
_rollEnabled = ["FIXICS_rollStabilityEnabled", _rollEnabled] call _getProfileSetting;
private _rollEligible = _withinRollGrace
    && {_rollEnabled}
    && {_swayBarEnabled}
    && {_swayBarStrengthMultiplier > 0}
    && {_speedKmh >= _activationSpeedKmh};
private _rollApplied = false;
private _recommendedVertical = _vertical;
private _rollCorrection = 0;
private _rollSeverity = 0;
private _rollReason = "not-evaluated";
private _rollEvaluated = false;
private _bank = 0;
private _bankRate = 0;
_stabilityDecision set ["rollEligible", _rollEligible];
_stabilityDecision set ["rollPreset", _rollPreset];
_stabilityDecision set ["swayBarEnabled", _swayBarEnabled];
_stabilityDecision set ["frontSwayBarEnabled", _frontSwayBarEnabled];
_stabilityDecision set ["frontSwayBarStrength", _frontSwayBarStrength];
_stabilityDecision set ["rearSwayBarEnabled", _rearSwayBarEnabled];
_stabilityDecision set ["rearSwayBarStrength", _rearSwayBarStrength];
_stabilityDecision set ["swayBarStrengthMultiplier", _swayBarStrengthMultiplier];
_stabilityDecision set ["rollActivationBankDeg", _rollActivationBankDeg];
_stabilityDecision set ["rollActivationRateDeg", _rollActivationRateDeg];

if (!_rollEligible) then {
    [_vehicle] call _clearRollSample;
    _rollReason = switch (true) do {
        case (!_rollEnabled): {"disabled"};
        case (!_swayBarEnabled): {"sway-bar-disabled"};
        case (_swayBarStrengthMultiplier <= 0): {"sway-bars-disabled"};
        case (!_withinRollGrace): {"airborne-grace-expired"};
        case (_speedKmh < _activationSpeedKmh): {"below-speed-threshold"};
        default {"not-eligible"};
    };
    _stabilityDecision set ["rollReason", _rollReason];
} else {
    _rollEvaluated = true;
    private _pitchBank = _vehicle call BIS_fnc_getPitchBank;
    _bank = _pitchBank # 1;
    private _previousBank = _vehicle getVariable [
        "FIXICS_rollPreviousBank",
        _bank
    ];
    private _previousRollTime = _vehicle getVariable [
        "FIXICS_rollPreviousTime",
        _now
    ];
    private _rollDeltaTime = (_now - _previousRollTime) max 0.001;
    private _bankDelta = ((_bank - _previousBank + 540) mod 360) - 180;
    _bankRate = _bankDelta / _rollDeltaTime;

    _vehicle setVariable ["FIXICS_rollPreviousBank", _bank, false];
    _vehicle setVariable ["FIXICS_rollPreviousTime", _now, false];
    _stabilityDecision set ["bank", _bank];
    _stabilityDecision set ["bankRate", _bankRate];

    private _rollSettings = [
        _rollActivationBankDeg,
        _rollActivationRateDeg,
        _rollStrength * _swayBarStrengthMultiplier,
        _rollMaximumCorrection
    ];
    private _rollRecommendation = [
        _vertical,
        _bank,
        _bankRate,
        _rollDeltaTime,
        _rollSettings
    ] call FIXICS_fnc_getRollStabilityRecommendation;

    private _recommendedRoll = _rollRecommendation param [0, false, [false]];
    _recommendedVertical = _rollRecommendation param [1, _vertical, [0]];
    _rollCorrection = _rollRecommendation param [2, 0, [0]];
    _rollSeverity = _rollRecommendation param [3, 0, [0]];
    _rollReason = _rollRecommendation param [4, "unknown", [""]];

    if (_recommendedRoll && {_recommendedVertical != _vertical}) then {
        _velocity set [2, _recommendedVertical];
        _rollApplied = true;
        _stabilityDecision set ["rollDelta", _rollCorrection];
        _stabilityDecision set ["rollApplied", _rollApplied];
        _stabilityDecision set ["rollReason", _rollReason];
    } else {
        _stabilityDecision set ["rollReason", _rollReason];
    };
};

private _controlledSlipSettings = createHashMapFromArray [
    ["enabled", ["FIXICS_controlledSlipEnabled", true] call _getProfileSetting],
    [
        "activationSpeedKmh",
        ["FIXICS_controlledSlipActivationSpeedKmh", 55] call _getProfileSetting
    ],
    [
        "steeringThreshold",
        ["FIXICS_controlledSlipSteeringThreshold", 0.65] call _getProfileSetting
    ],
    ["strength", ["FIXICS_controlledSlipStrength", 0.16] call _getProfileSetting],
    [
        "maximumRelease",
        ["FIXICS_controlledSlipMaximumRelease", 0.22] call _getProfileSetting
    ],
    [
        "terrainInfluence",
        ["FIXICS_controlledSlipTerrainInfluence", true] call _getProfileSetting
    ]
];
private _controlledSlipState = createHashMapFromArray [
    ["speedKmh", _speedKmh],
    ["steeringDemand", abs _steeringInput],
    ["lateralSpeed", _lateral],
    ["longitudinalSpeed", _longitudinal],
    ["bank", _bank],
    ["bankRate", _bankRate],
    ["terrainClass", _terrainClass]
];
private _controlledSlipDecision = [
    _controlledSlipState,
    _controlledSlipSettings
] call FIXICS_fnc_getControlledSlipRecommendation;
_controlledSlipCorrection = _controlledSlipDecision getOrDefault [
    "controlledSlipCorrection",
    0
];
_controlledSlipApplied = (
    _controlledSlipDecision getOrDefault ["controlledSlipApplied", false]
) && {_controlledSlipCorrection != 0};
private _rolloverSuppressed = _terrainTireRecommendation getOrDefault ["rolloverSuppressed", false];
if (_controlledSlipApplied && {!_rolloverSuppressed}) then {
    private _terrainLimitedControlledSlipCorrection = (
        _controlledSlipCorrection * _turningTractionMultiplier
    );
    _velocity set [0, (_velocity # 0) - _terrainLimitedControlledSlipCorrection];
    _stabilityDecision set ["controlledSlipDelta", -_terrainLimitedControlledSlipCorrection];
    _controlledSlipCorrection = _terrainLimitedControlledSlipCorrection;
} else {
    if (_rolloverSuppressed) then {
        _controlledSlipApplied = false;
        _controlledSlipCorrection = 0;
    };
};

_stabilityDecision set [
    "controlledSlipEnabled",
    ["FIXICS_controlledSlipEnabled", true] call _getProfileSetting
];
_stabilityDecision set [
    "controlledSlipEligible",
    _controlledSlipDecision getOrDefault ["controlledSlipEligible", false]
];
_stabilityDecision set ["controlledSlipApplied", _controlledSlipApplied];
_stabilityDecision set [
    "controlledSlipReason",
    _controlledSlipDecision getOrDefault ["controlledSlipReason", "not-evaluated"]
];
_stabilityDecision set [
    "controlledSlipSteeringDemand",
    _controlledSlipDecision getOrDefault ["controlledSlipSteeringDemand", 0]
];
_stabilityDecision set [
    "controlledSlipLateralDemand",
    _controlledSlipDecision getOrDefault ["controlledSlipLateralDemand", 0]
];
_stabilityDecision set [
    "controlledSlipRollRisk",
    _controlledSlipDecision getOrDefault ["controlledSlipRollRisk", 0]
];
_stabilityDecision set [
    "controlledSlipTerrainClass",
    _controlledSlipDecision getOrDefault ["controlledSlipTerrainClass", "unknown"]
];
_stabilityDecision set [
    "controlledSlipTerrainMultiplier",
    _controlledSlipDecision getOrDefault ["controlledSlipTerrainMultiplier", 1]
];
_stabilityDecision set [
    "controlledSlipGripReleaseFactor",
    _controlledSlipDecision getOrDefault ["controlledSlipGripReleaseFactor", 0]
];
_stabilityDecision set ["controlledSlipCorrection", _controlledSlipCorrection];

if (missionNamespace getVariable ["FIXICS_controlledSlipDebugLogging", false]) then {
    diag_log format [
        "[FIXICS][ControlledSlip] class=%1 speedKmh=%2 steering=%3 lateralDemand=%4 rollRisk=%5 terrain=%6 terrainMultiplier=%7 gripRelease=%8 correction=%9 applied=%10 reason=%11",
        typeOf _vehicle,
        _speedKmh,
        _controlledSlipDecision getOrDefault ["controlledSlipSteeringDemand", 0],
        _controlledSlipDecision getOrDefault ["controlledSlipLateralDemand", 0],
        _controlledSlipDecision getOrDefault ["controlledSlipRollRisk", 0],
        _controlledSlipDecision getOrDefault ["controlledSlipTerrainClass", "unknown"],
        _controlledSlipDecision getOrDefault ["controlledSlipTerrainMultiplier", 1],
        _controlledSlipDecision getOrDefault ["controlledSlipGripReleaseFactor", 0],
        _controlledSlipCorrection,
        _controlledSlipApplied,
        _controlledSlipDecision getOrDefault ["controlledSlipReason", "not-evaluated"]
    ];
};

if (!_lateralApplied && {!_rollApplied} && {!_controlledSlipApplied}) exitWith {
    _vehicle setVariable ["FIXICS_stabilityLastDecision", _stabilityDecision, false];
    false
};

_vehicle setVelocityModelSpace _velocity;
_stabilityDecision set ["applied", _lateralApplied || {_rollApplied} || {_controlledSlipApplied}];
_vehicle setVariable ["FIXICS_stabilityLastDecision", _stabilityDecision, false];

private _actualVelocity = velocityModelSpace _vehicle;
private _actualLateral = _actualVelocity # 0;
private _actualLongitudinal = _actualVelocity # 1;
private _actualVertical = _actualVelocity # 2;
private _slipRatio = (abs _lateral) / ((abs _longitudinal) max 1);
if (missionNamespace getVariable ["FIXICS_stabilityDebugLogging", false]) then {
    private _presetIndex = missionNamespace getVariable [
        "FIXICS_stabilityPreset",
        0
    ];
    private _preset = ["REALISTIC_STABLE", "RALLY", "CUSTOM"] param [
        _presetIndex,
        "REALISTIC_STABLE"
    ];

    diag_log format [
        "[FIXICS][Stability] class=%1 preset=%2 mode=%3 speedKmh=%4 slip=%5 yawRate=%6 lateralBefore=%7 lateralAfter=%8 longitudinalBefore=%9 longitudinalAfter=%10 verticalBefore=%11 verticalAfter=%12 recommendedLongitudinal=%13 unusedYawRecommendation=%14 rollApplied=%15 bank=%16 bankRate=%17 rollCorrection=%18 rollSeverity=%19 rollReason=%20 rollPreset=%21 rollEnabled=%22 swayBarEnabled=%23 frontSwayBarEnabled=%24 frontSwayBarStrength=%25 rearSwayBarEnabled=%26 rearSwayBarStrength=%27 swayBarStrengthMultiplier=%28 rollEligible=%29 rollEvaluated=%30 rollActivationBank=%31 rollActivationRate=%32 controlledSlipEnabled=%33 controlledSlipEligible=%34 controlledSlipApplied=%35 controlledSlipReason=%36 controlledSlipSteeringDemand=%37 controlledSlipLateralDemand=%38 controlledSlipRollRisk=%39 controlledSlipTerrainClass=%40 controlledSlipTerrainMultiplier=%41 controlledSlipGripReleaseFactor=%42 controlledSlipCorrection=%43 terrainGripClass=%44 tractionMultiplier=%45 accelerationTractionMultiplier=%46 brakingTractionMultiplier=%47 turningTractionMultiplier=%48 slopeTractionMultiplier=%49 wheelspinEstimate=%50 tireDragPenalty=%51 tireSteeringPenalty=%52 massModifier=%53 controlledSlipTelemetryVersion=1 rollTelemetryVersion=3",
        typeOf _vehicle,
        _preset,
        _recommendedMode,
        (abs _longitudinal) * 3.6,
        _slipRatio,
        _diagnosticYawRate,
        _lateral,
        _actualLateral,
        _longitudinal,
        _actualLongitudinal,
        _vertical,
        _actualVertical,
        _recommendedLongitudinal,
        _yawRecommendation,
        _rollApplied,
        _bank,
        _bankRate,
        _rollCorrection,
        _rollSeverity,
        _rollReason,
        _rollPreset,
        _rollEnabled,
        _swayBarEnabled,
        _frontSwayBarEnabled,
        _frontSwayBarStrength,
        _rearSwayBarEnabled,
        _rearSwayBarStrength,
        _swayBarStrengthMultiplier,
        _rollEligible,
        _rollEvaluated,
        _rollActivationBankDeg,
        _rollActivationRateDeg,
        _stabilityDecision getOrDefault ["controlledSlipEnabled", false],
        _stabilityDecision getOrDefault ["controlledSlipEligible", false],
        _stabilityDecision getOrDefault ["controlledSlipApplied", false],
        _stabilityDecision getOrDefault ["controlledSlipReason", "not-evaluated"],
        _stabilityDecision getOrDefault ["controlledSlipSteeringDemand", 0],
        _stabilityDecision getOrDefault ["controlledSlipLateralDemand", 0],
        _stabilityDecision getOrDefault ["controlledSlipRollRisk", 0],
        _stabilityDecision getOrDefault ["controlledSlipTerrainClass", "unknown"],
        _stabilityDecision getOrDefault ["controlledSlipTerrainMultiplier", 1],
        _stabilityDecision getOrDefault ["controlledSlipGripReleaseFactor", 0],
        _stabilityDecision getOrDefault ["controlledSlipCorrection", 0],
        _stabilityDecision getOrDefault ["terrainGripClass", "UNKNOWN"],
        _stabilityDecision getOrDefault ["tractionMultiplier", 1],
        _stabilityDecision getOrDefault ["accelerationTractionMultiplier", 1],
        _stabilityDecision getOrDefault ["brakingTractionMultiplier", 1],
        _stabilityDecision getOrDefault ["turningTractionMultiplier", 1],
        _stabilityDecision getOrDefault ["slopeTractionMultiplier", 1],
        _stabilityDecision getOrDefault ["wheelspinEstimate", 0],
        _stabilityDecision getOrDefault ["tireDragPenalty", 0],
        _stabilityDecision getOrDefault ["tireSteeringPenalty", 0],
        _stabilityDecision getOrDefault ["massModifier", 1]
    ];
};

true
