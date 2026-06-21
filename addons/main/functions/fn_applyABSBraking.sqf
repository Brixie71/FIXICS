/*
 * FIXICS_fnc_applyABSBraking
 *
 * Applies local velocity-level ABS-like braking modulation for player-driven land vehicles.
 *
 * Arguments:
 *   0: Vehicle to update <OBJECT>
 *   1: Requested direction: -1 reverse, 0 combined brake, 1 forward <NUMBER>
 *   2: Ignore normal low-speed cutoff for a direction transition <BOOL>
 *   3: Elapsed time since the previous update <NUMBER> (default: 0.25)
 *
 * Return: <BOOL> true when ABS changed vehicle velocity
 * Locality: local machine; vehicle velocity changes only apply where the vehicle is local
 *
 * Example:
 *   [_vehicle, 1, true, _deltaTime] call FIXICS_fnc_applyABSBraking;
 */

params [
    ["_vehicle", objNull, [objNull]],
    ["_requestedDirection", 0, [0]],
    ["_ignoreLowSpeedCutoff", false, [true]],
    ["_deltaTime", 0.25, [0]]
];

if (!(missionNamespace getVariable ["FIXICS_absEnabled", true])) exitWith {
    false
};

if (isNull _vehicle) exitWith {
    false
};

if (!(_vehicle isKindOf "LandVehicle")) exitWith {
    false
};

if (!(local _vehicle)) exitWith {
    false
};

private _clearAbsDecision = {
    _vehicle setVariable [
        "FIXICS_absLastDecision",
        createHashMapFromArray [
            ["applied", false],
            ["delta", 0]
        ],
        false
    ];
};

if (!isTouchingGround _vehicle) exitWith {
    call _clearAbsDecision;
    false
};

if (_vehicle getVariable ["FIXICS_handbrakeEnabled", false]) exitWith {
    call _clearAbsDecision;
    false
};

private _driver = driver _vehicle;
if (!(hasInterface && {!isNull _driver} && {_driver == player})) exitWith {
    call _clearAbsDecision;
    false
};

if ((inputAction "CarHandBrake") > 0) exitWith {
    call _clearAbsDecision;
    false
};

