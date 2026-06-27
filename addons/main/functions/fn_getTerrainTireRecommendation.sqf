/*
 * FIXICS_fnc_getTerrainTireRecommendation
 *
 * Calculates terrain, traction, tire-pressure, drag, steering, mass, and wheelspin recommendations.
 *
 * Arguments:
 *   0: State hashmap <HASHMAP>
 *   1: Settings hashmap <HASHMAP>
 *
 * Return: Recommendation hashmap <HASHMAP>
 * Locality: Pure calculation. Does not mutate vehicle state.
 */

params [
    ["_state", createHashMap, [createHashMap]],
    ["_settings", createHashMap, [createHashMap]]
];

private _getNumber = {
    params ["_map", "_key", "_default"];

    private _value = _map getOrDefault [_key, _default];
    if (_value isEqualType 0) exitWith {_value};

    _default
};

private _enabledValue = _settings getOrDefault ["enabled", true];
private _enabled = [true, _enabledValue] select (_enabledValue isEqualType true);
private _rawSurfaceType = _state getOrDefault ["surfaceType", ""];
private _surfaceType = if (_rawSurfaceType isEqualType "") then {toLowerANSI _rawSurfaceType} else {""};
private _previousAir = (([_state, "tireAirState", 1] call _getNumber) max 0) min 1;
private _neutralPhase2 = [
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
    ["weatherReason", "DISABLED"]
];

if (!_enabled) exitWith {
    createHashMapFromArray ([
        ["enabled", false],
        ["eligible", false],
        ["reason", "DISABLED"],
        ["surfaceType", _surfaceType],
        ["terrainGripClass", "UNKNOWN"],
        ["tractionMultiplier", 1],
        ["accelerationTractionMultiplier", 1],
        ["brakingTractionMultiplier", 1],
        ["turningTractionMultiplier", 1],
        ["slopeTractionMultiplier", 1],
        ["wheelspinEstimate", 0],
        ["tireAirState", _previousAir],
        ["tireDeflationState", "NONE"],
        ["tireDragPenalty", 0],
        ["tireSteeringPenalty", 0],
        ["massModifier", 1],
        ["terrainTireTelemetryVersion", 2],
        ["perWheelMode", "FALLBACK"]
    ] + _neutralPhase2)
};

