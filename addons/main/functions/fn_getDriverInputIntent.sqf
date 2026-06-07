/*
 * FIXICS_fnc_getDriverInputIntent
 *
 * Normalizes Arma's forward action variants and reverse/brake action.
 *
 * Arguments:
 *   None
 *
 * Return:
 *   0: Forward input active <BOOL>
 *   1: Reverse/brake input active <BOOL>
 *   2: Requested direction: -1 reverse, 0 neutral/combined, 1 forward <NUMBER>
 * Locality: client with interface
 *
 * Example:
 *   (call FIXICS_fnc_getDriverInputIntent) params ["_forward", "_back", "_direction"];
 */

if (!hasInterface) exitWith {
    [false, false, 0]
};

private _hasForwardInput = (inputAction "CarForward") > 0
    || {(inputAction "CarFastForward") > 0}
    || {(inputAction "CarSlowForward") > 0};
private _hasBackInput = (inputAction "CarBack") > 0;
private _requestedDirection = 0;

if (_hasForwardInput && {!_hasBackInput}) then {
    _requestedDirection = 1;
};
if (_hasBackInput && {!_hasForwardInput}) then {
    _requestedDirection = -1;
};

[_hasForwardInput, _hasBackInput, _requestedDirection]
