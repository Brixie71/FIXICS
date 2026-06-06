$ErrorActionPreference = 'Stop'

if (-not $PSScriptRoot) {
    $PSScriptRoot = (Get-Location).Path
}

Push-Location $PSScriptRoot
try {
    if (Test-Path ".\hemtt.exe") {
        & .\hemtt.exe build
    } else {
        & hemtt build
    }
} finally {
    Pop-Location
}