private _speedKmh = abs ([_state, "speedKmh", 0] call _getNumber);
private _forwardDemand = abs ([_state, "forwardDemand", 0] call _getNumber);
private _brakeDemand = abs ([_state, "brakeDemand", 0] call _getNumber);
private _steeringDemand = abs ([_state, "steeringDemand", 0] call _getNumber);
private _slopeSeverity = abs ([_state, "slopeSeverity", 0] call _getNumber);
private _massKg = [_state, "massKg", 1500] call _getNumber;
private _deltaTime = (([_state, "deltaTime", 0.016] call _getNumber) max 0.001) min 0.25;
private _tireDamage = (([_state, "tireDamage", 0] call _getNumber) max 0) min 1;
private _tirePressureEnabled = _settings getOrDefault ["tirePressureEnabled", true];
private _deflationRate = (([_settings, "deflationRate", 0.025] call _getNumber) max 0) min 1;
private _minimumMobility = (([_settings, "minimumMobility", 0.35] call _getNumber) max 0.05) min 1;
private _dragStrength = (([_settings, "dragStrength", 0.35] call _getNumber) max 0) min 1;
private _steeringPenaltySetting = (([_settings, "steeringPenalty", 0.30] call _getNumber) max 0) min 1;
private _rolloverSafetyEnabled = _settings getOrDefault ["rolloverSafetyEnabled", true];
private _airborneGraceWindow = (([_settings, "airborneGraceWindow", 0.50] call _getNumber) max 0) min 1;
private _driverlessDecayEnabled = _settings getOrDefault ["driverlessDecayEnabled", true];
private _driverlessDecayCap = (([_settings, "driverlessDecayCap", 0.15] call _getNumber) max 0) min 1;
private _destroyedTireThreshold = (([_settings, "destroyedTireThreshold", 0.85] call _getNumber) max 0.5) min 1;
private _weatherTerrainEnabled = _settings getOrDefault ["weatherTerrainEnabled", true];
private _weatherSaturationTime = (([_settings, "weatherSaturationTime", 30] call _getNumber) max 5) min 120;
private _weatherDryingTime = (([_settings, "weatherDryingTime", 180] call _getNumber) max 30) min 600;
private _hydroplaningEnabled = _settings getOrDefault ["hydroplaningEnabled", true];
private _hydroplaningSpeedKmh = (([_settings, "hydroplaningSpeedKmh", 70] call _getNumber) max 40) min 140;
private _windHandlingEnabled = _settings getOrDefault ["windHandlingEnabled", true];
private _windHandlingStrength = (([_settings, "windHandlingStrength", 0.05] call _getNumber) max 0) min 0.25;
private _groundedValue = _state getOrDefault ["isTouchingGround", true];
private _isGrounded = [true, _groundedValue] select (_groundedValue isEqualType true);
private _driverValue = _state getOrDefault ["driverPresent", true];
private _driverPresent = [true, _driverValue] select (_driverValue isEqualType true);
private _lastGroundedAge = (([_state, "lastGroundedAge", 999] call _getNumber) max 0) min 999;
private _vectorUp = _state getOrDefault ["vectorUp", [0, 0, 1]];
private _pitch = [_state, "pitch", 0] call _getNumber;
private _bank = [_state, "bank", 0] call _getNumber;
private _wheelDamageValues = _state getOrDefault ["wheelDamageValues", []];
private _vehicle = _state getOrDefault ["vehicle", objNull];
private _rainLevel = (([_state, "rainLevel", 0] call _getNumber) max 0) min 1;
private _overcastLevel = (([_state, "overcastLevel", 0] call _getNumber) max 0) min 1;
private _previousSaturation = (([_state, "weatherSaturation", 0] call _getNumber) max 0) min 1;
private _weatherDeltaTime = (([_state, "weatherDeltaTime", _deltaTime] call _getNumber) max 0) min 10;
private _windStrength = (([_state, "windStrength", 0] call _getNumber) max 0) min 1;
private _windVector = _state getOrDefault ["windVector", [0, 0, 0]];
private _vehicleRightVector = _state getOrDefault ["vehicleRightVector", [1, 0, 0]];

