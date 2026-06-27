/*
 * FIXICS_fnc_getVehicleProfile
 *
 * Resolves effective per-vehicle FIXICS settings for a local vehicle.
 *
 * Arguments:
 *   0: Vehicle <OBJECT>
 *   1: Force refresh <BOOL> (default: false)
 *
 * Return: <HASHMAP>
 */

params [
    ["_vehicle", objNull, [objNull]],
    ["_forceRefresh", false, [true]]
];

private _defaults = [
    ["FIXICS_absEnabled", true],
    ["FIXICS_absBrakeStrength", 0.45],
    ["FIXICS_absReleaseBias", 0.35],
    ["FIXICS_absLowSpeedCutoffKmh", 3],
    ["FIXICS_absSlopeCompensation", 0.25],
    ["FIXICS_slopeRollbackMinimumSlope", 0.035],
    ["FIXICS_slopeRollbackMaxSpeed", 2.2],
    ["FIXICS_slopeRollbackAcceleration", 0.55],
    ["FIXICS_slopeCoastBreakawayVelocity", 0.18],
    ["FIXICS_slopeDriveAcceleration", 0.22],
    ["FIXICS_slopeDriveMaxSpeedKmh", 120],
    ["FIXICS_stationaryBrakeBypassSpeedKmh", 1],
    ["FIXICS_directionChangeThresholdKmh", 2],
    ["FIXICS_directionLaunchVelocity", 0.35],
    ["FIXICS_directionNeutralPulseSeconds", 0.08],
    ["FIXICS_driverControllerInterval", 0.03],
    ["FIXICS_stabilityPreset", 0],
    ["FIXICS_stabilityAssistMode", 0],
    ["FIXICS_stabilityActivationSpeedKmh", 35],
    ["FIXICS_stabilitySlipThreshold", 0.12],
    ["FIXICS_stabilityYawStrength", 0.22],
    ["FIXICS_stabilityLateralStrength", 0.12],
    ["FIXICS_stabilityCountersteerStrength", 0.08],
    ["FIXICS_stabilityMaximumCorrection", 0.12],
    ["FIXICS_rollStabilityPreset", 0],
    ["FIXICS_rollStabilityEnabled", true],
    ["FIXICS_rollActivationBankDeg", 18],
    ["FIXICS_rollActivationRateDeg", 45],
    ["FIXICS_rollStrength", 0.08],
    ["FIXICS_rollMaximumCorrection", 0.08],
    ["FIXICS_rollAirborneGraceSeconds", 0.35],
    ["FIXICS_swayBarEnabled", true],
    ["FIXICS_frontSwayBarEnabled", true],
    ["FIXICS_frontSwayBarStrength", 0.5],
    ["FIXICS_rearSwayBarEnabled", true],
    ["FIXICS_rearSwayBarStrength", 0.5],
    ["FIXICS_controlledSlipEnabled", true],
    ["FIXICS_controlledSlipActivationSpeedKmh", 55],
    ["FIXICS_controlledSlipSteeringThreshold", 0.65],
    ["FIXICS_controlledSlipStrength", 0.16],
    ["FIXICS_controlledSlipMaximumRelease", 0.22],
    ["FIXICS_controlledSlipTerrainInfluence", true],
    ["FIXICS_terrainTireEnabled", true],
    ["FIXICS_tirePressureEnabled", true],
    ["FIXICS_tireDeflationRate", 0.025],
    ["FIXICS_tireMinimumMobility", 0.35],
    ["FIXICS_tireDragStrength", 0.35],
    ["FIXICS_tireSteeringPenalty", 0.30],
    ["FIXICS_runtimeAssistTerrainInfluenceEnabled", true],
    ["FIXICS_runtimeAssistTerrainInfluenceStrength", 0.25],
    ["FIXICS_runtimeAssistBrakingSlopeRetention", 0.35],
    ["FIXICS_runtimeAssistMassDampingStrength", 0.15],
    ["FIXICS_runtimeAssistMaximumComposedCorrection", 0.25]
];

if (isNull _vehicle) exitWith {
    createHashMapFromArray [
        ["vehicleProfileId", "DEFAULT"],
        ["vehicleProfileSource", "global"],
        ["vehicleProfileOverridesApplied", []],
        ["settings", createHashMap]
    ]
};

private _cached = _vehicle getVariable ["FIXICS_vehicleProfile", createHashMap];
if (!_forceRefresh && {_cached isEqualType createHashMap} && {count _cached > 0}) exitWith {
    _cached
};

private _settings = createHashMap;
{
    _x params ["_key", "_default"];
    _settings set [_key, missionNamespace getVariable [_key, _default]];
} forEach _defaults;

