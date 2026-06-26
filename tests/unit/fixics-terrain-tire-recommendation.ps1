$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$functionPath = Join-Path $repoRoot "addons\main\functions\fn_getTerrainTireRecommendation.sqf"

if (-not (Test-Path -LiteralPath $functionPath)) {
    throw "Missing Terrain Tire recommendation function: $functionPath"
}

$content = Get-Content -LiteralPath $functionPath -Raw

$requiredTokens = @(
    "FIXICS_fnc_getTerrainTireRecommendation",
    "terrainGripClass",
    "tractionMultiplier",
    "accelerationTractionMultiplier",
    "brakingTractionMultiplier",
    "turningTractionMultiplier",
    "slopeTractionMultiplier",
    "wheelspinEstimate",
    "tireAirState",
    "tireDeflationState",
    "tireDragPenalty",
    "tireSteeringPenalty",
    "massModifier",
    "terrainTireTelemetryVersion",
    "PAVED",
    "DIRT",
    "GRASS",
    "SAND",
    "ROCK",
    "UNKNOWN"
)

foreach ($token in $requiredTokens) {
    if ($content -notmatch [regex]::Escape($token)) {
        throw "Terrain Tire recommendation function missing token: $token"
    }
}

$boundedPatterns = @(
    "\bmax\b",
    "\bmin\b",
    "linearConversion",
    "deflationRate",
    "minimumMobility",
    "dragStrength",
    "steeringPenalty"
)

foreach ($pattern in $boundedPatterns) {
    if ($content -notmatch $pattern) {
        throw "Terrain Tire recommendation function missing bounded math marker: $pattern"
    }
}

Write-Host "Terrain Tire recommendation contract passed."
