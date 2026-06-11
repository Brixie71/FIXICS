# Canonical Guidance Cleanup — Implementation Plan

> **Codex:** Do NOT start. Present the suggestion card. Wait for SQA approval before touching any file.
> **Loop: Ask → Suggest → Wait → Do.**

**Goal:** Make the FIXICS operating layer tracked, internally consistent, source-verified, and practical for future coding and planning.

**Architecture:** Repository facts and workflow centralized in `AGENTS.md` and `CODEX.md`. Governance is the sole enforceable policy source. Agent files are thin domain overlays only. `CONTEXT-LOAD.md` controls what Codex loads per session. One static governance test protects naming, paths, tracking, references, tools, and phase status from drifting.

**Tech Stack:** Markdown, YAML, PowerShell, Git, HEMTT, Arma 3 SQF documentation.

**SQA Authority:** SQA approves each task before implementation. Codex presents one suggestion card per task. No task proceeds without a yes.

---

## Suggestion Card Format

Before starting any task, present this to SQA:

```
Objective  : [task name]
Approach   : [one sentence]
Files      : [exact files to be created or modified]
Risk       : [what could break]
Ready to proceed?
```

Wait. Do not write code. Do not modify files. SQA says yes — then execute.

---

## Task 1 — Add Governance Regression Coverage

**Files:**
- Create: `tests/integration/fixics-governance-static.ps1`
- Modify: `tests/README.md`

**Approval required:** Yes — new test file, affects validation gate.

- [ ] Present suggestion card to SQA. Wait for yes.
- [ ] Create `fixics-governance-static.ps1` with assertions for:
  - Canonical files present (`AGENTS.md`, `CODEX.md`, `CONTEXT-LOAD.md`, `orchestration/state.md`)
  - `FIXICS_` naming convention in all SQF functions
  - `x\fixics\addons\main` PBO prefix in `config.cpp`
  - Phase 1 marked In Progress in `CODEX.md` and `agents/specialist/phase-control.md`
  - No unsupported engine claims in `docs/reference/`
  - Tool output uses `FIXICS` prefix, not stale names
  - YAML and PowerShell files are parseable
  - Generated-output ignore rules present in `.gitignore`
- [ ] Run the test. Confirm it fails on existing stale guidance before proceeding to Task 2.
- [ ] Update `tests/README.md` to document the new test.
- [ ] Report completion card to SQA.

---

## Task 2 — Canonicalize Authority and Tracking

**Files:**
- Modify: `.gitignore`
- Modify: `AGENTS.md`
- Modify: `CODEX.md`
- Modify: `CONTEXT-LOAD.md`
- Modify: `governance/policies/*.md`
- Modify: `agents/**/*.md`
- Modify: `agents/orchestrator/policies.yaml`
- Modify: `orchestration/router.yaml`
- Modify: `orchestration/state.md`
- Modify: `prompts/library/*.md`

**Approval required:** Yes — touches authority order, approval gates, and agent contracts.

- [ ] Present suggestion card to SQA. Wait for yes.
- [ ] Remove broad basename ignore rules from `.gitignore`. Keep only precise generated-output and private-key ignores.
- [ ] Confirm authority order in `CODEX.md`: `AGENTS.md` → `CODEX.md` → `governance/policies/` → `agents/` → `docs/reference/`.
- [ ] Confirm risk-based approval gates in `CODEX.md` match `AGENTS.md` approval gate section exactly.
- [ ] Replace any stale namespace or PBO-prefix examples across all agent and governance files.
- [ ] Reduce all `agents/` files to domain overlays only — no duplicate workflow rules, no duplicate policy text.
- [ ] Confirm `CONTEXT-LOAD.md` objective table matches current task set in `orchestration/state.md`.
- [ ] Refresh `orchestration/router.yaml` routing entries to match current specialist list.
- [ ] Report completion card to SQA.

---

## Task 3 — Correct References and Tools

**Files:**
- Modify: `docs/reference/physx-command-ref.md`
- Modify: `docs/reference/vehicle-config-ref.md`
- Modify: `docs/reference/known-engine-limits.md`
- Modify: `tools/README.md`
- Modify: `tools/launch-eden.ps1`
- Modify: `tools/rpt-parser.ps1`
- Modify: `tools/watch-rpt.ps1`
- Create: `tools/rpt-patterns.ps1`

**Approval required:** Yes — corrects documented engine claims, affects reference authority.

- [ ] Present suggestion card to SQA. Wait for yes.
- [ ] Audit every engine claim in `docs/reference/`. Replace unsupported claims with either a Bohemia-cited fact or an explicit label: `[project hypothesis — not source-verified]`.
- [ ] Correct documentation for: angular velocity, center-of-mass, mass, autobrake behavior, and `brakeIdleSpeed`.
- [ ] Extract all RPT pattern strings into `tools/rpt-patterns.ps1`. Update `rpt-parser.ps1` and `watch-rpt.ps1` to import from it.
- [ ] Switch all tool console output prefix from stale names to `FIXICS`.
- [ ] Standardize tool wrapper structure and ASCII output format across all `tools/*.ps1`.
- [ ] Update `tools/README.md` to reflect new `rpt-patterns.ps1` and corrected wrapper list.
- [ ] Report completion card to SQA.

---

## Task 4 — Backfill Project Memory

**Files:**
- Modify: `docs/fixes/fix-log.md`
- Modify: `docs/fixes/workaround-registry.md`
- Modify: `docs/fixes/open-issues.md`
- Modify: `agents/specialist/phase-control.md`

**Approval required:** Yes — writes permanent project memory, must use only verified evidence.

- [ ] Present suggestion card to SQA. Wait for yes.
- [ ] Record existing Phase 1 milestones in `fix-log.md` using committed code and SQA-verified evidence only. Mark anything unverified as `not recorded`.
- [ ] Record all active scripted workarounds in `workaround-registry.md` with removal conditions.
- [ ] Leave `open-issues.md` empty unless a real unresolved issue exists. Do not invent placeholder entries.
- [ ] Confirm `phase-control.md` shows Phase 1 In Progress and Phase 2 Blocked. No other changes.
- [ ] Report completion card to SQA.

---

## Task 5 — Verify

**Approval required:** No — validation only, no source changes.

- [ ] Run `tests/integration/fixics-governance-static.ps1` — must pass.
- [ ] Run `tests/integration/fixics-vehicle-physics-static.ps1` — must pass.
- [ ] Run `tools/check.ps1` — must pass.
- [ ] Run `git diff --check` — no whitespace errors.
- [ ] Inspect final `git status` and `git diff`. Confirm no unintended changes.
- [ ] Report final completion card to SQA:

```
Done      : [list of tasks completed]
Validated : [all tests passed]
Logged    : [what was written to fix-log or workaround-registry]
Next      : [suggested next task or gap, if any]
```

---

## Hard Rules for This Plan

- Do not implement any task without SQA approval on that task's suggestion card.
- Do not modify Phase 2–7 files. Those phases are BLOCKED.
- Do not invent engine facts. Label unverified claims explicitly.
- Do not bulk-load all plan and spec files. Load this plan only.
- Do not revert unrelated local changes.
- Record only what is real. `not recorded` is a valid and correct entry.