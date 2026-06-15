$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$SourcePath = Join-Path $RepoRoot 'addons\main\functions\fn_getVehicleStabilityRecommendation.sqf'
$ValidatorPath = Join-Path $PSScriptRoot 'fixics-stability-recommendation.ps1'
$Source = Get-Content -Raw -LiteralPath $SourcePath
$TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) (
    'fixics-stability-mutations-' + [guid]::NewGuid().ToString('N')
)

$mutations = @(
    @{
        Name = 'mode branching'
        Old = 'case "YAW":'
        New = 'case "YAW_DISABLED":'
    },
    @{
        Name = 'finite guard'
        Old = '|| {!finite _yawRate}'
        New = '|| {finite _yawRate}'
    },
    @{
        Name = 'activation threshold'
        Old = '(abs _longitudinalSpeed) * 3.6 < _activationSpeedKmh'
        New = '(abs _longitudinalSpeed) * 3.6 > _activationSpeedKmh'
    },
    @{
        Name = 'slip threshold'
        Old = '_slipRatio < _slipThreshold'
        New = '_slipRatio > _slipThreshold'
    },
    @{
        Name = 'yaw strength'
        Old = '-_yawRate * _yawStrength * _deltaTime'
        New = '-_yawRate * _lateralStrength * _deltaTime'
        ExpectedOccurrences = 2
    },
    @{
        Name = 'lateral strength'
        Old = '_lateralStrength * _deltaTime'
        New = '_yawStrength * _deltaTime'
    },
    @{
        Name = 'lateral cap'
        Old = 'min 0.5)'
        New = 'min 0.4)'
    },
    @{
        Name = 'countersteer strength'
        Old = '* _countersteerStrength'
        New = '* _yawStrength'
    },
    @{
        Name = 'maximum correction clamp'
        Old = '_maximumCorrection = (_maximumCorrection max 0) min 0.5;'
        New = '_maximumCorrection = (_maximumCorrection max 0) min 0.4;'
    },
    @{
        Name = 'longitudinal return invariance'
        Old = '    _longitudinalSpeed,'
        New = '    _recommendedLateralSpeed,'
    }
)

New-Item -ItemType Directory -Path $TempRoot | Out-Null
try {
    foreach ($mutation in $mutations) {
        $occurrences = ([regex]::Matches(
            $Source,
            [regex]::Escape($mutation.Old)
        )).Count
        $expectedOccurrences = if ($mutation.ContainsKey('ExpectedOccurrences')) {
            $mutation.ExpectedOccurrences
        } else {
            1
        }
        if ($occurrences -ne $expectedOccurrences) {
            throw "Mutation '$($mutation.Name)' expected $expectedOccurrences source match(es), found $occurrences."
        }

        $mutationIndex = $Source.IndexOf(
            $mutation.Old,
            [System.StringComparison]::Ordinal
        )
        $mutatedSource = $Source.Substring(0, $mutationIndex) +
            $mutation.New +
            $Source.Substring($mutationIndex + $mutation.Old.Length)
        $mutantPath = Join-Path $TempRoot (
            ($mutation.Name -replace '[^A-Za-z0-9]+', '-') + '.sqf'
        )
        Set-Content -LiteralPath $mutantPath -Value $mutatedSource -Encoding UTF8

        $priorErrorActionPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            & powershell.exe `
                -NoProfile `
                -ExecutionPolicy Bypass `
                -File $ValidatorPath `
                -SqfPath $mutantPath *> $null
            $validatorExitCode = $LASTEXITCODE
        } finally {
            $ErrorActionPreference = $priorErrorActionPreference
        }

        if ($validatorExitCode -eq 0) {
            throw "Mutation survived: $($mutation.Name)"
        }

        Write-Host "Killed mutation: $($mutation.Name)"
    }
} finally {
    Remove-Item -LiteralPath $TempRoot -Recurse -Force
}

Write-Host "FIXICS stability recommendation mutation test passed ($($mutations.Count) killed)."
