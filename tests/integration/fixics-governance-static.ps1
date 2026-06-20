$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$Failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([string]$Message)
    $Failures.Add($Message)
}

function Assert-FileExists {
    param([string]$RelativePath)
    if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot $RelativePath))) {
        Add-Failure "Missing canonical file: $RelativePath"
    }
}

function Assert-Contains {
    param(
        [string]$Content,
        [string]$Pattern,
        [string]$Message
    )
    if ($Content -notmatch $Pattern) {
        Add-Failure $Message
    }
}

$CanonicalFiles = @(
    'AGENTS.md',
    'CODEX.md',
    'agents\orchestrator\workflow.md',
    'agents\orchestrator\policies.yaml',
    'agents\specialist\sqf-agent.md',
    'agents\specialist\config-agent.md',
    'agents\specialist\qa-agent.md',
    'agents\specialist\physics-agent.md',
    'agents\specialist\phase-control.md',
    'governance\policies\coding-standards.md',
    'governance\policies\scope-control.md',
    'governance\policies\workaround-policy.md',
    'orchestration\router.yaml',
    'orchestration\state.md',
    'prompts\registry.yaml',
    'docs\fixes\fix-log.md',
    'docs\fixes\open-issues.md',
    'docs\fixes\workaround-registry.md',
    'docs\vehicle-behavior\README.md',
    'docs\vehicle-behavior\telemetry-snapshot-schema.md',
    'docs\vehicle-behavior\vehicle-behavior-profiles.md',
    'docs\vehicle-behavior\behavior-classifications.md',
    'docs\vehicle-behavior\sqa-evidence-matrix.md',
    'docs\reference\physx-command-ref.md',
    'docs\reference\vehicle-config-ref.md',
    'docs\reference\known-engine-limits.md',
    'tools\rpt-patterns.ps1',
    'tools\rpt-parser.ps1',
    'tools\watch-rpt.ps1',
    'tools\export-vehicle-telemetry.ps1',
    'tools\launch-eden.ps1'
)
$CanonicalFiles | ForEach-Object { Assert-FileExists $_ }

$ActivePaths = @(
    'AGENTS.md',
    'CODEX.md',
    'agents',
    'governance\policies',
    'orchestration',
    'prompts',
    'docs\fixes',
    'docs\reference',
    'tools'
)
$ActiveFiles = foreach ($relativePath in $ActivePaths) {
    $fullPath = Join-Path $RepoRoot $relativePath
    if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
        Get-Item -LiteralPath $fullPath
    } elseif (Test-Path -LiteralPath $fullPath -PathType Container) {
        Get-ChildItem -LiteralPath $fullPath -Recurse -File
    }
}

$StaleNamespace = $ActiveFiles | Select-String -Pattern 'BASEARMA|base_arma' -List
if ($StaleNamespace) {
    Add-Failure "Active guidance/tools contain stale BASEARMA identifiers: $(($StaleNamespace.Path | Sort-Object -Unique) -join ', ')"
}

$Gitignore = (Get-Content -Raw -LiteralPath (Join-Path $RepoRoot '.gitignore')) -replace "`r`n", "`n"
foreach ($broadPattern in @(
    '(?m)^CODEX\.md$',
    '(?m)^AGENTS\.md$',
    '(?m)^workflow\.md$',
    '(?m)^router\.yaml$',
    '(?m)^state\.md$',
    '(?m)^registry\.yaml$'
)) {
    if ($Gitignore -match $broadPattern) {
        Add-Failure "Broad AI guidance ignore remains: $broadPattern"
    }
}
Assert-Contains $Gitignore '(?m)^\.hemttout/$' '.hemttout must remain ignored.'
Assert-Contains $Gitignore '(?m)^evals/reports/$' 'Generated evaluation reports must be ignored.'
Assert-Contains $Gitignore '(?m)^diagnostics/$' 'Generated telemetry exports must be ignored.'
Assert-Contains $Gitignore '(?m)^\*\.biprivatekey$' 'Private signing keys must remain ignored.'

$Codex = Get-Content -Raw -LiteralPath (Join-Path $RepoRoot 'CODEX.md')
Assert-Contains $Codex 'AGENTS\.md[\s\S]*CODEX\.md[\s\S]*governance/policies[\s\S]*agents/[\s\S]*docs/reference/' 'CODEX must define canonical authority order.'
Assert-Contains $Codex 'risk-based' 'CODEX must define risk-based approval gates.'
Assert-Contains $Codex 'Phase 1.*In Progress' 'CODEX must keep Phase 1 in progress.'

