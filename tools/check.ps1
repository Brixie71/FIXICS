$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot

Push-Location $RepoRoot
try {
    if (Test-Path -LiteralPath ".\hemtt.exe") {
        & .\hemtt.exe check
    } else {
        & hemtt check
    }

    $exitCode = $LASTEXITCODE
    if ($null -ne $exitCode -and $exitCode -ne 0) {
        exit $exitCode
    }

    & powershell -ExecutionPolicy Bypass -File tests\unit\fixics-stability-recommendation.ps1
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    & powershell -ExecutionPolicy Bypass -File tests\unit\fixics-roll-stability-recommendation.ps1
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    & powershell -ExecutionPolicy Bypass -File tests\unit\fixics-runtime-assist-recommendation.ps1
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    & powershell -ExecutionPolicy Bypass -File tests\unit\fixics-stability-recommendation-mutations.ps1
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
} finally {
    Pop-Location
}
