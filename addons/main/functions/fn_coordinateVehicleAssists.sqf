/*
 * FIXICS_fnc_coordinateVehicleAssists
 *
 * Applies final local Runtime Assist coordination after subsystem updates.
 *
 * Arguments:
 *   0: Vehicle <OBJECT>
 *   1: Delta time <NUMBER>
 *   2: Driver state <STRING>
 *
 * Return: <BOOL> true when the coordinator changed or recorded a decision
 */
params [
    ["_vehicle", objNull, [objNull]],
    ["_deltaTime", 0, [0]],
    ["_driverState", "", [""]]
];

if (!(missionNamespace getVariable ["FIXICS_runtimeAssistCoordinatorEnabled", true])) exitWith {
    false
};
if (isNull _vehicle) exitWith {
    false
};
if (!(_vehicle isKindOf "LandVehicle")) exitWith {
    false
};
if (!local _vehicle) exitWith {
    false
};
if (!(hasInterface && {driver _vehicle == player})) exitWith {
    false
};

private _decision = createHashMapFromArray [
    ["enabled", true],
    ["eligible", false],
    ["priorityWinner", "none"],
    ["terrainMultiplier", 1],
    ["massMultiplier", 1],
    ["slopeRetention", 1],
    ["suppressedAssists", []],
    ["finalCorrection", 0],
    ["nativeAdvisory", "ignored"]
];

if (_vehicle getVariable ["FIXICS_handbrakeEnabled", false]) exitWith {
    _decision set ["eligible", false];
    _decision set ["priorityWinner", "handbrake"];
    _vehicle setVariable ["FIXICS_runtimeAssistLastDecision", _decision, false];
    false
};

private _surface = surfaceType (getPosWorld _vehicle);
private _terrainFriction = switch (true) do {
    case (_surface find "#GdtAsphalt" >= 0): {1};
    case (_surface find "#GdtConcrete" >= 0): {1};
    case (_surface find "#GdtDirt" >= 0): {0.82};
    case (_surface find "#GdtGrass" >= 0): {0.68};
    default {0.75};
};

private _massKg = getMass _vehicle;
if (!finite _massKg || {_massKg <= 0}) then {
    _massKg = getNumber (configOf _vehicle >> "mass");
};
if (!finite _massKg || {_massKg <= 0}) then {
    _massKg = 1200;
};

private _velocityModel = velocityModelSpace _vehicle;
private _speedKmh = (abs (_velocityModel # 1)) * 3.6;
private _absDecision = _vehicle getVariable ["FIXICS_absLastDecision", createHashMap];
private _slopeDecision = _vehicle getVariable ["FIXICS_slopeLastDecision", createHashMap];
private _stabilityDecision = _vehicle getVariable ["FIXICS_stabilityLastDecision", createHashMap];

private _state = createHashMapFromArray [
    ["speedKmh", _speedKmh],
    ["terrainFriction", _terrainFriction],
    ["massKg", _massKg],
    ["serviceBraking", _driverState == "SERVICE_BRAKE"],
    ["slopeDelta", _slopeDecision getOrDefault ["delta", 0]],
    ["stabilityDelta", _stabilityDecision getOrDefault ["lateralDelta", 0]],
    ["rollDelta", _stabilityDecision getOrDefault ["rollDelta", 0]]
];

private _settings = createHashMapFromArray [
    ["terrainInfluenceEnabled", missionNamespace getVariable ["FIXICS_runtimeAssistTerrainInfluenceEnabled", true]],
    ["terrainInfluenceStrength", missionNamespace getVariable ["FIXICS_runtimeAssistTerrainInfluenceStrength", 0.25]],
    ["brakingSlopeRetention", missionNamespace getVariable ["FIXICS_runtimeAssistBrakingSlopeRetention", 0.35]],
    ["massDampingStrength", missionNamespace getVariable ["FIXICS_runtimeAssistMassDampingStrength", 0.15]],
    ["maximumComposedCorrection", missionNamespace getVariable ["FIXICS_runtimeAssistMaximumComposedCorrection", 0.25]]
];

private _recommendation = [_state, _settings] call FIXICS_fnc_getRuntimeAssistRecommendation;

_decision set ["eligible", true];
_decision set ["priorityWinner", _recommendation getOrDefault ["priorityWinner", "none"]];
_decision set ["terrainMultiplier", _recommendation getOrDefault ["terrainMultiplier", 1]];
_decision set ["massMultiplier", _recommendation getOrDefault ["massMultiplier", 1]];
_decision set ["slopeRetention", _recommendation getOrDefault ["slopeRetention", 1]];
_decision set ["suppressedAssists", _recommendation getOrDefault ["suppressedAssists", []]];
_decision set ["finalCorrection", _recommendation getOrDefault ["finalCorrection", 0]];
_decision set ["nativeAdvisory", "advisory-only"];
_decision set ["absApplied", _absDecision getOrDefault ["applied", false]];

_vehicle setVariable ["FIXICS_runtimeAssistLastDecision", _decision, false];

if (missionNamespace getVariable ["FIXICS_runtimeAssistDebugLogging", false]) then {
    diag_log format [
        "[FIXICS][RuntimeAssist] class=%1 state=%2 speedKmh=%3 priority=%4 terrain=%5 mass=%6 slopeRetention=%7 suppressed=%8 finalCorrection=%9",
        typeOf _vehicle,
        _driverState,
        _speedKmh,
        _decision get "priorityWinner",
        _decision get "terrainMultiplier",
        _decision get "massMultiplier",
        _decision get "slopeRetention",
        _decision get "suppressedAssists",
        _decision get "finalCorrection"
    ];
};

true
