$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot

Push-Location $RepoRoot
try {
    if (Test-Path -LiteralPath ".\hemtt.exe") {
        & .\hemtt.exe build
    } else {
        & hemtt build
    }

    $exitCode = $LASTEXITCODE
    if ($null -ne $exitCode -and $exitCode -ne 0) {
        exit $exitCode
    }
} finally {
    Pop-Location
}
