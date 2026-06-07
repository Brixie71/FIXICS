param(
    [string]$RptPath = '',
    [switch]$SaveReport = $false,
    [int]$PollMs = 300
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

    $rules = @(
        @{ Label = 'ERROR'; Pattern = ($script:FIXICS_RptErrorPatterns -join '|'); Color = 'Red' },
        @{ Label = 'FIXICS'; Pattern = ($script:FIXICS_RptProjectPatterns -join '|'); Color = 'Green' },
        @{ Label = 'PHYSICS'; Pattern = ($script:FIXICS_RptPhysicsPatterns -join '|'); Color = 'Yellow' },
        @{ Label = 'WARN'; Pattern = ($script:FIXICS_RptWarningPatterns -join '|'); Color = 'DarkYellow' }
    )

    $captured = [System.Collections.Generic.List[string]]::new()
    $errorCount = 0
    $startTime = Get-Date
    $startPos = (Get-Item -LiteralPath $RptPath).Length

    Write-Host ''
    Write-Host 'WATCH RPT - FIXICS'
    Write-Host "Watching : $RptPath"
    Write-Host "Poll     : ${PollMs}ms"
    Write-Host 'Stop     : Ctrl+C'
    Write-Host ''

    $stream = $null
    $reader = $null
    try {
        $stream = [System.IO.File]::Open($RptPath, 'Open', 'Read', 'ReadWrite')
        $reader = [System.IO.StreamReader]::new($stream)
        $stream.Seek($startPos, 'Begin') | Out-Null

        while ($true) {
            while (-not $reader.EndOfStream) {
                $line = $reader.ReadLine()
                if (-not $line) {
                    continue
                }

                foreach ($rule in $rules) {
                    if ($line -match $rule.Pattern) {
                        $prefix = "[$($rule.Label)]".PadRight(10)
                        Write-Host "$prefix $line" -ForegroundColor $rule.Color
                        $captured.Add("[$($rule.Label)] $line")
                        if ($rule.Label -eq 'ERROR') {
                            $errorCount++
                        }
                        break
                    }
                }
            }
            Start-Sleep -Milliseconds $PollMs
        }
    } finally {
        if ($reader) {
            $reader.Dispose()
        }
        if ($stream) {
            $stream.Dispose()
        }

        $elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)
        Write-Host ''
        Write-Host 'WATCH SESSION ENDED'
        Write-Host "Duration       : ${elapsed}s"
        Write-Host "Captured lines : $($captured.Count)"
        Write-Host "Script errors  : $errorCount"

        if ($SaveReport -and $captured.Count -gt 0) {
            $timestamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
            $reportDir = Join-Path $RepoRoot 'evals\reports'
            $reportPath = Join-Path $reportDir "rpt-watch_$timestamp.txt"
            if (-not (Test-Path -LiteralPath $reportDir)) {
                New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
            }
            $report = @(
                'RPT WATCH REPORT - FIXICS',
                "Generated : $timestamp",
                "Source    : $RptPath",
                "Duration  : ${elapsed}s",
                "Errors    : $errorCount",
                '',
                ($captured -join "`n")
            ) -join "`n"
            Set-Content -LiteralPath $reportPath -Value $report -Encoding UTF8
            Write-Host "Report saved: $reportPath"
        }
    }
} finally {
    Pop-Location
}
