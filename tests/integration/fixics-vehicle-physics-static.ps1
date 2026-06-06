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
    'addons\main\functions\fn_applyHandbrakeLock.sqf',
    'addons\main\functions\fn_logVehicleHandlingConfig.sqf',
    'addons\main\functions\fn_getNativeSlopeControl.sqf'
) | ForEach-Object {
    Assert-FileExists $_
}

@(
    'native\fixics_physics\src\FIXICSPhysics.cpp',
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
Assert-Contains $Config 'class applyHandbrakeLock\s*\{\s*\};' 'applyHandbrakeLock must be registered in CfgFunctions.'
Assert-Contains $Config 'class logVehicleHandlingConfig\s*\{\s*\};' 'logVehicleHandlingConfig must be registered in CfgFunctions.'
Assert-Contains $Config 'class getNativeSlopeControl\s*\{\s*\};' 'getNativeSlopeControl must be registered in CfgFunctions.'
if ($Config -match 'class CfgVehicles|brakeIdleSpeed\s*=\s*0\.01|dampingRateZeroThrottleClutchEngaged\s*=\s*0\.25|dampingRateZeroThrottleClutchDisengaged\s*=\s*0\.25') {
    Add-Failure 'Failed config-class experiment must be removed before native gameplay-control escalation.'
}

Assert-Contains $Init 'FIXICS_fnc_hello' 'fn_init.sqf must call FIXICS_fnc_hello.'
Assert-Contains $Init 'FIXICS_fnc_registerSettings' 'fn_init.sqf must register CBA settings.'
Assert-Contains $Init 'FIXICS_fnc_registerAceInteractions' 'fn_init.sqf must register ACE interactions.'
Assert-Contains $Init 'FIXICS_fnc_monitorVehicleAutobrake' 'fn_init.sqf must start the vehicle autobrake monitor.'
Assert-Contains $Mission 'FIXICS_fnc_vrHello' 'VR mission must call FIXICS_fnc_vrHello.'

Assert-Contains $Stringtable 'STR_FIXICS_HAND_BRAKE_SET' 'Stringtable must define Set Handbrake text.'
Assert-Contains $Stringtable 'STR_FIXICS_HAND_BRAKE_RELEASE' 'Stringtable must define Release Handbrake text.'
Assert-Contains $Stringtable 'STR_FIXICS_HAND_BRAKE_STATUS_SET' 'Stringtable must define handbrake set status text.'
Assert-Contains $Stringtable 'STR_FIXICS_HAND_BRAKE_STATUS_RELEASED' 'Stringtable must define handbrake released status text.'
Assert-Contains $Stringtable 'STR_FIXICS_SETTING_DISABLE_IDLE_AUTOBRAKE' 'Stringtable must define the idle autobrake setting title.'
Assert-Contains $Stringtable 'STR_FIXICS_SETTING_DISABLE_IDLE_AUTOBRAKE_TOOLTIP' 'Stringtable must define the idle autobrake setting tooltip.'

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
}

$DecisionFile = Join-Path $RepoRoot 'addons\main\functions\fn_shouldVehicleRoll.sqf'
if (Test-Path -LiteralPath $DecisionFile) {
    $Decision = Get-Content -Raw -LiteralPath $DecisionFile
    Assert-Contains $Decision '"FIXICS_handbrakeEnabled"' 'Decision helper must check FIXICS_handbrakeEnabled.'
    Assert-Contains $Decision 'FIXICS_disableIdleAutobrake' 'Decision helper must check FIXICS_disableIdleAutobrake.'
    Assert-Contains $Decision 'CarBack' 'Decision helper must check built-in car brake input.'
    Assert-Contains $Decision 'CarHandBrake' 'Decision helper must check built-in car handbrake input.'
    Assert-Contains $Decision 'FIXICS_stationaryBrakeBypassSpeedKmh' 'Decision helper must define the near-stationary brake bypass threshold.'
    Assert-Contains $Decision 'private _isStationary' 'Decision helper must calculate near-stationary state.'
    Assert-Contains $Decision '_isBraking && \{!_isStationary\}' 'CarBack must only block rolling while above near-stationary speed.'

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
}

