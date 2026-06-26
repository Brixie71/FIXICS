$ErrorActionPreference = 'Stop'

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$SourcePath = Join-Path $RepoRoot 'addons\main\functions\fn_getControlledSlipRecommendation.sqf'
$Failures = New-Object System.Collections.Generic.List[string]

function Add-Failure {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $Failures.Add($Message)
}

function RequirePattern {
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

if (-not (Test-Path -LiteralPath $SourcePath)) {
    Add-Failure 'Controlled Slip recommendation function file must exist.'
} else {
    $Source = Get-Content -Raw -LiteralPath $SourcePath

    RequirePattern $Source 'params\s*\[\s*\["_state",\s*createHashMap' 'Function must accept state hashmap.'
    RequirePattern $Source 'params\s*\[[\s\S]*\["_settings",\s*createHashMap' 'Function must accept settings hashmap.'
    RequirePattern $Source 'controlledSlipEligible' 'Recommendation must return eligibility telemetry.'
    RequirePattern $Source 'controlledSlipApplied' 'Recommendation must return applied telemetry.'
    RequirePattern $Source 'controlledSlipReason' 'Recommendation must return reason telemetry.'
    RequirePattern $Source 'steeringDemand' 'Recommendation must read steering demand.'
    RequirePattern $Source 'lateralDemand' 'Recommendation must calculate lateral demand.'
    RequirePattern $Source 'rollRisk' 'Recommendation must calculate roll risk.'
    RequirePattern $Source 'terrainClass' 'Recommendation must read terrain class.'
    RequirePattern $Source 'gripReleaseFactor' 'Recommendation must return grip release factor.'
    RequirePattern $Source 'maximumRelease' 'Recommendation must clamp release with maximumRelease.'
    RequirePattern $Source 'invalid' 'Invalid input must fail closed.'
    RequirePattern $Source 'below-speed-threshold' 'Low speed must fail closed.'
    RequirePattern $Source 'below-steering-threshold' 'Low steering demand must fail closed.'
}

if ($Failures.Count -gt 0) {
    Write-Host 'FIXICS controlled slip recommendation unit test failed:'
    $Failures | ForEach-Object { Write-Host " - $_" }
    exit 1
}

Write-Host 'FIXICS controlled slip recommendation unit test passed.'
