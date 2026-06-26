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

if (!_enabled) exitWith {
    createHashMapFromArray [
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
        ["terrainTireTelemetryVersion", 1],
        ["perWheelMode", "FALLBACK"]
    ]
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
    ["terrainTireTelemetryVersion", 1],
    ["perWheelMode", "FALLBACK"]
]
