/*
 * FIXICS_fnc_getControlledSlipRecommendation
 *
 * Calculates a bounded controlled lateral slip release recommendation.
 *
 * Arguments:
 *   0: State hashmap <HASHMAP>
 *   1: Settings hashmap <HASHMAP>
 *
 * Return: <HASHMAP> telemetry and recommendation values
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

private _result = createHashMapFromArray [
    ["controlledSlipEligible", false],
    ["controlledSlipApplied", false],
    ["controlledSlipReason", "invalid"],
    ["controlledSlipSteeringDemand", 0],
    ["controlledSlipLateralDemand", 0],
    ["controlledSlipRollRisk", 0],
    ["controlledSlipTerrainClass", "unknown"],
    ["controlledSlipTerrainMultiplier", 1],
    ["controlledSlipGripReleaseFactor", 0],
    ["controlledSlipCorrection", 0]
];

private _enabled = _settings getOrDefault ["enabled", true];
if (!_enabled) exitWith {
    _result set ["controlledSlipReason", "disabled"];
    _result
};

private _speedKmh = [_state, "speedKmh", 0] call _safeNumber;
private _steeringDemand = abs ([_state, "steeringDemand", 0] call _safeNumber);
private _lateralSpeed = [_state, "lateralSpeed", 0] call _safeNumber;
private _longitudinalSpeed = abs ([_state, "longitudinalSpeed", 0] call _safeNumber);
private _bank = abs ([_state, "bank", 0] call _safeNumber);
private _bankRate = abs ([_state, "bankRate", 0] call _safeNumber);
private _activationSpeedKmh = (
    [_settings, "activationSpeedKmh", 55] call _safeNumber
) max 0 min 180;
private _steeringThreshold = (
    [_settings, "steeringThreshold", 0.65] call _safeNumber
) max 0 min 1;
private _strength = (
    [_settings, "strength", 0.16] call _safeNumber
) max 0 min 0.5;
private _maximumRelease = (
    [_settings, "maximumRelease", 0.22] call _safeNumber
) max 0 min 0.6;
private _terrainInfluence = _settings getOrDefault ["terrainInfluence", true];
private _terrainClass = _state getOrDefault ["terrainClass", "unknown"];

private _lateralDemand = (abs _lateralSpeed) / (_longitudinalSpeed max 1);
_lateralDemand = _lateralDemand max 0 min 1;
private _rollRisk = ((_bank / 45) max (_bankRate / 180)) max 0 min 1;
private _terrainMultiplier = switch (_terrainClass) do {
    case "paved": {0.75};
    case "dirt": {1};
    case "grass": {1.15};
    default {0.9};
};
if (!_terrainInfluence) then {
    _terrainMultiplier = 1;
};

_result set ["controlledSlipSteeringDemand", _steeringDemand max 0 min 1];
_result set ["controlledSlipLateralDemand", _lateralDemand];
_result set ["controlledSlipRollRisk", _rollRisk];
_result set ["controlledSlipTerrainClass", _terrainClass];
_result set ["controlledSlipTerrainMultiplier", _terrainMultiplier];

if (_speedKmh < _activationSpeedKmh) exitWith {
    _result set ["controlledSlipReason", "below-speed-threshold"];
    _result
};
if (_steeringDemand < _steeringThreshold) exitWith {
    _result set ["controlledSlipReason", "below-steering-threshold"];
    _result
};

private _releaseDemand = (
    (_steeringDemand - _steeringThreshold)
    / ((1 - _steeringThreshold) max 0.001)
) max 0 min 1;
private _gripReleaseFactor = (
    _releaseDemand
    * (0.35 + (_rollRisk * 0.65))
    * _terrainMultiplier
) max 0 min 1;
private _correction = (
    _lateralSpeed * _strength * _gripReleaseFactor
) max -_maximumRelease min _maximumRelease;

_result set ["controlledSlipEligible", true];
_result set ["controlledSlipGripReleaseFactor", _gripReleaseFactor];
_result set ["controlledSlipCorrection", _correction];
_result set ["controlledSlipApplied", (abs _correction) > 0.0001];
_result set [
    "controlledSlipReason",
    ["eligible-no-correction", "controlled-slip"] select ((abs _correction) > 0.0001)
];

_result
