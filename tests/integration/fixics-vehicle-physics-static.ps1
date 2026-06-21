$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$Failures = New-Object System.Collections.Generic.List[string]

function Add-Failure {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $Failures.Add($Message)
}

function Assert-FileExists {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot $Path))) {
        Add-Failure "Missing expected file: $Path"
    }
}

function Assert-Contains {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [string]$Pattern,

        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    if ($Content -notmatch $Pattern) {
        Add-Failure $Message
    }
}

$ConfigPath = Join-Path $RepoRoot 'addons\main\config.cpp'
$StringtablePath = Join-Path $RepoRoot 'addons\main\stringtable.xml'
$InitPath = Join-Path $RepoRoot 'addons\main\functions\fn_init.sqf'
$MissionPath = Join-Path $RepoRoot 'addons\main\missions\HelloWorld.VR\mission.sqm'

$Config = Get-Content -Raw -LiteralPath $ConfigPath
$Stringtable = Get-Content -Raw -LiteralPath $StringtablePath
$Init = Get-Content -Raw -LiteralPath $InitPath
$Mission = Get-Content -Raw -LiteralPath $MissionPath

Assert-Contains $Config 'tag\s*=\s*"FIXICS";' 'CfgFunctions tag must be FIXICS.'
Assert-Contains $Config 'requiredAddons\[\]\s*=\s*\{[^}]*"ace_interact_menu"[^}]*\};' 'ACE interaction menu must be a required addon.'
Assert-Contains $Config 'requiredAddons\[\]\s*=\s*\{[^}]*"cba_settings"[^}]*\};' 'CBA settings must be a required addon.'
Assert-Contains $Config 'requiredAddons\[\]\s*=\s*\{[^}]*"cba_common"[^}]*\};' 'CBA common must be a required addon for the driver controller PFH.'
if ($Config -match '"A3_Soft_F"|\"A3_Armor_F\"') {
    Add-Failure 'Failed config-class experiment must not keep A3_Soft_F/A3_Armor_F load-order dependencies.'
}

@(
    'addons\main\functions\fn_registerSettings.sqf',
    'addons\main\functions\fn_registerAceInteractions.sqf',
    'addons\main\functions\fn_setVehicleHandbrake.sqf',
    'addons\main\functions\fn_shouldVehicleRoll.sqf',
    'addons\main\functions\fn_monitorVehicleAutobrake.sqf',
    'addons\main\functions\fn_applySlopeRollback.sqf',
    'addons\main\functions\fn_applyABSBraking.sqf',
    'addons\main\functions\fn_applyHandbrakeLock.sqf',
    'addons\main\functions\fn_getDriverInputIntent.sqf',
    'addons\main\functions\fn_registerVehicleControls.sqf',
    'addons\main\functions\fn_updateDriverController.sqf',
    'addons\main\functions\fn_logVehicleHandlingConfig.sqf',
    'addons\main\functions\fn_startSteeringDiagnostics.sqf',
    'addons\main\functions\fn_getNativeSlopeControl.sqf',
    'addons\main\functions\fn_getNativeDriverAssist.sqf',
    'addons\main\functions\fn_getRuntimeAssistRecommendation.sqf',
    'addons\main\functions\fn_coordinateVehicleAssists.sqf'
) | ForEach-Object {
    Assert-FileExists $_
}

@(
    'native\fixics_physics\src\FIXICSPhysics.cpp',
    'native\fixics_physics\tests\FIXICSPhysicsTests.cpp',
    'native\fixics_physics\README.md',
    'native\fixics_physics\CMakeLists.txt',
    'tools\build-native.ps1',
    'FIXICSPhysics_x64.dll'
) | ForEach-Object {
    Assert-FileExists $_
}

Assert-Contains $Config 'class registerSettings\s*\{\s*\};' 'registerSettings must be registered in CfgFunctions.'
Assert-Contains $Config 'class registerAceInteractions\s*\{\s*\};' 'registerAceInteractions must be registered in CfgFunctions.'
Assert-Contains $Config 'class setVehicleHandbrake\s*\{\s*\};' 'setVehicleHandbrake must be registered in CfgFunctions.'
Assert-Contains $Config 'class shouldVehicleRoll\s*\{\s*\};' 'shouldVehicleRoll must be registered in CfgFunctions.'
Assert-Contains $Config 'class monitorVehicleAutobrake\s*\{\s*\};' 'monitorVehicleAutobrake must be registered in CfgFunctions.'
Assert-Contains $Config 'class applySlopeRollback\s*\{\s*\};' 'applySlopeRollback must be registered in CfgFunctions.'
Assert-Contains $Config 'class applyABSBraking\s*\{\s*\};' 'applyABSBraking must be registered in CfgFunctions.'
Assert-Contains $Config 'class applyHandbrakeLock\s*\{\s*\};' 'applyHandbrakeLock must be registered in CfgFunctions.'
Assert-Contains $Config 'class getDriverInputIntent\s*\{\s*\};' 'getDriverInputIntent must be registered in CfgFunctions.'
Assert-Contains $Config 'class registerVehicleControls\s*\{\s*\};' 'registerVehicleControls must be registered in CfgFunctions.'
Assert-Contains $Config 'class updateDriverController\s*\{\s*\};' 'updateDriverController must be registered in CfgFunctions.'
Assert-Contains $Config 'class logVehicleHandlingConfig\s*\{\s*\};' 'logVehicleHandlingConfig must be registered in CfgFunctions.'
Assert-Contains $Config 'class startSteeringDiagnostics\s*\{\s*\};' 'startSteeringDiagnostics must be registered in CfgFunctions.'
Assert-Contains $Config 'class getNativeSlopeControl\s*\{\s*\};' 'getNativeSlopeControl must be registered in CfgFunctions.'
Assert-Contains $Config 'class getNativeDriverAssist\s*\{\s*\};' 'getNativeDriverAssist must be registered in CfgFunctions.'
Assert-Contains $Config 'class getVehicleStabilityProfile\s*\{\s*\};' 'Stability profile resolver must be registered.'
Assert-Contains $Config 'class getVehicleStabilityRecommendation\s*\{\s*\};' 'Stability recommendation math must be registered.'
Assert-Contains $Config 'class applyVehicleStability\s*\{\s*\};' 'Local stability mutation boundary must be registered.'
Assert-Contains $Config 'class getRollStabilityRecommendation\s*\{\s*\};' 'getRollStabilityRecommendation must be registered in CfgFunctions.'
Assert-Contains $Config 'class getRuntimeAssistRecommendation\s*\{\s*\};' 'Runtime assist recommendation must be registered in CfgFunctions.'
Assert-Contains $Config 'class coordinateVehicleAssists\s*\{\s*\};' 'Runtime assist coordinator must be registered in CfgFunctions.'
if ($Config -match 'class CfgVehicles|brakeIdleSpeed\s*=\s*0\.01|dampingRateZeroThrottleClutchEngaged\s*=\s*0\.25|dampingRateZeroThrottleClutchDisengaged\s*=\s*0\.25') {
    Add-Failure 'Failed config-class experiment must be removed before native gameplay-control escalation.'
}

$StabilityProfileFile = Join-Path $RepoRoot 'addons\main\functions\fn_getVehicleStabilityProfile.sqf'
Assert-FileExists 'addons\main\functions\fn_getVehicleStabilityProfile.sqf'
if (Test-Path -LiteralPath $StabilityProfileFile) {
    $StabilityProfile = Get-Content -Raw -LiteralPath $StabilityProfileFile
    Assert-Contains $StabilityProfile '"EMP_Polaris_DAGOR"' 'Compatibility registry must contain the approved DAGOR class.'
    Assert-Contains $StabilityProfile '"B_LSV_01_unarmed_F"' 'Compatibility registry must contain the vanilla LSV class used for SQA telemetry.'
    Assert-Contains $StabilityProfile '"LOP_IA_Offroad"' 'Compatibility registry must contain the LOP IA Offroad class used for SQA telemetry.'
    Assert-Contains $StabilityProfile '"B_G_Offroad_01_F"' 'Compatibility registry must contain the vanilla Offroad base class observed in SQA telemetry.'
    Assert-Contains $StabilityProfile '"REALISTIC_STABLE"' 'Profile resolver must support the realistic preset.'
    Assert-Contains $StabilityProfile '"RALLY"' 'Profile resolver must support the rally preset.'
    Assert-Contains $StabilityProfile '"CUSTOM"' 'Profile resolver must support the custom preset.'
    Assert-Contains $StabilityProfile 'missionNamespace getVariable' 'Custom profile must read synchronized CBA values.'
    if ($StabilityProfile -match 'isKindOf\s+"(?:Car_F|LandVehicle)"') {
        Add-Failure 'Stability compatibility must use exact approved classes, not broad vehicle inheritance.'
    }
}

function Split-SqfArray {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ArrayText
    )

    $Trimmed = $ArrayText.Trim()
    if (-not ($Trimmed.StartsWith('[') -and $Trimmed.EndsWith(']'))) {
        return $null
    }

    $Arguments = New-Object System.Collections.Generic.List[string]
    $Start = 1
    $Depth = 1
    $InString = $false

    for ($Index = 1; $Index -lt ($Trimmed.Length - 1); $Index++) {
        $Character = $Trimmed[$Index]
        if ($Character -eq '"') {
            if ($InString -and ($Index + 1) -lt $Trimmed.Length -and $Trimmed[$Index + 1] -eq '"') {
                $Index++
                continue
            }

            $InString = -not $InString
            continue
        }

        if ($InString) {
            continue
        }

        if ($Character -in @('[', '(', '{')) {
            $Depth++
            continue
        }

        if ($Character -in @(']', ')', '}')) {
            $Depth--
            continue
        }

        if ($Character -eq ',' -and $Depth -eq 1) {
            $Arguments.Add($Trimmed.Substring($Start, $Index - $Start).Trim())
            $Start = $Index + 1
        }
    }

    $Arguments.Add($Trimmed.Substring($Start, ($Trimmed.Length - 1) - $Start).Trim())
    return $Arguments.ToArray()
}

function Get-CbaSettingArguments {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [string]$Variable
    )

    $BlockPattern = '(?ms)^\[\s*\r?\n\s*"' + [regex]::Escape($Variable) +
        '".*?\]\s*call CBA_fnc_addSetting;'
    $BlockMatch = [regex]::Match($Content, $BlockPattern)
    if (-not $BlockMatch.Success) {
        Add-Failure "$Variable must be registered through CBA_fnc_addSetting."
        return $null
    }

    $Block = $BlockMatch.Value
    $CallSuffixIndex = $Block.LastIndexOf('call CBA_fnc_addSetting;')
    return Split-SqfArray $Block.Substring(0, $CallSuffixIndex).Trim()
}

function Normalize-Sqf {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    $Normalized = New-Object System.Text.StringBuilder
    $InString = $false

    for ($Index = 0; $Index -lt $Text.Length; $Index++) {
        $Character = $Text[$Index]
        if ($Character -eq '"') {
            [void]$Normalized.Append($Character)
            if ($InString -and ($Index + 1) -lt $Text.Length -and $Text[$Index + 1] -eq '"') {
                [void]$Normalized.Append($Text[$Index + 1])
                $Index++
                continue
            }

            $InString = -not $InString
            continue
        }

        if ($InString -or -not [char]::IsWhiteSpace($Character)) {
            [void]$Normalized.Append($Character)
        }
    }

    return $Normalized.ToString()
}

function Assert-CbaSetting {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [hashtable]$Spec
    )

    $Arguments = Get-CbaSettingArguments $Content $Spec.Variable
    if ($null -eq $Arguments) {
        return
    }

    if ($Arguments.Count -ne 6) {
        Add-Failure "$($Spec.Variable) must use exactly six CBA setting arguments."
        return
    }

    if ($Arguments[0] -ne "`"$($Spec.Variable)`"") {
        Add-Failure "$($Spec.Variable) must be the first CBA setting argument."
    }
    if ($Arguments[1] -ne "`"$($Spec.ControlType)`"") {
        Add-Failure "$($Spec.Variable) must use a CBA $($Spec.ControlType) control."
    }
    if ((Normalize-Sqf $Arguments[3]) -ne '["FIXICS","Vehicle Stability"]') {
        Add-Failure "$($Spec.Variable) must appear under Vehicle Stability."
    }
    if ((Normalize-Sqf $Arguments[4]) -ne (Normalize-Sqf $Spec.Payload)) {
        Add-Failure "$($Spec.Variable) must use payload $($Spec.Payload)."
    }
    if ($Arguments[5] -ne '1') {
        Add-Failure "$($Spec.Variable) must use CBA global flag 1 as argument six."
    }

    $PayloadDefault = if ($Spec.ControlType -in @('LIST', 'SLIDER')) {
        $PayloadArguments = Split-SqfArray $Arguments[4]
        if ($null -eq $PayloadArguments) {
            $null
        } else {
            $PayloadArguments[$Spec.DefaultIndex]
        }
    } else {
        $Arguments[4]
    }
    if ($PayloadDefault -ne $Spec.NamespaceDefault) {
        Add-Failure "$($Spec.Variable) CBA payload default must match missionNamespace default $($Spec.NamespaceDefault)."
    }
}

