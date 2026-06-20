# Vehicle Behavior Evidence Registry Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a read-only Evidence Registry that standardizes FIXICS vehicle telemetry evidence, vehicle behavior profiles, classification names, and SQA evidence rows before future runtime assist or config research work.

**Architecture:** Add documentation-backed registry files under `docs/vehicle-behavior/` and protect them with governance static checks. The first implementation is evidence-only: it creates schema/profile/matrix records and updates project guidance, but does not change ABS, slope, stability, roll, native, config, or SQF gameplay behavior.

**Tech Stack:** Markdown registry files, PowerShell static regression tests, existing FIXICS governance validation, HEMTT check wrapper.

---

## File Structure

- Create: `docs/vehicle-behavior/README.md`
  - Purpose: entry point for the Evidence Registry, states scope and workflow.
- Create: `docs/vehicle-behavior/telemetry-snapshot-schema.md`
  - Purpose: canonical telemetry snapshot fields and field meanings.
- Create: `docs/vehicle-behavior/vehicle-behavior-profiles.md`
  - Purpose: vehicle profile format, support status values, and initial profile rows.
- Create: `docs/vehicle-behavior/behavior-classifications.md`
  - Purpose: approved classification names and meanings.
- Create: `docs/vehicle-behavior/sqa-evidence-matrix.md`
  - Purpose: SQA evidence row format and first matrix scaffold.
- Modify: `tests/integration/fixics-governance-static.ps1`
  - Purpose: require registry files and approved values.
- Modify: `docs/fixes/open-issues.md`
  - Purpose: point ISSUE-001 evidence recording to the new matrix.
- Modify: `orchestration/state.md`
  - Purpose: record that the Evidence Registry is the next evidence foundation.
- Modify: `governance/audit/validation-log.md`
  - Purpose: record implementation validation results after checks pass.

Do not modify:

- `addons/main/functions/*.sqf`
- `addons/main/config.cpp`
- `addons/main/stringtable.xml`
- `native/fixics_physics/**`
- `.hemttout/**`
- `diagnostics/**`

## Task 1: Static Regression For Registry Files And Vocabulary

**Files:**
- Modify: `tests/integration/fixics-governance-static.ps1`
- Read: `docs/superpowers/specs/2026-06-20-vehicle-behavior-evidence-registry-design.md`

- [ ] **Step 1: Add registry file existence assertions**

Add these paths to `$CanonicalFiles` in `tests/integration/fixics-governance-static.ps1`:

```powershell
'docs\vehicle-behavior\README.md',
'docs\vehicle-behavior\telemetry-snapshot-schema.md',
'docs\vehicle-behavior\vehicle-behavior-profiles.md',
'docs\vehicle-behavior\behavior-classifications.md',
'docs\vehicle-behavior\sqa-evidence-matrix.md',
```

- [ ] **Step 2: Add registry content assertions**

Add this block after the existing reference-source assertions:

```powershell
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
```

- [ ] **Step 3: Run governance test to verify red**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1
```

Expected: fails with missing `docs\vehicle-behavior\*.md` files.

- [ ] **Step 4: Commit the failing regression**

Run:

```powershell
git add tests\integration\fixics-governance-static.ps1
git commit -m "test: require vehicle behavior evidence registry"
```

Expected: commit succeeds with only the static regression staged.

## Task 2: Add Registry Entry Point And Schema

**Files:**
- Create: `docs/vehicle-behavior/README.md`
- Create: `docs/vehicle-behavior/telemetry-snapshot-schema.md`
- Test: `tests/integration/fixics-governance-static.ps1`

- [ ] **Step 1: Create registry README**

Create `docs/vehicle-behavior/README.md`:

```markdown
# Vehicle Behavior Evidence Registry

## Purpose

This folder is the read-only Evidence Registry for FIXICS Phase 1 ground-vehicle behavior work.

It records structured telemetry evidence, vehicle behavior profiles, SQA evidence rows, and controlled behavior classifications before any future Runtime Assist or Config Research work is approved.

## Boundary

No gameplay behavior changes are authorized by this registry.

This registry does not change:

