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
if (hasInterface) then {
    _leftInput = inputAction "CarLeft";
    _rightInput = inputAction "CarRight";
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
    ["steeringInput", _leftInput, _rightInput, _rightInput - _leftInput],
    ["speedKmh", speed _vehicle],
    ["velocityModelSpace", velocityModelSpace _vehicle],
    ["heading", getDir _vehicle],
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
        private _previousHeading = getDir _vehicle;

        while {
            !isNull _vehicle
            && {diag_tickTime < _deadline}
            && {missionNamespace getVariable ["FIXICS_handlingConfigLogRunning", false]}
        } do {
            private _leftInput = inputAction "CarLeft";
            private _rightInput = inputAction "CarRight";
            private _heading = getDir _vehicle;
            private _headingDelta = ((_heading - _previousHeading + 540) mod 360) - 180;

            diag_log format [
                "[FIXICS] Vehicle handling sample: t=%1 vehicle=%2 input=[%3,%4,%5] speedKmh=%6 velocityModelSpace=%7 heading=%8 headingDelta=%9 surface=%10",
                diag_tickTime - _startedAt,
                typeOf _vehicle,
                _leftInput,
                _rightInput,
                _rightInput - _leftInput,
                speed _vehicle,
                velocityModelSpace _vehicle,
                _heading,
                _headingDelta,
                surfaceType (getPosWorld _vehicle)
            ];

            _previousHeading = _heading;
            sleep _interval;
        };

        missionNamespace setVariable ["FIXICS_handlingConfigLogRunning", false];
        diag_log format ["[FIXICS] Continuous vehicle handling evidence stopped: vehicle=%1", typeOf _vehicle];
    };
};

true