$StabilityRecommendationFile = Join-Path $RepoRoot 'addons\main\functions\fn_getVehicleStabilityRecommendation.sqf'
Assert-FileExists 'addons\main\functions\fn_getVehicleStabilityRecommendation.sqf'
if (Test-Path -LiteralPath $StabilityRecommendationFile) {
    $Recommendation = Get-Content -Raw -LiteralPath $StabilityRecommendationFile
    Assert-Contains $Recommendation '"OFF"' 'Recommendation must support disabled assistance.'
    Assert-Contains $Recommendation '"YAW"' 'Recommendation must support yaw damping.'
    Assert-Contains $Recommendation '"YAW_LATERAL"' 'Recommendation must support yaw and lateral damping.'
    Assert-Contains $Recommendation '"COUNTERSTEER"' 'Recommendation must support bounded countersteering.'
    Assert-Contains $Recommendation 'finite' 'Recommendation must reject non-finite inputs.'
    Assert-Contains $Recommendation '_longitudinalSpeed' 'Recommendation must carry longitudinal speed unchanged.'
    if ($Recommendation -match 'setVelocity|setVelocityModelSpace|setDir|setVectorDirAndUp|disableBrakes') {
        Add-Failure 'Stability recommendation must remain pure and must not mutate objects.'
    }
}

$RollStabilityRecommendationFile = Join-Path $RepoRoot 'addons\main\functions\fn_getRollStabilityRecommendation.sqf'
Assert-FileExists 'addons\main\functions\fn_getRollStabilityRecommendation.sqf'
if (Test-Path -LiteralPath $RollStabilityRecommendationFile) {
    $RollRecommendation = Get-Content -Raw -LiteralPath $RollStabilityRecommendationFile
    Assert-Contains $RollRecommendation '\bparams\b' 'Roll recommendation must declare parameters.'
    Assert-Contains $RollRecommendation 'finite' 'Roll recommendation must reject non-finite inputs.'
    Assert-Contains $RollRecommendation '(?i)(bank|rate)[\s\S]*?(max|min)|(?:max|min)[\s\S]*?(bank|rate)' 'Roll recommendation must bound bank and rate thresholds.'
    Assert-Contains $RollRecommendation '(?i)strength[\s\S]*?(max|min)|(?:max|min)[\s\S]*?strength' 'Roll recommendation must bound roll strength.'
    Assert-Contains $RollRecommendation '(?i)(correction|maximum)[\s\S]*?(max|min)|(?:max|min)[\s\S]*?(correction|maximum)' 'Roll recommendation must bound maximum correction.'
    Assert-Contains $RollRecommendation '(?i)severity' 'Roll recommendation must calculate severity.'
    Assert-Contains $RollRecommendation '(?i)damping' 'Roll recommendation must calculate damping.'
    Assert-Contains $RollRecommendation '(?i)recommended' 'Roll recommendation must produce a recommended vertical value.'
    Assert-Contains $RollRecommendation '(?i)applied[\s\S]*?recommended[\s\S]*?correction[\s\S]*?severity|severity[\s\S]*?correction[\s\S]*?recommended[\s\S]*?applied' 'Roll recommendation must return applied state, recommendation, correction, and severity.'
    if ($RollRecommendation -match 'setVelocity|setVelocityModelSpace|setDir|setVectorDirAndUp|disableBrakes') {
        Add-Failure 'Roll recommendation must remain pure and must not mutate objects.'
    }
}

$RuntimeRecommendationFile = Join-Path $RepoRoot 'addons\main\functions\fn_getRuntimeAssistRecommendation.sqf'
Assert-FileExists 'addons\main\functions\fn_getRuntimeAssistRecommendation.sqf'
if (Test-Path -LiteralPath $RuntimeRecommendationFile) {
    $RuntimeRecommendation = Get-Content -Raw -LiteralPath $RuntimeRecommendationFile
    Assert-Contains $RuntimeRecommendation '\bparams\b' 'Runtime recommendation must declare parameters.'
    Assert-Contains $RuntimeRecommendation 'priorityWinner' 'Runtime recommendation must expose a priority winner.'
    Assert-Contains $RuntimeRecommendation 'terrainMultiplier' 'Runtime recommendation must expose terrain multiplier.'
    Assert-Contains $RuntimeRecommendation 'massMultiplier' 'Runtime recommendation must expose mass multiplier.'
    Assert-Contains $RuntimeRecommendation 'slopeRetention' 'Runtime recommendation must expose braking slope retention.'
    Assert-Contains $RuntimeRecommendation 'suppressedAssists' 'Runtime recommendation must expose suppressed or reduced assists.'
    Assert-Contains $RuntimeRecommendation 'finalCorrection' 'Runtime recommendation must expose final correction summary.'
    Assert-Contains $RuntimeRecommendation '\bfinite\b' 'Runtime recommendation must reject non-finite numeric inputs.'
    if ($RuntimeRecommendation -match '\b(setVelocity|setVelocityModelSpace|setDir|setVectorDirAndUp|disableBrakes|setVariable|publicVariable|remoteExec|remoteExecCall|callExtension)\b') {
        Add-Failure 'Runtime recommendation must remain pure and must not mutate objects, network state, brakes, or native extension state.'
    }
}

$RuntimeCoordinatorFile = Join-Path $RepoRoot 'addons\main\functions\fn_coordinateVehicleAssists.sqf'
Assert-FileExists 'addons\main\functions\fn_coordinateVehicleAssists.sqf'
if (Test-Path -LiteralPath $RuntimeCoordinatorFile) {
    $RuntimeCoordinator = Get-Content -Raw -LiteralPath $RuntimeCoordinatorFile
    Assert-Contains $RuntimeCoordinator 'driver _vehicle == player' 'Runtime coordinator must require the local player driver.'
    Assert-Contains $RuntimeCoordinator 'local _vehicle' 'Runtime coordinator must require local vehicle ownership.'
    Assert-Contains $RuntimeCoordinator 'FIXICS_handbrakeEnabled' 'Runtime coordinator must respect persistent FIXICS handbrake priority.'
    Assert-Contains $RuntimeCoordinator 'FIXICS_fnc_getRuntimeAssistRecommendation' 'Runtime coordinator must call the pure recommendation helper.'
    Assert-Contains $RuntimeCoordinator 'FIXICS_runtimeAssistLastDecision' 'Runtime coordinator must store last decision telemetry.'
    Assert-Contains $RuntimeCoordinator 'FIXICS_runtimeAssistDebugLogging' 'Runtime coordinator must support explicit debug logging.'
    Assert-Contains $RuntimeCoordinator 'velocityModelSpace _vehicle' 'Runtime coordinator must work in model-space velocity.'
    if ($RuntimeCoordinator -match '\b(setDir|setVectorDirAndUp|remoteExec|remoteExecCall|publicVariable)\b') {
        Add-Failure 'Runtime coordinator must not mutate orientation or network state.'
    }
}

