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

function Assert-Close {
    param (
        [Parameter(Mandatory = $true)]
        [double]$Actual,

        [Parameter(Mandatory = $true)]
        [double]$Expected,

        [Parameter(Mandatory = $true)]
        [string]$Message,

        [double]$Tolerance = 0.000001
    )

    if ([Math]::Abs($Actual - $Expected) -gt $Tolerance) {
        Add-Failure "$Message Expected $Expected, got $Actual."
    }
}

function Assert-RollResult {
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Actual,

        [Parameter(Mandatory = $true)]
        [object[]]$Expected,

        [Parameter(Mandatory = $true)]
        [string]$Scenario
    )

    if ($Actual.Count -ne 4) {
        Add-Failure "$Scenario must return a four-element tuple."
        return
    }

    if ($Actual[0] -ne $Expected[0]) {
        Add-Failure "$Scenario applied flag mismatch. Expected $($Expected[0]), got $($Actual[0])."
    }

    Assert-Close ([double]$Actual[1]) ([double]$Expected[1]) "$Scenario recommended vertical mismatch."
    Assert-Close ([double]$Actual[2]) ([double]$Expected[2]) "$Scenario correction mismatch."
    Assert-Close ([double]$Actual[3]) ([double]$Expected[3]) "$Scenario severity mismatch."
}

function Test-Finite {
    param (
        [Parameter(Mandatory = $true)]
        [double]$Value
    )

    return -not ([double]::IsNaN($Value) -or [double]::IsInfinity($Value))
}

function Get-RollRecommendationMirror {
    param (
        [Parameter(Mandatory = $true)]
        [double]$VerticalSpeed,

        [Parameter(Mandatory = $true)]
        [double]$BankDeg,

        [Parameter(Mandatory = $true)]
        [double]$BankRateDeg,

        [Parameter(Mandatory = $true)]
        [double]$DeltaTime,

        [Parameter(Mandatory = $true)]
        [object[]]$Settings
    )

    if (-not (Test-Finite $VerticalSpeed)) {
        return @($false, 0.0, 0.0, 0.0)
    }

    if (
        -not (Test-Finite $BankDeg) -or
        -not (Test-Finite $BankRateDeg) -or
        -not (Test-Finite $DeltaTime)
    ) {
        return @($false, $VerticalSpeed, 0.0, 0.0)
    }

    if ($Settings.Count -lt 4) {
        return @($false, $VerticalSpeed, 0.0, 0.0)
    }

    [double]$ActivationBankDeg = $Settings[0]
    [double]$ActivationRateDeg = $Settings[1]
    [double]$Strength = $Settings[2]
    [double]$MaximumCorrection = $Settings[3]

    if (
        -not (Test-Finite $ActivationBankDeg) -or
        -not (Test-Finite $ActivationRateDeg) -or
        -not (Test-Finite $Strength) -or
        -not (Test-Finite $MaximumCorrection)
    ) {
        return @($false, $VerticalSpeed, 0.0, 0.0)
    }

    $ActivationBankDeg = [Math]::Min([Math]::Max($ActivationBankDeg, 5.0), 60.0)
    $ActivationRateDeg = [Math]::Min([Math]::Max($ActivationRateDeg, 5.0), 240.0)
    $Strength = [Math]::Min([Math]::Max($Strength, 0.0), 0.5)
    $MaximumCorrection = [Math]::Min([Math]::Max($MaximumCorrection, 0.01), 0.4)
    $DeltaTime = [Math]::Min([Math]::Max($DeltaTime, 0.0), 1.0)

    $BankSeverity = [Math]::Max(([Math]::Abs($BankDeg) - $ActivationBankDeg) / $ActivationBankDeg, 0.0)
    $RateSeverity = [Math]::Max(([Math]::Abs($BankRateDeg) - $ActivationRateDeg) / $ActivationRateDeg, 0.0)
    $Severity = [Math]::Min([Math]::Max($BankSeverity, $RateSeverity), 1.0)

    if ($Severity -le 0.0 -or $Strength -le 0.0) {
        return @($false, $VerticalSpeed, 0.0, 0.0)
    }

    $Damping = [Math]::Min($Severity * $Strength * $DeltaTime, $MaximumCorrection)
    $RecommendedVertical = $VerticalSpeed * (1.0 - $Damping)
    $Correction = $RecommendedVertical - $VerticalSpeed
    $Applied = $Correction -ne 0.0

    return @($Applied, $RecommendedVertical, $Correction, $Severity)
}