private _allowedKeys = _defaults apply {_x # 0};
private _profileId = "DEFAULT";
private _profileSource = "global";
private _overridesApplied = [];
private _debug = missionNamespace getVariable ["FIXICS_vehicleProfileDebugLogging", false];

private _applyPreset = {
    params ["_presetName", "_source"];

    private _preset = toUpper _presetName;
    if (_preset in ["", "DEFAULT"]) exitWith {};
    _profileId = _preset;
    _profileSource = _source;

    switch (_preset) do {
        case "LIGHT_OFFROAD": {
            {
                _x params ["_key", "_value"];
                _settings set [_key, _value];
                _overridesApplied pushBackUnique _key;
            } forEach [
                ["FIXICS_controlledSlipActivationSpeedKmh", 45],
                ["FIXICS_controlledSlipStrength", 0.18],
                ["FIXICS_controlledSlipMaximumRelease", 0.26],
                ["FIXICS_runtimeAssistTerrainInfluenceStrength", 0.35],
                ["FIXICS_tireDragStrength", 0.4]
            ];
        };
        case "MRAP": {
            {
                _x params ["_key", "_value"];
                _settings set [_key, _value];
                _overridesApplied pushBackUnique _key;
            } forEach [
                ["FIXICS_absBrakeStrength", 0.38],
                ["FIXICS_stabilityActivationSpeedKmh", 30],
                ["FIXICS_stabilityLateralStrength", 0.16],
                ["FIXICS_rollStrength", 0.12],
                ["FIXICS_runtimeAssistMassDampingStrength", 0.25],
                ["FIXICS_controlledSlipStrength", 0.10]
            ];
        };
        case "TRUCK": {
            {
                _x params ["_key", "_value"];
                _settings set [_key, _value];
                _overridesApplied pushBackUnique _key;
            } forEach [
                ["FIXICS_absBrakeStrength", 0.32],
                ["FIXICS_absReleaseBias", 0.42],
                ["FIXICS_stabilityActivationSpeedKmh", 28],
                ["FIXICS_rollStrength", 0.10],
                ["FIXICS_runtimeAssistMassDampingStrength", 0.30],
                ["FIXICS_directionNeutralPulseSeconds", 0.11]
            ];
        };
        case "TRACKED": {
            _overridesApplied pushBackUnique "TRACKED_RESERVED";
        };
        case "CUSTOM": {};
        default {
            if (_debug) then {
                diag_log format ["[FIXICS][VehicleProfile] Unknown preset '%1' for %2.", _presetName, typeOf _vehicle];
            };
        };
    };
};

private _parseEntries = {
    params ["_text", "_sourceName"];

    if !(_text isEqualType "") exitWith {[]};
    if (_text == "") exitWith {[]};

    private _entries = [];
    private _compiled = call compile _text;
    if (_compiled isEqualType []) then {
        _entries = _compiled;
    } else {
        if (_debug) then {
            diag_log format ["[FIXICS][VehicleProfile] %1 profile text did not compile to an array.", _sourceName];
        };
    };

    _entries
};

private _exactEntries = [
    missionNamespace getVariable ["FIXICS_vehicleProfileExactOverrides", "[]"],
    "exact"
] call _parseEntries;
private _parentEntries = [
    missionNamespace getVariable ["FIXICS_vehicleProfileParentOverrides", "[]"],
    "parent"
] call _parseEntries;

private _type = typeOf _vehicle;
private _config = configOf _vehicle;

private _matchesParent = {
    params ["_className"];

    if !(_className isEqualType "") exitWith {false};
    if (_className == _type) exitWith {false};
    _vehicle isKindOf _className
};

private _applyEntry = {
    params ["_entry", "_source"];

    if !(_entry isEqualType []) exitWith {false};
    if ((count _entry) < 2) exitWith {false};

    private _className = _entry param [0, "", [""]];
    private _presetName = _entry param [1, "CUSTOM", [""]];
    private _overrides = _entry param [2, [], [[]]];

    [_presetName, _source] call _applyPreset;
    {
        if (_x isEqualType [] && {(count _x) >= 2}) then {
            private _key = _x # 0;
            private _value = _x # 1;
            if (_key in _allowedKeys) then {
                _settings set [_key, _value];
                _overridesApplied pushBackUnique _key;
                _profileSource = _source;
                if (_profileId == "DEFAULT") then {
                    _profileId = "CUSTOM";
                };
            } else {
                if (_debug) then {
                    diag_log format ["[FIXICS][VehicleProfile] Ignored unsupported key '%1' for %2.", _key, _className];
                };
            };
        };
    } forEach _overrides;

    true
};

{
    private _entry = _x;
    if (_entry isEqualType [] && {[_entry param [0, "", [""]]] call _matchesParent}) then {
        [_entry, "parentClass"] call _applyEntry;
    };
} forEach _parentEntries;

{
    private _entry = _x;
    if (_entry isEqualType [] && {(_entry param [0, "", [""]]) == _type}) then {
        [_entry, "exactClass"] call _applyEntry;
    };
} forEach _exactEntries;

private _profile = createHashMapFromArray [
    ["vehicleProfileId", _profileId],
    ["vehicleProfileSource", _profileSource],
    ["vehicleProfileOverridesApplied", _overridesApplied],
    ["vehicleClass", _type],
    ["vehicleParentClass", configName inheritsFrom _config],
    ["settings", _settings]
];

_vehicle setVariable ["FIXICS_vehicleProfile", _profile, false];
_profile