$StabilityControllerFile = Join-Path $RepoRoot 'addons\main\functions\fn_applyVehicleStability.sqf'
Assert-FileExists 'addons\main\functions\fn_applyVehicleStability.sqf'
if (Test-Path -LiteralPath $StabilityControllerFile) {
    $StabilityController = Get-Content -Raw -LiteralPath $StabilityControllerFile
    function Get-StabilityControllerContractFailures {
        param (
            [Parameter(Mandatory = $true)]
            [string]$Content
        )

        $ContractFailures = New-Object System.Collections.Generic.List[string]
        $RequiredPatterns = @(
            @{
                Pattern = 'private _clearYawSample = \{[\s\S]*?FIXICS_stabilityPreviousHeading",\s*nil,\s*false[\s\S]*?FIXICS_stabilityPreviousTime",\s*nil,\s*false[\s\S]*?\};'
                Message = 'Stability controller must use one helper to clear heading and time before re-entry.'
            },
            @{
                Pattern = 'if \(!local _vehicle\) exitWith \{\s*\[_vehicle\] call _clearYawSample;\s*false\s*\};'
                Message = 'Nonlocal guard must clear yaw state before exit.'
            },
            @{
                Pattern = 'if \(!_isPlayerDriver\) exitWith \{\s*\[_vehicle\] call _clearYawSample;\s*false\s*\};'
                Message = 'Wrong-driver guard must clear yaw state before exit.'
            },
            @{
                Pattern = 'if !\(isTouchingGround _vehicle\) exitWith \{\s*\[_vehicle\] call _clearYawSample;\s*false\s*\};'
                Message = 'Airborne guard must clear yaw state before exit.'
            },
            @{
                Pattern = 'if \(_vehicle getVariable \["FIXICS_handbrakeEnabled", false\]\) exitWith \{\s*\[_vehicle\] call _clearYawSample;\s*false\s*\};'
                Message = 'Handbrake guard must clear yaw state before exit.'
            },
            @{
                Pattern = 'if \(\(count _profile\) < 7 \|\| \{!\(_profile # 0\)\}\) exitWith \{\s*\[_vehicle\] call _clearYawSample;\s*false\s*\};'
                Message = 'Unsupported-profile guard must clear yaw state before exit.'
            },
            @{
                Pattern = 'driver _vehicle == player'
                Message = 'Stability controller must require the local player to be the driver.'
            },
            @{
                Pattern = 'FIXICS_fnc_getVehicleStabilityProfile'
                Message = 'Stability controller must resolve the approved vehicle profile.'
            },
            @{
                Pattern = 'FIXICS_fnc_getVehicleStabilityRecommendation'
                Message = 'Stability controller must call the pure recommendation function.'
            },
            @{
                Pattern = 'FIXICS_fnc_getRollStabilityRecommendation'
                Message = 'Stability controller must call the pure roll recommendation function.'
            },
            @{
                Pattern = '_vehicle call BIS_fnc_getPitchBank'
                Message = 'Stability controller must sample bank with the vehicle object directly.'
            },
            @{
                Pattern = 'FIXICS_rollLastGroundedAt'
                Message = 'Stability controller must track recent ground contact for roll grace.'
            },
            @{
                Pattern = 'FIXICS_rollStabilityPreset'
                Message = 'Stability controller must read the roll stability preset before building roll settings.'
            },
            @{
                Pattern = '"AGGRESSIVE_SQA"[\s\S]*?\[5,\s*240,\s*0\.5,\s*0\.4,\s*1\]'
                Message = 'Stability controller must provide the SQA max-tested roll preset values.'
            },
            @{
                Pattern = '"CUSTOM"[\s\S]*?FIXICS_rollActivationBankDeg[\s\S]*?FIXICS_rollActivationRateDeg[\s\S]*?FIXICS_rollStrength[\s\S]*?FIXICS_rollMaximumCorrection[\s\S]*?FIXICS_rollAirborneGraceSeconds'
                Message = 'Custom roll preset must use the existing roll sliders.'
            },
            @{
                Pattern = 'FIXICS_rollPreviousBank'
                Message = 'Stability controller must store prior bank for bank-rate calculation.'
            },
            @{
                Pattern = '\(\(\(inputAction "CarRight"\) - \(inputAction "CarLeft"\)\) / 3\) max -1 min 1'
                Message = 'Stability controller must normalize observed 0..3 steering input.'
            },
            @{
                Pattern = 'private _headingDelta = \(\(_heading - _previousHeading \+ 540\) mod 360\) - 180;'
                Message = 'Stability controller must calculate wrapped heading delta.'
            },
            @{
                Pattern = 'private _yawRate = _headingDelta / \(_deltaTime max 0\.001\);'
                Message = 'Stability controller must calculate yaw rate from elapsed time.'
            },
            @{
                Pattern = 'private _longitudinal = _velocity # 1;'
                Message = 'Stability controller must preserve model-space longitudinal index 1.'
            },
            @{
                Pattern = 'private _vertical = _velocity # 2;'
                Message = 'Stability controller must preserve model-space vertical index 2.'
            },
            @{
                Pattern = '_velocity set \[0, _recommendedLateral\];'
                Message = 'Stability controller must apply only the recommended lateral speed at index 0.'
            },
            @{
                Pattern = '_velocity set \[2, _recommendedVertical\];'
                Message = 'Roll assist may only apply its vertical recommendation at model-space index 2.'
            },
            @{
                Pattern = '_vehicle setVelocityModelSpace _velocity;[\s\S]*?private _actualVelocity = velocityModelSpace _vehicle;'
                Message = 'Stability controller must resample actual model-space velocity after applying the correction.'
            },
            @{
                Pattern = 'private _actualLateral = _actualVelocity # 0;'
                Message = 'Stability diagnostics must report actual lateral velocity after mutation.'
            },
            @{
                Pattern = 'private _actualLongitudinal = _actualVelocity # 1;'
                Message = 'Stability diagnostics must report actual longitudinal velocity after mutation.'
            },
            @{
                Pattern = 'private _actualVertical = _actualVelocity # 2;'
                Message = 'Stability diagnostics must report actual vertical velocity after mutation.'
            },
            @{
                Pattern = 'unusedYawRecommendation='
                Message = 'Stability debug evidence must identify the unused yaw recommendation.'
            },
            @{
                Pattern = 'verticalAfter='
                Message = 'Stability debug evidence must include actual vertical velocity after mutation.'
            }
        )

        foreach ($Requirement in $RequiredPatterns) {
            if ($Content -notmatch $Requirement.Pattern) {
                $ContractFailures.Add($Requirement.Message)
            }
        }

        $VelocityMutationMatches = [regex]::Matches(
            $Content,
            '(?m)\bsetVelocityModelSpace\b'
        )
        if ($VelocityMutationMatches.Count -lt 1) {
            $ContractFailures.Add('Stability controller must mutate model-space velocity through setVelocityModelSpace.')
        }

        if ($Content -match '\w+\s+set\s+\[\s*1\s*,') {
            $ContractFailures.Add('Stability controller must not mutate longitudinal vector index 1.')
        }
        if ($Content -match 'setVelocityModelSpace\s+\[') {
            $ContractFailures.Add('Stability controller must not replace model-space velocity with a new vector.')
        }
        if ($Content -match '(?m)^\s*(?:private\s+)?_velocity\b\s*=\s*\[') {
            $ContractFailures.Add('Stability controller must not assign a replacement model-space velocity vector.')
        }
        $VectorLiteralAssignments = [regex]::Matches(
            $Content,
            '(?m)^\s*(?:private\s+)?(?<Variable>_[A-Za-z][A-Za-z0-9_]*)\s*=\s*\['
        )
        foreach ($Assignment in $VectorLiteralAssignments) {
            $VectorVariable = [regex]::Escape($Assignment.Groups['Variable'].Value)
            if ($Content -match ('setVelocityModelSpace\s+' + $VectorVariable + '\b')) {
                $ContractFailures.Add("Stability controller must not pass vector literal variable $($Assignment.Groups['Variable'].Value) to setVelocityModelSpace.")
            }
        }
        $ModelSpaceMutationAssignments = [regex]::Matches(
            $Content,
            'setVelocityModelSpace\s+(?<Operand>_[A-Za-z][A-Za-z0-9_]*)\b'
        )
        foreach ($Mutation in $ModelSpaceMutationAssignments) {
            $Operand = $Mutation.Groups['Operand'].Value
            $OperandAssignments = [regex]::Matches(
                $Content,
                '(?m)^\s*(?:private\s+)?' + [regex]::Escape($Operand) + '\s*=\s*(?<Source>[^\r\n;]+)'
            ) | Where-Object {
                $_.Index -lt $Mutation.Index
            }
            $LastAssignment = $OperandAssignments | Select-Object -Last 1
            if ($null -eq $LastAssignment -or $LastAssignment.Groups['Source'].Value -notmatch '^velocityModelSpace\s+_vehicle\b') {
                $ContractFailures.Add("Stability controller model-space mutation variable $Operand must come from velocityModelSpace _vehicle.")
            }
        }

        $VerticalAfterIndex = $Content.LastIndexOf('verticalAfter=')
        if ($VerticalAfterIndex -ge 0) {
            $LastVelocityMutationBeforeVerticalAfter = $Content.LastIndexOf('setVelocityModelSpace', $VerticalAfterIndex)
            if ($LastVelocityMutationBeforeVerticalAfter -lt 0) {
                $ContractFailures.Add('Roll diagnostics must occur after a model-space velocity mutation.')
            } else {
                $DiagnosticsSpan = $Content.Substring(
                    $LastVelocityMutationBeforeVerticalAfter,
                    $VerticalAfterIndex - $LastVelocityMutationBeforeVerticalAfter
                )
                if ($DiagnosticsSpan -notmatch 'velocityModelSpace\s+_vehicle') {
                    $ContractFailures.Add('Roll diagnostics must resample model-space vertical velocity after the final relevant mutation.')
                }
            }

            $VelocityMutationAfterVerticalAfter = $Content.IndexOf('setVelocityModelSpace', $VerticalAfterIndex)
            if ($VelocityMutationAfterVerticalAfter -ge 0) {
                $ContractFailures.Add('Roll diagnostics must occur after the final model-space velocity mutation.')
            }
        }
        if ($Content -match 'FIXICS_fnc_(?:applyABSBraking|applySlopeRollback|applyHandbrakeLock)|disableBrakes') {
            $ContractFailures.Add('Stability controller must not call ABS, slope rollback, handbrake lock, or disableBrakes.')
        }
        if ($Content -match 'setDir|setVectorDirAndUp') {
            $ContractFailures.Add('Stability controller must not mutate vehicle orientation.')
        }

        return $ContractFailures.ToArray()
    }

    foreach ($ContractFailure in (Get-StabilityControllerContractFailures $StabilityController)) {
        Add-Failure $ContractFailure
    }

    if ((Get-StabilityControllerContractFailures $StabilityController).Count -eq 0) {
        $StaleStatePattern = [regex]::new(
            '(if \(!local _vehicle\) exitWith \{\s*)\[_vehicle\] call _clearYawSample;\s*'
        )
        $StaleStateMutation = $StaleStatePattern.Replace(
            $StabilityController,
            '$1',
            1
        )
        if ((Get-StabilityControllerContractFailures $StaleStateMutation).Count -eq 0) {
            Add-Failure 'Mutation survived: stale yaw state on nonlocal eligibility gap.'
        } else {
            Write-Host 'Killed mutation: stale yaw state on eligibility gap'
        }

        $VerticalMutation = $StabilityController.Replace(
            '_velocity set [0, _recommendedLateral];',
            '_velocity set [1, _recommendedLateral];'
        )
        if ((Get-StabilityControllerContractFailures $VerticalMutation).Count -eq 0) {
            Add-Failure 'Mutation survived: longitudinal velocity mutation.'
        } else {
            Write-Host 'Killed mutation: longitudinal velocity mutation'
        }

        $ReplacementVelocityMutation = $StabilityController.Replace(
            '_vehicle setVelocityModelSpace _velocity;',
            'private _otherVelocity = [0, _recommendedLateral, _vertical];' + [Environment]::NewLine + '_vehicle setVelocityModelSpace _otherVelocity;'
        )
        if ((Get-StabilityControllerContractFailures $ReplacementVelocityMutation).Count -eq 0) {
            Add-Failure 'Mutation survived: model-space velocity replacement through arbitrary variable.'
        } else {
            Write-Host 'Killed mutation: model-space velocity replacement through arbitrary variable'
        }

        $LateVelocityMutation = $StabilityController.Replace(
            '];' + [Environment]::NewLine + '};' + [Environment]::NewLine + [Environment]::NewLine + 'true',
            '];' + [Environment]::NewLine + '};' + [Environment]::NewLine + [Environment]::NewLine + '_vehicle setVelocityModelSpace _velocity;' + [Environment]::NewLine + [Environment]::NewLine + 'true'
        )
        if ((Get-StabilityControllerContractFailures $LateVelocityMutation).Count -eq 0) {
            Add-Failure 'Mutation survived: model-space velocity mutation after verticalAfter diagnostics.'
        } else {
            Write-Host 'Killed mutation: model-space velocity mutation after verticalAfter diagnostics'
        }

        $StaleVerticalAfterMutation = $StabilityController.Replace(
            'private _actualVelocity = velocityModelSpace _vehicle;',
            'private _actualVelocity = _velocity;'
        )
        if ((Get-StabilityControllerContractFailures $StaleVerticalAfterMutation).Count -eq 0) {
            Add-Failure 'Mutation survived: stale verticalAfter diagnostic without post-mutation resample.'
        } else {
            Write-Host 'Killed mutation: stale verticalAfter diagnostic without post-mutation resample'
        }
    }
}

$StabilityMutationRunnerFile = Join-Path $RepoRoot 'tests\unit\fixics-stability-recommendation-mutations.ps1'
Assert-FileExists 'tests\unit\fixics-stability-recommendation-mutations.ps1'
if (Test-Path -LiteralPath $StabilityMutationRunnerFile) {
    $StabilityMutationRunner = Get-Content -Raw -LiteralPath $StabilityMutationRunnerFile
    if ($StabilityMutationRunner -match 'Start-Process') {
        Add-Failure 'Stability mutation runner must avoid Start-Process environment serialization.'
    }
}

Assert-Contains $Init 'FIXICS_fnc_hello' 'fn_init.sqf must call FIXICS_fnc_hello.'
Assert-Contains $Init 'FIXICS_fnc_registerSettings' 'fn_init.sqf must register CBA settings.'
Assert-Contains $Init 'FIXICS_fnc_registerAceInteractions' 'fn_init.sqf must register ACE interactions.'
Assert-Contains $Init 'FIXICS_fnc_registerVehicleControls' 'fn_init.sqf must register the local driver controller.'
Assert-Contains $Init 'FIXICS_fnc_monitorVehicleAutobrake' 'fn_init.sqf must start the vehicle autobrake monitor.'
Assert-Contains $Mission 'FIXICS_fnc_vrHello' 'VR mission must call FIXICS_fnc_vrHello.'

Assert-Contains $Stringtable 'STR_FIXICS_HAND_BRAKE_SET' 'Stringtable must define Set Handbrake text.'
Assert-Contains $Stringtable 'STR_FIXICS_HAND_BRAKE_RELEASE' 'Stringtable must define Release Handbrake text.'
Assert-Contains $Stringtable 'STR_FIXICS_HAND_BRAKE_STATUS_SET' 'Stringtable must define handbrake set status text.'
Assert-Contains $Stringtable 'STR_FIXICS_HAND_BRAKE_STATUS_RELEASED' 'Stringtable must define handbrake released status text.'
Assert-Contains $Stringtable 'STR_FIXICS_SETTING_DISABLE_IDLE_AUTOBRAKE' 'Stringtable must define the idle autobrake setting title.'
Assert-Contains $Stringtable 'STR_FIXICS_SETTING_DISABLE_IDLE_AUTOBRAKE_TOOLTIP' 'Stringtable must define the idle autobrake setting tooltip.'
Assert-Contains $Stringtable 'STR_FIXICS_SETTING_SLOPE_MINIMUM' 'Stringtable must define the slope minimum setting title.'
Assert-Contains $Stringtable 'STR_FIXICS_SETTING_SLOPE_ROLLBACK_MAX_SPEED' 'Stringtable must define the slope rollback max-speed setting title.'
Assert-Contains $Stringtable 'STR_FIXICS_SETTING_SLOPE_ROLLBACK_ACCELERATION' 'Stringtable must define the slope rollback acceleration setting title.'
Assert-Contains $Stringtable 'STR_FIXICS_SETTING_SLOPE_COAST_BREAKAWAY' 'Stringtable must define the slope coast breakaway setting title.'
Assert-Contains $Stringtable 'STR_FIXICS_SETTING_SLOPE_DRIVE_ACCELERATION' 'Stringtable must define the slope drive acceleration setting title.'
Assert-Contains $Stringtable 'STR_FIXICS_SETTING_SLOPE_DRIVE_MAX_SPEED' 'Stringtable must define the slope drive max-speed setting title.'
Assert-Contains $Stringtable 'STR_FIXICS_SETTING_STATIONARY_BRAKE_BYPASS' 'Stringtable must define the stationary brake bypass setting title.'
Assert-Contains $Stringtable 'STR_FIXICS_SETTING_ABS_ENABLED' 'Stringtable must define the ABS enabled setting title.'
Assert-Contains $Stringtable 'STR_FIXICS_SETTING_ABS_BRAKE_STRENGTH' 'Stringtable must define the ABS brake strength setting title.'
Assert-Contains $Stringtable 'STR_FIXICS_SETTING_ABS_RELEASE_BIAS' 'Stringtable must define the ABS release bias setting title.'
Assert-Contains $Stringtable 'STR_FIXICS_SETTING_ABS_LOW_SPEED_CUTOFF' 'Stringtable must define the ABS low-speed cutoff setting title.'
Assert-Contains $Stringtable 'STR_FIXICS_SETTING_ABS_SLOPE_COMPENSATION' 'Stringtable must define the ABS slope compensation setting title.'
Assert-Contains $Stringtable 'STR_FIXICS_SETTING_ABS_DEBUG_LOGGING' 'Stringtable must define the ABS debug logging setting title.'
Assert-Contains $Stringtable 'STR_FIXICS_SETTING_DRIVER_CONTROLLER_ENABLED' 'Stringtable must define the driver controller setting title.'
Assert-Contains $Stringtable 'STR_FIXICS_SETTING_HANDBRAKE_INPUT_MODE' 'Stringtable must define the handbrake input mode setting title.'
Assert-Contains $Stringtable 'STR_FIXICS_SETTING_HANDBRAKE_INPUT_HOLD' 'Stringtable must define the hold handbrake input mode.'
Assert-Contains $Stringtable 'STR_FIXICS_SETTING_HANDBRAKE_INPUT_TOGGLE' 'Stringtable must define the toggle handbrake input mode.'
Assert-Contains $Stringtable 'ID="STR_FIXICS_SETTING_NATIVE_DRIVER_ASSIST"' 'Stringtable must define the native driver assist setting title.'
Assert-Contains $Stringtable 'ID="STR_FIXICS_SETTING_NATIVE_DRIVER_ASSIST_TOOLTIP"' 'Stringtable must define the native driver assist setting tooltip.'
Assert-Contains $Stringtable 'ID="STR_FIXICS_SETTING_DRIVER_ASSIST_DEBUG_LOGGING"' 'Stringtable must define the driver assist debug logging setting title.'
Assert-Contains $Stringtable 'ID="STR_FIXICS_SETTING_DRIVER_ASSIST_DEBUG_LOGGING_TOOLTIP"' 'Stringtable must define the driver assist debug logging setting tooltip.'
Assert-Contains $Stringtable 'STR_FIXICS_SETTING_DIRECTION_CHANGE_THRESHOLD' 'Stringtable must define the direction change threshold setting title.'
Assert-Contains $Stringtable 'STR_FIXICS_SETTING_DIRECTION_LAUNCH_VELOCITY' 'Stringtable must define the direction launch velocity setting title.'
Assert-Contains $Stringtable 'STR_FIXICS_SETTING_DIRECTION_NEUTRAL_PULSE' 'Stringtable must define the direction neutral pulse setting title.'
Assert-Contains $Stringtable 'STR_FIXICS_SETTING_DIRECTION_NEUTRAL_PULSE_TOOLTIP' 'Stringtable must define the direction neutral pulse setting tooltip.'
Assert-Contains $Stringtable 'STR_FIXICS_SETTING_DRIVER_CONTROLLER_INTERVAL' 'Stringtable must define the driver controller interval setting title.'

