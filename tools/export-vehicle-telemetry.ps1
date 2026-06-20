param(
    [string]$RptPath = '',
    [string]$OutputDir = '',
    [switch]$IncludeEvidenceHeader = $false
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'rpt-patterns.ps1')

Push-Location $RepoRoot
try {
    if (-not $RptPath) {
        $defaultDirs = @(
            (Join-Path $env:LOCALAPPDATA 'Arma 3'),
            (Join-Path $env:USERPROFILE 'Documents\Arma 3')
        )

        foreach ($dir in $defaultDirs) {
            if (Test-Path -LiteralPath $dir) {
                $found = Get-ChildItem -LiteralPath $dir -Filter '*.rpt' -ErrorAction SilentlyContinue |
                    Sort-Object LastWriteTime -Descending |
                    Select-Object -First 1
                if ($found) {
                    $RptPath = $found.FullName
                    break
                }
            }
        }
    }

    if (-not $RptPath -or -not (Test-Path -LiteralPath $RptPath)) {
        Write-Error 'RPT file not found. Specify -RptPath or launch Arma 3 first.'
        exit 1
    }

    if (-not $OutputDir) {
        $OutputDir = Join-Path $RepoRoot 'diagnostics'
    }
    if (-not (Test-Path -LiteralPath $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }

    $timestamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
    $outputPath = Join-Path $OutputDir "vehicle-telemetry_$timestamp.log"
    $telemetry = [System.Collections.Generic.List[string]]::new()
    $lineNumber = 0

    foreach ($line in (Get-Content -LiteralPath $RptPath -Encoding UTF8)) {
        $lineNumber++

        $isSample = $line -match '\[FIXICS\] Vehicle handling sample:'
        $isEvidence = $IncludeEvidenceHeader -and $line -match '\[FIXICS\] Vehicle handling evidence:'
        if ($isSample -or $isEvidence) {
            $telemetry.Add("[$lineNumber] $line")
        }
    }

    $report = @(
        'FIXICS VEHICLE TELEMETRY EXPORT',
        "Generated : $timestamp",
        "Source    : $RptPath",
        "Lines     : $($telemetry.Count)",
        ''
    )

    if ($telemetry.Count -gt 0) {
        $report += $telemetry
    } else {
        $report += '(no FIXICS vehicle handling telemetry found)'
    }

    Set-Content -LiteralPath $outputPath -Value ($report -join "`n") -Encoding UTF8

    Write-Host "Telemetry exported: $outputPath"
    Write-Host "Lines: $($telemetry.Count)"

    if ($telemetry.Count -eq 0) {
        exit 2
    }
} finally {
    Pop-Location
}