$PhaseControl = Get-Content -Raw -LiteralPath (Join-Path $RepoRoot 'agents\specialist\phase-control.md')
Assert-Contains $PhaseControl '\| 1 \| Ground Vehicle Physics \| In Progress \|' 'Phase control must keep Phase 1 in progress.'

$AgentWorkaroundPath = Join-Path $RepoRoot 'agents\specialist\workaround-policy.md'
if (Test-Path -LiteralPath $AgentWorkaroundPath) {
    $AgentWorkaround = Get-Content -Raw -LiteralPath $AgentWorkaroundPath
    Assert-Contains $AgentWorkaround 'governance/policies/workaround-policy\.md' 'Specialist workaround guidance must point to the canonical governance policy.'
    if ($AgentWorkaround.Length -gt 800) {
        Add-Failure 'Specialist workaround policy duplicates too much canonical policy.'
    }
}

$ReferenceSources = @(
    'docs\reference\physx-command-ref.md',
    'docs\reference\vehicle-config-ref.md',
    'docs\reference\known-engine-limits.md'
)
foreach ($relativePath in $ReferenceSources) {
    $content = Get-Content -Raw -LiteralPath (Join-Path $RepoRoot $relativePath)
    Assert-Contains $content 'https://community\.bohemia\.net/wiki/' "$relativePath must cite Bohemia primary documentation."
}

$VehicleBehaviorReadmePath = Join-Path $RepoRoot 'docs\vehicle-behavior\README.md'
$TelemetrySchemaPath = Join-Path $RepoRoot 'docs\vehicle-behavior\telemetry-snapshot-schema.md'
$VehicleProfilesPath = Join-Path $RepoRoot 'docs\vehicle-behavior\vehicle-behavior-profiles.md'
$BehaviorClassificationsPath = Join-Path $RepoRoot 'docs\vehicle-behavior\behavior-classifications.md'
$SqaEvidenceMatrixPath = Join-Path $RepoRoot 'docs\vehicle-behavior\sqa-evidence-matrix.md'

if (Test-Path -LiteralPath $VehicleBehaviorReadmePath) {
    $VehicleBehaviorReadme = Get-Content -Raw -LiteralPath $VehicleBehaviorReadmePath
    Assert-Contains $VehicleBehaviorReadme 'read-only Evidence Registry' 'Vehicle behavior README must define the read-only Evidence Registry boundary.'
    Assert-Contains $VehicleBehaviorReadme 'No gameplay behavior changes' 'Vehicle behavior README must prohibit gameplay behavior changes.'
    Assert-Contains $VehicleBehaviorReadme 'Runtime Assist' 'Vehicle behavior README must state Runtime Assist depends on registry evidence.'
    Assert-Contains $VehicleBehaviorReadme 'Config Research' 'Vehicle behavior README must state Config Research depends on registry evidence.'
}

if (Test-Path -LiteralPath $TelemetrySchemaPath) {
    $TelemetrySchema = Get-Content -Raw -LiteralPath $TelemetrySchemaPath
    @(
        'sampleIndex',
        'vehicleClass',
        'supportStatus',
        'driverState',
        'inputState',
        'activeSettings',
        'worldVelocity',
        'modelVelocity',
        'speedKmh',
        'position',
        'headingDeg',
        'yawRateDegPerSecond',
        'pitchDeg',
        'bankDeg',
        'pitchRateDegPerSecond',
        'bankRateDegPerSecond',
        'terrainNormal',
        'slopeEvidence',
        'isTouchingGround',
        'wheelHitpointEvidence'
    ) | ForEach-Object {
        Assert-Contains $TelemetrySchema $_ "Telemetry snapshot schema must define $_."
    }
}

if (Test-Path -LiteralPath $VehicleProfilesPath) {
    $VehicleProfiles = Get-Content -Raw -LiteralPath $VehicleProfilesPath
    @(
        'observed-only',
        'telemetry-supported',
        'runtime-assist-supported',
        'config-experiment-candidate'
    ) | ForEach-Object {
        Assert-Contains $VehicleProfiles $_ "Vehicle behavior profiles must define support status $_."
    }
    Assert-Contains $VehicleProfiles 'EMP_Polaris_DAGOR' 'Vehicle behavior profiles must include the approved DAGOR class.'
    Assert-Contains $VehicleProfiles 'B_LSV_01_unarmed_F' 'Vehicle behavior profiles must include the tested vanilla LSV class.'
    Assert-Contains $VehicleProfiles 'LOP_IA_Offroad' 'Vehicle behavior profiles must include the tested LOP IA Offroad class.'
    Assert-Contains $VehicleProfiles 'B_G_Offroad_01_F' 'Vehicle behavior profiles must include the tested vanilla Offroad class.'
}