@(
    'STR_FIXICS_SETTING_STABILITY_PRESET',
    'STR_FIXICS_SETTING_STABILITY_PRESET_TOOLTIP',
    'STR_FIXICS_SETTING_STABILITY_PRESET_REALISTIC_STABLE',
    'STR_FIXICS_SETTING_STABILITY_PRESET_RALLY',
    'STR_FIXICS_SETTING_STABILITY_PRESET_CUSTOM',
    'STR_FIXICS_SETTING_STABILITY_ASSIST_MODE',
    'STR_FIXICS_SETTING_STABILITY_ASSIST_MODE_TOOLTIP',
    'STR_FIXICS_SETTING_STABILITY_ASSIST_OFF',
    'STR_FIXICS_SETTING_STABILITY_ASSIST_YAW',
    'STR_FIXICS_SETTING_STABILITY_ASSIST_YAW_LATERAL',
    'STR_FIXICS_SETTING_STABILITY_ASSIST_COUNTERSTEER',
    'STR_FIXICS_SETTING_STABILITY_ACTIVATION_SPEED',
    'STR_FIXICS_SETTING_STABILITY_ACTIVATION_SPEED_TOOLTIP',
    'STR_FIXICS_SETTING_STABILITY_SLIP_THRESHOLD',
    'STR_FIXICS_SETTING_STABILITY_SLIP_THRESHOLD_TOOLTIP',
    'STR_FIXICS_SETTING_STABILITY_YAW_STRENGTH',
    'STR_FIXICS_SETTING_STABILITY_YAW_STRENGTH_TOOLTIP',
    'STR_FIXICS_SETTING_STABILITY_LATERAL_STRENGTH',
    'STR_FIXICS_SETTING_STABILITY_LATERAL_STRENGTH_TOOLTIP',
    'STR_FIXICS_SETTING_STABILITY_COUNTERSTEER_STRENGTH',
    'STR_FIXICS_SETTING_STABILITY_COUNTERSTEER_STRENGTH_TOOLTIP',
    'STR_FIXICS_SETTING_STABILITY_MAXIMUM_CORRECTION',
    'STR_FIXICS_SETTING_STABILITY_MAXIMUM_CORRECTION_TOOLTIP',
    'STR_FIXICS_SETTING_STABILITY_DEBUG_LOGGING',
    'STR_FIXICS_SETTING_STABILITY_DEBUG_LOGGING_TOOLTIP'
) | ForEach-Object {
    Assert-Contains $Stringtable ('ID="' + $_ + '"') "Stringtable must define $_."
}
Assert-Contains $Stringtable 'server-global' 'Stability descriptions must state that settings are server-global.'
Assert-Contains $Stringtable 'registered vehicles' 'Stability descriptions must state that only registered vehicles are eligible.'
Assert-Contains $Stringtable 'Custom values are ignored by fixed presets' 'Stability descriptions must state that fixed presets ignore Custom values.'
@(
    'STR_FIXICS_SETTING_ROLL_STABILITY_ENABLED',
    'STR_FIXICS_SETTING_ROLL_STABILITY_ENABLED_TOOLTIP',
    'STR_FIXICS_SETTING_ROLL_ACTIVATION_BANK',
    'STR_FIXICS_SETTING_ROLL_ACTIVATION_BANK_TOOLTIP',
    'STR_FIXICS_SETTING_ROLL_ACTIVATION_RATE',
    'STR_FIXICS_SETTING_ROLL_ACTIVATION_RATE_TOOLTIP',
    'STR_FIXICS_SETTING_ROLL_STRENGTH',
    'STR_FIXICS_SETTING_ROLL_STRENGTH_TOOLTIP',
    'STR_FIXICS_SETTING_ROLL_MAXIMUM_CORRECTION',
    'STR_FIXICS_SETTING_ROLL_MAXIMUM_CORRECTION_TOOLTIP',
    'STR_FIXICS_SETTING_ROLL_AIRBORNE_GRACE',
    'STR_FIXICS_SETTING_ROLL_AIRBORNE_GRACE_TOOLTIP'
) | ForEach-Object {
    Assert-Contains $Stringtable ('ID="' + $_ + '"') "Stringtable must define $_."
}

$AddonFiles = Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'addons\main') -Recurse -File
$BaseArmaRefs = $AddonFiles | Select-String -Pattern 'BASEARMA_fnc_' -List
if ($BaseArmaRefs) {
    $Paths = ($BaseArmaRefs | ForEach-Object { $_.Path }) -join ', '
    Add-Failure "Addon source must not reference BASEARMA_fnc_: $Paths"
}

$HandbrakeFile = Join-Path $RepoRoot 'addons\main\functions\fn_setVehicleHandbrake.sqf'
if (Test-Path -LiteralPath $HandbrakeFile) {
    $Handbrake = Get-Content -Raw -LiteralPath $HandbrakeFile
    Assert-Contains $Handbrake '"FIXICS_handbrakeEnabled"' 'Handbrake function must use FIXICS_handbrakeEnabled.'
    Assert-Contains $Handbrake 'disableBrakes' 'Handbrake function must apply disableBrakes.'
    Assert-Contains $Handbrake 'FIXICS_fnc_applyHandbrakeLock' 'Setting the handbrake must immediately apply the hard lock.'
    Assert-Contains $Handbrake 'FIXICS_brakeControlOwner' 'Persistent handbrake must participate in FIXICS autobrake ownership.'
    Assert-Contains $Handbrake 'FIXICS_priorBrakesDisabled' 'Persistent handbrake must preserve and restore the prior autobrake state.'
    Assert-Contains $Handbrake 'brakesDisabled' 'Persistent handbrake must capture the prior autobrake state when needed.'
}

$DecisionFile = Join-Path $RepoRoot 'addons\main\functions\fn_shouldVehicleRoll.sqf'
if (Test-Path -LiteralPath $DecisionFile) {
    $Decision = Get-Content -Raw -LiteralPath $DecisionFile
    Assert-Contains $Decision '"FIXICS_handbrakeEnabled"' 'Decision helper must check FIXICS_handbrakeEnabled.'
    Assert-Contains $Decision 'FIXICS_disableIdleAutobrake' 'Decision helper must check FIXICS_disableIdleAutobrake.'
    Assert-Contains $Decision 'CarBack' 'Decision helper must check built-in car brake input.'
    Assert-Contains $Decision 'CarHandBrake' 'Decision helper must check built-in car handbrake input.'
    Assert-Contains $Decision 'FIXICS_stationaryBrakeBypassSpeedKmh' 'Decision helper must define the near-stationary brake bypass threshold.'
    Assert-Contains $Decision 'isTouchingGround' 'Decision helper must reject airborne vehicles.'
    Assert-Contains $Decision 'private _isStationary' 'Decision helper must calculate near-stationary state.'
    Assert-Contains $Decision '_isBraking && \{!_isStationary\}' 'CarBack must only block rolling while above near-stationary speed.'
    Assert-Contains $Decision 'private _inputBlocksRolling' 'Decision helper must carry player input rejection out of the nested interface scope.'
    Assert-Contains $Decision 'if \(_inputBlocksRolling\) exitWith' 'Decision helper must reject handbrake/brake input from the function scope.'
    Assert-Contains $Decision 'surfaceNormal' 'Decision helper must read terrain slope before disabling brakes.'
    Assert-Contains $Decision 'FIXICS_slopeRollbackMinimumSlope' 'Decision helper must use the rollback slope threshold before disabling brakes.'
    Assert-Contains $Decision '_slope < _minimumSlope' 'Decision helper must reject flat or near-flat ground.'

    if ($Decision -match 'if\s*\(missionNamespace getVariable\s*\["FIXICS_disableIdleAutobrake",\s*true\]\)\s*exitWith\s*\{\s*true\s*\};\s*true') {
        Add-Failure 'Decision helper must not return true unconditionally after checking FIXICS_disableIdleAutobrake.'
    }

    $BrakeInputIndex = $Decision.IndexOf('inputAction "CarBack"')
    $SettingIndex = $Decision.IndexOf('"FIXICS_disableIdleAutobrake"')
    if ($BrakeInputIndex -lt 0 -or $SettingIndex -lt 0 -or $BrakeInputIndex -gt $SettingIndex) {
        Add-Failure 'Decision helper must honor active driver brake input before the idle autobrake setting.'
    }
}