_requestedDirection = (_requestedDirection max -1) min 1;
private _modelVelocity = velocityModelSpace _vehicle;
private _longitudinalSpeed = _modelVelocity # 1;
private _vehicleForward = vectorDir _vehicle;
private _forward = [_vehicleForward # 0, _vehicleForward # 1, 0];
private _forwardLength = sqrt (((_forward # 0) * (_forward # 0)) + ((_forward # 1) * (_forward # 1)));
if (_forwardLength <= 0) exitWith {
    false
};

_forward = _forward vectorMultiply (1 / _forwardLength);

private _speedKmh = (abs _longitudinalSpeed) * 3.6;
private _lowSpeedCutoffKmh = missionNamespace getVariable ["FIXICS_absLowSpeedCutoffKmh", 3];
if (!_ignoreLowSpeedCutoff && {_speedKmh <= _lowSpeedCutoffKmh}) exitWith {
    call _clearAbsDecision;
    false
};

private _stationarySpeedKmh = missionNamespace getVariable ["FIXICS_stationaryBrakeBypassSpeedKmh", 1];
private _stationarySpeedMps = _stationarySpeedKmh / 3.6;
private _brakingThreshold = [_stationarySpeedMps, 0] select _ignoreLowSpeedCutoff;
private _isForwardBraking = (
    _requestedDirection < 0
    || {_requestedDirection == 0}
) && {_longitudinalSpeed > _brakingThreshold};
private _isReverseBraking = (
    _requestedDirection > 0
    || {_requestedDirection == 0}
) && {_longitudinalSpeed < -_brakingThreshold};
private _isBraking = _isForwardBraking || {_isReverseBraking};
if (!_isBraking) exitWith {
    call _clearAbsDecision;
    false
};

private _normal = surfaceNormal (getPosASL _vehicle);
private _normalZ = ((_normal # 2) max -1) min 1;
private _slopeAngleDegrees = acos _normalZ;
private _slope = sin _slopeAngleDegrees;
private _downhill = [_normal # 0, _normal # 1, 0];
private _downhillLength = sqrt (((_downhill # 0) * (_downhill # 0)) + ((_downhill # 1) * (_downhill # 1)));
if (_downhillLength > 0) then {
    _downhill = _downhill vectorMultiply (1 / _downhillLength);
};

private _downhillAlignment = 0;
if (_downhillLength > 0) then {
    _downhillAlignment = ((_downhill # 0) * (_forward # 0)) + ((_downhill # 1) * (_forward # 1));
};

private _slopeCompensation = missionNamespace getVariable ["FIXICS_absSlopeCompensation", 0.25];
private _downhillBrakeLoad = if (_isForwardBraking) then {
    _downhillAlignment max 0
} else {
    (-_downhillAlignment) max 0
};

private _brakeStrength = missionNamespace getVariable ["FIXICS_absBrakeStrength", 0.45];
private _releaseBias = missionNamespace getVariable ["FIXICS_absReleaseBias", 0.35];
private _applySqfAbsFallback = {
    private _timeScale = ((_deltaTime max 0.001) min 0.25) / 0.25;
    private _effectiveBrake = _brakeStrength
        * (1 - _releaseBias)
        * (1 + (_downhillBrakeLoad * _slopeCompensation))
        * _timeScale;
    private _delta = _effectiveBrake min (abs _longitudinalSpeed);
    private _targetLongitudinalSpeed = if (_isForwardBraking) then {
        (_longitudinalSpeed - _delta) max 0
    } else {
        (_longitudinalSpeed + _delta) min 0
    };

    if (missionNamespace getVariable ["FIXICS_absDebugLogging", false]) then {
        diag_log format [
            "FIXICS ABS: type=%1 requestedDirection=%2 speedKmh=%3 longitudinalMps=%4 delta=%5 slope=%6 downhillLoad=%7",
            typeOf _vehicle,
            _requestedDirection,
            _speedKmh,
            _longitudinalSpeed,
            _delta,
            _slope,
            _downhillBrakeLoad
        ];
    };

    [_delta > 0, _targetLongitudinalSpeed, _delta, "fallback"]
};

private _source = "sqf";
private _selectedResult = [];
private _nativeAlignment = if (_isForwardBraking) then {
    _downhillAlignment
} else {
    -_downhillAlignment
};

private _directionThreshold = (
    missionNamespace getVariable ["FIXICS_directionChangeThresholdKmh", 2]
) / 3.6;
private _directionLaunchVelocity = missionNamespace getVariable ["FIXICS_directionLaunchVelocity", 0.35];
private _neutralPulseSeconds = missionNamespace getVariable ["FIXICS_directionNeutralPulseSeconds", 0.08];
private _nativeAdvice = [
    "ABS",
    0,
    _longitudinalSpeed,
    _slope,
    _nativeAlignment,
    _deltaTime,
    _brakeStrength,
    _releaseBias,
    _slopeCompensation,
    _directionThreshold,
    _directionLaunchVelocity,
    _neutralPulseSeconds,
    _lowSpeedCutoffKmh / 3.6,
    false
] call FIXICS_fnc_getNativeDriverAssist;

if (
    _nativeAdvice isEqualType []
    && {count _nativeAdvice == 6}
    && {_nativeAdvice # 0}
    && {_nativeAdvice # 1 in ["SERVICE_BRAKE", "ABS"]}
) then {
    private _nativeTarget = _nativeAdvice # 2;
    private _boundedTarget = if (_isForwardBraking) then {
        (_nativeTarget max 0) min _longitudinalSpeed
    } else {
        (_nativeTarget min 0) max _longitudinalSpeed
    };
    private _nativeDelta = abs (_longitudinalSpeed - _boundedTarget);

    if (_nativeDelta > 0) then {
        _source = "native";
        _selectedResult = [true, _boundedTarget, _nativeDelta, _nativeAdvice # 5];
    };
};

if (_selectedResult isEqualTo []) then {
    _selectedResult = call _applySqfAbsFallback;
};

_selectedResult params ["_applied", "_newLongitudinalSpeed", "_delta", "_detail"];
if (!_applied) exitWith {
    call _clearAbsDecision;
    false
};

private _absDecision = createHashMapFromArray [
    ["applied", _applied],
    ["requestedDirection", _requestedDirection],
    ["targetLongitudinalSpeed", _newLongitudinalSpeed],
    ["delta", _delta],
    ["source", _source],
    ["detail", _detail],
    ["slope", _slope],
    ["downhillBrakeLoad", _downhillBrakeLoad]
];
_vehicle setVariable ["FIXICS_absLastDecision", _absDecision, false];

_modelVelocity set [1, _newLongitudinalSpeed];
_vehicle setVelocityModelSpace _modelVelocity;

if (missionNamespace getVariable ["FIXICS_driverAssistDebugLogging", false]) then {
    diag_log format [
        "FIXICS driver assist ABS: type=%1 requestedDirection=%2 speedKmh=%3 targetMps=%4 delta=%5 slope=%6 source=%7 detail=%8",
        typeOf _vehicle,
        _requestedDirection,
        _speedKmh,
        _newLongitudinalSpeed,
        _delta,
        _slope,
        _source,
        _detail
    ];
};

true
