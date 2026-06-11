/*
 * FIXICS_fnc_updateDriverController
 *
 * Owns local player drive, service-brake, reverse, coast, and handbrake transitions.
 *
 * Arguments:
 *   None
 *
 * Return: <BOOL> true when a player-driven land vehicle was updated
 * Locality: client with interface
 *
 * Example:
 *   [] call FIXICS_fnc_updateDriverController;
 */

private _previousVehicle = missionNamespace getVariable ["FIXICS_driverControllerVehicle", objNull];
private _clearDirectionTransition = {
    params ["_targetVehicle"];

    if (!isNull _targetVehicle) then {
        _targetVehicle setVariable ["FIXICS_directionTransitionTarget", 0, false];
        _targetVehicle setVariable ["FIXICS_directionTransitionNeutralUntil", 0, false];
    };
};

private _claimVehicle = {
    params ["_targetVehicle"];

    if (isNull _targetVehicle || {!(local _targetVehicle)}) exitWith {
        false
    };

    private _brakeControlOwner = _targetVehicle getVariable ["FIXICS_brakeControlOwner", ""];
    if (_brakeControlOwner == "") then {
        _targetVehicle setVariable ["FIXICS_priorBrakesDisabled", brakesDisabled _targetVehicle, false];
    };

    if (_brakeControlOwner in ["", "monitor", "driver", "handbrake"]) then {
        _targetVehicle setVariable ["FIXICS_brakeControlOwner", "driver", false];
        true
    } else {
        false
    };
};

private _releaseVehicle = {
    params ["_targetVehicle"];

    [_targetVehicle] call _clearDirectionTransition;

    if (!isNull _targetVehicle && {local _targetVehicle}) then {
        private _brakeControlOwner = _targetVehicle getVariable ["FIXICS_brakeControlOwner", ""];
        private _persistentHandbrake = _targetVehicle getVariable ["FIXICS_handbrakeEnabled", false];
        if (_brakeControlOwner == "driver" && {_persistentHandbrake}) then {
            _targetVehicle setVariable ["FIXICS_brakeControlOwner", "handbrake", false];
        } else {
            if (_brakeControlOwner == "driver") then {
                private _priorBrakesDisabled = _targetVehicle getVariable ["FIXICS_priorBrakesDisabled", false];
                _targetVehicle disableBrakes _priorBrakesDisabled;
                _targetVehicle setVariable ["FIXICS_brakeControlOwner", "", false];
                _targetVehicle setVariable ["FIXICS_priorBrakesDisabled", nil, false];
            };
        };

        if (
            _persistentHandbrake
            && {isTouchingGround _targetVehicle}
        ) then {
            [_targetVehicle] call FIXICS_fnc_applyHandbrakeLock;
        };
    };
};

if (!(missionNamespace getVariable ["FIXICS_driverControllerEnabled", true])) exitWith {
    [_previousVehicle] call _releaseVehicle;
    missionNamespace setVariable ["FIXICS_driverControllerVehicle", objNull, false];
    missionNamespace setVariable ["FIXICS_handbrakeInputWasDown", false, false];
    missionNamespace setVariable ["FIXICS_driverControllerLastUpdate", diag_tickTime, false];
    false
};

private _now = diag_tickTime;
private _nextUpdate = missionNamespace getVariable ["FIXICS_driverControllerNextUpdate", 0];
if (_now < _nextUpdate) exitWith {
    false
};

private _interval = (missionNamespace getVariable ["FIXICS_driverControllerInterval", 0.03]) max 0.01;
missionNamespace setVariable ["FIXICS_driverControllerNextUpdate", _now + _interval, false];
private _lastUpdate = missionNamespace getVariable ["FIXICS_driverControllerLastUpdate", _now - _interval];
private _deltaTime = ((_now - _lastUpdate) max 0.001) min 0.25;
missionNamespace setVariable ["FIXICS_driverControllerLastUpdate", _now, false];

