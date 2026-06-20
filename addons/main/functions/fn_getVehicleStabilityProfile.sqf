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
    "B_G_Offroad_01_F"
];
if !((typeOf _vehicle) in _supportedClasses) exitWith {
    _unsupportedProfile
};

private _presetIndex = missionNamespace getVariable ["FIXICS_stabilityPreset", 0];
private _presetName = ["REALISTIC_STABLE", "RALLY", "CUSTOM"] param [
    _presetIndex,
    "REALISTIC_STABLE"
];

switch (_presetName) do {
    case "RALLY": {
        [true, 50, 0.2, 0.12, 0.05, 0.04, 0.08]
    };
    case "CUSTOM": {
        private _customActivationSpeed = missionNamespace getVariable [
            "FIXICS_stabilityActivationSpeedKmh",
            35
        ];
        private _customSlipThreshold = missionNamespace getVariable [
            "FIXICS_stabilitySlipThreshold",
            0.12
        ];
        private _customYawStrength = missionNamespace getVariable [
            "FIXICS_stabilityYawStrength",
            0.22
        ];
        private _customLateralStrength = missionNamespace getVariable [
            "FIXICS_stabilityLateralStrength",
            0.12
        ];
        private _customCountersteerStrength = missionNamespace getVariable [
            "FIXICS_stabilityCountersteerStrength",
            0.08
        ];
        private _customMaximumCorrection = missionNamespace getVariable [
            "FIXICS_stabilityMaximumCorrection",
            0.12
        ];

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