private _upZ = 1;
if (_vectorUp isEqualType [] && {(count _vectorUp) >= 3}) then {
    _upZ = ((_vectorUp # 2) max -1) min 1;
};

private _wheelSupportState = "SUPPORTED";
if (!_isGrounded) then {
    _wheelSupportState = ["AIRBORNE", "AIRBORNE_GRACE"] select (_lastGroundedAge <= _airborneGraceWindow);
};
if (_isGrounded && {_upZ < -0.25}) then {
    _wheelSupportState = "FLIPPED";
};
if (_isGrounded && {_upZ >= -0.25} && {_upZ < 0.35}) then {
    _wheelSupportState = "SIDE_UNSUPPORTED";
};
private _rolloverSuppressed = _rolloverSafetyEnabled && {
    _wheelSupportState in ["AIRBORNE", "FLIPPED", "SIDE_UNSUPPORTED"]
};
private _driverlessDecay = [0, _driverlessDecayCap] select (!_driverPresent && {_driverlessDecayEnabled});

private _candidateWheelDamage = [];
if (_wheelDamageValues isEqualType []) then {
    {
        if (_x isEqualType 0 && {_x >= 0}) then {
            _candidateWheelDamage pushBack (_x max 0 min 1);
        };
        if (_x isEqualType [] && {(count _x) >= 2}) then {
            private _damageValue = _x # 1;
            if (_damageValue isEqualType 0 && {_damageValue >= 0}) then {
                _candidateWheelDamage pushBack (_damageValue max 0 min 1);
            };
        };
    } forEach _wheelDamageValues;
};
if (!isNull _vehicle) then {
    {
        private _hitDamage = _vehicle getHitPointDamage _x;
        if (_hitDamage isEqualType 0 && {_hitDamage >= 0}) then {
            _candidateWheelDamage pushBack (_hitDamage max 0 min 1);
        };
        if (_hitDamage isEqualTo -1) then {
            false
        };
    } forEach [
        "HitLFWheel",
        "HitRFWheel",
        "HitLF2Wheel",
        "HitRF2Wheel",
        "HitLMWheel",
        "HitRMWheel",
        "HitLBWheel",
        "HitRBWheel"
    ];
};
private _destroyedTireCount = {_x >= _destroyedTireThreshold} count _candidateWheelDamage;
private _wheelCount = count _candidateWheelDamage;
private _perWheelMode = ["FALLBACK", "PER_WHEEL"] select (_wheelCount > 0);
if (_wheelCount == 0 && {_tireDamage >= _destroyedTireThreshold}) then {
    _destroyedTireCount = 1;
    _wheelCount = 4;
};
private _destroyedTireRatio = if (_wheelCount > 0) then {
    (_destroyedTireCount / _wheelCount) max 0 min 1
} else {
    0
};

private _terrainGripClass = "UNKNOWN";
if (
    (_surfaceType find "concrete" >= 0)
    || {_surfaceType find "asphalt" >= 0}
    || {_surfaceType find "road" >= 0}
    || {_surfaceType find "tarmac" >= 0}
) then {
    _terrainGripClass = "PAVED";
} else {
    if (
        (_surfaceType find "dirt" >= 0)
        || {_surfaceType find "gravel" >= 0}
        || {_surfaceType find "soil" >= 0}
    ) then {
        _terrainGripClass = "DIRT";
    } else {
        if (
            (_surfaceType find "grass" >= 0)
            || {_surfaceType find "forest" >= 0}
        ) then {
            _terrainGripClass = "GRASS";
        } else {
            if (
                (_surfaceType find "sand" >= 0)
                || {_surfaceType find "beach" >= 0}
            ) then {
                _terrainGripClass = "SAND";
            } else {
                if (
                    (_surfaceType find "rock" >= 0)
                    || {_surfaceType find "stone" >= 0}
                ) then {
                    _terrainGripClass = "ROCK";
                };
            };
        };
    };
};

private _terrainBase = switch (_terrainGripClass) do {
    case "PAVED": {1.00};
    case "DIRT": {0.78};
    case "GRASS": {0.66};
    case "SAND": {0.52};
    case "ROCK": {0.70};
    default {0.84};
};

private _wheelspinBase = switch (_terrainGripClass) do {
    case "PAVED": {0.08};
    case "DIRT": {0.28};
    case "GRASS": {0.38};
    case "SAND": {0.55};
    case "ROCK": {0.34};
    default {0.18};
};

private _roughness = switch (_terrainGripClass) do {
    case "ROCK": {0.22};
    case "SAND": {0.12};
    case "GRASS": {0.10};
    case "DIRT": {0.08};
    default {0.02};
};

private _terrainSaturation = _previousSaturation;
private _weatherReason = "clear";
if (_weatherTerrainEnabled) then {
    if (_rainLevel > 0) then {
        private _saturationStep = (_weatherDeltaTime / _weatherSaturationTime) max 0 min 1;
        _terrainSaturation = _terrainSaturation + ((_rainLevel - _terrainSaturation) * _saturationStep);
        _weatherReason = "rain-saturating";
    } else {
        private _dryingStep = (_weatherDeltaTime / _weatherDryingTime) max 0 min 1;
        _terrainSaturation = _terrainSaturation + ((0 - _terrainSaturation) * _dryingStep);
        _weatherReason = "drying";
    };
} else {
    _weatherReason = "weather-disabled";
};
_terrainSaturation = _terrainSaturation max 0 min 1;
private _surfaceWetness = (_rainLevel max _terrainSaturation) max 0 min 1;
private _weatherGripMultiplier = 1;
if (_weatherTerrainEnabled) then {
    _weatherGripMultiplier = switch (_terrainGripClass) do {
        case "PAVED": {1 - (_surfaceWetness * 0.45)};
        case "DIRT": {1 - (_surfaceWetness * 0.50)};
        case "GRASS": {1 - (_surfaceWetness * 0.58)};
        case "SAND": {1 + (_surfaceWetness * 0.18)};
        case "ROCK": {1 - (_surfaceWetness * 0.35)};
        default {1 - (_surfaceWetness * 0.30)};
    };
    if (_rainLevel > 0.75 && {_overcastLevel > 0.75}) then {
        _weatherGripMultiplier = _weatherGripMultiplier * 0.88;
        _weatherReason = "storm";
    };
};
_weatherGripMultiplier = _weatherGripMultiplier max 0.15 min 1.10;

private _hydroplaningRisk = 0;
if (
    _weatherTerrainEnabled
    && {_hydroplaningEnabled}
    && {_terrainGripClass == "PAVED"}
    && {_surfaceWetness > 0.25}
    && {_speedKmh > _hydroplaningSpeedKmh}
) then {
    _hydroplaningRisk = (
        linearConversion [
            _hydroplaningSpeedKmh,
            _hydroplaningSpeedKmh + 50,
            _speedKmh,
            0,
            1,
            true
        ] * _surfaceWetness
    ) max 0 min 1;
    _weatherGripMultiplier = (_weatherGripMultiplier * (1 - (_hydroplaningRisk * 0.45))) max 0.05;
    _weatherReason = "hydroplaning-risk";
};

private _windCrossComponent = 0;
if (
    _windVector isEqualType []
    && {_vehicleRightVector isEqualType []}
    && {(count _windVector) >= 2}
    && {(count _vehicleRightVector) >= 2}
) then {
    _windCrossComponent = (
        ((_windVector # 0) * (_vehicleRightVector # 0))
        + ((_windVector # 1) * (_vehicleRightVector # 1))
    ) max -1 min 1;
};
private _windProfileScale = linearConversion [900, 6500, _massKg, 0.7, 1.25, true];
private _windHandlingMultiplier = 0;
if (_weatherTerrainEnabled && {_windHandlingEnabled}) then {
    _windHandlingMultiplier = (
        abs _windCrossComponent
        * _windStrength
        * _windHandlingStrength
        * _windProfileScale
    ) max 0 min 0.25;
};

private _massModifier = linearConversion [900, 4500, _massKg, 1.08, 0.72, true];
private _speedDemand = linearConversion [10, 100, _speedKmh, 0, 1, true];
private _accelDemand = (_forwardDemand * (1 - _terrainBase)) max 0 min 1;
private _turnDemand = (_steeringDemand * _speedDemand * (1 - (_terrainBase * 0.65))) max 0 min 1;
private _brakeDemandLoss = (_brakeDemand * _speedDemand * (1 - (_terrainBase * 0.75))) max 0 min 1;

private _newAir = _previousAir;
private _deflationState = "NONE";
if (_tirePressureEnabled && {_tireDamage > 0.05}) then {
    private _loss = _deflationRate * _deltaTime * (0.35 + _tireDamage);
    _newAir = (_previousAir - _loss) max _minimumMobility;
    _deflationState = ["LEAKING", "RUNFLAT"] select (_newAir <= (_minimumMobility + 0.001));
};

private _terrainClassIndex = switch (_terrainGripClass) do {
    case "PAVED": {0};
    case "DIRT": {1};
    case "GRASS": {2};
    case "SAND": {3};
    case "ROCK": {4};
    default {5};
};
private _nativeTerrainTire = [
    [
        _terrainClassIndex,
        _speedKmh,
        _forwardDemand,
        _brakeDemand,
        _steeringDemand,
        _slopeSeverity,
        _massKg,
        _deltaTime,
        _newAir,
        _tireDamage,
        parseNumber _isGrounded,
        _lastGroundedAge,
        _upZ,
        _airborneGraceWindow,
        parseNumber (!_driverPresent && {_driverlessDecayEnabled}),
        _driverlessDecayCap,
        _destroyedTireThreshold,
        _destroyedTireCount
    ]
] call FIXICS_fnc_getNativeTerrainTire;
if (_nativeTerrainTire isEqualType [] && {count _nativeTerrainTire == 19} && {_nativeTerrainTire # 0}) exitWith {
    createHashMapFromArray [
        ["enabled", _enabled],
        ["eligible", _enabled],
        ["reason", "native-terrain-tire"],
        ["surfaceType", _surfaceType],
        ["terrainGripClass", _terrainGripClass],
        ["tractionMultiplier", ((_nativeTerrainTire # 1) * _weatherGripMultiplier) max 0.05 min 1.10],
        ["accelerationTractionMultiplier", ((_nativeTerrainTire # 2) * _weatherGripMultiplier) max 0.03 min 1.10],
        ["brakingTractionMultiplier", ((_nativeTerrainTire # 3) * _weatherGripMultiplier) max 0.03 min 1.05],
        ["turningTractionMultiplier", ((_nativeTerrainTire # 4) * _weatherGripMultiplier * (1 - _windHandlingMultiplier)) max 0.03 min 1.05],
        ["slopeTractionMultiplier", ((_nativeTerrainTire # 5) * _weatherGripMultiplier) max 0.03 min 1.05],
        ["wheelspinEstimate", ((_nativeTerrainTire # 6) + (_surfaceWetness * 0.20) + (_hydroplaningRisk * 0.35)) max 0 min 1],
        ["tireAirState", _nativeTerrainTire # 7],
        ["tireDeflationState", _deflationState],
        ["tireDragPenalty", _nativeTerrainTire # 8],
        ["tireSteeringPenalty", _nativeTerrainTire # 9],
        ["massModifier", _nativeTerrainTire # 10],
        ["terrainTireTelemetryVersion", 2],
        ["perWheelMode", _perWheelMode],
        ["wheelSupportState", _nativeTerrainTire # 11],
        ["rolloverSuppressed", _nativeTerrainTire # 12],
        ["driverlessDecay", _nativeTerrainTire # 13],
        ["destroyedTireCount", _nativeTerrainTire # 14],
        ["destroyedTireRatio", _nativeTerrainTire # 15],
        ["destroyedTirePenalty", _nativeTerrainTire # 16],
        ["mobilityLimiter", _nativeTerrainTire # 17],
        ["nativeTelemetry", _nativeTerrainTire # 18],
        ["weatherTerrainEnabled", _weatherTerrainEnabled],
        ["rainLevel", _rainLevel],
        ["overcastLevel", _overcastLevel],
        ["surfaceWetness", _surfaceWetness],
        ["terrainSaturation", _terrainSaturation],
        ["weatherGripMultiplier", _weatherGripMultiplier],
        ["hydroplaningRisk", _hydroplaningRisk],
        ["windStrength", _windStrength],
        ["windCrossComponent", _windCrossComponent],
        ["windHandlingMultiplier", _windHandlingMultiplier],
        ["weatherReason", _weatherReason],
        ["pitch", _pitch],
        ["bank", _bank]
    ]
};

private _airLoss = 1 - _newAir;
private _tireDragPenalty = (_airLoss * _dragStrength) max 0 min 0.75;
private _tireSteeringPenalty = (_airLoss * _steeringPenaltySetting) max 0 min 0.65;
private _cleanGripLoss = (_airLoss * 0.35) max 0 min 0.35;

private _tractionMultiplier = (_terrainBase - _cleanGripLoss - (_roughness * _speedDemand * 0.25)) max 0.20 min 1.10;
private _accelerationTractionMultiplier = (_tractionMultiplier * (1 - (_accelDemand * 0.35)) * _massModifier) max 0.15 min 1.10;
private _brakingTractionMultiplier = (_tractionMultiplier * (1 - (_brakeDemandLoss * 0.28))) max 0.20 min 1.05;
private _turningTractionMultiplier = (_tractionMultiplier * (1 - (_turnDemand * 0.34)) * (1 - _tireSteeringPenalty)) max 0.15 min 1.05;
private _slopeTractionMultiplier = (_tractionMultiplier * (1 - (_slopeSeverity * (1 - _terrainBase) * 0.25))) max 0.20 min 1.05;
private _wheelspinEstimate = (_wheelspinBase + _accelDemand + (_airLoss * 0.25) + (_roughness * _speedDemand)) max 0 min 1;
_tractionMultiplier = (_tractionMultiplier * _weatherGripMultiplier) max 0.05 min 1.10;
_accelerationTractionMultiplier = (_accelerationTractionMultiplier * _weatherGripMultiplier) max 0.03 min 1.10;
_brakingTractionMultiplier = (_brakingTractionMultiplier * _weatherGripMultiplier) max 0.03 min 1.05;
_turningTractionMultiplier = (_turningTractionMultiplier * _weatherGripMultiplier * (1 - _windHandlingMultiplier)) max 0.03 min 1.05;
_slopeTractionMultiplier = (_slopeTractionMultiplier * _weatherGripMultiplier) max 0.03 min 1.05;
_wheelspinEstimate = (_wheelspinEstimate + (_surfaceWetness * 0.20) + (_hydroplaningRisk * 0.35)) max 0 min 1;
private _looseTerrainAmplifier = switch (_terrainGripClass) do {
    case "SAND": {1.35};
    case "GRASS": {1.25};
    case "DIRT": {1.15};
    case "ROCK": {1.20};
    default {1};
};
private _destroyedTirePenalty = (_destroyedTireRatio * 0.85 * _looseTerrainAmplifier) max 0 min 0.90;
private _mobilityLimiter = 1;
if (_rolloverSuppressed) then {
    _mobilityLimiter = 0;
} else {
    _mobilityLimiter = (1 - _destroyedTirePenalty) max 0.08 min 1;
};
_accelerationTractionMultiplier = (_accelerationTractionMultiplier * _mobilityLimiter) max 0.05 min 1.10;
_brakingTractionMultiplier = (_brakingTractionMultiplier * (1 - (_destroyedTirePenalty * 0.35))) max 0.05 min 1.05;
_turningTractionMultiplier = (_turningTractionMultiplier * (1 - (_destroyedTirePenalty * 0.75))) max 0.03 min 1.05;
_slopeTractionMultiplier = (_slopeTractionMultiplier * _mobilityLimiter) max 0.05 min 1.05;
_tireDragPenalty = (_tireDragPenalty + (_destroyedTirePenalty * 0.45)) max 0 min 0.95;
_tireSteeringPenalty = (_tireSteeringPenalty + (_destroyedTirePenalty * 0.65)) max 0 min 0.95;
if (_rolloverSuppressed) then {
    _accelerationTractionMultiplier = 0;
    _slopeTractionMultiplier = 0;
    _wheelspinEstimate = 0;
};

createHashMapFromArray [
    ["enabled", _enabled],
    ["eligible", _enabled],
    ["reason", ["DISABLED", "ACTIVE"] select _enabled],
    ["surfaceType", _surfaceType],
    ["terrainGripClass", _terrainGripClass],
    ["tractionMultiplier", _tractionMultiplier],
    ["accelerationTractionMultiplier", _accelerationTractionMultiplier],
    ["brakingTractionMultiplier", _brakingTractionMultiplier],
    ["turningTractionMultiplier", _turningTractionMultiplier],
    ["slopeTractionMultiplier", _slopeTractionMultiplier],
    ["wheelspinEstimate", _wheelspinEstimate],
    ["tireAirState", _newAir],
    ["tireDeflationState", _deflationState],
    ["tireDragPenalty", _tireDragPenalty],
    ["tireSteeringPenalty", _tireSteeringPenalty],
    ["massModifier", _massModifier],
    ["terrainTireTelemetryVersion", 2],
    ["perWheelMode", _perWheelMode],
    ["wheelSupportState", _wheelSupportState],
    ["rolloverSuppressed", _rolloverSuppressed],
    ["driverlessDecay", _driverlessDecay],
    ["destroyedTireCount", _destroyedTireCount],
    ["destroyedTireRatio", _destroyedTireRatio],
    ["destroyedTirePenalty", _destroyedTirePenalty],
    ["mobilityLimiter", _mobilityLimiter],
    ["weatherTerrainEnabled", _weatherTerrainEnabled],
    ["rainLevel", _rainLevel],
    ["overcastLevel", _overcastLevel],
    ["surfaceWetness", _surfaceWetness],
    ["terrainSaturation", _terrainSaturation],
    ["weatherGripMultiplier", _weatherGripMultiplier],
    ["hydroplaningRisk", _hydroplaningRisk],
    ["windStrength", _windStrength],
    ["windCrossComponent", _windCrossComponent],
    ["windHandlingMultiplier", _windHandlingMultiplier],
    ["weatherReason", _weatherReason],
    ["pitch", _pitch],
    ["bank", _bank]
]
