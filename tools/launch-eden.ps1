$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot

Push-Location $RepoRoot
try {
    $hemtt = if (Test-Path -LiteralPath '.\hemtt.exe') { '.\hemtt.exe' } else { 'hemtt' }

    Write-Host ''
    Write-Host 'LAUNCH EDEN - FIXICS'
    Write-Host 'Command : hemtt launch eden'
    Write-Host 'Manual  : SQA must observe gameplay behavior in Arma.'
    Write-Host ''

    & $hemtt launch eden @args

    $exitCode = $LASTEXITCODE
    if ($null -ne $exitCode -and $exitCode -ne 0) {
        exit $exitCode
    }
} finally {
    Pop-Location
}
