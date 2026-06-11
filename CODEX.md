# Codex Working Guide

## Purpose

Codex collaborates with SQA to research, design, implement, and validate targeted Arma 3 physics improvements without replacing the engine.

## Canonical Authority

When guidance conflicts, use this order:

1. `AGENTS.md` - repository facts and mandatory commands.
2. `CODEX.md` - workflow and approval gates.
3. `governance/policies/` - enforceable coding, scope, phase, and workaround policy.
4. `agents/` - task-specific role overlays.
5. `docs/reference/` - technical research aids.
6. `CONTENT-LOAD.md` - Instruction to be a Longer Development time but lessend token usage via the prompts.

Addon source and actual build configuration remain the final source of truth for implementation facts. SQA is the final authority for product behavior and acceptance.

## Current Phase

Phase 1 is In Progress. Later phases remain blocked until the Phase 1 gate is signed off by SQA.

| Phase | Title | Status |
|---|---|---|
| 1 | Ground Vehicle Physics | In Progress |
| 2 | Human Limb Physics | Blocked by Phase 1 |
| 3 | Body Kit Attachments | Blocked by Phase 2 |
| 4 | Aircraft Physics | Blocked by Phase 3 |
| 5 | Ship and Boat Physics | Blocked by Phase 4 |
| 6 | Performance Improvements | Blocked by Phase 5 |
| 7 | Memory Improvements | Blocked by Phase 6 |

Completed ABS, handbrake, slope-rolling, and direction-transition work are Phase 1 milestones. They do not close the phase.

## First Read

1. `AGENTS.md`
2. `CODEX.md`
3. `governance/policies/coding-standards.md`
4. `governance/policies/scope-control.md`
5. `governance/policies/phase-control.md`
6. Relevant `agents/` overlay
7. Relevant source, tests, fixes, and references

## Task Lifecycle

### 1. Intake

- Read the complete SQA report.
- Classify it as logic, physics, config, regression, tooling, documentation, or engine limitation.
- Inspect the repository before asking discoverable questions.
- File or update an issue in `docs/fixes/open-issues.md` for unresolved gameplay defects.

### 2. Research

- Trace the current behavior and identify the root cause.
- For technical claims, prefer Bohemia primary documentation.
- Treat `docs/reference/` as a starting point, not unquestioned authority.
- Evaluate at least two approaches for non-trivial work.
- Quantify physics behavior when evidence supports it; do not invent measurements.

### 3. Approval

Approval is risk-based, not file-count based.

Formal design approval is required for:

- new or changed gameplay behavior;
- architecture or public interface changes;
- new dependencies or external tools;
- native extension work;
- broad or inherited `CfgVehicles` changes;
- multiplayer authority or synchronization;
- changes with material regression risk.

Bounded documentation, test, and wrapper maintenance may use a concise intent update when behavior and interfaces do not change.

### 4. Implementation

- Implement only the approved behavior.
- Use tests first for bug fixes and behavior changes.
- Keep edits targeted and preserve unrelated work.
- Follow governance and specialist rules.

### 5. Verification

- Run relevant static tests and `tools\check.ps1`.
- Run `tools\build.ps1` when a packaged artifact is required.
- SQA performs gameplay verification.
- Update `docs/fixes/` and `governance/audit/validation-log.md` with evidence.

## Agent Routing

| Task | Guidance |
|---|---|
| Planning and approval | `agents/orchestrator/workflow.md` |
| SQF behavior | `agents/specialist/sqf-agent.md` |
| Vehicle physics | `agents/specialist/physics-agent.md` |
| Config and metadata | `agents/specialist/config-agent.md` |
| Validation and review | `agents/specialist/qa-agent.md` |
| Routing data | `orchestration/router.yaml` |

## Evidence Policy

Function headers document purpose, arguments, return value, locality, and important engine constraints. Detailed root cause, math, before/after observations, approval, and VR evidence belong in `docs/fixes/fix-log.md` and `docs/fixes/workaround-registry.md`.

Missing historical evidence is written as `not recorded`. Automated validation and SQA gameplay verification are always reported separately.
