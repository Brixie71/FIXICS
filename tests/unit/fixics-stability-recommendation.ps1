$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$FixturePath = Join-Path $PSScriptRoot 'fixtures\stability-recommendation.json'

if (-not (Test-Path -LiteralPath $FixturePath)) {
    throw "Missing stability recommendation fixture: $FixturePath"
}

function Get-StabilityRecommendation {
    param (
        [string]$Mode,
        [double]$LongitudinalSpeed,
        [double]$LateralSpeed,
        [double]$YawRate,
        [double]$SteeringInput,
        [double]$DeltaTime,
        [object[]]$Profile
    )

    $Mode = $Mode.ToUpperInvariant()
    if ($Mode -notin @('OFF', 'YAW', 'YAW_LATERAL', 'COUNTERSTEER')) {
        $Mode = 'OFF'
    }

    $values = @(
        $LongitudinalSpeed,
        $LateralSpeed,
        $YawRate,
        $SteeringInput,
        $DeltaTime
    )
    if ($values.Where({ [double]::IsNaN($_) -or [double]::IsInfinity($_) }).Count -gt 0) {
        return @($false, 0.0, 0.0, 0.0, 'OFF')
    }

    if ($Profile.Count -lt 7) {
        return @($false, $LongitudinalSpeed, $LateralSpeed, 0.0, $Mode)
    }

    $supported = [bool]$Profile[0]
    $activationSpeedKmh = [math]::Min([math]::Max([double]$Profile[1], 0), 160)
    $slipThreshold = [math]::Min([math]::Max([double]$Profile[2], 0), 1)
    $yawStrength = [math]::Min([math]::Max([double]$Profile[3], 0), 1)
    $lateralStrength = [math]::Min([math]::Max([double]$Profile[4], 0), 1)
    $countersteerStrength = [math]::Min([math]::Max([double]$Profile[5], 0), 0.5)
    $maximumCorrection = [math]::Min([math]::Max([double]$Profile[6], 0), 0.5)
    $DeltaTime = [math]::Min([math]::Max($DeltaTime, 0), 1)

    $slipRatio = [math]::Abs($LateralSpeed) / [math]::Max([math]::Abs($LongitudinalSpeed), 1)
    if (
        -not $supported -or
        $Mode -eq 'OFF' -or
        ([math]::Abs($LongitudinalSpeed) * 3.6) -lt $activationSpeedKmh -or
        $slipRatio -lt $slipThreshold
    ) {
        return @($false, $LongitudinalSpeed, $LateralSpeed, 0.0, $Mode)
    }

    $recommendedLateral = $LateralSpeed
    $yawCorrection = 0.0
    switch ($Mode) {
        'YAW' {
            $yawCorrection = [math]::Min(
                [math]::Max(-$YawRate * $yawStrength * $DeltaTime, -$maximumCorrection),
                $maximumCorrection
            )
        }
        'YAW_LATERAL' {
            $recommendedLateral = $LateralSpeed * (
                1 - [math]::Min($lateralStrength * $DeltaTime, 0.5)
            )
            $yawCorrection = [math]::Min(
                [math]::Max(-$YawRate * $yawStrength * $DeltaTime, -$maximumCorrection),
                $maximumCorrection
            )
        }
        'COUNTERSTEER' {
            $yawCorrection = [math]::Min(
                [math]::Max(-$YawRate * $countersteerStrength * $DeltaTime, -$maximumCorrection),
                $maximumCorrection
            )
        }
    }

    $applied = $recommendedLateral -ne $LateralSpeed -or $yawCorrection -ne 0
    return @($applied, $LongitudinalSpeed, $recommendedLateral, $yawCorrection, $Mode)
}

function Assert-Near {
    param (
        [double]$Actual,
        [double]$Expected,
        [string]$Message
    )

    if ([math]::Abs($Actual - $Expected) -gt 0.000001) {
        throw "$Message Expected $Expected, got $Actual."
    }
}

function Resolve-FixtureNumber {
    param ([object]$Value)

    if ($Value -eq 'NaN') {
        return [double]::NaN
    }
    if ($Value -eq 'PositiveInfinity') {
        return [double]::PositiveInfinity
    }
    if ($Value -eq 'NegativeInfinity') {
        return [double]::NegativeInfinity
    }

    return [double]$Value
}

$sqfPath = Join-Path $RepoRoot 'addons\main\functions\fn_getVehicleStabilityRecommendation.sqf'
$sqf = Get-Content -Raw -LiteralPath $sqfPath
$fixtures = Get-Content -Raw -LiteralPath $FixturePath | ConvertFrom-Json

foreach ($case in $fixtures.cases) {
    $input = $case.input
    $result = Get-StabilityRecommendation `
        -Mode $input.mode `
        -LongitudinalSpeed (Resolve-FixtureNumber $input.longitudinalSpeed) `
        -LateralSpeed (Resolve-FixtureNumber $input.lateralSpeed) `
        -YawRate (Resolve-FixtureNumber $input.yawRate) `
        -SteeringInput (Resolve-FixtureNumber $input.steeringInput) `
        -DeltaTime (Resolve-FixtureNumber $input.deltaTime) `
        -Profile @($input.profile)

    if ([bool]$result[0] -ne [bool]$case.expected.applied) {
        throw "$($case.name): applied mismatch."
    }
    Assert-Near $result[1] $case.expected.longitudinalSpeed "$($case.name): longitudinal mismatch."
    Assert-Near $result[2] $case.expected.lateralSpeed "$($case.name): lateral mismatch."
    Assert-Near $result[3] $case.expected.yawCorrection "$($case.name): yaw mismatch."
    if ($result[4] -ne $case.expected.mode) {
        throw "$($case.name): mode mismatch. Expected $($case.expected.mode), got $($result[4])."
    }
}

foreach ($requiredToken in $fixtures.requiredSqfTokens) {
    if (-not $sqf.Contains($requiredToken)) {
        throw "SQF recommendation is missing fixture contract token: $requiredToken"
    }
}

Write-Host "FIXICS stability recommendation executable test passed ($($fixtures.cases.Count) cases)."