$SettingsFile = Join-Path $RepoRoot 'addons\main\functions\fn_registerSettings.sqf'
if (Test-Path -LiteralPath $SettingsFile) {
    $Settings = Get-Content -Raw -LiteralPath $SettingsFile
    Assert-Contains $Settings 'CBA_fnc_addSetting' 'Settings registration must use CBA_fnc_addSetting.'
    Assert-Contains $Settings '"FIXICS_disableIdleAutobrake"' 'Settings registration must define FIXICS_disableIdleAutobrake.'
    Assert-Contains $Settings '"CHECKBOX"' 'Idle autobrake setting must be a checkbox.'
    Assert-Contains $Settings '"SLIDER"' 'Physics tuning settings must use CBA sliders.'
    Assert-Contains $Settings '"FIXICS_slopeRollbackMinimumSlope"' 'Settings registration must define FIXICS_slopeRollbackMinimumSlope.'
    Assert-Contains $Settings '"FIXICS_slopeRollbackMaxSpeed"' 'Settings registration must define FIXICS_slopeRollbackMaxSpeed.'
    Assert-Contains $Settings '"FIXICS_slopeRollbackAcceleration"' 'Settings registration must define FIXICS_slopeRollbackAcceleration.'
    Assert-Contains $Settings '"FIXICS_slopeCoastBreakawayVelocity"' 'Settings registration must define the slope coasting breakaway default.'
    Assert-Contains $Settings '"FIXICS_slopeDriveAcceleration"' 'Settings registration must define the slope drive acceleration default.'
    Assert-Contains $Settings '"FIXICS_slopeDriveMaxSpeedKmh"' 'Settings registration must define the slope drive max-speed default.'
    Assert-Contains $Settings '"FIXICS_stationaryBrakeBypassSpeedKmh"' 'Settings registration must define FIXICS_stationaryBrakeBypassSpeedKmh.'
    Assert-Contains $Settings '"FIXICS_absEnabled"' 'Settings registration must define FIXICS_absEnabled.'
    Assert-Contains $Settings '"FIXICS_absBrakeStrength"' 'Settings registration must define FIXICS_absBrakeStrength.'
    Assert-Contains $Settings '"FIXICS_absReleaseBias"' 'Settings registration must define FIXICS_absReleaseBias.'
    Assert-Contains $Settings '"FIXICS_absLowSpeedCutoffKmh"' 'Settings registration must define FIXICS_absLowSpeedCutoffKmh.'
    Assert-Contains $Settings '"FIXICS_absSlopeCompensation"' 'Settings registration must define FIXICS_absSlopeCompensation.'
    Assert-Contains $Settings '"FIXICS_absDebugLogging"' 'Settings registration must define FIXICS_absDebugLogging.'
    Assert-Contains $Settings '"FIXICS_driverControllerEnabled"' 'Settings registration must define FIXICS_driverControllerEnabled.'
    Assert-Contains $Settings '"FIXICS_nativeDriverAssistEnabled"' 'Settings registration must define FIXICS_nativeDriverAssistEnabled.'
    Assert-Contains $Settings '"FIXICS_driverAssistDebugLogging"' 'Settings registration must define FIXICS_driverAssistDebugLogging.'
    Assert-Contains $Settings '"FIXICS_handbrakeInputMode"' 'Settings registration must define FIXICS_handbrakeInputMode.'
    Assert-Contains $Settings '"FIXICS_directionChangeThresholdKmh"' 'Settings registration must define FIXICS_directionChangeThresholdKmh.'
    Assert-Contains $Settings '"FIXICS_directionLaunchVelocity"' 'Settings registration must define FIXICS_directionLaunchVelocity.'
    Assert-Contains $Settings '"FIXICS_directionNeutralPulseSeconds"' 'Settings registration must define FIXICS_directionNeutralPulseSeconds.'
    Assert-Contains $Settings '"FIXICS_driverControllerInterval"' 'Settings registration must define FIXICS_driverControllerInterval.'
    Assert-Contains $Settings '"LIST"' 'Handbrake input mode must use a CBA list setting.'

    $StabilitySettings = @(
        @{
            Variable = 'FIXICS_stabilityPreset'
            ControlType = 'LIST'
            NamespaceDefault = '0'
            Payload = '[[0, 1, 2], [localize "STR_FIXICS_SETTING_STABILITY_PRESET_REALISTIC_STABLE", localize "STR_FIXICS_SETTING_STABILITY_PRESET_RALLY", localize "STR_FIXICS_SETTING_STABILITY_PRESET_CUSTOM"], 0]'
            DefaultIndex = 2
        },
        @{
            Variable = 'FIXICS_stabilityAssistMode'
            ControlType = 'LIST'
            NamespaceDefault = '0'
            Payload = '[[0, 1, 2, 3], [localize "STR_FIXICS_SETTING_STABILITY_ASSIST_OFF", localize "STR_FIXICS_SETTING_STABILITY_ASSIST_YAW", localize "STR_FIXICS_SETTING_STABILITY_ASSIST_YAW_LATERAL", localize "STR_FIXICS_SETTING_STABILITY_ASSIST_COUNTERSTEER"], 0]'
            DefaultIndex = 2
        },
        @{
            Variable = 'FIXICS_stabilityActivationSpeedKmh'
            ControlType = 'SLIDER'
            NamespaceDefault = '35'
            Payload = '[10, 160, 35, 0]'
            DefaultIndex = 2
        },
        @{
            Variable = 'FIXICS_stabilitySlipThreshold'
            ControlType = 'SLIDER'
            NamespaceDefault = '0.12'
            Payload = '[0.05, 0.8, 0.12, 2]'
            DefaultIndex = 2
        },
        @{
            Variable = 'FIXICS_stabilityYawStrength'
            ControlType = 'SLIDER'
            NamespaceDefault = '0.22'
            Payload = '[0, 1, 0.22, 2]'
            DefaultIndex = 2
        },
        @{
            Variable = 'FIXICS_stabilityLateralStrength'
            ControlType = 'SLIDER'
            NamespaceDefault = '0.12'
            Payload = '[0, 1, 0.12, 2]'
            DefaultIndex = 2
        },
        @{
            Variable = 'FIXICS_stabilityCountersteerStrength'
            ControlType = 'SLIDER'
            NamespaceDefault = '0.08'
            Payload = '[0, 0.5, 0.08, 2]'
            DefaultIndex = 2
        },
        @{
            Variable = 'FIXICS_stabilityMaximumCorrection'
            ControlType = 'SLIDER'
            NamespaceDefault = '0.12'
            Payload = '[0.01, 0.5, 0.12, 2]'
            DefaultIndex = 2
        },
        @{
            Variable = 'FIXICS_stabilityDebugLogging'
            ControlType = 'CHECKBOX'
            NamespaceDefault = 'false'
            Payload = 'false'
            DefaultIndex = 0
        }
    )
    foreach ($Spec in $StabilitySettings) {
        Assert-Contains `
            $Settings `
            ('missionNamespace setVariable \["' + $Spec.Variable + '", ' + [regex]::Escape($Spec.NamespaceDefault) + ', false\];') `
            "$($Spec.Variable) must have the approved Task 3 default."
        Assert-CbaSetting $Settings $Spec
    }

    $RollStabilitySettings = @(
        @{
            Variable = 'FIXICS_rollStabilityPreset'
            ControlType = 'LIST'
            NamespaceDefault = '0'
            Payload = '[[0, 1, 2, 3], [localize "STR_FIXICS_SETTING_ROLL_PRESET_REALISTIC_STABLE", localize "STR_FIXICS_SETTING_ROLL_PRESET_OFFROAD_ASSIST", localize "STR_FIXICS_SETTING_ROLL_PRESET_AGGRESSIVE_SQA", localize "STR_FIXICS_SETTING_ROLL_PRESET_CUSTOM"], 0]'
            DefaultIndex = 2
        },
        @{
            Variable = 'FIXICS_rollStabilityEnabled'
            ControlType = 'CHECKBOX'
            NamespaceDefault = 'true'
            Payload = 'true'
            DefaultIndex = 0
        },
        @{
            Variable = 'FIXICS_rollActivationBankDeg'
            ControlType = 'SLIDER'
            NamespaceDefault = '18'
            Payload = '[5, 60, 18, 0]'
            DefaultIndex = 2
        },
        @{
            Variable = 'FIXICS_rollActivationRateDeg'
            ControlType = 'SLIDER'
            NamespaceDefault = '45'
            Payload = '[5, 240, 45, 0]'
            DefaultIndex = 2
        },
        @{
            Variable = 'FIXICS_rollStrength'
            ControlType = 'SLIDER'
            NamespaceDefault = '0.08'
            Payload = '[0, 0.5, 0.08, 2]'
            DefaultIndex = 2
        },
        @{
            Variable = 'FIXICS_rollMaximumCorrection'
            ControlType = 'SLIDER'
            NamespaceDefault = '0.08'
            Payload = '[0.01, 0.4, 0.08, 2]'
            DefaultIndex = 2
        },
        @{
            Variable = 'FIXICS_rollAirborneGraceSeconds'
            ControlType = 'SLIDER'
            NamespaceDefault = '0.35'
            Payload = '[0, 1, 0.35, 2]'
            DefaultIndex = 2
        }
    )
    foreach ($Spec in $RollStabilitySettings) {
        Assert-Contains `
            $Settings `
            ('missionNamespace setVariable \["' + $Spec.Variable + '", ' + [regex]::Escape($Spec.NamespaceDefault) + ', false\];') `
            "$($Spec.Variable) must have the approved roll stability default."
        Assert-CbaSetting $Settings $Spec
    }

    Assert-Contains $Stringtable 'STR_FIXICS_SETTING_ROLL_PRESET_AGGRESSIVE_SQA' 'Stringtable must expose the Aggressive SQA roll preset label.'
    Assert-Contains $Stringtable 'STR_FIXICS_SETTING_ROLL_PRESET_OFFROAD_ASSIST' 'Stringtable must expose the Offroad Assist roll preset label.'
    Assert-Contains $Stringtable 'STR_FIXICS_SETTING_ROLL_PRESET_CUSTOM' 'Stringtable must expose the Custom roll preset label.'

    @(
        'FIXICS_runtimeAssistCoordinatorEnabled',
        'FIXICS_runtimeAssistTerrainInfluenceEnabled',
        'FIXICS_runtimeAssistTerrainInfluenceStrength',
        'FIXICS_runtimeAssistBrakingSlopeRetention',
        'FIXICS_runtimeAssistMassDampingStrength',
        'FIXICS_runtimeAssistMaximumComposedCorrection',
        'FIXICS_runtimeAssistDebugLogging'
    ) | ForEach-Object {
        Assert-Contains $Settings $_ "Runtime Assist setting $_ must be registered."
    }

    @(
        'STR_FIXICS_SETTING_RUNTIME_COORDINATOR_ENABLED',
        'STR_FIXICS_SETTING_RUNTIME_COORDINATOR_ENABLED_TOOLTIP',
        'STR_FIXICS_SETTING_RUNTIME_TERRAIN_ENABLED',
        'STR_FIXICS_SETTING_RUNTIME_TERRAIN_ENABLED_TOOLTIP',
        'STR_FIXICS_SETTING_RUNTIME_TERRAIN_STRENGTH',
        'STR_FIXICS_SETTING_RUNTIME_TERRAIN_STRENGTH_TOOLTIP',
        'STR_FIXICS_SETTING_RUNTIME_BRAKING_SLOPE_RETENTION',
        'STR_FIXICS_SETTING_RUNTIME_BRAKING_SLOPE_RETENTION_TOOLTIP',
        'STR_FIXICS_SETTING_RUNTIME_MASS_DAMPING',
        'STR_FIXICS_SETTING_RUNTIME_MASS_DAMPING_TOOLTIP',
        'STR_FIXICS_SETTING_RUNTIME_MAX_CORRECTION',
        'STR_FIXICS_SETTING_RUNTIME_MAX_CORRECTION_TOOLTIP',
        'STR_FIXICS_SETTING_RUNTIME_DEBUG_LOGGING',
        'STR_FIXICS_SETTING_RUNTIME_DEBUG_LOGGING_TOOLTIP'
    ) | ForEach-Object {
        Assert-Contains $Stringtable ('ID="' + $_ + '"') "Stringtable must define $_."
    }

    Assert-Contains $Settings 'missionNamespace setVariable \["FIXICS_runtimeAssistCoordinatorEnabled", true, false\]' 'Runtime Assist coordinator must default enabled.'
    Assert-Contains $Settings 'missionNamespace setVariable \["FIXICS_runtimeAssistBrakingSlopeRetention", 0\.35, false\]' 'Runtime Assist braking slope retention must default conservative.'
    Assert-Contains $Settings '\["FIXICS", "Runtime Assist"\]' 'Runtime Assist settings must use their own FIXICS Global category.'
}

$MonitorFile = Join-Path $RepoRoot 'addons\main\functions\fn_monitorVehicleAutobrake.sqf'
if (Test-Path -LiteralPath $MonitorFile) {
    $Monitor = Get-Content -Raw -LiteralPath $MonitorFile
    Assert-Contains $Monitor 'FIXICS_fnc_applySlopeRollback' 'Vehicle monitor must apply slope rollback assist.'
    Assert-Contains $Monitor 'FIXICS_fnc_applyHandbrakeLock' 'Vehicle monitor must enforce hard handbrake lock.'
    Assert-Contains $Monitor 'sleep 0\.25' 'Vehicle monitor must run frequently enough for local slope rollback assist.'
    Assert-Contains $Monitor 'private _shouldRoll' 'Vehicle monitor must calculate rolling ownership once per update.'
    Assert-Contains $Monitor 'if \(_shouldRoll\) then' 'Vehicle monitor must apply slope assist only while rolling.'
    Assert-Contains $Monitor '_x disableBrakes _priorBrakesDisabled' 'Vehicle monitor must restore the captured autobrake state when rolling ends.'
    Assert-Contains $Monitor 'private _isPlayerDriven' 'Vehicle monitor must identify vehicles owned by the local player driver controller.'
    Assert-Contains $Monitor 'FIXICS_vehicleControlsRegistered' 'Vehicle monitor must yield player ownership only after the fast controller is registered.'
    Assert-Contains $Monitor '!_isPlayerDriven' 'Vehicle monitor must skip player-driven vehicles owned by the fast controller.'
    Assert-Contains $Monitor 'FIXICS_brakeControlOwner' 'Vehicle monitor must track its autobrake ownership.'
    Assert-Contains $Monitor 'FIXICS_priorBrakesDisabled' 'Vehicle monitor must preserve the pre-FIXICS autobrake state.'
    Assert-Contains $Monitor 'brakesDisabled' 'Vehicle monitor must read the pre-FIXICS autobrake state.'
    Assert-Contains $Monitor 'FIXICS_vehicleAutobrakeMonitorLastUpdate' 'Vehicle monitor must measure actual scheduled elapsed time.'
    if ($Monitor -match 'FIXICS_fnc_applyABSBraking') {
        Add-Failure 'The slow vehicle monitor must not own player ABS braking.'
    }
}

$AbsFile = Join-Path $RepoRoot 'addons\main\functions\fn_applyABSBraking.sqf'
if (Test-Path -LiteralPath $AbsFile) {
    $Abs = Get-Content -Raw -LiteralPath $AbsFile
    Assert-Contains $Abs 'FIXICS_absEnabled' 'ABS helper must honor FIXICS_absEnabled.'
    Assert-Contains $Abs 'FIXICS_handbrakeEnabled' 'ABS helper must respect ACE handbrake state.'
    Assert-Contains $Abs 'inputAction "CarHandBrake"' 'ABS helper must check built-in handbrake input.'
    Assert-Contains $Abs '"_requestedDirection"' 'ABS helper must accept the controller-decoded direction intent.'
    if ($Abs -match 'inputAction "Car(?:Forward|FastForward|SlowForward|Back)"') {
        Add-Failure 'ABS helper must not independently decode W/S input.'
    }
    Assert-Contains $Abs 'vectorDir _vehicle' 'ABS helper must use vehicle orientation.'
    Assert-Contains $Abs 'velocityModelSpace _vehicle' 'ABS helper must read model-space longitudinal velocity.'
    Assert-Contains $Abs 'private _isForwardBraking' 'ABS helper must classify forward braking.'
    Assert-Contains $Abs 'private _isReverseBraking' 'ABS helper must classify reverse braking.'
    Assert-Contains $Abs '_requestedDirection < 0[\s\S]*?_longitudinalSpeed > _brakingThreshold' 'ABS helper must brake forward motion for reverse intent.'
    Assert-Contains $Abs '_requestedDirection > 0[\s\S]*?_longitudinalSpeed < -_brakingThreshold' 'ABS helper must brake reverse motion for forward intent.'
    Assert-Contains $Abs 'FIXICS_absLowSpeedCutoffKmh' 'ABS helper must honor the low-speed cutoff setting.'
    Assert-Contains $Abs 'FIXICS_absBrakeStrength' 'ABS helper must honor the brake strength setting.'
    Assert-Contains $Abs 'FIXICS_absReleaseBias' 'ABS helper must honor the release bias setting.'
    Assert-Contains $Abs 'FIXICS_absSlopeCompensation' 'ABS helper must honor slope compensation setting.'
    Assert-Contains $Abs 'FIXICS_absDebugLogging' 'ABS helper must honor debug logging setting.'
    Assert-Contains $Abs 'FIXICS_fnc_getNativeDriverAssist' 'ABS helper must consult the optional native driver assist bridge.'
    Assert-Contains $Abs 'source=%' 'ABS helper telemetry must include its recommendation source.'
    Assert-Contains $Abs '"native"' 'ABS helper telemetry must identify native-sourced recommendations.'
    Assert-Contains $Abs '"sqf"' 'ABS helper telemetry must identify SQF fallback recommendations.'
    Assert-Contains $Abs 'FIXICS_driverAssistDebugLogging' 'ABS helper must honor driver assist debug logging.'
    Assert-Contains $Abs 'private _applySqfAbsFallback' 'ABS helper must keep an explicit SQF fallback path.'
    Assert-Contains $Abs 'setVelocityModelSpace' 'ABS helper must apply adjusted model-space velocity.'
    if ($Abs -match '_vehicle setVelocity \[') {
        Add-Failure 'ABS helper must not rewrite world-space velocity.'
    }
    Assert-Contains $Abs '"_ignoreLowSpeedCutoff"' 'ABS helper must accept a direction-transition low-speed override.'
    Assert-Contains $Abs '!_ignoreLowSpeedCutoff' 'ABS helper must bypass the normal low-speed cutoff only when requested.'
    Assert-Contains $Abs '"_deltaTime"' 'ABS helper must accept elapsed time for controller/monitor-independent tuning.'
    Assert-Contains $Abs 'private _timeScale = \(\(_deltaTime[\s\S]*?\) / 0\.25;' 'ABS helper must normalize braking against the original monitor interval.'
    Assert-Contains $Abs 'FIXICS_absLastDecision' 'ABS must store last decision metadata for Runtime Assist telemetry.'
}

