/*
 * FIXICS_fnc_getRuntimeAssistRecommendation
 *
 * Pure coordinator math for composing assist recommendations.
 *
 * Arguments:
 *   0: State hashmap <HASHMAP>
 *   1: Settings hashmap <HASHMAP>
 *
 * Return:
 *   HashMap with applied, priorityWinner, terrainMultiplier, massMultiplier,
 *   slopeRetention, suppressedAssists, finalCorrection.
 */
params [
    ["_state", createHashMap, [createHashMap]],
    ["_settings", createHashMap, [createHashMap]]
];

private _safeNumber = {
    params ["_map", "_key", "_default"];

    private _value = _map getOrDefault [_key, _default];
    if !(_value isEqualType 0) exitWith {
        _default
    };
    if (!finite _value) exitWith {
        _default
    };

    _value
};

private _invalid = createHashMapFromArray [
    ["applied", false],
    ["priorityWinner", "invalid"],
    ["terrainMultiplier", 1],
    ["massMultiplier", 1],
    ["slopeRetention", 1],
    ["suppressedAssists", ["invalid"]],
    ["finalCorrection", 0],
    ["terrainTireRecommendation", createHashMap],
    ["terrainGripClass", "UNKNOWN"],
    ["tractionMultiplier", 1],
    ["accelerationTractionMultiplier", 1],
    ["brakingTractionMultiplier", 1],
    ["turningTractionMultiplier", 1],
    ["slopeTractionMultiplier", 1],
    ["wheelspinEstimate", 0],
    ["tireDragPenalty", 0],
    ["tireSteeringPenalty", 0],
    ["massModifier", 1]
];

private _speedKmh = [_state, "speedKmh", 0] call _safeNumber;
private _terrainFriction = [_state, "terrainFriction", 1] call _safeNumber;
private _massKg = [_state, "massKg", 1200] call _safeNumber;
private _slopeDelta = [_state, "slopeDelta", 0] call _safeNumber;
private _stabilityDelta = [_state, "stabilityDelta", 0] call _safeNumber;
private _rollDelta = [_state, "rollDelta", 0] call _safeNumber;

if (
    !finite _speedKmh
    || {!finite _terrainFriction}
    || {!finite _massKg}
    || {!finite _slopeDelta}
    || {!finite _stabilityDelta}
    || {!finite _rollDelta}
) exitWith {
    _invalid
};

private _terrainInfluenceEnabled = _settings getOrDefault ["terrainInfluenceEnabled", true];
private _terrainInfluenceStrength = ([_settings, "terrainInfluenceStrength", 0.25] call _safeNumber) max 0 min 1;
private _brakingSlopeRetention = ([_settings, "brakingSlopeRetention", 0.35] call _safeNumber) max 0 min 1;
private _massDampingStrength = ([_settings, "massDampingStrength", 0.15] call _safeNumber) max 0 min 1;
private _maximumComposedCorrection = ([_settings, "maximumComposedCorrection", 0.25] call _safeNumber) max 0 min 0.5;
private _terrainTireRecommendation = _state getOrDefault ["terrainTireRecommendation", createHashMap];
if !(_terrainTireRecommendation isEqualType createHashMap) then {
    _terrainTireRecommendation = createHashMap;
};
private _terrainGripClass = _terrainTireRecommendation getOrDefault ["terrainGripClass", "UNKNOWN"];
if !(_terrainGripClass isEqualType "") then {
    _terrainGripClass = "UNKNOWN";
};
private _tractionMultiplier = (
    [_terrainTireRecommendation, "tractionMultiplier", 1] call _safeNumber
) max 0.2 min 1;
private _accelerationTractionMultiplier = (
    [_terrainTireRecommendation, "accelerationTractionMultiplier", 1] call _safeNumber
) max 0.15 min 1.1;
private _brakingTractionMultiplier = (
    [_terrainTireRecommendation, "brakingTractionMultiplier", 1] call _safeNumber
) max 0.2 min 1;
private _turningTractionMultiplier = (
    [_terrainTireRecommendation, "turningTractionMultiplier", 1] call _safeNumber
) max 0.15 min 1;
private _slopeTractionMultiplier = (
    [_terrainTireRecommendation, "slopeTractionMultiplier", 1] call _safeNumber
) max 0.2 min 1;
private _wheelspinEstimate = (
    [_terrainTireRecommendation, "wheelspinEstimate", 0] call _safeNumber
) max 0 min 1;
private _tireDragPenalty = (
    [_terrainTireRecommendation, "tireDragPenalty", 0] call _safeNumber
) max 0 min 0.75;
private _tireSteeringPenalty = (
    [_terrainTireRecommendation, "tireSteeringPenalty", 0] call _safeNumber
) max 0 min 0.65;
private _massModifier = (
    [_terrainTireRecommendation, "massModifier", 1] call _safeNumber
) max 0.72 min 1.08;

