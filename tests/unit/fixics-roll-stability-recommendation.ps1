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