$DriverInputFile = Join-Path $RepoRoot 'addons\main\functions\fn_getDriverInputIntent.sqf'
if (Test-Path -LiteralPath $DriverInputFile) {
    $DriverInput = Get-Content -Raw -LiteralPath $DriverInputFile
    Assert-Contains $DriverInput 'inputAction "CarForward"' 'Driver input decoder must include standard forward input.'
    Assert-Contains $DriverInput 'inputAction "CarFastForward"' 'Driver input decoder must include fast-forward input.'
    Assert-Contains $DriverInput 'inputAction "CarSlowForward"' 'Driver input decoder must include slow-forward input.'
    Assert-Contains $DriverInput 'inputAction "CarBack"' 'Driver input decoder must include reverse/brake input.'
    Assert-Contains $DriverInput '\[_hasForwardInput, _hasBackInput, _requestedDirection\]' 'Driver input decoder must return normalized W/S intent.'
}

$SlopeRollbackFile = Join-Path $RepoRoot 'addons\main\functions\fn_applySlopeRollback.sqf'
if (Test-Path -LiteralPath $SlopeRollbackFile) {
    $SlopeRollback = Get-Content -Raw -LiteralPath $SlopeRollbackFile
    Assert-Contains $SlopeRollback 'surfaceNormal' 'Slope rollback helper must read terrain slope with surfaceNormal.'
    Assert-Contains $SlopeRollback 'setVelocity' 'Slope rollback helper must apply downhill velocity.'
    Assert-Contains $SlopeRollback 'velocity _vehicle' 'Slope rollback helper must preserve existing velocity.'
    Assert-Contains $SlopeRollback 'FIXICS_fnc_getDriverInputIntent' 'Slope rollback helper must use the shared W/S input decoder.'
    Assert-Contains $SlopeRollback '_hasForwardInput = _driverInputIntent # 0' 'Slope rollback helper must assign decoded forward input into the outer scope.'
    Assert-Contains $SlopeRollback '_hasBackInput = _driverInputIntent # 1' 'Slope rollback helper must assign decoded reverse input into the outer scope.'
    if ($SlopeRollback -match 'inputAction "Car(?:Forward|FastForward|SlowForward|Back)"') {
        Add-Failure 'Slope rollback helper must not independently decode W/S input.'
    }
    Assert-Contains $SlopeRollback 'inputAction "CarHandBrake"' 'Slope rollback helper must respect built-in temporary handbrake input.'
    Assert-Contains $SlopeRollback 'private _hasDriveInput' 'Slope rollback helper must calculate W/S drive input.'
    if ($SlopeRollback -match 'if\s*\(\s*_hasDriveInput\s*\)\s*exitWith\s*\{\s*false\s*\}') {
        Add-Failure 'Slope rollback helper must not exit on all W/S input; it must allow slope-relative acceleration while W/S is drive input.'
    }
    if ($SlopeRollback -match '_hasDriveInput && \{!_isStationary\}') {
        Add-Failure 'Slope rollback helper must not allow W/S near-stationary input to receive rollback assist.'
    }
    Assert-Contains $SlopeRollback 'FIXICS_slopeRollbackAcceleration", 0\.55' 'Slope rollback helper must use the stronger gear-independent acceleration default.'
    Assert-Contains $SlopeRollback 'FIXICS_fnc_getNativeSlopeControl' 'Slope rollback helper must consult the optional native gameplay-control bridge.'
    Assert-Contains $SlopeRollback 'FIXICS_handbrakeEnabled' 'Slope rollback helper must respect the ACE handbrake state.'
    Assert-Contains $SlopeRollback 'vectorDir _vehicle' 'Slope rollback helper must use vehicle orientation for drive-axis slope acceleration.'
    Assert-Contains $SlopeRollback 'private _forwardDownhillAlignment' 'Slope rollback helper must calculate forward/downhill orientation alignment.'
    Assert-Contains $SlopeRollback 'private _isForwardBraking' 'Slope rollback helper must classify S as braking when moving forward.'
    Assert-Contains $SlopeRollback 'private _isReverseBraking' 'Slope rollback helper must classify W as braking when moving backward.'
    Assert-Contains $SlopeRollback 'private _isBraking' 'Slope rollback helper must preserve normal braking by exiting during active braking.'
    Assert-Contains $SlopeRollback 'acos' 'Slope rollback helper must calculate slope angle in degrees.'
    Assert-Contains $SlopeRollback 'private _slopeAngleDegrees' 'Slope rollback helper must store slope angle in degrees.'
    Assert-Contains $SlopeRollback 'FIXICS_slopeCoastBreakawayVelocity' 'Slope rollback helper must apply a near-zero downhill coasting breakaway.'
    Assert-Contains $SlopeRollback 'FIXICS_slopeDriveAcceleration' 'Slope rollback helper must apply slope-relative drive acceleration.'
    Assert-Contains $SlopeRollback 'FIXICS_slopeDriveMaxSpeedKmh' 'Slope rollback helper must cap downhill drive assist speed.'
    Assert-Contains $SlopeRollback '_effectiveDriveSlope <= 0' 'Powered slope assist must never push against active drive intent uphill.'
    Assert-Contains $SlopeRollback 'private _inputBlocksSlopeAssist' 'Slope helper must carry input rejection out of the nested interface scope.'
    Assert-Contains $SlopeRollback 'if \(_inputBlocksSlopeAssist\) exitWith' 'Slope helper must reject handbrake/combined input from the function scope.'
    Assert-Contains $SlopeRollback '"_deltaTime"' 'Slope helper must accept elapsed time for controller/monitor-independent tuning.'
    Assert-Contains $SlopeRollback 'private _timeScale = \(\(_deltaTime[\s\S]*?\) / 0\.25;' 'Slope helper must normalize acceleration against the original monitor interval.'
    Assert-Contains $SlopeRollback 'FIXICS_slopeLastDecision' 'Slope rollback must store last decision metadata for Runtime Assist telemetry.'
    Assert-Contains $SlopeRollback 'FIXICS_runtimeAssistBrakingSlopeRetention' 'Slope rollback must allow reduced, not disabled, slope acceleration while service braking.'
}

$RegisterVehicleControlsFile = Join-Path $RepoRoot 'addons\main\functions\fn_registerVehicleControls.sqf'
if (Test-Path -LiteralPath $RegisterVehicleControlsFile) {
    $RegisterVehicleControls = Get-Content -Raw -LiteralPath $RegisterVehicleControlsFile
    Assert-Contains $RegisterVehicleControls 'CBA_fnc_addPerFrameHandler' 'Vehicle controls must use a CBA per-frame handler.'
    Assert-Contains $RegisterVehicleControls 'FIXICS_fnc_updateDriverController' 'Vehicle controls PFH must invoke the driver controller.'
    Assert-Contains $RegisterVehicleControls 'FIXICS_vehicleControlsRegistered' 'Vehicle controls registration must be idempotent.'
}