$MonitorFile = Join-Path $RepoRoot 'addons\main\functions\fn_monitorVehicleAutobrake.sqf'
if (Test-Path -LiteralPath $MonitorFile) {
    $Monitor = Get-Content -Raw -LiteralPath $MonitorFile
    Assert-Contains $Monitor 'FIXICS_fnc_applySlopeRollback' 'Vehicle monitor must apply slope rollback assist.'
    Assert-Contains $Monitor 'FIXICS_fnc_applyHandbrakeLock' 'Vehicle monitor must enforce hard handbrake lock.'
    Assert-Contains $Monitor 'sleep 0\.25' 'Vehicle monitor must run frequently enough for local slope rollback assist.'
}

$SlopeRollbackFile = Join-Path $RepoRoot 'addons\main\functions\fn_applySlopeRollback.sqf'
if (Test-Path -LiteralPath $SlopeRollbackFile) {
    $SlopeRollback = Get-Content -Raw -LiteralPath $SlopeRollbackFile
    Assert-Contains $SlopeRollback 'surfaceNormal' 'Slope rollback helper must read terrain slope with surfaceNormal.'
    Assert-Contains $SlopeRollback 'setVelocity' 'Slope rollback helper must apply downhill velocity.'
    Assert-Contains $SlopeRollback 'velocity _vehicle' 'Slope rollback helper must preserve existing velocity.'
    Assert-Contains $SlopeRollback 'inputAction "CarForward"' 'Slope rollback helper must not fight forward throttle input.'
    Assert-Contains $SlopeRollback 'inputAction "CarBack"' 'Slope rollback helper must not fight reverse throttle input.'
    Assert-Contains $SlopeRollback 'inputAction "CarHandBrake"' 'Slope rollback helper must respect built-in temporary handbrake input.'
    Assert-Contains $SlopeRollback 'FIXICS_stationaryBrakeBypassSpeedKmh' 'Slope rollback helper must use the near-stationary threshold for W/S input.'
    Assert-Contains $SlopeRollback 'private _isStationary' 'Slope rollback helper must calculate near-stationary state.'
    Assert-Contains $SlopeRollback '_hasDriveInput && \{!_isStationary\}' 'W/S input must only block rollback while above near-stationary speed.'
    Assert-Contains $SlopeRollback 'FIXICS_slopeRollbackAcceleration", 0\.55' 'Slope rollback helper must use the stronger gear-independent acceleration default.'
    Assert-Contains $SlopeRollback 'FIXICS_fnc_getNativeSlopeControl' 'Slope rollback helper must consult the optional native gameplay-control bridge.'
    Assert-Contains $SlopeRollback 'FIXICS_handbrakeEnabled' 'Slope rollback helper must respect the ACE handbrake state.'
}

$HandbrakeLockFile = Join-Path $RepoRoot 'addons\main\functions\fn_applyHandbrakeLock.sqf'
if (Test-Path -LiteralPath $HandbrakeLockFile) {
    $HandbrakeLock = Get-Content -Raw -LiteralPath $HandbrakeLockFile
    Assert-Contains $HandbrakeLock 'FIXICS_handbrakeEnabled' 'Handbrake lock helper must require FIXICS_handbrakeEnabled.'
    Assert-Contains $HandbrakeLock 'setVelocity \[0, 0, 0\]' 'Handbrake lock helper must zero vehicle velocity.'
    Assert-Contains $HandbrakeLock 'disableBrakes false' 'Handbrake lock helper must keep engine autobrake enabled while locked.'
    Assert-Contains $HandbrakeLock 'local _vehicle' 'Handbrake lock helper must only mutate local vehicles.'
}

