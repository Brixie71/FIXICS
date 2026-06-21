$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$FunctionPath = Join-Path $RepoRoot 'addons\main\functions\fn_getRuntimeAssistRecommendation.sqf'
$Failures = New-Object System.Collections.Generic.List[string]

function Add-Failure {
    param ([Parameter(Mandatory = $true)][string]$Message)
    $Failures.Add($Message)
}

function Assert-Contains {
    param (
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if ($Content -notmatch $Pattern) {
        Add-Failure $Message
    }
}

function Test-Finite {
    param ([double]$Value)
    return -not ([double]::IsNaN($Value) -or [double]::IsInfinity($Value))
}

function Get-RecommendationMirror {
    param (
        [hashtable]$State,
        [hashtable]$Settings
    )

    foreach ($Name in @('SpeedKmh', 'TerrainFriction', 'MassKg', 'SlopeDelta', 'StabilityDelta', 'RollDelta')) {
        if (-not (Test-Finite ([double]$State[$Name]))) {
            return @{
                Applied = $false
                PriorityWinner = 'invalid'
                TerrainMultiplier = 1.0
                MassMultiplier = 1.0
                SlopeRetention = 1.0
                SuppressedAssists = @('invalid')
                FinalCorrection = 0.0
            }
        }
    }

    [double]$TerrainStrength = [math]::Min([math]::Max([double]$Settings.TerrainInfluenceStrength, 0.0), 1.0)
    [double]$BrakingSlopeRetention = [math]::Min([math]::Max([double]$Settings.BrakingSlopeRetention, 0.0), 1.0)
    [double]$MassDampingStrength = [math]::Min([math]::Max([double]$Settings.MassDampingStrength, 0.0), 1.0)
    [double]$MaximumComposedCorrection = [math]::Min([math]::Max([double]$Settings.MaximumComposedCorrection, 0.0), 0.5)

    $TerrainMultiplier = 1.0
    if ($Settings.TerrainInfluenceEnabled) {
        $TerrainMultiplier = 1.0 - ((1.0 - [double]$State.TerrainFriction) * $TerrainStrength)
        $TerrainMultiplier = [math]::Min([math]::Max($TerrainMultiplier, 0.35), 1.0)
    }

    $MassMultiplier = 1.0 - ([math]::Min([math]::Max(([double]$State.MassKg - 1200.0) / 2800.0, 0.0), 1.0) * $MassDampingStrength)
    $MassMultiplier = [math]::Min([math]::Max($MassMultiplier, 0.45), 1.0)

    $Suppressed = @()
    $SlopeDelta = [double]$State.SlopeDelta
    if ($State.ServiceBraking) {
        $SlopeDelta *= $BrakingSlopeRetention
        $Suppressed += 'slope-reduced-by-service-brake'
    }

    $PriorityWinner = 'none'
    $FinalCorrection = 0.0
    if ([math]::Abs([double]$State.RollDelta) -gt 0.0) {
        $PriorityWinner = 'roll'
        $FinalCorrection = [double]$State.RollDelta
    } elseif ([math]::Abs([double]$State.StabilityDelta) -gt 0.0) {
        $PriorityWinner = 'stability'
        $FinalCorrection = [double]$State.StabilityDelta
    } elseif ([math]::Abs($SlopeDelta) -gt 0.0) {
        $PriorityWinner = 'slope'
        $FinalCorrection = $SlopeDelta
    }

    $FinalCorrection *= $TerrainMultiplier * $MassMultiplier
    $FinalCorrection = [math]::Min([math]::Max($FinalCorrection, -$MaximumComposedCorrection), $MaximumComposedCorrection)

    return @{
        Applied = [math]::Abs($FinalCorrection) -gt 0.0
        PriorityWinner = $PriorityWinner
        TerrainMultiplier = $TerrainMultiplier
        MassMultiplier = $MassMultiplier
        SlopeRetention = if ($State.ServiceBraking) { $BrakingSlopeRetention } else { 1.0 }
        SuppressedAssists = $Suppressed
        FinalCorrection = $FinalCorrection
    }
}

function Assert-Near {
    param ([double]$Actual, [double]$Expected, [string]$Message)

    if ([math]::Abs($Actual - $Expected) -gt 0.000001) {
        Add-Failure "$Message Expected $Expected, got $Actual."
    }
}

$BaseSettings = @{
    TerrainInfluenceEnabled = $true
    TerrainInfluenceStrength = 0.25
    BrakingSlopeRetention = 0.35
    MassDampingStrength = 0.15
    MaximumComposedCorrection = 0.25
}

$RollCase = Get-RecommendationMirror @{
    SpeedKmh = 90.0
    TerrainFriction = 0.8
    MassKg = 1600.0
    ServiceBraking = $false
    SlopeDelta = 0.12
    StabilityDelta = 0.18
    RollDelta = -0.2
} $BaseSettings

if ($RollCase.PriorityWinner -ne 'roll') {
    Add-Failure 'Roll must win over stability and slope.'
}
Assert-Near ([double]$RollCase.FinalCorrection) -0.185928571428571 'Roll final correction mismatch.'

$BrakeCase = Get-RecommendationMirror @{
    SpeedKmh = 50.0
    TerrainFriction = 1.0
    MassKg = 1200.0
    ServiceBraking = $true
    SlopeDelta = 0.2
    StabilityDelta = 0.0
    RollDelta = 0.0
} $BaseSettings

if ($BrakeCase.PriorityWinner -ne 'slope') {
    Add-Failure 'Slope must remain active under service braking when no roll/stability correction exists.'
}
Assert-Near ([double]$BrakeCase.FinalCorrection) 0.07 'Service braking must reduce, not disable, slope correction.'
if (-not ($BrakeCase.SuppressedAssists -contains 'slope-reduced-by-service-brake')) {
    Add-Failure 'Service braking must record slope reduction.'
}

$TerrainCase = Get-RecommendationMirror @{
    SpeedKmh = 80.0
    TerrainFriction = 0.5
    MassKg = 4000.0
    ServiceBraking = $false
    SlopeDelta = 0.3
    StabilityDelta = 0.0
    RollDelta = 0.0
} $BaseSettings

Assert-Near ([double]$TerrainCase.TerrainMultiplier) 0.875 'Terrain multiplier mismatch.'
Assert-Near ([double]$TerrainCase.MassMultiplier) 0.85 'Mass multiplier mismatch.'
Assert-Near ([double]$TerrainCase.FinalCorrection) 0.223125 'Terrain/mass bounded correction mismatch.'

if (-not (Test-Path -LiteralPath $FunctionPath)) {
    Add-Failure 'Missing expected file: addons\main\functions\fn_getRuntimeAssistRecommendation.sqf'
} else {
    $Source = Get-Content -Raw -LiteralPath $FunctionPath
    Assert-Contains $Source '\bparams\s*\[' 'Runtime recommendation must declare parameters.'
    Assert-Contains $Source '_terrainMultiplier' 'Runtime recommendation must calculate terrain multiplier.'
    Assert-Contains $Source '_massMultiplier' 'Runtime recommendation must calculate mass multiplier.'
    Assert-Contains $Source '_slopeRetention' 'Runtime recommendation must calculate slope retention.'
    Assert-Contains $Source '_priorityWinner' 'Runtime recommendation must select a priority winner.'
    Assert-Contains $Source '_suppressedAssists' 'Runtime recommendation must list suppressed or reduced assists.'
    Assert-Contains $Source '_finalCorrection' 'Runtime recommendation must calculate final correction.'
    Assert-Contains $Source '"roll"[\s\S]*?"stability"[\s\S]*?"slope"' 'Priority order must be roll, stability, then slope.'
    Assert-Contains $Source 'slope-reduced-by-service-brake' 'Service braking must reduce slope assist visibly.'
    Assert-Contains $Source '\bfinite\b' 'Runtime recommendation must reject non-finite inputs.'
    if ($Source -match '\b(setVelocity|setVelocityModelSpace|setDir|setVectorDirAndUp|disableBrakes|setVariable|publicVariable|remoteExec|remoteExecCall|callExtension)\b') {
        Add-Failure 'Runtime recommendation must remain pure and must not mutate objects, network state, brakes, or native extension state.'
    }
}

if ($Failures.Count -gt 0) {
    Write-Host 'FIXICS runtime assist recommendation unit test failed:'
    foreach ($Failure in $Failures) {
        Write-Host " - $Failure"
    }
    exit 1
}

Write-Host 'FIXICS runtime assist recommendation unit test passed.'