$BehaviorCases = @(
    @{
        Name = 'below threshold preserves vertical'
        Actual = Get-RollRecommendationMirror 2.0 10.0 20.0 0.5 @(20.0, 45.0, 0.2, 0.1)
        Expected = @($false, 2.0, 0.0, 0.0)
    },
    @{
        Name = 'above bank threshold dampens vertical'
        Actual = Get-RollRecommendationMirror 2.0 30.0 20.0 0.5 @(20.0, 45.0, 0.2, 0.4)
        Expected = @($true, 1.9, -0.1, 0.5)
    },
    @{
        Name = 'above rate threshold applies damping'
        Actual = Get-RollRecommendationMirror 2.0 10.0 90.0 0.5 @(20.0, 45.0, 0.2, 0.4)
        Expected = @($true, 1.8, -0.2, 1.0)
    },
    @{
        Name = 'clamped settings bound correction'
        Actual = Get-RollRecommendationMirror 2.0 200.0 500.0 5.0 @(1.0, 1.0, 2.0, 2.0)
        Expected = @($true, 1.2, -0.8, 1.0)
    },
    @{
        Name = 'missing settings preserves vertical'
        Actual = Get-RollRecommendationMirror 2.0 30.0 90.0 0.5 @(20.0, 45.0)
        Expected = @($false, 2.0, 0.0, 0.0)
    },
    @{
        Name = 'zero strength does not apply'
        Actual = Get-RollRecommendationMirror 2.0 30.0 90.0 0.5 @(20.0, 45.0, 0.0, 0.4)
        Expected = @($false, 2.0, 0.0, 0.0)
    },
    @{
        Name = 'zero delta does not apply'
        Actual = Get-RollRecommendationMirror 2.0 30.0 90.0 0.0 @(20.0, 45.0, 0.2, 0.4)
        Expected = @($false, 2.0, 0.0, 1.0)
    },
    @{
        Name = 'non-finite bank preserves vertical'
        Actual = Get-RollRecommendationMirror 2.0 ([double]::NaN) 90.0 0.5 @(20.0, 45.0, 0.2, 0.4)
        Expected = @($false, 2.0, 0.0, 0.0)
    },
    @{
        Name = 'non-finite rate preserves vertical'
        Actual = Get-RollRecommendationMirror 2.0 30.0 ([double]::PositiveInfinity) 0.5 @(20.0, 45.0, 0.2, 0.4)
        Expected = @($false, 2.0, 0.0, 0.0)
    },
    @{
        Name = 'non-finite delta preserves vertical'
        Actual = Get-RollRecommendationMirror 2.0 30.0 90.0 ([double]::NegativeInfinity) @(20.0, 45.0, 0.2, 0.4)
        Expected = @($false, 2.0, 0.0, 0.0)
    },
    @{
        Name = 'non-finite vertical returns safe zero'
        Actual = Get-RollRecommendationMirror ([double]::NaN) 30.0 90.0 0.5 @(20.0, 45.0, 0.2, 0.4)
        Expected = @($false, 0.0, 0.0, 0.0)
    }
)

foreach ($Case in $BehaviorCases) {
    Assert-RollResult $Case.Actual $Case.Expected $Case.Name
}

$FunctionPath = Join-Path $RepoRoot 'addons\main\functions\fn_getRollStabilityRecommendation.sqf'