- ABS braking;
- slope rolling;
- ACE/FIXICS handbrake behavior;
- Drive/Reverse direction transition behavior;
- Vehicle Stability Assistance;
- Roll Stability Assist;
- native extension behavior;
- vehicle config values.

## Workflow

1. SQA runs a vehicle test.
2. FIXICS telemetry records the vehicle state.
3. The run is mapped to the telemetry snapshot schema.
4. SQA records an evidence matrix row.
5. The run receives one or more approved behavior classifications.
6. The vehicle behavior profile is updated.
7. The next action is selected:
   - `collect-more-telemetry`;
   - `runtime-assist-tuning`;
   - `config-research`;
   - `no-change`;
   - `blocked`.

## Relationship To Future Work

Runtime Assist work must use this registry to justify how ABS, slope, stability, roll, terrain, and driver-intent systems coordinate.

Config Research work must use this registry to justify any class-specific tire, suspension, anti-roll, mass, center-of-mass, steering, or gearbox investigation.
```

- [ ] **Step 2: Create telemetry snapshot schema**

Create `docs/vehicle-behavior/telemetry-snapshot-schema.md`:

```markdown
# Telemetry Snapshot Schema

## Purpose

A telemetry snapshot is one normalized vehicle sample from a FIXICS vehicle behavior test.

This schema standardizes fields already produced or implied by the current telemetry logger so future analysis does not depend on one raw RPT line format.

## Required Fields

| Field | Meaning |
|---|---|
| `sampleIndex` | Sequential sample number inside one capture. |
| `sampleTime` | Runtime timestamp or elapsed seconds when available. |
| `vehicleClass` | `typeOf` class name for the tested vehicle. |
| `vehicleDisplayName` | Human-readable vehicle name when available. |
| `supportStatus` | Registry support state for this vehicle class. |
| `driverState` | Current FIXICS driver state such as Drive, Reverse, Coast, Service Brake, Neutral, or Handbrake. |
| `inputState` | Driver input evidence: forward, reverse, brake, handbrake, steering left/right, and throttle-related values when available. |
| `activeSettings` | Relevant FIXICS settings for ABS, slope, native assist, stability assist, roll assist, presets, and debug flags. |
| `worldVelocity` | World-space velocity from Arma. |
| `modelVelocity` | Vehicle model-space velocity, including lateral X, longitudinal Y, and vertical Z. |
| `speedKmh` | Vehicle speed in kilometers per hour. |
| `position` | World and/or ASL position when available. |
| `headingDeg` | Vehicle heading in degrees. |
| `yawRateDegPerSecond` | Derived yaw-rate estimate. |
| `pitchDeg` | Vehicle pitch angle. |
| `bankDeg` | Vehicle bank angle. |
| `pitchRateDegPerSecond` | Derived pitch-rate estimate. |
| `bankRateDegPerSecond` | Derived bank-rate estimate. |
| `terrainNormal` | Terrain normal under or near the vehicle. |
| `slopeEvidence` | Derived slope magnitude or downhill alignment evidence. |
| `isTouchingGround` | Ground contact state from Arma. |
| `wheelHitpointEvidence` | Wheel hitpoint proxy data from available hitpoint damage information. |

## Rules

- Missing values must be recorded as `not recorded`, not invented.
- A snapshot is evidence, not a correction command.
- The schema does not authorize vehicle mutation.
- New fields may be proposed during SQA review, but existing field names should remain stable once used by issue records.
```

- [ ] **Step 3: Run governance test to verify partial red**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1
```

Expected: still fails because profile, classification, and matrix files are missing.

- [ ] **Step 4: Commit registry README and schema**

Run:

```powershell
git add docs\vehicle-behavior\README.md docs\vehicle-behavior\telemetry-snapshot-schema.md
git commit -m "docs: add vehicle behavior registry schema"
```

Expected: commit succeeds.

## Task 3: Add Profiles, Classifications, And Evidence Matrix

**Files:**
- Create: `docs/vehicle-behavior/vehicle-behavior-profiles.md`
- Create: `docs/vehicle-behavior/behavior-classifications.md`
- Create: `docs/vehicle-behavior/sqa-evidence-matrix.md`
- Test: `tests/integration/fixics-governance-static.ps1`

