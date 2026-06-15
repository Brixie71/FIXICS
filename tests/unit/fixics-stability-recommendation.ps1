$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$SqfPath = Join-Path $RepoRoot 'addons\main\functions\fn_getVehicleStabilityRecommendation.sqf'
$Sqf = Get-Content -Raw -LiteralPath $SqfPath

function Require-Match {
    param (
        [string]$Pattern,
        [string]$Description
    )

    $match = [regex]::Match(
        $Sqf,
        $Pattern,
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
    if (-not $match.Success) {
        throw "SQF source contract missing: $Description"
    }

    return $match
}

function Assert-Near {
    param (
        [double]$Actual,
        [double]$Expected,
        [string]$Description
    )

    if ([math]::Abs($Actual - $Expected) -gt 0.000001) {
        throw "$Description Expected $Expected, got $Actual."
    }
}

function Get-ClampBounds {
    param ([string]$Variable)

    $escaped = [regex]::Escape($Variable)
    $match = Require-Match `
        "$escaped\s*=\s*\($escaped\s+max\s+(-?\d+(?:\.\d+)?)\)\s+min\s+(-?\d+(?:\.\d+)?)\s*;" `
        "$Variable clamp"

    return @(
        [double]$match.Groups[1].Value,
        [double]$match.Groups[2].Value
    )
}

function Apply-Clamp {
    param (
        [double]$Value,
        [double[]]$Bounds
    )

    return [math]::Min([math]::Max($Value, $Bounds[0]), $Bounds[1])
}

function Get-ModeBlock {
    param ([string]$Mode)

    $escaped = [regex]::Escape($Mode)
    return (Require-Match `
        "case\s+`"$escaped`"\s*:\s*\{(?<body>.*?)\n\s*\};" `
        "$Mode branch").Groups['body'].Value
}

function Get-YawFormula {
    param (
        [string]$Block,
        [string]$StrengthVariable
    )

    $escapedStrength = [regex]::Escape($StrengthVariable)
    $match = [regex]::Match(
        $Block,
        "-_yawRate\s*\*\s*$escapedStrength\s*\*\s*_deltaTime\s*\)\s*max\s*-_maximumCorrection\s+min\s+_maximumCorrection",
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
    if (-not $match.Success) {
        throw "SQF source contract missing: yaw formula using $StrengthVariable"
    }

    return {
        param (
            [double]$YawRate,
            [double]$Strength,
            [double]$DeltaTime,
            [double]$MaximumCorrection
        )

        [math]::Min(
            [math]::Max(-$YawRate * $Strength * $DeltaTime, -$MaximumCorrection),
            $MaximumCorrection
        )
    }
}

$modeList = (Require-Match `
    '_mode\s+in\s+\[(?<modes>[^\]]+)\]' `
    'assistance mode allow-list').Groups['modes'].Value
$modes = [regex]::Matches($modeList, '"([^"]+)"') |
    ForEach-Object { $_.Groups[1].Value }

if ($modes.Count -ne 4) {
    throw "Expected four parsed assistance modes, got $($modes.Count)."
}

$finiteMatch = Require-Match `
    '!finite\s+_longitudinalSpeed[\s\S]*?!finite\s+_lateralSpeed[\s\S]*?!finite\s+_yawRate[\s\S]*?!finite\s+_steeringInput[\s\S]*?!finite\s+_deltaTime[\s\S]*?\[false,\s*0,\s*0,\s*0,\s*"OFF"\]' `
    'finite-input rejection and safe return'

$activationPredicate = Require-Match `
    '\(abs\s+_longitudinalSpeed\)\s*\*\s*(?<conversion>\d+(?:\.\d+)?)\s*<\s*_activationSpeedKmh' `
    'activation-speed threshold'
$slipPredicate = Require-Match `
    'private\s+_slipRatio\s*=\s*\(abs\s+_lateralSpeed\)\s*/\s*\(\(abs\s+_longitudinalSpeed\)\s+max\s+(?<floor>\d+(?:\.\d+)?)\)' `
    'zero-safe slip-ratio expression'
Require-Match '_slipRatio\s*<\s*_slipThreshold' 'slip threshold predicate' | Out-Null

$returnTuple = Require-Match `
    '\[\s*_applied,\s*(?<longitudinal>_longitudinalSpeed),\s*_recommendedLateralSpeed,\s*_yawCorrection,\s*_mode\s*\]\s*$' `
    'final return tuple preserving longitudinal speed'

$bounds = @{
    Activation = Get-ClampBounds '_activationSpeedKmh'
    Slip = Get-ClampBounds '_slipThreshold'
    Yaw = Get-ClampBounds '_yawStrength'
    Lateral = Get-ClampBounds '_lateralStrength'
    Countersteer = Get-ClampBounds '_countersteerStrength'
    Correction = Get-ClampBounds '_maximumCorrection'
    DeltaTime = Get-ClampBounds '_deltaTime'
}

$yawBlock = Get-ModeBlock 'YAW'
$yawLateralBlock = Get-ModeBlock 'YAW_LATERAL'
$countersteerBlock = Get-ModeBlock 'COUNTERSTEER'
$yawFormula = Get-YawFormula $yawBlock '_yawStrength'
$yawLateralFormula = Get-YawFormula $yawLateralBlock '_yawStrength'

$lateralMatch = [regex]::Match(
    $yawLateralBlock,
    '_recommendedLateralSpeed\s*=\s*_lateralSpeed\s*\*\s*\(\s*1\s*-\s*\(\(_lateralStrength\s*\*\s*_deltaTime\)\s+min\s+(?<cap>\d+(?:\.\d+)?)\)\s*\)',
    [System.Text.RegularExpressions.RegexOptions]::Singleline
)
if (-not $lateralMatch.Success) {
    throw 'SQF source contract missing: YAW_LATERAL damping expression'
}

$countersteerMatch = [regex]::Match(
    $countersteerBlock,
    'private\s+_countersteer\s*=\s*-_yawRate\s*\*\s*_countersteerStrength\s*\*\s*_deltaTime\s*;[\s\S]*?_yawCorrection\s*=\s*\(\s*_countersteer\s+max\s+-_maximumCorrection\s*\)\s+min\s+_maximumCorrection',
    [System.Text.RegularExpressions.RegexOptions]::Singleline
)
if (-not $countersteerMatch.Success) {
    throw 'SQF source contract missing: COUNTERSTEER formula'
}

if (($modes -join ',') -ne 'OFF,YAW,YAW_LATERAL,COUNTERSTEER') {
    throw "Unexpected parsed mode order: $($modes -join ',')"
}

$conversion = [double]$activationPredicate.Groups['conversion'].Value
$slipFloor = [double]$slipPredicate.Groups['floor'].Value
$lateralCap = [double]$lateralMatch.Groups['cap'].Value

Assert-Near $conversion 3.6 'Speed conversion'
Assert-Near $slipFloor 1 'Slip denominator floor'
Assert-Near $lateralCap 0.5 'Lateral damping cap'

Assert-Near (Apply-Clamp -20 $bounds.Activation) 0 'Activation lower clamp'
Assert-Near (Apply-Clamp 500 $bounds.Activation) 160 'Activation upper clamp'
Assert-Near (Apply-Clamp -1 $bounds.Slip) 0 'Slip lower clamp'
Assert-Near (Apply-Clamp 2 $bounds.Slip) 1 'Slip upper clamp'
Assert-Near (Apply-Clamp 5 $bounds.Yaw) 1 'Yaw strength upper clamp'
Assert-Near (Apply-Clamp 5 $bounds.Lateral) 1 'Lateral strength upper clamp'
Assert-Near (Apply-Clamp 5 $bounds.Countersteer) 0.5 'Countersteer upper clamp'
Assert-Near (Apply-Clamp 5 $bounds.Correction) 0.5 'Correction upper clamp'
Assert-Near (Apply-Clamp 2 $bounds.DeltaTime) 1 'Delta-time upper clamp'

$yawCorrection = & $yawFormula 10 0.22 0.1 0.12
Assert-Near $yawCorrection -0.12 'YAW extracted formula'

$yawLateralCorrection = & $yawLateralFormula 2 0.22 0.5 0.12
Assert-Near $yawLateralCorrection -0.12 'YAW_LATERAL extracted yaw formula'
$lateralAfter = 4 * (1 - [math]::Min(0.12 * 0.5, $lateralCap))
Assert-Near $lateralAfter 3.76 'YAW_LATERAL extracted damping formula'

$countersteerCorrection = [math]::Min(
    [math]::Max(-10 * 0.08 * 0.1, -0.12),
    0.12
)
Assert-Near $countersteerCorrection -0.08 'COUNTERSTEER extracted formula'

$activationSpeed = 35
$belowActivation = ([math]::Abs(5) * $conversion) -lt $activationSpeed
if (-not $belowActivation) {
    throw 'Extracted activation threshold did not reject low speed.'
}

$slipRatio = [math]::Abs(1) / [math]::Max([math]::Abs(20), $slipFloor)
if (-not ($slipRatio -lt 0.12)) {
    throw 'Extracted slip threshold did not reject low slip.'
}

if ($returnTuple.Groups['longitudinal'].Value -ne '_longitudinalSpeed') {
    throw 'Production return tuple does not preserve longitudinal speed.'
}

Write-Host 'FIXICS stability recommendation source-derived test passed.'
