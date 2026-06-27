/*
 * FIXICS_fnc_getNativeTerrainTire
 *
 * Requests a native Terrain Tire Phase 2 recommendation without mutating the vehicle.
 *
 * Arguments:
 *   0: Native argument values <ARRAY>
 *
 * Return: <ARRAY> native result or []
 * Locality: local machine
 */

params [
    ["_arguments", [], [[]]]
];

if !(missionNamespace getVariable ["FIXICS_nativeTerrainTireEnabled", false]) exitWith {
    []
};
if ((count _arguments) < 18) exitWith {
    []
};

private _now = diag_tickTime;
private _surfaceBucket = _arguments # 0;
private _speedBucket = round (((_arguments # 1) max 0) / 5);
private _groundBucket = _arguments # 10;
private _supportBucket = floor (((_arguments # 12) + 1) * 10);
private _damageBucket = round (((_arguments # 17) max 0) min 16);
private _cacheKey = format [
    "surfaceBucket=%1|speedBucket=%2|ground=%3|support=%4|damage=%5",
    _surfaceBucket,
    _speedBucket,
    _groundBucket,
    _supportBucket,
    _damageBucket
];
private _cacheTtl = (
    missionNamespace getVariable ["FIXICS_nativeTerrainTireCacheTtl", 0.15]
) max 0.10 min 0.25;
private _cache = missionNamespace getVariable ["FIXICS_nativeTerrainTireCache", createHashMap];
if !(_cache isEqualType createHashMap) then {
    _cache = createHashMap;
};
private _cached = _cache getOrDefault [_cacheKey, []];
if (_cached isEqualType [] && {(count _cached) == 2}) then {
    private _cachedAt = _cached # 0;
    private _cachedResult = _cached # 1;
    if (
        _cachedAt isEqualType 0
        && {_cachedResult isEqualType []}
        && {(_now - _cachedAt) <= _cacheTtl}
    ) exitWith {
        +_cachedResult
    };
};

private _nativeArguments = _arguments apply {str _x};
private _result = "FIXICSPhysics" callExtension [
    "terrainTireV2",
    _nativeArguments
];

_result params [
    ["_payload", "", [""]],
    ["_returnCode", 0, [0]],
    ["_errorCode", 0, [0]]
];

if (_errorCode != 0 || {_returnCode != 0} || {_payload isEqualTo ""}) exitWith {
    []
};

private _parsed = [];
try {
    _parsed = parseSimpleArray _payload;
} catch {
    _parsed = [];
};

if !(_parsed isEqualType [] && {count _parsed == 19}) exitWith {
    []
};

_parsed params [
    ["_applied", false, [false]],
    ["_tractionMultiplier", 1, [0]],
    ["_accelerationTractionMultiplier", 1, [0]],
    ["_brakingTractionMultiplier", 1, [0]],
    ["_turningTractionMultiplier", 1, [0]],
    ["_slopeTractionMultiplier", 1, [0]],
    ["_wheelspinEstimate", 0, [0]],
    ["_tireAirState", 1, [0]],
    ["_tireDragPenalty", 0, [0]],
    ["_tireSteeringPenalty", 0, [0]],
    ["_massModifier", 1, [0]],
    ["_wheelSupportState", "UNKNOWN", [""]],
    ["_rolloverSuppressed", false, [false]],
    ["_driverlessDecay", 0, [0]],
    ["_destroyedTireCount", 0, [0]],
    ["_destroyedTireRatio", 0, [0]],
    ["_destroyedTirePenalty", 0, [0]],
    ["_mobilityLimiter", 1, [0]],
    ["_telemetry", "", [""]]
];

private _finite = {
    params ["_value"];
    finite _value
};

if !(
    [_tractionMultiplier] call _finite
    && {[_accelerationTractionMultiplier] call _finite}
    && {[_brakingTractionMultiplier] call _finite}
    && {[_turningTractionMultiplier] call _finite}
    && {[_slopeTractionMultiplier] call _finite}
    && {[_wheelspinEstimate] call _finite}
    && {[_tireAirState] call _finite}
    && {[_tireDragPenalty] call _finite}
    && {[_tireSteeringPenalty] call _finite}
    && {[_massModifier] call _finite}
    && {[_driverlessDecay] call _finite}
    && {[_destroyedTireCount] call _finite}
    && {[_destroyedTireRatio] call _finite}
    && {[_destroyedTirePenalty] call _finite}
    && {[_mobilityLimiter] call _finite}
) exitWith {
    []
};

if !(_wheelSupportState in ["SUPPORTED", "AIRBORNE_GRACE", "AIRBORNE", "SIDE_UNSUPPORTED", "FLIPPED", "UNKNOWN"]) exitWith {
    []
};

if (
    _tractionMultiplier < 0.2 || {_tractionMultiplier > 1.1}
    || {_accelerationTractionMultiplier < 0 || {_accelerationTractionMultiplier > 1.1}}
    || {_brakingTractionMultiplier < 0 || {_brakingTractionMultiplier > 1.05}}
    || {_turningTractionMultiplier < 0 || {_turningTractionMultiplier > 1.05}}
    || {_slopeTractionMultiplier < 0 || {_slopeTractionMultiplier > 1.05}}
    || {_wheelspinEstimate < 0 || {_wheelspinEstimate > 1}}
    || {_tireAirState < 0 || {_tireAirState > 1}}
    || {_tireDragPenalty < 0 || {_tireDragPenalty > 0.95}}
    || {_tireSteeringPenalty < 0 || {_tireSteeringPenalty > 0.95}}
    || {_massModifier < 0.72 || {_massModifier > 1.08}}
    || {_driverlessDecay < 0 || {_driverlessDecay > 1}}
    || {_destroyedTireCount < 0 || {_destroyedTireCount > 16}}
    || {_destroyedTireRatio < 0 || {_destroyedTireRatio > 1}}
    || {_destroyedTirePenalty < 0 || {_destroyedTirePenalty > 0.95}}
    || {_mobilityLimiter < 0 || {_mobilityLimiter > 1}}
) exitWith {
    []
};

private _validatedResult = [
    _applied,
    _tractionMultiplier,
    _accelerationTractionMultiplier,
    _brakingTractionMultiplier,
    _turningTractionMultiplier,
    _slopeTractionMultiplier,
    _wheelspinEstimate,
    _tireAirState,
    _tireDragPenalty,
    _tireSteeringPenalty,
    _massModifier,
    _wheelSupportState,
    _rolloverSuppressed,
    _driverlessDecay,
    round _destroyedTireCount,
    _destroyedTireRatio,
    _destroyedTirePenalty,
    _mobilityLimiter,
    _telemetry
];

_cache set [_cacheKey, [_now, +_validatedResult]];
missionNamespace setVariable ["FIXICS_nativeTerrainTireCache", _cache, false];

_validatedResult
