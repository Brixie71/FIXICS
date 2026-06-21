/*
 * FIXICS_fnc_applySlopeRollback
 *
 * Adds downhill slope velocity assist for local land vehicles.
 *
 * Arguments:
 *   0: Vehicle to update <OBJECT>
 *   1: Elapsed time since the previous update <NUMBER> (default: 0.25)
 *
 * Return: <BOOL> true when rollback assist was applied
 * Locality: local machine; vehicle velocity changes only apply where the vehicle is local
 *
 * Example:
 *   [_vehicle] call FIXICS_fnc_applySlopeRollback;
 */

params [
    ["_vehicle", objNull, [objNull]],
    ["_deltaTime", 0.25, [0]]
];

if (isNull _vehicle) exitWith {
    false
};

if (!(_vehicle isKindOf "LandVehicle")) exitWith {
    false
};

if (!(local _vehicle)) exitWith {
    false
};

if (!isTouchingGround _vehicle) exitWith {
    false
};

if (_vehicle getVariable ["FIXICS_handbrakeEnabled", false]) exitWith {
    false
};

private _clearSlopeDecision = {
    _vehicle setVariable [
        "FIXICS_slopeLastDecision",
        createHashMapFromArray [
            ["applied", false],
            ["delta", 0]
        ],
        false
    ];
};

private _hasForwardInput = false;
private _hasBackInput = false;
private _inputBlocksSlopeAssist = false;

private _driver = driver _vehicle;
if (hasInterface && {!isNull _driver} && {_driver == player}) then {
    private _isHandbraking = (inputAction "CarHandBrake") > 0;
    private _driverInputIntent = call FIXICS_fnc_getDriverInputIntent;
    _hasForwardInput = _driverInputIntent # 0;
    _hasBackInput = _driverInputIntent # 1;
    _inputBlocksSlopeAssist = _isHandbraking || {_hasForwardInput && {_hasBackInput}};
};

if (_inputBlocksSlopeAssist) exitWith {
    call _clearSlopeDecision;
    false
};

