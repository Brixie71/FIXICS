/*
 * FIXICS_fnc_getRollStabilityRecommendation
 *
 * Calculates a pure vertical-speed recommendation for roll stability assist.
 *
 * Arguments:
 *   0: Current model-space vertical speed <NUMBER>
 *   1: Current vehicle bank angle in degrees <NUMBER>
 *   2: Current vehicle bank rate in degrees per second <NUMBER>
 *   3: Delta time in seconds <NUMBER>
 *   4: Settings [activationBankDeg, activationRateDeg, strength, maximumCorrection] <ARRAY>
 *
 * Return: [applied, recommendedVertical, correction, severity] <ARRAY>
 * Locality: any machine
 *
 * Engine note:
 *   This function does not mutate vehicle state. The local controller owns any
 *   velocity application after it validates locality and driver authority.
 *
 * Example:
 *   [1.2, 35, 80, 0.016, [20, 45, 0.2, 0.1]] call FIXICS_fnc_getRollStabilityRecommendation;
 */
params [
    ["_verticalSpeed", 0, [0]],
    ["_bankDeg", 0, [0]],
    ["_bankRateDeg", 0, [0]],
    ["_deltaTime", 0, [0]],
    ["_settings", [], [[]]]
];

if (
    !finite _verticalSpeed
    || {!finite _bankDeg}
    || {!finite _bankRateDeg}
    || {!finite _deltaTime}
) exitWith {
    [false, 0, 0, 0]
};

if ((count _settings) < 4) exitWith {
    [false, _verticalSpeed, 0, 0]
};

_settings params [
    ["_activationBankDeg", 0, [0]],
    ["_activationRateDeg", 0, [0]],
    ["_strength", 0, [0]],
    ["_maximumCorrection", 0, [0]]
];

private _settingValues = [
    _activationBankDeg,
    _activationRateDeg,
    _strength,
    _maximumCorrection
];
if ((_settingValues findIf {!finite _x}) >= 0) exitWith {
    [false, _verticalSpeed, 0, 0]
};

_activationBankDeg = (_activationBankDeg max 5) min 60;
_activationRateDeg = (_activationRateDeg max 5) min 240;
_strength = (_strength max 0) min 0.5;
_maximumCorrection = (_maximumCorrection max 0.01) min 0.4;
_deltaTime = (_deltaTime max 0) min 1;

private _bankSeverity = (((abs _bankDeg) - _activationBankDeg) / _activationBankDeg) max 0;
private _rateSeverity = (((abs _bankRateDeg) - _activationRateDeg) / _activationRateDeg) max 0;
private _severity = (_bankSeverity max _rateSeverity) min 1;

if (_severity <= 0 || {_strength <= 0}) exitWith {
    [false, _verticalSpeed, 0, 0]
};

private _damping = (_severity * _strength * _deltaTime) min _maximumCorrection;
private _recommendedVertical = _verticalSpeed * (1 - _damping);
private _correction = _recommendedVertical - _verticalSpeed;
private _applied = _correction != 0;

[
    _applied,
    _recommendedVertical,
    _correction,
    _severity
]