if (Test-Path -LiteralPath $BehaviorClassificationsPath) {
    $BehaviorClassifications = Get-Content -Raw -LiteralPath $BehaviorClassificationsPath
    @(
        'input-limitation',
        'understeer',
        'oversteer',
        'rollover-risk',
        'braking-instability',
        'slope-autobrake',
        'direction-transition',
        'terrain-interaction'
    ) | ForEach-Object {
        Assert-Contains $BehaviorClassifications $_ "Behavior classifications must define $_."
    }
    Assert-Contains $BehaviorClassifications 'SQA approval' 'New behavior classifications must require SQA approval.'
}

if (Test-Path -LiteralPath $SqaEvidenceMatrixPath) {
    $SqaEvidenceMatrix = Get-Content -Raw -LiteralPath $SqaEvidenceMatrixPath
    @(
        'telemetry log path',
        'observed behavior',
        'classification',
        'recommended next action',
        'collect-more-telemetry',
        'runtime-assist-tuning',
        'config-research',
        'no-change',
        'blocked'
    ) | ForEach-Object {
        Assert-Contains $SqaEvidenceMatrix $_ "SQA evidence matrix must define $_."
    }
}

$PhysxReference = Get-Content -Raw -LiteralPath (Join-Path $RepoRoot 'docs\reference\physx-command-ref.md')
Assert-Contains $PhysxReference 'angularVelocity' 'PhysX reference must document angular velocity access.'
Assert-Contains $PhysxReference 'setCenterOfMass' 'PhysX reference must document runtime center-of-mass control.'
if ($PhysxReference -match 'setPhysicsProperties') {
    Add-Failure 'Unverified setPhysicsProperties command must not be documented as supported.'
}

$VehicleReference = Get-Content -Raw -LiteralPath (Join-Path $RepoRoot 'docs\reference\vehicle-config-ref.md')
Assert-Contains $VehicleReference 'brakeIdleSpeed.*m/s' 'Vehicle config reference must document brakeIdleSpeed in m/s.'

$PowerShellFiles = Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'tools') -Filter '*.ps1' -File
foreach ($file in $PowerShellFiles) {
    $tokens = $null
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile(
        $file.FullName,
        [ref]$tokens,
        [ref]$errors
    )
    if ($errors.Count -gt 0) {
        Add-Failure "PowerShell parse failed for $($file.Name): $($errors.Message -join ' | ')"
    }
}

$YamlFiles = @(
    'agents\orchestrator\policies.yaml',
    'orchestration\router.yaml',
    'prompts\registry.yaml'
)
foreach ($relativePath in $YamlFiles) {
    $fullPath = Join-Path $RepoRoot $relativePath
    & python -c "import sys, yaml; yaml.safe_load(open(sys.argv[1], encoding='utf-8'))" $fullPath
    if ($LASTEXITCODE -ne 0) {
        Add-Failure "YAML parse failed: $relativePath"
    }
}

$RptParser = Get-Content -Raw -LiteralPath (Join-Path $RepoRoot 'tools\rpt-parser.ps1')
$RptWatcher = Get-Content -Raw -LiteralPath (Join-Path $RepoRoot 'tools\watch-rpt.ps1')
$TelemetryExporter = Get-Content -Raw -LiteralPath (Join-Path $RepoRoot 'tools\export-vehicle-telemetry.ps1')
Assert-Contains $RptParser 'rpt-patterns\.ps1' 'RPT parser must load shared patterns.'
Assert-Contains $RptWatcher 'rpt-patterns\.ps1' 'RPT watcher must load shared patterns.'
Assert-Contains $TelemetryExporter 'rpt-patterns\.ps1' 'Vehicle telemetry exporter must load shared patterns.'
Assert-Contains $RptParser 'FIXICS' 'RPT parser must filter FIXICS output.'
Assert-Contains $RptWatcher 'FIXICS' 'RPT watcher must filter FIXICS output.'
Assert-Contains $TelemetryExporter 'Vehicle handling sample' 'Vehicle telemetry exporter must extract handling samples.'
Assert-Contains $TelemetryExporter '\[FIXICS\\\]\\\[Stability\\\]' 'Vehicle telemetry exporter must extract stability debug lines.'
Assert-Contains $TelemetryExporter '\[FIXICS\\\]\\\[RollStability\\\]' 'Vehicle telemetry exporter must extract roll stability debug lines.'
Assert-Contains $TelemetryExporter 'diagnostics' 'Vehicle telemetry exporter must write to the local diagnostics directory by default.'

if ($Failures.Count -gt 0) {
    Write-Host 'FIXICS governance static test failed:'
    foreach ($failure in $Failures) {
        Write-Host " - $failure"
    }
    exit 1
}

Write-Host 'FIXICS governance static test passed.'