private _vehicle = vehicle player;
if (
    !hasInterface
    || {isNull _vehicle}
    || {_vehicle == player}
    || {!(_vehicle isKindOf "LandVehicle")}
    || {!(local _vehicle)}
    || {driver _vehicle != player}
) exitWith {
    [_previousVehicle] call _releaseVehicle;
    missionNamespace setVariable ["FIXICS_driverControllerVehicle", objNull, false];
    missionNamespace setVariable ["FIXICS_handbrakeInputWasDown", false, false];
    false
};

if (_previousVehicle != _vehicle) then {
    [_previousVehicle] call _releaseVehicle;
    missionNamespace setVariable ["FIXICS_handbrakeInputWasDown", false, false];
};
missionNamespace setVariable ["FIXICS_driverControllerVehicle", _vehicle, false];

if (!isTouchingGround _vehicle) exitWith {
    [_vehicle] call _releaseVehicle;
    false
};

if (!([_vehicle] call _claimVehicle)) exitWith {
    false
};

private _setState = {
    params ["_targetVehicle", "_state"];

    private _previousState = _targetVehicle getVariable ["FIXICS_driverState", ""];
    if (
        _previousState != _state
        && {missionNamespace getVariable ["FIXICS_absDebugLogging", false]}
    ) then {
        diag_log format [
            "FIXICS driver state: type=%1 previous=%2 next=%3",
            typeOf _targetVehicle,
            _previousState,
            _state
        ];
    };

    _targetVehicle setVariable ["FIXICS_driverState", _state, false];
};

private _handbrakeInput = (inputAction "CarHandBrake") > 0;
private _handbrakeInputWasDown = missionNamespace getVariable ["FIXICS_handbrakeInputWasDown", false];
private _handbrakeInputMode = missionNamespace getVariable ["FIXICS_handbrakeInputMode", 0];

if (_handbrakeInputMode == 1 && {_handbrakeInput} && {!_handbrakeInputWasDown}) then {
    private _persistentHandbrake = _vehicle getVariable ["FIXICS_handbrakeEnabled", false];
    [_vehicle, !_persistentHandbrake] call FIXICS_fnc_setVehicleHandbrake;
};

missionNamespace setVariable ["FIXICS_handbrakeInputWasDown", _handbrakeInput, false];

private _persistentHandbrake = _vehicle getVariable ["FIXICS_handbrakeEnabled", false];
private _temporaryHandbrake = _handbrakeInput
    && {_handbrakeInputMode == 0 || {!_persistentHandbrake}};
if (_persistentHandbrake || {_temporaryHandbrake}) exitWith {
    [_vehicle] call _clearDirectionTransition;
    [_vehicle, "HANDBRAKE"] call _setState;

    if (_persistentHandbrake) then {
        [_vehicle] call FIXICS_fnc_applyHandbrakeLock;
    } else {
        _vehicle disableBrakes false;
        _vehicle setVelocityModelSpace [0, 0, 0];
    };

    true
};

(call FIXICS_fnc_getDriverInputIntent) params [
    "_hasForwardInput",
    "_hasBackInput",
    "_requestedDirection"
];