$DriverControllerFile = Join-Path $RepoRoot 'addons\main\functions\fn_updateDriverController.sqf'
if (Test-Path -LiteralPath $DriverControllerFile) {
    $DriverController = Get-Content -Raw -LiteralPath $DriverControllerFile
    Assert-Contains $DriverController 'FIXICS_driverControllerEnabled' 'Driver controller must honor its enable setting.'
    Assert-Contains $DriverController 'FIXICS_driverControllerInterval' 'Driver controller must honor its update interval.'
    Assert-Contains $DriverController '_getDriverAssist[\s\S]*FIXICS_fnc_getNativeDriverAssist' 'Driver controller helper must consult the optional native driver assist bridge.'
    Assert-Contains $DriverController 'FIXICS_driverAssistDebugLogging' 'Driver controller must honor driver assist debug logging.'
    Assert-Contains $DriverController 'source=%' 'Driver controller telemetry must include its recommendation source.'
    Assert-Contains $DriverController '"native"' 'Driver controller telemetry must identify native-sourced recommendations.'
    Assert-Contains $DriverController '"sqf"' 'Driver controller telemetry must identify SQF fallback recommendations.'
    Assert-Contains $DriverController 'isTouchingGround' 'Driver controller must not rewrite land-vehicle velocity while airborne.'
    Assert-Contains $DriverController 'velocityModelSpace' 'Driver controller must read model-space longitudinal velocity.'
    Assert-Contains $DriverController 'setVelocityModelSpace' 'Driver controller must apply model-space direction transitions.'
    Assert-Contains $DriverController 'FIXICS_fnc_getDriverInputIntent' 'Driver controller must use the shared W/S input decoder.'
    Assert-Contains $DriverController 'FIXICS_fnc_coordinateVehicleAssists' 'Driver controller finalizer must route through Runtime Assist Coordinator.'
    if ($DriverController -match 'inputAction "Car(?:Forward|FastForward|SlowForward|Back)"') {
        Add-Failure 'Driver controller must not independently decode W/S input.'
    }
    Assert-Contains $DriverController 'inputAction "CarHandBrake"' 'Driver controller must honor the configured X handbrake input.'
    Assert-Contains $DriverController '"COAST"' 'Driver controller must expose a COAST state.'
    Assert-Contains $DriverController '"DRIVE"' 'Driver controller must expose a DRIVE state.'
    Assert-Contains $DriverController '"REVERSE"' 'Driver controller must expose a REVERSE state.'
    Assert-Contains $DriverController '"SERVICE_BRAKE"' 'Driver controller must expose a SERVICE_BRAKE state.'
    Assert-Contains $DriverController '"NEUTRAL"' 'Driver controller must expose a NEUTRAL gearbox handoff state.'
    Assert-Contains $DriverController '"HANDBRAKE"' 'Driver controller must expose a HANDBRAKE state.'
    Assert-Contains $DriverController 'FIXICS_handbrakeInputWasDown' 'Toggle handbrake mode must use rising-edge input detection.'
    Assert-Contains $DriverController 'FIXICS_fnc_setVehicleHandbrake' 'Toggle handbrake mode must use the persistent FIXICS/ACE handbrake.'
    Assert-Contains $DriverController 'FIXICS_fnc_applyABSBraking' 'Service braking must invoke the ABS helper.'
    Assert-Contains $DriverController 'FIXICS_fnc_applySlopeRollback' 'Driver controller must own player slope assist.'
    Assert-Contains $DriverController 'private _finishUpdate = \{[\s\S]*?params \["_result"\];[\s\S]*?_currentState[\s\S]*?\[_vehicle, _deltaTime\] call FIXICS_fnc_applyVehicleStability;[\s\S]*?\[_vehicle, _deltaTime, _currentState\] call FIXICS_fnc_coordinateVehicleAssists;[\s\S]*?_result[\s\S]*?\};' 'Driver controller must centralize stability and runtime assist application in a finalizer.'
    Assert-Contains $DriverController 'if \(_transitionTarget != 0\) exitWith \{[\s\S]*?\[true\] call _finishUpdate\s*\};' 'Direction-transition completion must apply stability after longitudinal state work.'
    Assert-Contains $DriverController 'if \(_isCombinedBrake\) exitWith \{[\s\S]*?\[true\] call _finishUpdate\s*\};' 'Combined service-brake completion must apply stability after ABS/fallback braking.'
    Assert-Contains $DriverController 'if \(_requestedDirection != 0\) exitWith \{[\s\S]*?FIXICS_fnc_applySlopeRollback;[\s\S]*?\[true\] call _finishUpdate\s*\};' 'Drive/reverse completion must apply stability after slope rollback.'
    Assert-Contains $DriverController 'if \(\[_vehicle\] call FIXICS_fnc_shouldVehicleRoll\) then \{[\s\S]*?FIXICS_fnc_applySlopeRollback;[\s\S]*?\};[\s\S]*?\[true\] call _finishUpdate\s*$' 'Coast completion must apply stability after slope/coast longitudinal handling.'
    Assert-Contains $DriverController 'FIXICS_directionChangeThresholdKmh' 'Driver controller must honor direction change threshold.'
    Assert-Contains $DriverController 'FIXICS_directionLaunchVelocity' 'Driver controller must honor direction launch velocity.'
    Assert-Contains $DriverController 'FIXICS_directionNeutralPulseSeconds' 'Driver controller must honor the neutral pulse duration.'
    Assert-Contains $DriverController 'FIXICS_directionTransitionTarget' 'Driver controller must latch the requested direction during opposite-input braking.'
    Assert-Contains $DriverController 'FIXICS_directionTransitionNeutralUntil' 'Driver controller must store the neutral pulse deadline.'
    Assert-Contains $DriverController '_now >= _neutralUntil[\s\S]*"NEUTRAL"[\s\S]*call _getDriverAssist' 'Native launch recommendations must be gated after the neutral pulse expires.'
    Assert-Contains $DriverController '_requestedDirection > 0 && \{_longitudinalSpeed < 0\}' 'Reverse-to-Drive detection must latch on any remaining reverse motion.'
    Assert-Contains $DriverController '_requestedDirection < 0 && \{_longitudinalSpeed > 0\}' 'Drive-to-Reverse detection must latch on any remaining forward motion.'
    Assert-Contains $DriverController '_requestedDirection != _transitionTarget' 'Driver controller must cancel a latched transition when input changes or is released.'
    Assert-Contains $DriverController '_modelVelocity set \[1, 0\]' 'Driver controller must clamp longitudinal velocity to exact zero during the neutral pulse.'
    Assert-Contains $DriverController '_now \+ _neutralPulseSeconds' 'Driver controller must start a configurable neutral deadline.'
    Assert-Contains $DriverController '_now >= _neutralUntil' 'Driver controller must delay direction launch until the neutral pulse expires.'
    Assert-Contains $DriverController 'FIXICS_driverControllerVehicle' 'Driver controller must track the vehicle whose brake ownership it changed.'
    Assert-Contains $DriverController 'private _releaseVehicle' 'Driver controller must clean up brake ownership when disabled or changing vehicles.'
    Assert-Contains $DriverController 'private _claimVehicle' 'Driver controller must claim autobrake ownership before changing it.'
    Assert-Contains $DriverController 'FIXICS_brakeControlOwner' 'Driver controller must identify its autobrake ownership.'
    Assert-Contains $DriverController 'FIXICS_priorBrakesDisabled' 'Driver controller must restore the pre-FIXICS autobrake state.'
    Assert-Contains $DriverController 'brakesDisabled' 'Driver controller must read the pre-FIXICS autobrake state.'
    Assert-Contains $DriverController 'FIXICS_driverControllerLastUpdate' 'Driver controller must calculate elapsed update time.'
    Assert-Contains $DriverController '\[\s*_vehicle,\s*_transitionTarget,\s*true,\s*_deltaTime\s*\]' 'Direction transitions must pass decoded intent and elapsed time to ABS.'
    Assert-Contains $DriverController '\[_vehicle, 0, true, _deltaTime\]' 'Combined braking must pass neutral brake intent and elapsed time to ABS.'
    Assert-Contains $DriverController '\[_vehicle, _deltaTime\]' 'Driver controller must pass elapsed time to slope assistance.'
    Assert-Contains $DriverController 'FIXICS_absReleaseBias' 'Direction-transition fallback braking must honor ABS release bias.'
    Assert-Contains $DriverController '\[_vehicle, "NEUTRAL"\] call _setState;\s*_vehicle disableBrakes false;' 'Neutral handoff must keep normal engine braking enabled.'
    $ServiceBrakeEngineBrakeCount = [regex]::Matches(
        $DriverController,
        '\[_vehicle, "SERVICE_BRAKE"\] call _setState;\s*_vehicle disableBrakes false;'
    ).Count
    if ($ServiceBrakeEngineBrakeCount -lt 2) {
        Add-Failure 'All service-brake paths must keep normal engine braking enabled.'
    }
    $FirstStabilityInvocation = $DriverController.IndexOf('call _finishUpdate')
    if ($FirstStabilityInvocation -lt 0) {
        Add-Failure 'Driver controller must invoke the stability finalizer from grounded non-handbrake completion paths.'
    } else {
        $InvalidVehicleExit = $DriverController.IndexOf('driver _vehicle != player')
        $AirborneExit = $DriverController.IndexOf('if (!isTouchingGround _vehicle) exitWith')
        $HandbrakeExit = $DriverController.IndexOf('if (_persistentHandbrake || {_temporaryHandbrake}) exitWith')
        if (
            $InvalidVehicleExit -lt 0 -or
            $AirborneExit -lt 0 -or
            $HandbrakeExit -lt 0 -or
            $FirstStabilityInvocation -le $InvalidVehicleExit -or
            $FirstStabilityInvocation -le $AirborneExit -or
            $FirstStabilityInvocation -le $HandbrakeExit
        ) {
            Add-Failure 'Stability finalizer must not be invoked by invalid-vehicle, airborne, or handbrake exits.'
        }
    }
    if ($DriverController -match 'if \(_requestedDirection != 0\) exitWith \{[\s\S]*?_modelVelocity set \[1,\s*_requestedDirection \* _launchVelocity\]') {
        Add-Failure 'Ordinary drive/reverse input must not inject launch velocity outside the neutral handoff.'
    }
    if ($DriverController -match 'if\s*\(\(abs _longitudinalSpeed\)\s*<=\s*_directionThreshold\)\s*then\s*\{\s*_modelVelocity set \[1,\s*_requestedDirection \* _launchVelocity\]') {
        Add-Failure 'Direction transition must not launch in the same update that first reaches the speed threshold.'
    }
}

$HandbrakeLockFile = Join-Path $RepoRoot 'addons\main\functions\fn_applyHandbrakeLock.sqf'
if (Test-Path -LiteralPath $HandbrakeLockFile) {
    $HandbrakeLock = Get-Content -Raw -LiteralPath $HandbrakeLockFile
    Assert-Contains $HandbrakeLock 'FIXICS_handbrakeEnabled' 'Handbrake lock helper must require FIXICS_handbrakeEnabled.'
    Assert-Contains $HandbrakeLock 'setVelocity \[0, 0, 0\]' 'Handbrake lock helper must zero vehicle velocity.'
    Assert-Contains $HandbrakeLock 'disableBrakes false' 'Handbrake lock helper must keep engine autobrake enabled while locked.'
    Assert-Contains $HandbrakeLock 'local _vehicle' 'Handbrake lock helper must only mutate local vehicles.'
    Assert-Contains $HandbrakeLock 'isTouchingGround' 'Handbrake lock helper must not freeze airborne vehicles.'
}

$HandlingConfigLogFile = Join-Path $RepoRoot 'addons\main\functions\fn_logVehicleHandlingConfig.sqf'
if (Test-Path -LiteralPath $HandlingConfigLogFile) {
    $HandlingConfigLog = Get-Content -Raw -LiteralPath $HandlingConfigLogFile
    Assert-Contains $HandlingConfigLog 'configOf _vehicle' 'Handling diagnostic must read the tested vehicle class config with configOf.'
    Assert-Contains $HandlingConfigLog 'brakeIdleSpeed' 'Handling diagnostic must include brakeIdleSpeed.'
    Assert-Contains $HandlingConfigLog 'dampingRateZeroThrottleClutchEngaged' 'Handling diagnostic must include engaged zero-throttle damping.'
    Assert-Contains $HandlingConfigLog 'dampingRateZeroThrottleClutchDisengaged' 'Handling diagnostic must include disengaged zero-throttle damping.'
    Assert-Contains $HandlingConfigLog 'PlayerSteeringCoefficients' 'Handling diagnostic must inspect inherited player steering coefficients.'
    @(
        'turnIncreaseConst',
        'turnIncreaseLinear',
        'turnIncreaseTime',
        'turnDecreaseConst',
        'turnDecreaseLinear',
        'turnDecreaseTime',
        'maxTurnHundred'
    ) | ForEach-Object {
        Assert-Contains $HandlingConfigLog $_ "Handling diagnostic must include steering coefficient $_."
    }
    Assert-Contains $HandlingConfigLog 'inputAction "CarLeft"' 'Handling diagnostic must record left steering input.'
    Assert-Contains $HandlingConfigLog 'inputAction "CarRight"' 'Handling diagnostic must record right steering input.'
    Assert-Contains $HandlingConfigLog 'inputAction "CarForward"' 'Handling diagnostic must record drive input.'
    Assert-Contains $HandlingConfigLog 'inputAction "CarFastForward"' 'Handling diagnostic must record fast drive input.'
    Assert-Contains $HandlingConfigLog 'inputAction "CarSlowForward"' 'Handling diagnostic must record slow drive input.'
    Assert-Contains $HandlingConfigLog 'inputAction "CarBack"' 'Handling diagnostic must record reverse input.'
    Assert-Contains $HandlingConfigLog 'inputAction "CarHandBrake"' 'Handling diagnostic must record engine handbrake input.'
    Assert-Contains $HandlingConfigLog 'velocity _vehicle' 'Handling diagnostic must record world-space velocity.'
    Assert-Contains $HandlingConfigLog 'velocityModelSpace _vehicle' 'Handling diagnostic must record model-space velocity.'
    Assert-Contains $HandlingConfigLog 'getPosWorld _vehicle' 'Handling diagnostic must record world position.'
    Assert-Contains $HandlingConfigLog 'getPosASL _vehicle' 'Handling diagnostic must record ASL position.'
    Assert-Contains $HandlingConfigLog 'getDir _vehicle' 'Handling diagnostic must record vehicle heading.'
    Assert-Contains $HandlingConfigLog 'vectorDir _vehicle' 'Handling diagnostic must record vehicle forward vector.'
    Assert-Contains $HandlingConfigLog 'vectorUp _vehicle' 'Handling diagnostic must record vehicle up vector.'
    Assert-Contains $HandlingConfigLog 'BIS_fnc_getPitchBank' 'Handling diagnostic must record pitch and bank.'
    if ($HandlingConfigLog -match '\[_vehicle\]\s+call\s+BIS_fnc_getPitchBank') {
        Add-Failure 'Handling diagnostic must pass the vehicle object directly to BIS_fnc_getPitchBank, not wrap it in an array.'
    }
    Assert-Contains $HandlingConfigLog 'surfaceNormal' 'Handling diagnostic must record terrain normal.'
    Assert-Contains $HandlingConfigLog 'isTouchingGround _vehicle' 'Handling diagnostic must record ground contact state.'
    Assert-Contains $HandlingConfigLog 'getAllHitPointsDamage _vehicle' 'Handling diagnostic must include wheel hitpoint damage proxy data.'
    Assert-Contains $HandlingConfigLog 'FIXICS_driverState' 'Handling diagnostic must include FIXICS driver state.'
    Assert-Contains $HandlingConfigLog 'FIXICS_handbrakeEnabled' 'Handling diagnostic must include persistent FIXICS handbrake state.'
    Assert-Contains $HandlingConfigLog 'FIXICS_absEnabled' 'Handling diagnostic must include ABS setting state.'
    Assert-Contains $HandlingConfigLog 'FIXICS_stabilityAssistMode' 'Handling diagnostic must include stability assist mode.'
    @(
        'FIXICS_runtimeAssistLastDecision',
        'runtimeAssistPriorityWinner',
        'runtimeAssistTerrainMultiplier',
        'runtimeAssistMassMultiplier',
        'runtimeAssistSuppressedAssists',
        'runtimeAssistFinalCorrection'
    ) | ForEach-Object {
        Assert-Contains $HandlingConfigLog $_ "Handling telemetry must include $_."
    }
    Assert-Contains $HandlingConfigLog '\[FIXICS\]\[RuntimeAssistSample\]' 'Handling telemetry must write compact Runtime Assist sample lines to avoid long-line truncation.'
    Assert-Contains $HandlingConfigLog 'finalCorrection=%' 'Compact Runtime Assist sample must include final correction.'
    Assert-Contains $HandlingConfigLog 'yawRate' 'Handling diagnostic must derive yaw rate during continuous capture.'
    Assert-Contains $HandlingConfigLog 'pitchRate' 'Handling diagnostic must derive pitch rate during continuous capture.'
    Assert-Contains $HandlingConfigLog 'bankRate' 'Handling diagnostic must derive bank rate during continuous capture.'
    Assert-Contains $HandlingConfigLog 'speed _vehicle' 'Handling diagnostic must record vehicle speed.'
    Assert-Contains $HandlingConfigLog 'spawn' 'Handling diagnostic must support continuous capture after the Debug Console closes.'
    Assert-Contains $HandlingConfigLog 'diag_tickTime' 'Handling diagnostic must bound continuous capture by elapsed time.'
    Assert-Contains $HandlingConfigLog 'sleep _interval' 'Handling diagnostic must honor its continuous sample interval.'
    Assert-Contains $HandlingConfigLog 'FIXICS_handlingConfigLogRunning' 'Handling diagnostic must prevent overlapping continuous captures.'
    Assert-Contains $HandlingConfigLog 'diag_log' 'Handling diagnostic must write evidence to the RPT log.'
    if ($HandlingConfigLog -match '\b(setVelocity|setVelocityModelSpace|setDir|setVectorDirAndUp|disableBrakes)\b') {
        Add-Failure 'Handling diagnostic must remain read-only and must not mutate vehicle physics.'
    }
}

