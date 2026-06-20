/*
 * FIXICS_fnc_startSteeringDiagnostics
 *
 * Records a bounded stream of read-only steering evidence to the RPT.
 *
 * Arguments:
 *   0: Vehicle to observe <OBJECT>
 *   1: Capture duration in seconds <NUMBER> (default: 30, range: 5-120)
 *   2: Sample interval in seconds <NUMBER> (default: 0.1, range: 0.05-1)
 *
 * Return: <BOOL> true when the capture was started
 * Locality: client with interface
 *
 * Example:
 *   [vehicle player, 30, 0.1] call FIXICS_fnc_startSteeringDiagnostics;
 */

params [
    ["_vehicle", objNull, [objNull]],
    ["_duration", 30, [0]],
    ["_interval", 0.1, [0]]
];

if (!hasInterface || {isNull _vehicle}) exitWith {
    false
};

if (missionNamespace getVariable ["FIXICS_steeringDiagnosticsRunning", false]) exitWith {
    diag_log "[FIXICS] Steering diagnostics already running.";
    false
};

_duration = (_duration max 5) min 120;
_interval = (_interval max 0.05) min 1;
missionNamespace setVariable ["FIXICS_steeringDiagnosticsRunning", true];

[_vehicle, _duration, _interval] spawn {
    params ["_vehicle", "_duration", "_interval"];

    private _startedAt = diag_tickTime;
    private _deadline = _startedAt + _duration;
    private _previousHeading = getDir _vehicle;

    diag_log format [
        "[FIXICS] Steering diagnostics started: vehicle=%1 duration=%2 interval=%3",
        typeOf _vehicle,
        _duration,
        _interval
    ];

    while {
        !isNull _vehicle
        && {diag_tickTime < _deadline}
        && {missionNamespace getVariable ["FIXICS_steeringDiagnosticsRunning", false]}
    } do {
        private _leftInput = inputAction "CarLeft";
        private _rightInput = inputAction "CarRight";
        private _heading = getDir _vehicle;
        private _headingDelta = ((_heading - _previousHeading + 540) mod 360) - 180;

        diag_log format [
            "[FIXICS] Steering sample: t=%1 vehicle=%2 input=[%3,%4,%5] speedKmh=%6 velocityModelSpace=%7 heading=%8 headingDelta=%9 surface=%10",
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

    missionNamespace setVariable ["FIXICS_steeringDiagnosticsRunning", false];
    diag_log format ["[FIXICS] Steering diagnostics stopped: vehicle=%1", typeOf _vehicle];
};

true