private _modelVelocity = velocityModelSpace _vehicle;
private _longitudinalSpeed = _modelVelocity # 1;
private _directionThreshold = (missionNamespace getVariable ["FIXICS_directionChangeThresholdKmh", 2]) / 3.6;
private _launchVelocity = missionNamespace getVariable ["FIXICS_directionLaunchVelocity", 0.35];
private _neutralPulseSeconds = missionNamespace getVariable ["FIXICS_directionNeutralPulseSeconds", 0.08];
private _getDriverAssist = {
    params ["_state", "_direction", "_speed", "_ignoreLowSpeedCutoff"];

    private _normal = surfaceNormal (getPosASL _vehicle);
    private _normalZ = ((_normal # 2) max -1) min 1;
    private _slope = sin (acos _normalZ);
    private _forward = vectorDir _vehicle;
    private _forwardLength = sqrt (((_forward # 0) * (_forward # 0)) + ((_forward # 1) * (_forward # 1)));
    private _downhillAlignment = 0;
    if (_forwardLength > 0) then {
        _forward = _forward vectorMultiply (1 / _forwardLength);
        private _downhill = [_normal # 0, _normal # 1, 0];
        private _downhillLength = sqrt (((_downhill # 0) * (_downhill # 0)) + ((_downhill # 1) * (_downhill # 1)));
        if (_downhillLength > 0) then {
            _downhill = _downhill vectorMultiply (1 / _downhillLength);
            _downhillAlignment = ((_downhill # 0) * (_forward # 0)) + ((_downhill # 1) * (_forward # 1));
        };
    };

    private _advice = [
        _state,
        _direction,
        _speed,
        _slope,
        _downhillAlignment,
        _deltaTime,
        missionNamespace getVariable ["FIXICS_absBrakeStrength", 0.45],
        missionNamespace getVariable ["FIXICS_absReleaseBias", 0.35],
        missionNamespace getVariable ["FIXICS_absSlopeCompensation", 0.25],
        _directionThreshold,
        _launchVelocity,
        _neutralPulseSeconds,
        (missionNamespace getVariable ["FIXICS_absLowSpeedCutoffKmh", 3]) / 3.6,
        _ignoreLowSpeedCutoff
    ] call FIXICS_fnc_getNativeDriverAssist;

    if !(_advice isEqualType [] && {count _advice == 6}) exitWith {
        []
    };

    _advice
};
private _logDriverAssist = {
    params ["_state", "_direction", "_speed", "_source", "_mode", "_targetSpeed", "_detail"];

    if (missionNamespace getVariable ["FIXICS_driverAssistDebugLogging", false]) then {
        diag_log format [
            "FIXICS driver assist: type=%1 state=%2 direction=%3 speed=%4 source=%5 mode=%6 target=%7 time=%8 detail=%9",
            typeOf _vehicle,
            _state,
            _direction,
            _speed,
            _source,
            _mode,
            _targetSpeed,
            _now,
            _detail
        ];
    };
};
private _isOppositeDirection = (_requestedDirection > 0 && {_longitudinalSpeed < 0})
    || {_requestedDirection < 0 && {_longitudinalSpeed > 0}};
private _isCombinedBrake = _hasForwardInput && {_hasBackInput};
private _transitionTarget = _vehicle getVariable ["FIXICS_directionTransitionTarget", 0];
private _neutralUntil = _vehicle getVariable ["FIXICS_directionTransitionNeutralUntil", 0];

if (_transitionTarget != 0 && {_requestedDirection != _transitionTarget}) then {
    [_vehicle] call _clearDirectionTransition;
    _transitionTarget = 0;
    _neutralUntil = 0;
};

if (_transitionTarget == 0 && {_isOppositeDirection}) then {
    _transitionTarget = _requestedDirection;
    _neutralUntil = 0;
    _vehicle setVariable ["FIXICS_directionTransitionTarget", _transitionTarget, false];
    _vehicle setVariable ["FIXICS_directionTransitionNeutralUntil", 0, false];
};

if (_transitionTarget != 0) exitWith {
    if (_neutralUntil > 0) then {
        [_vehicle, "NEUTRAL"] call _setState;
        _vehicle disableBrakes false;

        _modelVelocity = velocityModelSpace _vehicle;
        _modelVelocity set [1, 0];
        _vehicle setVelocityModelSpace _modelVelocity;

        if (_now >= _neutralUntil) then {
            private _state = ["REVERSE", "DRIVE"] select (_transitionTarget > 0);
            [_vehicle, _state] call _setState;
            [_vehicle] call _clearDirectionTransition;

            private _launchSpeed = _transitionTarget * _launchVelocity;
            private _launchSource = "sqf";
            private _launchMode = "LAUNCH";
            private _launchDetail = "fallback";
            private _nativeAdvice = ["NEUTRAL", _transitionTarget, 0, true] call _getDriverAssist;
            if (
                _nativeAdvice isEqualType []
                && {count _nativeAdvice == 6}
                && {_nativeAdvice # 0}
                && {_nativeAdvice # 1 == "LAUNCH"}
                && {_nativeAdvice # 4 == _transitionTarget}
            ) then {
                private _nativeLaunchSpeed = _nativeAdvice # 2;
                private _isSignCorrect = (_transitionTarget > 0 && {_nativeLaunchSpeed > 0})
                    || {_transitionTarget < 0 && {_nativeLaunchSpeed < 0}};
                if (
                    finite _nativeLaunchSpeed
                    && {_isSignCorrect}
                    && {abs _nativeLaunchSpeed <= abs _launchVelocity}
                ) then {
                    _launchSpeed = _nativeLaunchSpeed;
                    _launchSource = "native";
                    _launchDetail = _nativeAdvice # 5;
                };
            };

            _modelVelocity = velocityModelSpace _vehicle;
            _modelVelocity set [1, _launchSpeed];
            _vehicle setVelocityModelSpace _modelVelocity;
            [
                "NEUTRAL",
                _transitionTarget,
                0,
                _launchSource,
                _launchMode,
                _launchSpeed,
                _launchDetail
            ] call _logDriverAssist;
        };
    } else {
        [_vehicle, "SERVICE_BRAKE"] call _setState;
        _vehicle disableBrakes false;

        private _absApplied = [
            _vehicle,
            _transitionTarget,
            true,
            _deltaTime
        ] call FIXICS_fnc_applyABSBraking;
        _modelVelocity = velocityModelSpace _vehicle;
        _longitudinalSpeed = _modelVelocity # 1;

        if (!_absApplied) then {
            private _fallbackBrake = (missionNamespace getVariable ["FIXICS_absBrakeStrength", 0.45])
                * (1 - (missionNamespace getVariable ["FIXICS_absReleaseBias", 0.35]))
                * (_deltaTime / 0.25);
            if (_longitudinalSpeed > 0) then {
                _longitudinalSpeed = (_longitudinalSpeed - _fallbackBrake) max 0;
            } else {
                _longitudinalSpeed = (_longitudinalSpeed + _fallbackBrake) min 0;
            };
            _modelVelocity set [1, _longitudinalSpeed];
            _vehicle setVelocityModelSpace _modelVelocity;
        };

        _modelVelocity = velocityModelSpace _vehicle;
        _longitudinalSpeed = _modelVelocity # 1;
        if ((abs _longitudinalSpeed) <= _directionThreshold) then {
            _modelVelocity set [1, 0];
            _vehicle setVelocityModelSpace _modelVelocity;

            _neutralUntil = _now + _neutralPulseSeconds;
            _vehicle setVariable ["FIXICS_directionTransitionNeutralUntil", _neutralUntil, false];
        };
    };

    true
};

if (_isCombinedBrake) exitWith {
    [_vehicle, "SERVICE_BRAKE"] call _setState;
    _vehicle disableBrakes false;

    private _absApplied = [_vehicle, 0, true, _deltaTime] call FIXICS_fnc_applyABSBraking;
    _modelVelocity = velocityModelSpace _vehicle;
    _longitudinalSpeed = _modelVelocity # 1;

    if (!_absApplied) then {
        private _fallbackBrake = (missionNamespace getVariable ["FIXICS_absBrakeStrength", 0.45])
            * (1 - (missionNamespace getVariable ["FIXICS_absReleaseBias", 0.35]))
            * (_deltaTime / 0.25);
        if (_longitudinalSpeed > 0) then {
            _longitudinalSpeed = (_longitudinalSpeed - _fallbackBrake) max 0;
        } else {
            _longitudinalSpeed = (_longitudinalSpeed + _fallbackBrake) min 0;
        };
        _modelVelocity set [1, _longitudinalSpeed];
        _vehicle setVelocityModelSpace _modelVelocity;
    };

    true
};

if (_requestedDirection != 0) exitWith {
    private _state = ["REVERSE", "DRIVE"] select (_requestedDirection > 0);
    [_vehicle, _state] call _setState;
    _vehicle disableBrakes true;

    [_vehicle, _deltaTime] call FIXICS_fnc_applySlopeRollback;
    true
};

[_vehicle, "COAST"] call _setState;
if ([_vehicle] call FIXICS_fnc_shouldVehicleRoll) then {
    _vehicle disableBrakes true;
    [_vehicle, _deltaTime] call FIXICS_fnc_applySlopeRollback;
} else {
    _vehicle disableBrakes false;
};

true