private _terrainMultiplier = 1;
if (_terrainInfluenceEnabled) then {
    _terrainFriction = _terrainFriction max 0 min 1;
    _terrainMultiplier = 1 - ((1 - _terrainFriction) * _terrainInfluenceStrength);
    _terrainMultiplier = _terrainMultiplier max 0.35 min 1;
};

private _massMultiplier = 1 - (((((_massKg - 1200) / 2800) max 0) min 1) * _massDampingStrength);
_massMultiplier = _massMultiplier max 0.45 min 1;

private _serviceBraking = _state getOrDefault ["serviceBraking", false];
private _suppressedAssists = [];
private _slopeRetention = 1;
if (_serviceBraking) then {
    _slopeRetention = _brakingSlopeRetention;
    _slopeDelta = _slopeDelta * _slopeRetention;
    _suppressedAssists pushBack "slope-reduced-by-service-brake";
};

private _priorityWinner = "none";
private _finalCorrection = 0;
if ((abs _rollDelta) > 0) then {
    _priorityWinner = "roll";
    _finalCorrection = _rollDelta;
} else {
    if ((abs _stabilityDelta) > 0) then {
        _priorityWinner = "stability";
        _finalCorrection = _stabilityDelta;
    } else {
        if ((abs _slopeDelta) > 0) then {
            _priorityWinner = "slope";
            _finalCorrection = _slopeDelta;
        };
    };
};

_finalCorrection = _finalCorrection * _terrainMultiplier * _massMultiplier;
_finalCorrection = _finalCorrection * (switch (_priorityWinner) do {
    case "stability": {_turningTractionMultiplier};
    case "slope": {_slopeTractionMultiplier};
    default {1};
});
_finalCorrection = (_finalCorrection max -_maximumComposedCorrection) min _maximumComposedCorrection;

createHashMapFromArray [
    ["applied", (abs _finalCorrection) > 0],
    ["priorityWinner", _priorityWinner],
    ["terrainMultiplier", _terrainMultiplier],
    ["massMultiplier", _massMultiplier],
    ["slopeRetention", _slopeRetention],
    ["suppressedAssists", _suppressedAssists],
    ["finalCorrection", _finalCorrection],
    ["terrainTireRecommendation", _terrainTireRecommendation],
    ["terrainGripClass", _terrainGripClass],
    ["tractionMultiplier", _tractionMultiplier],
    ["accelerationTractionMultiplier", _accelerationTractionMultiplier],
    ["brakingTractionMultiplier", _brakingTractionMultiplier],
    ["turningTractionMultiplier", _turningTractionMultiplier],
    ["slopeTractionMultiplier", _slopeTractionMultiplier],
    ["wheelspinEstimate", _wheelspinEstimate],
    ["tireDragPenalty", _tireDragPenalty],
    ["tireSteeringPenalty", _tireSteeringPenalty],
    ["massModifier", _massModifier]
]