if (-not (Test-Path -LiteralPath $FunctionPath)) {
    Add-Failure 'Missing expected file: addons\main\functions\fn_getRollStabilityRecommendation.sqf'
} else {
    $Source = Get-Content -Raw -LiteralPath $FunctionPath

    Assert-Contains $Source '\bparams\s*\[' 'Roll recommendation must declare parameters at source level.'
    Assert-Contains $Source '_verticalSpeed' 'Roll recommendation must accept vertical speed.'
    Assert-Contains $Source '_bankDeg' 'Roll recommendation must accept bank angle in degrees.'
    Assert-Contains $Source '_bankRateDeg' 'Roll recommendation must accept bank rate in degrees per second.'
    Assert-Contains $Source '_deltaTime' 'Roll recommendation must accept delta time.'
    Assert-Contains $Source '_settings' 'Roll recommendation must accept a settings array.'

    Assert-Contains $Source '\bfinite\b' 'Roll recommendation must reject non-finite numeric inputs.'
    Assert-Contains $Source 'if\s*\(!finite\s+_verticalSpeed\)\s*exitWith\s*\{\s*\[\s*false,\s*0,\s*0,\s*0\s*\]\s*\};' 'Non-finite vertical speed must return a safe zero recommendation.'
    Assert-Contains $Source 'if\s*\([\s\S]*!finite\s+_bankDeg[\s\S]*!finite\s+_bankRateDeg[\s\S]*!finite\s+_deltaTime[\s\S]*\)\s*exitWith\s*\{\s*\[\s*false,\s*_verticalSpeed,\s*0,\s*0\s*\]\s*\};' 'Non-finite bank, rate, or delta time must preserve finite vertical speed.'
    Assert-Contains $Source '_activationBankDeg\s*=\s*\(_activationBankDeg\s+max\s+5\)\s+min\s+60' 'Activation bank threshold must be clamped to 5..60.'
    Assert-Contains $Source '_activationRateDeg\s*=\s*\(_activationRateDeg\s+max\s+5\)\s+min\s+240' 'Activation rate threshold must be clamped to 5..240.'
    Assert-Contains $Source '_strength\s*=\s*\(_strength\s+max\s+0\)\s+min\s+0\.5' 'Strength must be clamped to 0..0.5.'
    Assert-Contains $Source '_maximumCorrection\s*=\s*\(_maximumCorrection\s+max\s+0\.01\)\s+min\s+0\.4' 'Maximum correction must be clamped to 0.01..0.4.'
    Assert-Contains $Source '_deltaTime\s*=\s*\(_deltaTime\s+max\s+0\)\s+min\s+1' 'Delta time must be clamped to 0..1.'

    Assert-Contains $Source '_bankSeverity' 'Roll recommendation must calculate bank severity.'
    Assert-Contains $Source '_rateSeverity' 'Roll recommendation must calculate rate severity.'
    Assert-Contains $Source '_severity\s*=\s*\(_bankSeverity\s+max\s+_rateSeverity\)\s+min\s+1' 'Roll recommendation must use the capped max severity.'
    Assert-Contains $Source '_damping' 'Roll recommendation must calculate damping.'
    Assert-Contains $Source '_recommendedVertical\s*=\s*_verticalSpeed\s*\*\s*\(1\s*-\s*_damping\)' 'Roll recommendation must dampen vertical speed without mutation.'
    Assert-Contains $Source '_correction' 'Roll recommendation must expose the vertical correction amount.'

    Assert-Contains $Source '\[\s*_applied,\s*_recommendedVertical,\s*_correction,\s*_severity\s*\]' 'Return tuple must include applied, recommended vertical, correction, and severity.'

    if ($Source -match '\b(setVelocity|setVelocityModelSpace|setDir|setVectorDirAndUp|disableBrakes|setVariable|publicVariable|remoteExec|remoteExecCall)\b') {
        Add-Failure 'Roll recommendation must remain pure and must not mutate objects or network state.'
    }
}

if ($Failures.Count -gt 0) {
    Write-Host 'FIXICS roll stability recommendation unit test failed:'
    foreach ($Failure in $Failures) {
        Write-Host " - $Failure"
    }
    exit 1
}

Write-Host 'FIXICS roll stability recommendation unit test passed.'
