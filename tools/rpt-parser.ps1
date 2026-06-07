param(
    [string]$RptPath = '',
    [switch]$SaveReport = $false,
    [string]$Filter = ''
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

    $userFilters = if ($Filter) {
        $Filter -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    } else {
        @()
    }

    $errorPatterns = $script:FIXICS_RptErrorPatterns
    $projectPatterns = $script:FIXICS_RptProjectPatterns + $userFilters
    $physicsPatterns = $script:FIXICS_RptPhysicsPatterns
    $warningPatterns = $script:FIXICS_RptWarningPatterns

    $errors = [System.Collections.Generic.List[string]]::new()
    $project = [System.Collections.Generic.List[string]]::new()
    $physics = [System.Collections.Generic.List[string]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()

    $lineNumber = 0
    foreach ($line in (Get-Content -LiteralPath $RptPath -Encoding UTF8)) {
        $lineNumber++

        foreach ($pattern in $errorPatterns) {
            if ($line -match $pattern) {
                $errors.Add("[$lineNumber] $line")
                break
            }
        }
        foreach ($pattern in $projectPatterns) {
            if ($line -match $pattern) {
                $project.Add("[$lineNumber] $line")
                break
            }
        }
        foreach ($pattern in $physicsPatterns) {
            if ($line -match $pattern) {
                $physics.Add("[$lineNumber] $line")
                break
            }
        }
        foreach ($pattern in $warningPatterns) {
            if ($line -match $pattern) {
                $warnings.Add("[$lineNumber] $line")
                break
            }
        }
    }

    function Write-Section {
        param(
            [string]$Title,
            [System.Collections.Generic.List[string]]$Items,
            [int]$MaxLines = 50
        )

        Write-Host "[$Title] ($($Items.Count) found)"
        if ($Items.Count -eq 0) {
            Write-Host '  (none)'
        } else {
            foreach ($item in ($Items | Select-Object -First $MaxLines)) {
                Write-Host "  $item"
            }
            if ($Items.Count -gt $MaxLines) {
                Write-Host "  ... and $($Items.Count - $MaxLines) more lines"
            }
        }
        Write-Host ''
    }

    Write-Host ''
    Write-Host 'RPT PARSER - FIXICS'
    Write-Host "Source : $RptPath"
    Write-Host ''

    Write-Section 'SCRIPT ERRORS' $errors
    Write-Section 'FIXICS OUTPUT' $project
    Write-Section 'PHYSICS LINES' $physics
    Write-Section 'WARNINGS' $warnings 20

    if ($SaveReport) {
        $timestamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
        $reportDir = Join-Path $RepoRoot 'evals\reports'
        $reportPath = Join-Path $reportDir "rpt-parse_$timestamp.txt"
        if (-not (Test-Path -LiteralPath $reportDir)) {
            New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
        }

        $report = @(
            'RPT PARSE REPORT - FIXICS',
            "Generated : $timestamp",
            "Source    : $RptPath",
            '',
            "SCRIPT ERRORS ($($errors.Count))",
            ($errors -join "`n"),
            '',
            "FIXICS OUTPUT ($($project.Count))",
            ($project -join "`n"),
            '',
            "PHYSICS LINES ($($physics.Count))",
            ($physics -join "`n"),
            '',
            "WARNINGS ($($warnings.Count))",
            ($warnings -join "`n")
        ) -join "`n"

        Set-Content -LiteralPath $reportPath -Value $report -Encoding UTF8
        Write-Host "Report saved: $reportPath"
    }

    if ($errors.Count -gt 0) {
        exit 1
    }
} finally {
    Pop-Location
}