$HandlingConfigLogFile = Join-Path $RepoRoot 'addons\main\functions\fn_logVehicleHandlingConfig.sqf'
if (Test-Path -LiteralPath $HandlingConfigLogFile) {
    $HandlingConfigLog = Get-Content -Raw -LiteralPath $HandlingConfigLogFile
    Assert-Contains $HandlingConfigLog 'configOf _vehicle' 'Handling diagnostic must read the tested vehicle class config with configOf.'
    Assert-Contains $HandlingConfigLog 'brakeIdleSpeed' 'Handling diagnostic must include brakeIdleSpeed.'
    Assert-Contains $HandlingConfigLog 'dampingRateZeroThrottleClutchEngaged' 'Handling diagnostic must include engaged zero-throttle damping.'
    Assert-Contains $HandlingConfigLog 'dampingRateZeroThrottleClutchDisengaged' 'Handling diagnostic must include disengaged zero-throttle damping.'
    Assert-Contains $HandlingConfigLog 'diag_log' 'Handling diagnostic must write evidence to the RPT log.'
}

$NativeBridgeFile = Join-Path $RepoRoot 'addons\main\functions\fn_getNativeSlopeControl.sqf'
if (Test-Path -LiteralPath $NativeBridgeFile) {
    $NativeBridge = Get-Content -Raw -LiteralPath $NativeBridgeFile
    Assert-Contains $NativeBridge '"FIXICS_nativeSlopeControlEnabled", false' 'Native gameplay-control bridge must default disabled.'
    Assert-Contains $NativeBridge '"FIXICSPhysics"\s+callExtension\s+\[[\s\S]*?"slopeControl"' 'Native gameplay-control bridge must call the FIXICSPhysics slopeControl function.'
    Assert-Contains $NativeBridge 'parseSimpleArray' 'Native gameplay-control bridge must parse the extension response.'
    Assert-Contains $NativeBridge 'errorCode' 'Native gameplay-control bridge must check callExtension errorCode.'
}

$NativeSourceFile = Join-Path $RepoRoot 'native\fixics_physics\src\FIXICSPhysics.cpp'
if (Test-Path -LiteralPath $NativeSourceFile) {
    $NativeSource = Get-Content -Raw -LiteralPath $NativeSourceFile
    Assert-Contains $NativeSource 'RVExtensionVersion' 'Native source must export RVExtensionVersion.'
    Assert-Contains $NativeSource 'RVExtensionArgs' 'Native source must export RVExtensionArgs.'
    Assert-Contains $NativeSource 'slopeControl' 'Native source must implement slopeControl dispatch.'
    Assert-Contains $NativeSource 'FIXICSPhysics' 'Native source must use the FIXICSPhysics extension identity.'
    if ($NativeSource -match 'strncpy') {
        Add-Failure 'Native source must avoid strncpy to keep MSVC warning output clean.'
    }
}

$NativeReadmeFile = Join-Path $RepoRoot 'native\fixics_physics\README.md'
if (Test-Path -LiteralPath $NativeReadmeFile) {
    $NativeReadme = Get-Content -Raw -LiteralPath $NativeReadmeFile
    Assert-Contains $NativeReadme 'native-assisted gameplay control' 'Native README must describe the native-assisted gameplay-control boundary.'
    Assert-Contains $NativeReadme 'FIXICSPhysics_x64\.dll' 'Native README must document the approved Windows x64 binary.'
}

$NativeCmakeFile = Join-Path $RepoRoot 'native\fixics_physics\CMakeLists.txt'
if (Test-Path -LiteralPath $NativeCmakeFile) {
    $NativeCmake = Get-Content -Raw -LiteralPath $NativeCmakeFile
    Assert-Contains $NativeCmake 'add_library\(FIXICSPhysics SHARED' 'Native CMake file must build FIXICSPhysics as a shared library.'
    Assert-Contains $NativeCmake 'FIXICSPhysics_x64' 'Native CMake file must name the Windows x64 output FIXICSPhysics_x64.'
}

$NativeBuildScriptFile = Join-Path $RepoRoot 'tools\build-native.ps1'
if (Test-Path -LiteralPath $NativeBuildScriptFile) {
    $NativeBuildScript = Get-Content -Raw -LiteralPath $NativeBuildScriptFile
    Assert-Contains $NativeBuildScript 'VsDevCmd\.bat' 'Native build script must load the Visual Studio developer environment.'
    Assert-Contains $NativeBuildScript 'cmake' 'Native build script must invoke CMake.'
    Assert-Contains $NativeBuildScript 'FIXICSPhysics_x64\.dll' 'Native build script must verify the approved Windows x64 DLL output.'
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