private _velocity = velocity _vehicle;
private _vehicleForward = vectorDir _vehicle;
private _forward = [_vehicleForward # 0, _vehicleForward # 1, 0];
private _forwardLength = sqrt (((_forward # 0) * (_forward # 0)) + ((_forward # 1) * (_forward # 1)));
if (_forwardLength <= 0) exitWith {
    call _clearSlopeDecision;
    false
};

_forward = _forward vectorMultiply (1 / _forwardLength);

private _stationarySpeedKmh = missionNamespace getVariable ["FIXICS_stationaryBrakeBypassSpeedKmh", 1];
private _stationarySpeedMps = _stationarySpeedKmh / 3.6;
private _longitudinalSpeed = ((_velocity # 0) * (_forward # 0)) + ((_velocity # 1) * (_forward # 1));
private _isForwardBraking = _hasBackInput && {_longitudinalSpeed > _stationarySpeedMps};
private _isReverseBraking = _hasForwardInput && {_longitudinalSpeed < -_stationarySpeedMps};
private _isBraking = _isForwardBraking || {_isReverseBraking};
private _brakingSlopeRetention = missionNamespace getVariable [
    "FIXICS_runtimeAssistBrakingSlopeRetention",
    0.35
];
_brakingSlopeRetention = (_brakingSlopeRetention max 0) min 1;
private _serviceBrakeSlopeScale = [1, _brakingSlopeRetention] select _isBraking;

private _hasDriveInput = _hasForwardInput || {_hasBackInput};

private _normal = surfaceNormal (getPosASL _vehicle);
private _normalZ = ((_normal # 2) max -1) min 1;
private _slopeAngleDegrees = acos _normalZ;
private _slope = sin _slopeAngleDegrees;
private _downhill = [_normal # 0, _normal # 1, 0];
private _downhillLength = sqrt (((_downhill # 0) * (_downhill # 0)) + ((_downhill # 1) * (_downhill # 1)));
private _minimumSlope = missionNamespace getVariable ["FIXICS_slopeRollbackMinimumSlope", 0.035];
if ((_slope < _minimumSlope) || {_downhillLength <= 0}) exitWith {
    call _clearSlopeDecision;
    false
};

_downhill = _downhill vectorMultiply (1 / _downhillLength);

private _downhillSpeed = ((_velocity # 0) * (_downhill # 0)) + ((_velocity # 1) * (_downhill # 1));
private _forwardDownhillAlignment = ((_forward # 0) * (_downhill # 0)) + ((_forward # 1) * (_downhill # 1));
private _timeScale = ((_deltaTime max 0.001) min 0.5) / 0.25;

if (_hasDriveInput) exitWith {
    private _driveAxis = if (_hasForwardInput) then {
        _forward
    } else {
        _forward vectorMultiply -1
    };

    private _driveDownhillAlignment = if (_hasForwardInput) then {
        _forwardDownhillAlignment
    } else {
        -_forwardDownhillAlignment
    };
    private _effectiveDriveSlope = _slope * _driveDownhillAlignment;
    if (_effectiveDriveSlope <= 0 || {_effectiveDriveSlope < _minimumSlope}) exitWith {
        call _clearSlopeDecision;
        false
    };

    private _driveAxisSpeed = ((_velocity # 0) * (_driveAxis # 0)) + ((_velocity # 1) * (_driveAxis # 1));
    private _maxDriveSpeed = (missionNamespace getVariable ["FIXICS_slopeDriveMaxSpeedKmh", 120]) / 3.6;
    if (_driveAxisSpeed >= _maxDriveSpeed) exitWith {
        call _clearSlopeDecision;
        false
    };

    private _driveAcceleration = missionNamespace getVariable ["FIXICS_slopeDriveAcceleration", 0.22];
    private _driveDelta = _driveAcceleration * _effectiveDriveSlope * _timeScale * _serviceBrakeSlopeScale;
    _driveDelta = _driveDelta min (_maxDriveSpeed - _driveAxisSpeed);

    if ((abs _driveDelta) <= 0) exitWith {
        call _clearSlopeDecision;
        false
    };

    _vehicle setVariable [
        "FIXICS_slopeLastDecision",
        createHashMapFromArray [
            ["applied", true],
            ["delta", _driveDelta],
            ["serviceBraking", _isBraking],
            ["slopeScale", _serviceBrakeSlopeScale],
            ["slope", _slope],
            ["surface", surfaceType (getPosWorld _vehicle)]
        ],
        false
    ];

    _vehicle setVelocity [
        (_velocity # 0) + ((_driveAxis # 0) * _driveDelta),
        (_velocity # 1) + ((_driveAxis # 1) * _driveDelta),
        _velocity # 2
    ];

    true
};

private _maxRollbackSpeed = missionNamespace getVariable ["FIXICS_slopeRollbackMaxSpeed", 2.2];
if (_downhillSpeed >= _maxRollbackSpeed) exitWith {
    call _clearSlopeDecision;
    false
};

private _rollbackAcceleration = missionNamespace getVariable ["FIXICS_slopeRollbackAcceleration", 0.55];
private _coastBreakawayVelocity = missionNamespace getVariable ["FIXICS_slopeCoastBreakawayVelocity", 0.18];
private _minimumDelta = 0;
if ((abs _downhillSpeed) <= _stationarySpeedMps) then {
    _minimumDelta = _coastBreakawayVelocity * _timeScale;
};

private _nativeSlopeControl = [
    _downhill,
    _velocity,
    _slope,
    _maxRollbackSpeed,
    _rollbackAcceleration * _timeScale,
    _minimumDelta
] call FIXICS_fnc_getNativeSlopeControl;

if ((count _nativeSlopeControl) > 0) exitWith {
    _nativeSlopeControl params [
        ["_nativeApplied", true, [false]],
        ["_nativeDeltaX", 0, [0]],
        ["_nativeDeltaY", 0, [0]],
        ["_nativeDeltaZ", 0, [0]]
    ];
    if (!_nativeApplied) exitWith {
        call _clearSlopeDecision;
        false
    };
    private _nativeDelta = sqrt ((_nativeDeltaX * _nativeDeltaX) + (_nativeDeltaY * _nativeDeltaY) + (_nativeDeltaZ * _nativeDeltaZ));
    _vehicle setVariable [
        "FIXICS_slopeLastDecision",
        createHashMapFromArray [
            ["applied", true],
            ["delta", _nativeDelta],
            ["serviceBraking", _isBraking],
            ["slopeScale", _serviceBrakeSlopeScale],
            ["slope", _slope],
            ["surface", surfaceType (getPosWorld _vehicle)]
        ],
        false
    ];
    _vehicle setVelocity [
        (_velocity # 0) + _nativeDeltaX,
        (_velocity # 1) + _nativeDeltaY,
        (_velocity # 2) + _nativeDeltaZ
    ];
    true
};

private _remainingRollbackSpeed = _maxRollbackSpeed - _downhillSpeed;
private _delta = (_rollbackAcceleration * (_slope max 0.15) * _timeScale * _serviceBrakeSlopeScale) min _remainingRollbackSpeed;
if (_minimumDelta > 0) then {
    _delta = (_delta max _minimumDelta) min _remainingRollbackSpeed;
};

if (_delta <= 0) exitWith {
    call _clearSlopeDecision;
    false
};

_vehicle setVariable [
    "FIXICS_slopeLastDecision",
    createHashMapFromArray [
        ["applied", true],
        ["delta", _delta],
        ["serviceBraking", _isBraking],
        ["slopeScale", _serviceBrakeSlopeScale],
        ["slope", _slope],
        ["surface", surfaceType (getPosWorld _vehicle)]
    ],
    false
];

_vehicle setVelocity [
    (_velocity # 0) + ((_downhill # 0) * _delta),
    (_velocity # 1) + ((_downhill # 1) * _delta),
    _velocity # 2
];

true
