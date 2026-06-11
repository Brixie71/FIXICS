/*
 * FIXICS_fnc_getNativeDriverAssist
 *
 * Requests a native driver-control recommendation without mutating the vehicle.
 *
 * Arguments:
 *   0: Controller state <STRING>
 *   1: Requested direction, -1 to 1 <NUMBER>
 *   2: Longitudinal speed in m/s <NUMBER>
 *   3: Terrain slope magnitude <NUMBER>
 *   4: Downhill alignment, -1 to 1 <NUMBER>
 *   5: Elapsed update time in seconds <NUMBER>
 *   6: ABS brake strength <NUMBER>
 *   7: ABS release bias <NUMBER>
 *   8: ABS slope compensation <NUMBER>
 *   9: Direction change threshold in m/s <NUMBER>
 *   10: Direction launch velocity in m/s <NUMBER>
 *   11: Neutral pulse duration in seconds <NUMBER>
 *   12: ABS low-speed cutoff in m/s <NUMBER>
 *   13: Ignore low-speed cutoff <BOOL>
 *
 * Return: <ARRAY> [applied, mode, target speed, brake delta, launch direction, telemetry] or []
 * Locality: local machine
 *
 * Example:
 *   ["SERVICE_BRAKE", 1, -4, 0.1, 0.8, 0.03, 0.45, 0.35, 0.25, 0.55, 0.35, 0.08, 0.83, true]
 *       call FIXICS_fnc_getNativeDriverAssist;
 */

params [
    ["_state", "", [""]],
    ["_requestedDirection", 0, [0]],
    ["_longitudinalSpeed", 0, [0]],
    ["_slope", 0, [0]],
    ["_downhillAlignment", 0, [0]],
    ["_deltaTime", 0, [0]],
    ["_absBrakeStrength", 0, [0]],
    ["_absReleaseBias", 0, [0]],
    ["_absSlopeCompensation", 0, [0]],
    ["_directionThreshold", 0, [0]],
    ["_directionLaunchVelocity", 0, [0]],
    ["_neutralPulseSeconds", 0, [0]],
    ["_lowSpeedCutoff", 0, [0]],
    ["_ignoreLowSpeedCutoff", false, [false]]
];

if !(missionNamespace getVariable ["FIXICS_nativeDriverAssistEnabled", false]) exitWith {
    []
};

private _result = "FIXICSPhysics" callExtension [
    "driverAssist",
    [
        _state,
        str _requestedDirection,
        str _longitudinalSpeed,
        str _slope,
        str _downhillAlignment,
        str _deltaTime,
        str _absBrakeStrength,
        str _absReleaseBias,
        str _absSlopeCompensation,
        str _directionThreshold,
        str _directionLaunchVelocity,
        str _neutralPulseSeconds,
        str _lowSpeedCutoff,
        str ([0, 1] select _ignoreLowSpeedCutoff)
    ]
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

if !(_parsed isEqualType [] && {count _parsed == 6}) exitWith {
    []
};

private _applied = _parsed # 0;
private _mode = _parsed # 1;
private _targetLongitudinalSpeed = _parsed # 2;
private _brakeDelta = _parsed # 3;
private _launchDirection = _parsed # 4;
private _telemetry = _parsed # 5;

if !(
    _applied isEqualType false
    && {_mode isEqualType ""}
    && {_targetLongitudinalSpeed isEqualType 0}
    && {_brakeDelta isEqualType 0}
    && {_launchDirection isEqualType 0}
    && {_telemetry isEqualType ""}
) exitWith {
    []
};

private _finite = {
    params ["_value"];
    finite _value
};

if !(
    [_targetLongitudinalSpeed] call _finite
    && {[_brakeDelta] call _finite}
    && {[_launchDirection] call _finite}
) exitWith {
    []
};

if !(_mode in ["NONE", "SERVICE_BRAKE", "ABS", "LAUNCH"]) exitWith {
    []
};

if (_brakeDelta < 0) exitWith {
    []
};

if (
    _launchDirection < -1
    || {_launchDirection > 1}
    || {abs (_launchDirection - round _launchDirection) > 0.0001}
) exitWith {
    []
};

private _targetSpeedBound = abs _longitudinalSpeed + abs _directionLaunchVelocity + 1;
if (abs _targetLongitudinalSpeed > _targetSpeedBound) exitWith {
    []
};

[
    _applied,
    _mode,
    _targetLongitudinalSpeed,
    _brakeDelta,
    round _launchDirection,
    _telemetry
]