- [ ] **Step 1: Create vehicle behavior profiles**

Create `docs/vehicle-behavior/vehicle-behavior-profiles.md`:

```markdown
# Vehicle Behavior Profiles

## Purpose

A vehicle behavior profile records what FIXICS knows about one vehicle class or family.

Profiles record evidence and support status only. They do not authorize broad config patches or gameplay behavior changes.

## Support Status Values

| Status | Meaning |
|---|---|
| `observed-only` | Vehicle has appeared in telemetry or SQA notes, but has no approved FIXICS support. |
| `telemetry-supported` | Vehicle can be logged and studied through the Evidence Registry. |
| `runtime-assist-supported` | Vehicle is approved for current runtime assist behavior. |
| `config-experiment-candidate` | Vehicle has enough evidence for a possible class-specific config design. |

## Profile Fields

| Field | Meaning |
|---|---|
| Vehicle class | Exact Arma class name. |
| Family/source | Vanilla, mod source, or vehicle family when known. |
| Support status | One approved support status value. |
| Tested surfaces | Paved, dirt, grass, slope, or other recorded surfaces. |
| Tested speed bands | Speed bands covered by SQA evidence. |
| Tested presets and modes | Stability, roll, ABS, or related presets used in evidence runs. |
| Known config evidence | Relevant inherited config values or `not recorded`. |
| Known classifications | Approved behavior classifications observed for this class. |
| Current recommendation | One next action from the SQA evidence matrix. |

## Initial Profiles

| Vehicle class | Family/source | Support status | Tested surfaces | Tested speed bands | Tested presets and modes | Known config evidence | Known classifications | Current recommendation |
|---|---|---|---|---|---|---|---|---|
| `EMP_Polaris_DAGOR` | Modded DAGOR | `runtime-assist-supported` | Paved, dirt, grass pending matrix completion | 30, 60, 90, 120 km/h pending matrix completion | Realistic Stable, Rally, stability modes pending matrix completion | Player steering coefficients recorded through diagnostics when SQA runs capture | `oversteer`, `rollover-risk` pending confirmation | `collect-more-telemetry` |
| `B_LSV_01_unarmed_F` | Vanilla LSV | `runtime-assist-supported` | SQA LSV/buggy rollover test surfaces | High-speed sharp-turn testing | Roll Stability Aggressive SQA verified as useful starting point | `not recorded` | `rollover-risk` | `runtime-assist-tuning` |
| `LOP_IA_Offroad` | LOP IA Offroad | `runtime-assist-supported` | SQA Offroad rollover validation surfaces | `not recorded` | Stability compatibility added after telemetry | `not recorded` | `rollover-risk` | `collect-more-telemetry` |
| `B_G_Offroad_01_F` | Vanilla Offroad | `runtime-assist-supported` | SQA Offroad rollover validation surfaces | `not recorded` | Stability compatibility added after telemetry | `not recorded` | `rollover-risk` | `collect-more-telemetry` |
```

- [ ] **Step 2: Create behavior classifications**

Create `docs/vehicle-behavior/behavior-classifications.md`:

```markdown
# Behavior Classifications

## Purpose

Behavior classifications provide one controlled vocabulary for SQA vehicle behavior evidence.

New classification names require SQA approval before use in issue records, profiles, or evidence matrices.

## Approved Classifications

| Classification | Meaning | Typical Evidence |
|---|---|---|
| `input-limitation` | Steering or control input appears limited before vehicle response is evaluated. | Full input is present, but steering angle or response stops building earlier than expected. |
| `understeer` | Steering input exists, but yaw or lateral response is insufficient. | Vehicle continues forward despite visible or logged steering input. |
| `oversteer` | Yaw grows beyond the intended path or rear rotation dominates. | Rear rotation increases faster than the desired turn path. |
| `rollover-risk` | Bank angle or bank rate approaches rollover conditions. | High bank angle, high bank rate, wheel lift, tumble, or rollover event. |
| `braking-instability` | Braking behavior causes instability or fails to slow predictably. | ABS or service braking produces unwanted yaw, slide, or delayed stop. |
| `slope-autobrake` | Slope rolling or low-speed autobrake behavior is the observed issue. | Vehicle sticks on slope, rolls only after W/S input, or autobrake holds near zero speed. |
| `direction-transition` | Drive/Reverse handoff behavior is the observed issue. | W while reversing or S while driving does not enter expected service-brake/neutral/launch flow. |
| `terrain-interaction` | Behavior changes materially by surface, slope, landing, or terrain transition. | Same vehicle/settings behave differently across paved, dirt, grass, slope, airborne, or landing conditions. |

## Rules

- Use one or more approved classifications per evidence row.
- Record uncertainty in the observed behavior field, not by inventing a new classification.
- If no classification fits, set recommended next action to `blocked` and ask SQA to approve a new classification name.
```

