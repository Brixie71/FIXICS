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

@(
    'addons\main\functions\fn_registerAceInteractions.sqf',
    'addons\main\functions\fn_setVehicleHandbrake.sqf',
    'addons\main\functions\fn_shouldVehicleRoll.sqf',
    'addons\main\functions\fn_monitorVehicleAutobrake.sqf'
) | ForEach-Object {
    Assert-FileExists $_
}

Assert-Contains $Config 'class registerAceInteractions\s*\{\s*\};' 'registerAceInteractions must be registered in CfgFunctions.'
Assert-Contains $Config 'class setVehicleHandbrake\s*\{\s*\};' 'setVehicleHandbrake must be registered in CfgFunctions.'
Assert-Contains $Config 'class shouldVehicleRoll\s*\{\s*\};' 'shouldVehicleRoll must be registered in CfgFunctions.'
Assert-Contains $Config 'class monitorVehicleAutobrake\s*\{\s*\};' 'monitorVehicleAutobrake must be registered in CfgFunctions.'

Assert-Contains $Init 'FIXICS_fnc_hello' 'fn_init.sqf must call FIXICS_fnc_hello.'
Assert-Contains $Init 'FIXICS_fnc_registerAceInteractions' 'fn_init.sqf must register ACE interactions.'
Assert-Contains $Init 'FIXICS_fnc_monitorVehicleAutobrake' 'fn_init.sqf must start the vehicle autobrake monitor.'
Assert-Contains $Mission 'FIXICS_fnc_vrHello' 'VR mission must call FIXICS_fnc_vrHello.'

Assert-Contains $Stringtable 'STR_FIXICS_HAND_BRAKE_SET' 'Stringtable must define Set Handbrake text.'
Assert-Contains $Stringtable 'STR_FIXICS_HAND_BRAKE_RELEASE' 'Stringtable must define Release Handbrake text.'
Assert-Contains $Stringtable 'STR_FIXICS_HAND_BRAKE_STATUS_SET' 'Stringtable must define handbrake set status text.'
Assert-Contains $Stringtable 'STR_FIXICS_HAND_BRAKE_STATUS_RELEASED' 'Stringtable must define handbrake released status text.'

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
}

$DecisionFile = Join-Path $RepoRoot 'addons\main\functions\fn_shouldVehicleRoll.sqf'
if (Test-Path -LiteralPath $DecisionFile) {
    $Decision = Get-Content -Raw -LiteralPath $DecisionFile
    Assert-Contains $Decision '"FIXICS_handbrakeEnabled"' 'Decision helper must check FIXICS_handbrakeEnabled.'
    Assert-Contains $Decision 'CarBack' 'Decision helper must check built-in car brake input.'
    Assert-Contains $Decision 'CarHandBrake' 'Decision helper must check built-in car handbrake input.'
}

if ($Failures.Count -gt 0) {
    Write-Host 'FIXICS vehicle physics static test failed:'
    foreach ($Failure in $Failures) {
        Write-Host " - $Failure"
    }
    exit 1
}

Write-Host 'FIXICS vehicle physics static test passed.'
