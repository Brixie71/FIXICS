/*
 * FIXICS_fnc_logVehicleHandlingConfig
 *
 * Logs selected vehicle handling config and runtime values for SQA evidence.
 *
 * Arguments:
 *   0: Vehicle to inspect <OBJECT>
 *   1: Runtime capture duration in seconds <NUMBER> (default: 0, range: 0-180)
 *   2: Runtime sample interval in seconds <NUMBER> (default: 0.1, range: 0.05-1)
 *
 * Return: <BOOL> true when evidence was logged or capture was started
 * Locality: any
 *
 * Example:
 *   [vehicle player] call FIXICS_fnc_logVehicleHandlingConfig;
 *   [vehicle player, 180, 0.1] call FIXICS_fnc_logVehicleHandlingConfig;
 */

params [
    ["_vehicle", objNull, [objNull]],
    ["_duration", 0, [0]],
    ["_interval", 0.1, [0]]
];

if (isNull _vehicle) exitWith {
    diag_log "[FIXICS_fnc_logVehicleHandlingConfig] ERROR: null vehicle.";
    false
};

private _config = configOf _vehicle;
if (!isClass _config) exitWith {
    diag_log format ["[FIXICS_fnc_logVehicleHandlingConfig] ERROR: missing CfgVehicles class for %1.", typeOf _vehicle];
    false
};

private _steeringConfig = _config >> "PlayerSteeringCoefficients";
private _steeringNames = [
    "turnIncreaseConst",
    "turnIncreaseLinear",
    "turnIncreaseTime",
    "turnDecreaseConst",
    "turnDecreaseLinear",
    "turnDecreaseTime",
    "maxTurnHundred"
];
private _steeringValues = _steeringNames apply {
    private _entry = _steeringConfig >> _x;

    // Preserve whether the inherited entry exists so a missing value is not
    // mistaken for a configured zero returned by getNumber.
    [_x, isNumber _entry, getNumber _entry]
};

private _leftInput = 0;
private _rightInput = 0;
private _forwardInput = 0;
private _fastForwardInput = 0;
private _slowForwardInput = 0;
private _backInput = 0;
private _handbrakeInput = 0;
if (hasInterface) then {
    _leftInput = inputAction "CarLeft";
    _rightInput = inputAction "CarRight";
    _forwardInput = inputAction "CarForward";
    _fastForwardInput = inputAction "CarFastForward";
    _slowForwardInput = inputAction "CarSlowForward";
    _backInput = inputAction "CarBack";
    _handbrakeInput = inputAction "CarHandBrake";
};