- [ ] **Step 3: Create SQA evidence matrix**

Create `docs/vehicle-behavior/sqa-evidence-matrix.md`:

```markdown
# SQA Evidence Matrix

## Purpose

The SQA evidence matrix connects telemetry logs to manual observations and recommended next actions.

Each row should describe one test run or one tightly scoped group of equivalent runs.

## Recommended Next Actions

| Action | Meaning |
|---|---|
| `collect-more-telemetry` | Current evidence is insufficient for a behavior or config decision. |
| `runtime-assist-tuning` | Evidence points to ABS, slope, stability, roll, or controller tuning. |
| `config-research` | Evidence points to class-specific tire, suspension, anti-roll, mass, center-of-mass, steering, or gearbox research. |
| `no-change` | Current behavior is acceptable for the tested scope. |
| `blocked` | Work cannot proceed without SQA clarification, new classification approval, or missing telemetry. |

## Matrix

| Date | SQA tester | Vehicle class | Terrain or surface | Speed band | Input pattern | Active preset | Assist mode | Roll preset | Telemetry log path | Observed behavior | Classification | Recommended next action |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 2026-06-20 | SQA | `B_LSV_01_unarmed_F` | SQA rollover test surface | High-speed sharp turn | Sudden left/right steering | `not recorded` | `Yaw + Lateral Damping` | `Aggressive SQA` | `diagnostics/vehicle-telemetry_2026-06-20_194337.log` | SQA confirmed rollover assist works when settings are maxed; controlled sliding remains possible but rollover can still occur under severe steering. | `rollover-risk`, `terrain-interaction` | `runtime-assist-tuning` |

## Rules

- Use repository-relative telemetry log paths when logs are available in the workspace.
- Use `not recorded` for unknown values.
- Do not mark a behavior resolved from this matrix alone. Manual SQA acceptance remains required.
```

- [ ] **Step 4: Run governance test to verify green**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1
```

Expected: `FIXICS governance static test passed.`

- [ ] **Step 5: Commit registry content**

Run:

```powershell
git add docs\vehicle-behavior\vehicle-behavior-profiles.md docs\vehicle-behavior\behavior-classifications.md docs\vehicle-behavior\sqa-evidence-matrix.md
git commit -m "docs: add vehicle behavior evidence records"
```

Expected: commit succeeds.

## Task 4: Connect Registry To Project Memory

**Files:**
- Modify: `docs/fixes/open-issues.md`
- Modify: `orchestration/state.md`
- Test: `tests/integration/fixics-governance-static.ps1`

- [ ] **Step 1: Add ISSUE-001 registry reference**

In `docs/fixes/open-issues.md`, under `#### Vehicle Stability Assistance Evidence Matrix`, add this paragraph before the existing matrix:

```markdown
The canonical evidence format now lives in `docs/vehicle-behavior/sqa-evidence-matrix.md`. Keep the table below as the issue-specific acceptance matrix, but record reusable telemetry evidence and recommended next actions in the Evidence Registry.
```

- [ ] **Step 2: Add project state note**

In `orchestration/state.md`, under `## Last Decision`, add:

```markdown
- Vehicle Behavior Evidence Registry architecture was approved on 2026-06-20. The first implementation is read-only documentation and static validation; Runtime Assist coordination and Config Research remain future designs.
```

