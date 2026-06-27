/*
 * FIXICS_fnc_getNativeSlopeControl
 *
 * Requests a native-assisted slope rollback recommendation.
 *
 * Arguments:
 *   0: Normalized downhill vector <ARRAY>
 *   1: Current vehicle velocity <ARRAY>
 *   2: Terrain slope magnitude <NUMBER>
 *   3: Maximum assisted rollback speed in m/s <NUMBER>
 *   4: Rollback acceleration coefficient <NUMBER>
 *   5: Minimum near-zero velocity delta <NUMBER>
 *
 * Return: <ARRAY> [applied <BOOL>, deltaX <NUMBER>, deltaY <NUMBER>, deltaZ <NUMBER>] or []
 * Locality: local machine
 *
 * Example:
 *   [_downhill, velocity _vehicle, 0.2, 2.2, 0.55, 0.18] call FIXICS_fnc_getNativeSlopeControl;
 */

params [
    ["_downhill", [0, 0, 0], [[]], [3]],
    ["_velocity", [0, 0, 0], [[]], [3]],
    ["_slope", 0, [0]],
    ["_maxRollbackSpeed", 0, [0]],
    ["_rollbackAcceleration", 0, [0]],
    ["_minimumDelta", 0, [0]]
];

if !(missionNamespace getVariable ["FIXICS_nativeSlopeControlEnabled", false]) exitWith {
    []
};
if (!hasInterface && {isMultiplayer}) exitWith {
    []
};

private _result = "FIXICSPhysics" callExtension [
    "slopeControl",
    [
        str (_downhill # 0),
        str (_downhill # 1),
        str (_velocity # 0),
        str (_velocity # 1),
        str _slope,
        str _maxRollbackSpeed,
        str _rollbackAcceleration,
        str _minimumDelta
    ]
];

_result params [
    ["_payload", "", [""]],
    ["_returnCode", 0, [0]],
    ["_errorCode", 0, [0]]
];

if (_errorCode != 0) exitWith {
    diag_log format ["[FIXICS_fnc_getNativeSlopeControl] Extension errorCode %1.", _errorCode];
    []
};

if (_returnCode != 0) exitWith {
    diag_log format ["[FIXICS_fnc_getNativeSlopeControl] Extension returnCode %1 payload %2.", _returnCode, _payload];
    []
};

if (_payload isEqualTo "") exitWith {
    []
};

private _parsed = [];
try {
    _parsed = parseSimpleArray _payload;
} catch {
    diag_log format ["[FIXICS_fnc_getNativeSlopeControl] Invalid extension payload: %1", _payload];
};

if ((count _parsed) < 4) exitWith {
    []
};

_parsed params [
    ["_applied", false, [false]],
    ["_deltaX", 0, [0]],
    ["_deltaY", 0, [0]],
    ["_deltaZ", 0, [0]]
];

if (!_applied) exitWith {
    []
};

[_applied, _deltaX, _deltaY, _deltaZ]