$TelemetryExporterFile = Join-Path $RepoRoot 'tools\export-vehicle-telemetry.ps1'
if (Test-Path -LiteralPath $TelemetryExporterFile) {
    $TelemetryExporter = Get-Content -Raw -LiteralPath $TelemetryExporterFile
    Assert-Contains $TelemetryExporter 'RuntimeAssistSample' 'Telemetry exporter must include compact Runtime Assist sample lines.'
    Assert-Contains $TelemetryExporter '\$isRuntimeAssist' 'Telemetry exporter must route compact Runtime Assist sample lines through an explicit predicate.'
}

$SteeringDiagnosticsFile = Join-Path $RepoRoot 'addons\main\functions\fn_startSteeringDiagnostics.sqf'
if (Test-Path -LiteralPath $SteeringDiagnosticsFile) {
    $SteeringDiagnostics = Get-Content -Raw -LiteralPath $SteeringDiagnosticsFile
    Assert-Contains $SteeringDiagnostics 'params' 'Steering diagnostics must accept bounded duration and interval inputs.'
    Assert-Contains $SteeringDiagnostics 'spawn' 'Steering diagnostics must continue after the Debug Console closes.'
    Assert-Contains $SteeringDiagnostics 'inputAction "CarLeft"' 'Steering diagnostics must sample live left input.'
    Assert-Contains $SteeringDiagnostics 'inputAction "CarRight"' 'Steering diagnostics must sample live right input.'
    Assert-Contains $SteeringDiagnostics 'velocityModelSpace _vehicle' 'Steering diagnostics must sample model-space velocity.'
    Assert-Contains $SteeringDiagnostics 'getDir _vehicle' 'Steering diagnostics must sample heading.'
    Assert-Contains $SteeringDiagnostics 'speed _vehicle' 'Steering diagnostics must sample speed.'
    Assert-Contains $SteeringDiagnostics 'diag_tickTime' 'Steering diagnostics must use a bounded elapsed-time deadline.'
    Assert-Contains $SteeringDiagnostics 'sleep _interval' 'Steering diagnostics must use the requested sample interval.'
    Assert-Contains $SteeringDiagnostics 'FIXICS_steeringDiagnosticsRunning' 'Steering diagnostics must prevent overlapping captures.'
    if ($SteeringDiagnostics -match '\b(setVelocity|setVelocityModelSpace|setDir|setVectorDirAndUp|disableBrakes)\b') {
        Add-Failure 'Steering diagnostics must remain read-only and must not mutate vehicle physics.'
    }
}

$NativeBridgeFile = Join-Path $RepoRoot 'addons\main\functions\fn_getNativeSlopeControl.sqf'
if (Test-Path -LiteralPath $NativeBridgeFile) {
    $NativeBridge = Get-Content -Raw -LiteralPath $NativeBridgeFile
    Assert-Contains $NativeBridge '"FIXICS_nativeSlopeControlEnabled", false' 'Native gameplay-control bridge must default disabled.'
    Assert-Contains $NativeBridge '"FIXICSPhysics"\s+callExtension\s+\[[\s\S]*?"slopeControl"' 'Native gameplay-control bridge must call the FIXICSPhysics slopeControl function.'
    Assert-Contains $NativeBridge 'parseSimpleArray' 'Native gameplay-control bridge must parse the extension response.'
    Assert-Contains $NativeBridge 'errorCode' 'Native gameplay-control bridge must check callExtension errorCode.'
    Assert-Contains $NativeBridge '_minimumDelta' 'Native gameplay-control bridge must pass the coasting breakaway delta.'
}

$NativeDriverAssistFile = Join-Path $RepoRoot 'addons\main\functions\fn_getNativeDriverAssist.sqf'
if (Test-Path -LiteralPath $NativeDriverAssistFile) {
    $NativeDriverAssist = Get-Content -Raw -LiteralPath $NativeDriverAssistFile
    Assert-Contains $NativeDriverAssist '"FIXICS_nativeDriverAssistEnabled", false' 'Native driver assist bridge must default disabled.'
    Assert-Contains $NativeDriverAssist '"FIXICSPhysics"\s+callExtension\s+\[[\s\S]*?"driverAssist"' 'Native driver assist bridge must call the FIXICSPhysics driverAssist function.'
    Assert-Contains $NativeDriverAssist 'parseSimpleArray' 'Native driver assist bridge must parse the extension response.'
    Assert-Contains $NativeDriverAssist 'errorCode' 'Native driver assist bridge must check callExtension errorCode.'
    Assert-Contains $NativeDriverAssist 'isEqualType' 'Native driver assist bridge must validate response element types.'
    Assert-Contains $NativeDriverAssist 'finite' 'Native driver assist bridge must reject non-finite numeric recommendations.'
}

$NativeSourceFile = Join-Path $RepoRoot 'native\fixics_physics\src\FIXICSPhysics.cpp'
if (Test-Path -LiteralPath $NativeSourceFile) {
    $NativeSource = Get-Content -Raw -LiteralPath $NativeSourceFile
    Assert-Contains $NativeSource 'RVExtensionVersion' 'Native source must export RVExtensionVersion.'
    Assert-Contains $NativeSource 'RVExtensionArgs' 'Native source must export RVExtensionArgs.'
    Assert-Contains $NativeSource 'slopeControl' 'Native source must implement slopeControl dispatch.'
    Assert-Contains $NativeSource 'FIXICSPhysics' 'Native source must use the FIXICSPhysics extension identity.'
    Assert-Contains $NativeSource 'minimumDelta' 'Native source must support a coasting breakaway delta.'
    Assert-Contains $NativeSource 'driverAssist' 'Native source must implement driverAssist dispatch.'
    Assert-Contains $NativeSource 'command == "driverAssist"' 'Native source must dispatch driverAssist explicitly.'
    Assert-Contains $NativeSource 'driverAssist\(args, argsCount\)' 'Native source must route driverAssist command arguments through the driverAssist handler.'
    Assert-Contains $NativeSource 'copyOutput\(output, outputSize, "\[\\"slopeControl[\s\S]*\\"driverAssist\\"' 'Native source schema payload must advertise driverAssist.'
    Assert-Contains $NativeSource 'std::isfinite' 'Native source must reject non-finite driver assist inputs.'
    Assert-Contains $NativeSource 'DriverAssistInput' 'Native source must use a named input structure for driver assist.'
    Assert-Contains $NativeSource 'DriverAssistResult' 'Native source must use a named result structure for driver assist.'
    Assert-Contains $NativeSource 'targetLongitudinalSpeed' 'Native source must return a bounded target longitudinal speed.'
    Assert-Contains $NativeSource 'brakeDelta' 'Native source must return a bounded brake delta.'
    if ($NativeSource -match 'strncpy') {
        Add-Failure 'Native source must avoid strncpy to keep MSVC warning output clean.'
    }
}

$NativeTestsFile = Join-Path $RepoRoot 'native\fixics_physics\tests\FIXICSPhysicsTests.cpp'
if (Test-Path -LiteralPath $NativeTestsFile) {
    $NativeTests = Get-Content -Raw -LiteralPath $NativeTestsFile
    Assert-Contains $NativeTests 'driverAssist' 'Native tests must cover driverAssist.'
    Assert-Contains $NativeTests 'expectEqual' 'Native tests must compare exact driverAssist outputs.'
    Assert-Contains $NativeTests 'callDriverAssist' 'Native tests must invoke driverAssist through a shared helper.'
    Assert-Contains $NativeTests 'forward braking' 'Native tests must cover forward braking driverAssist behavior.'
    Assert-Contains $NativeTests 'reverse braking' 'Native tests must cover reverse braking driverAssist behavior.'
    Assert-Contains $NativeTests 'low speed cutoff' 'Native tests must cover the driverAssist low speed cutoff.'
    Assert-Contains $NativeTests 'neutral launch' 'Native tests must cover neutral launch driverAssist behavior.'
    Assert-Contains $NativeTests 'non-finite input' 'Native tests must cover non-finite driverAssist input rejection.'
    Assert-Contains $NativeTests '\[true,\\"SERVICE_BRAKE\\",4\.7075,0\.2925,0,\\"brake\\"\]' 'Native tests must verify forward braking output exactly.'
    Assert-Contains $NativeTests '\[true,\\"SERVICE_BRAKE\\",-4\.7075,0\.2925,0,\\"brake\\"\]' 'Native tests must verify reverse braking output exactly.'
    Assert-Contains $NativeTests '\[false,\\"NONE\\",0\.5,0,0,\\"below-cutoff\\"\]' 'Native tests must verify low-speed cutoff output exactly.'
    Assert-Contains $NativeTests '\[true,\\"LAUNCH\\",0\.35,0,1,\\"launch\\"\]' 'Native tests must verify neutral launch output exactly.'
    Assert-Contains $NativeTests '\[false,\\"NONE\\",0,0,0,\\"invalid\\"\]' 'Native tests must verify non-finite input rejection output exactly.'
}

$NativeReadmeFile = Join-Path $RepoRoot 'native\fixics_physics\README.md'
if (Test-Path -LiteralPath $NativeReadmeFile) {
    $NativeReadme = Get-Content -Raw -LiteralPath $NativeReadmeFile
    Assert-Contains $NativeReadme 'native-assisted gameplay control' 'Native README must describe the native-assisted gameplay-control boundary.'
    Assert-Contains $NativeReadme 'FIXICSPhysics_x64\.dll' 'Native README must document the approved Windows x64 binary.'
    Assert-Contains $NativeReadme 'driverAssist' 'Native README must document driverAssist.'
    Assert-Contains $NativeReadme 'native advisor' 'Native README must preserve the SQF-owned mutation boundary.'
}

$NativeCmakeFile = Join-Path $RepoRoot 'native\fixics_physics\CMakeLists.txt'
if (Test-Path -LiteralPath $NativeCmakeFile) {
    $NativeCmake = Get-Content -Raw -LiteralPath $NativeCmakeFile
    Assert-Contains $NativeCmake 'add_library\(FIXICSPhysics SHARED' 'Native CMake file must build FIXICSPhysics as a shared library.'
    Assert-Contains $NativeCmake 'FIXICSPhysics_x64' 'Native CMake file must name the Windows x64 output FIXICSPhysics_x64.'
    Assert-Contains $NativeCmake 'include\(CTest\)' 'Native CMake must enable CTest.'
    Assert-Contains $NativeCmake 'add_executable\(FIXICSPhysicsTests' 'Native CMake must build FIXICSPhysicsTests.'
    Assert-Contains $NativeCmake 'target_link_libraries\(FIXICSPhysicsTests PRIVATE FIXICSPhysics\)' 'Native CMake must link FIXICSPhysicsTests against FIXICSPhysics.'
    Assert-Contains $NativeCmake 'add_test\(NAME FIXICSPhysicsTests COMMAND FIXICSPhysicsTests\)' 'Native CMake must register FIXICSPhysicsTests with CTest.'
}

$NativeBuildScriptFile = Join-Path $RepoRoot 'tools\build-native.ps1'
if (Test-Path -LiteralPath $NativeBuildScriptFile) {
    $NativeBuildScript = Get-Content -Raw -LiteralPath $NativeBuildScriptFile
    Assert-Contains $NativeBuildScript 'VsDevCmd\.bat' 'Native build script must load the Visual Studio developer environment.'
    Assert-Contains $NativeBuildScript 'cmake' 'Native build script must invoke CMake.'
    Assert-Contains $NativeBuildScript 'FIXICSPhysics_x64\.dll' 'Native build script must verify the approved Windows x64 DLL output.'
    Assert-Contains $NativeBuildScript 'ctest --test-dir `"\$NativeBuild`"[^\r\n]*--output-on-failure' 'Native build script must run CTest against the native build directory with failure output enabled.'
}

$NativeBinaries = @()
if (Test-Path -LiteralPath (Join-Path $RepoRoot 'native')) {
    $NativeBinaries = Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'native') -Recurse -File | Where-Object {
        $_.Extension -in @('.dll', '.so', '.dylib')
    }
}
if ($NativeBinaries.Count -gt 0) {
    $Paths = ($NativeBinaries | ForEach-Object { $_.FullName }) -join ', '
    Add-Failure "Native binaries must not be stored under native source folders: $Paths"
}

$ApprovedNativeDll = Join-Path $RepoRoot 'FIXICSPhysics_x64.dll'
if (Test-Path -LiteralPath $ApprovedNativeDll) {
    $DllInfo = Get-Item -LiteralPath $ApprovedNativeDll
    if ($DllInfo.Length -le 0) {
        Add-Failure 'Approved native DLL exists but is empty: FIXICSPhysics_x64.dll'
    }
}

if ($Failures.Count -gt 0) {
    Write-Host 'FIXICS vehicle physics static test failed:'
    foreach ($Failure in $Failures) {
        Write-Host " - $Failure"
    }
    exit 1
}

Write-Host 'FIXICS vehicle physics static test passed.'
