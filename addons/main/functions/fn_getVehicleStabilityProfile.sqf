/*
 * Arguments:
 *   0: Vehicle <OBJECT>
 * Return:
 *   [supported, activationSpeedKmh, slipThreshold, yawStrength,
 *    lateralStrength, countersteerStrength, maximumCorrection] <ARRAY>
 */
params [["_vehicle", objNull, [objNull]]];

private _unsupportedProfile = [false, 0, 0, 0, 0, 0, 0];
if (isNull _vehicle) exitWith {
    _unsupportedProfile
};

private _supportedClasses = [
    "EMP_Polaris_DAGOR",
    "B_LSV_01_unarmed_F",
    "LOP_IA_Offroad",
    "B_G_Offroad_01_F",
    "rhsusf_m1151_usarmy_d"
];
if !((typeOf _vehicle) in _supportedClasses) exitWith {
    _unsupportedProfile
};

private _presetIndex = missionNamespace getVariable ["FIXICS_stabilityPreset", 0];
private _vehicleProfile = [_vehicle] call FIXICS_fnc_getVehicleProfile;
private _profileSettings = _vehicleProfile getOrDefault ["settings", createHashMap];
private _getProfileSetting = {
    params ["_key", "_default"];

    _profileSettings getOrDefault [_key, missionNamespace getVariable [_key, _default]]
};

_presetIndex = ["FIXICS_stabilityPreset", _presetIndex] call _getProfileSetting;
private _presetName = ["REALISTIC_STABLE", "RALLY", "CUSTOM"] param [
    _presetIndex,
    "REALISTIC_STABLE"
];

switch (_presetName) do {
    case "RALLY": {
        [true, 50, 0.2, 0.12, 0.05, 0.04, 0.08]
    };
    case "CUSTOM": {
        private _customActivationSpeed = ["FIXICS_stabilityActivationSpeedKmh", 35] call _getProfileSetting;
        private _customSlipThreshold = ["FIXICS_stabilitySlipThreshold", 0.12] call _getProfileSetting;
        private _customYawStrength = ["FIXICS_stabilityYawStrength", 0.22] call _getProfileSetting;
        private _customLateralStrength = ["FIXICS_stabilityLateralStrength", 0.12] call _getProfileSetting;
        private _customCountersteerStrength = ["FIXICS_stabilityCountersteerStrength", 0.08] call _getProfileSetting;
        private _customMaximumCorrection = ["FIXICS_stabilityMaximumCorrection", 0.12] call _getProfileSetting;

        private _activationSpeed = (_customActivationSpeed max 10) min 160;
        private _slipThreshold = (_customSlipThreshold max 0.05) min 0.8;
        private _yawStrength = (_customYawStrength max 0) min 1;
        private _lateralStrength = (_customLateralStrength max 0) min 1;
        private _countersteerStrength = (_customCountersteerStrength max 0) min 0.5;
        private _maximumCorrection = (_customMaximumCorrection max 0.01) min 0.5;

        [
            true,
            _activationSpeed,
            _slipThreshold,
            _yawStrength,
            _lateralStrength,
            _countersteerStrength,
            _maximumCorrection
        ]
    };
    default {
        [true, 35, 0.12, 0.22, 0.12, 0.08, 0.12]
    };
};
