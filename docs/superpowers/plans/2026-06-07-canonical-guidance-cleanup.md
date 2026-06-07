# Canonical Guidance Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the FIXICS operating layer tracked, internally consistent, source-verified, and practical for future coding and planning.

**Architecture:** Keep repository facts and workflow centralized, with governance as the enforceable policy source and agent files as thin domain overlays. Add one static governance test that protects naming, paths, tracking, references, tools, and phase status from drifting again.

**Tech Stack:** Markdown, YAML, PowerShell, Git, HEMTT, Arma 3 SQF documentation.

---

### Task 1: Add Governance Regression Coverage

**Files:**
- Create: `tests/integration/fixics-governance-static.ps1`
- Modify: `tests/README.md`

- [ ] Add assertions for canonical files, `FIXICS_` naming, `x\fixics` paths, Phase 1 status, source links, tool filters, parseable YAML/PowerShell, and generated-output ignore rules.
- [ ] Run the test and confirm it fails on the existing stale guidance.

### Task 2: Canonicalize Authority And Tracking

**Files:**
- Modify: `.gitignore`
- Modify: `AGENTS.md`
- Modify: `CODEX.md`
- Modify: `governance/policies/*.md`
- Modify: `agents/**/*.md`
- Modify: `agents/orchestrator/policies.yaml`
- Modify: `orchestration/*`
- Modify: `prompts/*`

- [ ] Remove broad basename ignore rules and retain precise generated/private ignores.
- [ ] Establish the approved authority order and risk-based approval gates.
- [ ] Replace stale namespace and PBO-prefix examples.
- [ ] Make governance the sole policy source and reduce agent files to domain overlays.
- [ ] Refresh current project state and routing.

### Task 3: Correct References And Tools

**Files:**
- Modify: `docs/reference/*.md`
- Modify: `tools/README.md`
- Modify: `tools/launch-eden.ps1`
- Modify: `tools/rpt-parser.ps1`
- Modify: `tools/watch-rpt.ps1`
- Create: `tools/rpt-patterns.ps1`

- [ ] Replace unsupported claims with Bohemia-cited facts or explicit unverified hypotheses.
- [ ] Correct angular velocity, center-of-mass, mass, autobrake, and `brakeIdleSpeed` documentation.
- [ ] Centralize RPT patterns and switch all output to `FIXICS`.
- [ ] Standardize tool wrappers and ASCII console output.

### Task 4: Backfill Project Memory

**Files:**
- Modify: `docs/fixes/fix-log.md`
- Modify: `docs/fixes/workaround-registry.md`
- Modify: `docs/fixes/open-issues.md`
- Modify: `agents/specialist/phase-control.md`

- [ ] Record existing Phase 1 milestones using committed and SQA evidence only.
- [ ] Record active scripted workarounds and removal conditions.
- [ ] Keep Phase 1 in progress and leave unresolved issue tracking empty unless a real issue exists.

### Task 5: Verify

- [ ] Run `tests/integration/fixics-governance-static.ps1`.
- [ ] Run `tests/integration/fixics-vehicle-physics-static.ps1`.
- [ ] Run `tools/check.ps1`.
- [ ] Run `git diff --check` and inspect final status/diff.