private _pitchBank = _vehicle call BIS_fnc_getPitchBank;
private _surfacePosition = getPosASL _vehicle;
private _terrainNormal = surfaceNormal _surfacePosition;
private _terrainNormalZ = ((_terrainNormal # 2) max -1) min 1;
private _runtimeAssistDecision = _vehicle getVariable ["FIXICS_runtimeAssistLastDecision", createHashMap];
private _hitPointDamage = getAllHitPointsDamage _vehicle;
private _wheelHitpointDamage = [];
if ((count _hitPointDamage) >= 3) then {
    private _hitPointNames = _hitPointDamage # 0;
    private _hitPointValues = _hitPointDamage # 2;
    for "_index" from 0 to ((count _hitPointNames) - 1) do {
        private _hitPointName = _hitPointNames # _index;
        if (((toLower _hitPointName) find "wheel") >= 0) then {
            _wheelHitpointDamage pushBack [_hitPointName, _hitPointValues # _index];
        };
    };
};

private _values = [
    ["typeOf", typeOf _vehicle],
    ["simulation", getText (_config >> "simulation")],
    ["brakeIdleSpeed", getNumber (_config >> "brakeIdleSpeed")],
    ["dampingRateZeroThrottleClutchEngaged", getNumber (_config >> "dampingRateZeroThrottleClutchEngaged")],
    ["dampingRateZeroThrottleClutchDisengaged", getNumber (_config >> "dampingRateZeroThrottleClutchDisengaged")],
    ["changeGearType", getText (_config >> "changeGearType")],
    ["changeGearMinEffectivity", getArray (_config >> "changeGearMinEffectivity")],
    ["latency", getNumber (_config >> "latency")],
    ["switchTime", getNumber (_config >> "switchTime")],
    ["antiRollbarForceCoef", getNumber (_config >> "antiRollbarForceCoef")],
    ["antiRollbarSpeedMin", getNumber (_config >> "antiRollbarSpeedMin")],
    ["antiRollbarSpeedMax", getNumber (_config >> "antiRollbarSpeedMax")],
    ["PlayerSteeringCoefficients", isClass _steeringConfig, _steeringValues],
    ["controlInput", _forwardInput, _fastForwardInput, _slowForwardInput, _backInput, _handbrakeInput, _leftInput, _rightInput, _rightInput - _leftInput],
    ["speedKmh", speed _vehicle],
    ["velocityWorld", velocity _vehicle],
    ["velocityModelSpace", velocityModelSpace _vehicle],
    ["positionWorld", getPosWorld _vehicle],
    ["positionASL", _surfacePosition],
    ["heading", getDir _vehicle],
    ["pitch", _pitchBank # 0],
    ["bank", _pitchBank # 1],
    ["vectorDir", vectorDir _vehicle],
    ["vectorUp", vectorUp _vehicle],
    ["terrainNormal", _terrainNormal],
    ["slopeFactor", sin (acos _terrainNormalZ)],
    ["isTouchingGround", isTouchingGround _vehicle],
    ["wheelHitpointDamageProxy", _wheelHitpointDamage],
    ["FIXICS_driverState", _vehicle getVariable ["FIXICS_driverState", "idle"]],
    ["FIXICS_handbrakeEnabled", _vehicle getVariable ["FIXICS_handbrakeEnabled", false]],
    ["FIXICS_absEnabled", missionNamespace getVariable ["FIXICS_absEnabled", true]],
    ["FIXICS_stabilityAssistMode", missionNamespace getVariable ["FIXICS_stabilityAssistMode", 0]],
    ["FIXICS_runtimeAssistLastDecision", _runtimeAssistDecision],
    ["runtimeAssistPriorityWinner", _runtimeAssistDecision getOrDefault ["priorityWinner", "none"]],
    ["runtimeAssistTerrainMultiplier", _runtimeAssistDecision getOrDefault ["terrainMultiplier", 1]],
    ["runtimeAssistMassMultiplier", _runtimeAssistDecision getOrDefault ["massMultiplier", 1]],
    ["runtimeAssistSuppressedAssists", _runtimeAssistDecision getOrDefault ["suppressedAssists", []]],
    ["runtimeAssistFinalCorrection", _runtimeAssistDecision getOrDefault ["finalCorrection", 0]],
    ["surface", surfaceType (getPosWorld _vehicle)]
];

diag_log format ["[FIXICS] Vehicle handling evidence: %1", _values];

if (_duration > 0) then {
    if (missionNamespace getVariable ["FIXICS_handlingConfigLogRunning", false]) exitWith {
        diag_log "[FIXICS] Continuous vehicle handling evidence already running.";
        false
    };

    _duration = (_duration max 5) min 180;
    _interval = (_interval max 0.05) min 1;
    missionNamespace setVariable ["FIXICS_handlingConfigLogRunning", true];

    [_vehicle, _duration, _interval] spawn {
        params ["_vehicle", "_duration", "_interval"];

        private _startedAt = diag_tickTime;
        private _deadline = _startedAt + _duration;
        private _previousTime = _startedAt;
        private _previousHeading = getDir _vehicle;
        private _previousPitchBank = _vehicle call BIS_fnc_getPitchBank;
        private _previousPitch = _previousPitchBank # 0;
        private _previousBank = _previousPitchBank # 1;

        while {
            !isNull _vehicle
            && {diag_tickTime < _deadline}
            && {missionNamespace getVariable ["FIXICS_handlingConfigLogRunning", false]}
        } do {
            private _leftInput = inputAction "CarLeft";
            private _rightInput = inputAction "CarRight";
            private _forwardInput = inputAction "CarForward";
            private _fastForwardInput = inputAction "CarFastForward";
            private _slowForwardInput = inputAction "CarSlowForward";
            private _backInput = inputAction "CarBack";
            private _handbrakeInput = inputAction "CarHandBrake";
            private _now = diag_tickTime;
            private _elapsed = (_now - _previousTime) max 0.001;
            private _heading = getDir _vehicle;
            private _pitchBank = _vehicle call BIS_fnc_getPitchBank;
            private _pitch = _pitchBank # 0;
            private _bank = _pitchBank # 1;
            private _headingDelta = ((_heading - _previousHeading + 540) mod 360) - 180;
            private _yawRate = _headingDelta / _elapsed;
            private _pitchRate = (_pitch - _previousPitch) / _elapsed;
            private _bankRate = (_bank - _previousBank) / _elapsed;
            private _surfacePosition = getPosASL _vehicle;
            private _terrainNormal = surfaceNormal _surfacePosition;
            private _terrainNormalZ = ((_terrainNormal # 2) max -1) min 1;
            private _runtimeAssistDecision = _vehicle getVariable ["FIXICS_runtimeAssistLastDecision", createHashMap];
            private _runtimeAssistPriorityWinner = _runtimeAssistDecision getOrDefault ["priorityWinner", "none"];
            private _runtimeAssistTerrainMultiplier = _runtimeAssistDecision getOrDefault ["terrainMultiplier", 1];
            private _runtimeAssistMassMultiplier = _runtimeAssistDecision getOrDefault ["massMultiplier", 1];
            private _runtimeAssistSuppressedAssists = _runtimeAssistDecision getOrDefault ["suppressedAssists", []];
            private _runtimeAssistFinalCorrection = _runtimeAssistDecision getOrDefault ["finalCorrection", 0];
            private _hitPointDamage = getAllHitPointsDamage _vehicle;
            private _wheelHitpointDamage = [];
            if ((count _hitPointDamage) >= 3) then {
                private _hitPointNames = _hitPointDamage # 0;
                private _hitPointValues = _hitPointDamage # 2;
                for "_index" from 0 to ((count _hitPointNames) - 1) do {
                    private _hitPointName = _hitPointNames # _index;
                    if (((toLower _hitPointName) find "wheel") >= 0) then {
                        _wheelHitpointDamage pushBack [_hitPointName, _hitPointValues # _index];
                    };
                };
            };

            diag_log format [
                "[FIXICS] Vehicle handling sample: t=%1 vehicle=%2 input=[drive=%3,fast=%4,slow=%5,reverse=%6,engineHandbrake=%7,left=%8,right=%9,steerNet=%10] speedKmh=%11 velocityWorld=%12 velocityModelSpace=%13 positionWorld=%14 positionASL=%15 heading=%16 headingDelta=%17 yawRate=%18 pitch=%19 pitchRate=%20 bank=%21 bankRate=%22 vectorDir=%23 vectorUp=%24 terrainNormal=%25 slopeFactor=%26 isTouchingGround=%27 wheelHitpointDamageProxy=%28 FIXICS_driverState=%29 FIXICS_handbrakeEnabled=%30 FIXICS_absEnabled=%31 FIXICS_stabilityAssistMode=%32 surface=%33 runtimeAssistPriorityWinner=%34 runtimeAssistTerrainMultiplier=%35 runtimeAssistMassMultiplier=%36 runtimeAssistSuppressedAssists=%37 runtimeAssistFinalCorrection=%38",
                _now - _startedAt,
                typeOf _vehicle,
                _forwardInput,
                _fastForwardInput,
                _slowForwardInput,
                _backInput,
                _handbrakeInput,
                _leftInput,
                _rightInput,
                _rightInput - _leftInput,
                speed _vehicle,
                velocity _vehicle,
                velocityModelSpace _vehicle,
                getPosWorld _vehicle,
                _surfacePosition,
                _heading,
                _headingDelta,
                _yawRate,
                _pitch,
                _pitchRate,
                _bank,
                _bankRate,
                vectorDir _vehicle,
                vectorUp _vehicle,
                _terrainNormal,
                sin (acos _terrainNormalZ),
                isTouchingGround _vehicle,
                _wheelHitpointDamage,
                _vehicle getVariable ["FIXICS_driverState", "idle"],
                _vehicle getVariable ["FIXICS_handbrakeEnabled", false],
                missionNamespace getVariable ["FIXICS_absEnabled", true],
                missionNamespace getVariable ["FIXICS_stabilityAssistMode", 0],
                surfaceType (getPosWorld _vehicle),
                _runtimeAssistPriorityWinner,
                _runtimeAssistTerrainMultiplier,
                _runtimeAssistMassMultiplier,
                _runtimeAssistSuppressedAssists,
                _runtimeAssistFinalCorrection
            ];

            diag_log format [
                "[FIXICS][RuntimeAssistSample] t=%1 vehicle=%2 state=%3 speedKmh=%4 surface=%5 priority=%6 terrain=%7 mass=%8 suppressed=%9 finalCorrection=%10 bank=%11 bankRate=%12 yawRate=%13 grounded=%14",
                _now - _startedAt,
                typeOf _vehicle,
                _vehicle getVariable ["FIXICS_driverState", "idle"],
                speed _vehicle,
                surfaceType (getPosWorld _vehicle),
                _runtimeAssistPriorityWinner,
                _runtimeAssistTerrainMultiplier,
                _runtimeAssistMassMultiplier,
                _runtimeAssistSuppressedAssists,
                _runtimeAssistFinalCorrection,
                _bank,
                _bankRate,
                _yawRate,
                isTouchingGround _vehicle
            ];

            _previousTime = _now;
            _previousHeading = _heading;
            _previousPitch = _pitch;
            _previousBank = _bank;
            sleep _interval;
        };

        missionNamespace setVariable ["FIXICS_handlingConfigLogRunning", false];
        diag_log format ["[FIXICS] Continuous vehicle handling evidence stopped: vehicle=%1", typeOf _vehicle];
    };
};

true
