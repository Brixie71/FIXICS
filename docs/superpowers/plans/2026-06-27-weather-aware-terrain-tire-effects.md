# Weather-Aware Terrain Tire Effects Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add weather-aware wet terrain, hydroplaning, and minimal wind handling to Terrain Tire Behavior.

**Architecture:** SQF gathers weather/wind state, Terrain Tire computes bounded multipliers, Runtime Assist propagates telemetry, and existing stability path applies any wind lateral delta.

**Tech Stack:** Arma SQF, CBA settings, HEMTT static checks, PowerShell validation.

---

### Task 1: Static Tests

- [ ] Add settings contract assertions.
- [ ] Add Terrain Tire token assertions.
- [ ] Add Runtime Assist propagation assertions.
- [ ] Add telemetry token assertions.
- [ ] Run vehicle physics static test and verify RED failure.

### Task 2: Settings

- [ ] Add missionNamespace defaults.
- [ ] Register eight CBA settings under `["FIXICS", "Terrain Tire"]`.
- [ ] Add stringtable labels/tooltips.
- [ ] Sort stringtable.

### Task 3: Terrain Tire Weather Math

- [ ] Read weather state inputs.
- [ ] Add saturation/drying update.
- [ ] Compute weather grip multiplier.
- [ ] Compute hydroplaning risk.
- [ ] Compute minimal wind lateral multiplier.
- [ ] Apply weather multiplier to traction outputs.
- [ ] Return telemetry fields.

### Task 4: Integration And Telemetry

- [ ] Pass rain/overcast/wind state from stability integration.
- [ ] Propagate weather fields through Runtime Assist.
- [ ] Add weather fields to one-shot and continuous telemetry.
- [ ] Add weather debug logging.

### Task 5: Validation

- [ ] Run governance static.
- [ ] Run vehicle physics static.
- [ ] Run `tools/check.ps1`.
- [ ] Run `git diff --check`.
- [ ] Update `orchestration/state.md`.