- [ ] **Step 3: Run governance test**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1
```

Expected: `FIXICS governance static test passed.`

- [ ] **Step 4: Commit project memory updates**

Run:

```powershell
git add docs\fixes\open-issues.md orchestration\state.md
git commit -m "docs: link evidence registry to project memory"
```

Expected: commit succeeds.

## Task 5: Full Validation And Audit Log

**Files:**
- Modify: `governance/audit/validation-log.md`
- Test: required validation commands

- [ ] **Step 1: Run governance static validation**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1
```

Expected: `FIXICS governance static test passed.`

- [ ] **Step 2: Run vehicle physics static validation**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected includes:

```text
FIXICS vehicle physics static test passed.
```

- [ ] **Step 3: Run HEMTT/tool validation**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools\check.ps1
```

Expected includes:

```text
Compiled 22 sqf files
Checked 1 stringtables
FIXICS stability recommendation mutation test passed
```

- [ ] **Step 4: Append validation log entry**

Append this entry to `governance/audit/validation-log.md`, replacing command result wording only if the actual command output differs:

```markdown
### 2026-06-20 - Vehicle Behavior Evidence Registry

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1`
- Result: passed, exit code 0
- Automated coverage: verified Evidence Registry files, telemetry schema fields, support status values, behavior classifications, recommended next actions, and registry boundary wording.
- Manual coverage: not run.
- Notes: documentation-only registry implementation. No SQF gameplay source changed.

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1`
- Result: passed, exit code 0
- Automated coverage: confirmed existing vehicle physics static and mutation checks still pass after registry documentation changes.
- Manual coverage: not run.
- Notes: registry does not claim gameplay behavior improvements.

- Command: `powershell -ExecutionPolicy Bypass -File tools\check.ps1`
- Result: passed, exit code 0
- Automated coverage: HEMTT/tool wrapper checks passed after registry documentation changes.
- Manual coverage: not run.
- Notes: no build artifact was produced for this documentation-only task.
```

- [ ] **Step 5: Re-run all validation after log update**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
powershell -ExecutionPolicy Bypass -File tools\check.ps1
```

Expected:

```text
FIXICS governance static test passed.
FIXICS vehicle physics static test passed.
FIXICS stability recommendation mutation test passed
```

- [ ] **Step 6: Commit validation log**

Run:

```powershell
git add governance\audit\validation-log.md
git commit -m "docs: record evidence registry validation"
```

Expected: commit succeeds.

## Task 6: Completion Review

**Files:**
- Read: `docs/vehicle-behavior/README.md`
- Read: `docs/vehicle-behavior/telemetry-snapshot-schema.md`
- Read: `docs/vehicle-behavior/vehicle-behavior-profiles.md`
- Read: `docs/vehicle-behavior/behavior-classifications.md`
- Read: `docs/vehicle-behavior/sqa-evidence-matrix.md`
- Read: `git diff --stat HEAD~5..HEAD`

- [ ] **Step 1: Verify no forbidden files changed**

Run:

```powershell
git diff --name-only HEAD~5..HEAD
```

Expected changed paths are limited to:

```text
tests/integration/fixics-governance-static.ps1
docs/vehicle-behavior/README.md
docs/vehicle-behavior/telemetry-snapshot-schema.md
docs/vehicle-behavior/vehicle-behavior-profiles.md
docs/vehicle-behavior/behavior-classifications.md
docs/vehicle-behavior/sqa-evidence-matrix.md
docs/fixes/open-issues.md
orchestration/state.md
governance/audit/validation-log.md
```

- [ ] **Step 2: Check final status**

Run:

```powershell
git status --short
```

Expected: no unexpected source/config/native changes. Existing unrelated documentation cleanup or `.superpowers/` visual companion files may remain if they predated execution; do not stage them in this plan.

- [ ] **Step 3: Report completion**

Report:

```text
Done      : Vehicle Behavior Evidence Registry implemented as read-only documentation and static validation.
Validated : governance static, vehicle physics static, and tools/check passed.
Logged    : validation evidence recorded in governance/audit/validation-log.md.
Next      : Use the registry to write the Runtime Assist coordination design, or collect more SQA telemetry rows first.
```
