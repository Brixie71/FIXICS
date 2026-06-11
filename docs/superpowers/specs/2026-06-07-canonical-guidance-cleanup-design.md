# Canonical Guidance Cleanup — Design Spec

> **Codex:** This is a reference document. Do NOT act on it directly.
> When SQA assigns this task, load this file via `CONTEXT-LOAD.md` → Canonical Guidance Cleanup row.
> Present the suggestion card. Wait for yes. Then execute task by task.

---

## Purpose

Make the FIXICS operating layer consistent, tracked, source-verified, and efficient for future Codex sessions. Reduce per-session token cost by keeping agent files thin, governance authoritative, and `CONTEXT-LOAD.md` as the sole file-routing source.

---

## Operating Model

SQA is the authority. Codex is the delegator.
Loop: **Ask → Suggest → Wait → Do.**

Codex presents one suggestion card per task. No task proceeds without SQA approval.
Codex does not re-read files already in context. Codex does not load files not listed in `CONTEXT-LOAD.md` for this task.

---

## Authority Order

When guidance conflicts, resolve in this order:

| Priority | File | Role |
|---|---|---|
| 1 | `AGENTS.md` | Repository facts, session contract, hard rules |
| 2 | `CODEX.md` | Task lifecycle, phase table, approval gates |
| 3 | `governance/policies/` | Enforceable coding, scope, phase, and workaround rules |
| 4 | `agents/` | Thin domain overlays only — no duplicate policy |
| 5 | `docs/reference/` | Technical research aids — verify all claims |

The only valid public namespace is `FIXICS_`. The only valid addon path is `x\fixics\addons\main`.
Agent files must not repeat rules already in governance. If it is in governance, link to it — do not copy it.

---

## Session and File Loading

`CONTEXT-LOAD.md` is the sole routing source for what Codex loads per session.
Cold start loads only: `CODEX.md`, `AGENTS.md`, `orchestration/state.md`.
This design spec is loaded only when Canonical Guidance Cleanup is the active task.
All other plans and specs remain unloaded.

---

## Workflow and Approval Gates

Approval is risk-based, not file-count based. Required for:

- New or changed gameplay behavior
- Architecture or public interface changes
- New dependencies or external tools
- Native extension work
- Broad `CfgVehicles` patches
- Multiplayer authority or sync
- Changes with material regression risk

Bounded documentation, test, and wrapper maintenance may proceed with a concise intent update when behavior and interfaces do not change — but still require a suggestion card and SQA yes.

Phase 1 remains In Progress until its gate is satisfied and SQA explicitly signs off.
Completed ABS, handbrake, slope-rolling, and direction-transition work are Phase 1 milestones — not phase completion.

---

## Agent File Rules

After this cleanup, every file under `agents/` must satisfy all of the following:

- Contains only domain-specific guidance not already in governance or `AGENTS.md`.
- Does not duplicate workflow steps from `CODEX.md`.
- Does not duplicate policy rules from `governance/policies/`.
- Does not contain file paths outside its domain.
- Is loadable in isolation without pulling the entire `agents/` directory.

If a file cannot satisfy these rules, its content belongs in governance or `CODEX.md` — not in `agents/`.

---

## References and Tools

**Reference files (`docs/reference/`):**
Every engine or API claim must either cite Bohemia primary documentation or carry this label:
`[project hypothesis — not source-verified]`

Correct specifically:
- Angular velocity behavior and units
- Center-of-mass scripting access
- Mass scripting access
- Autobrake activation conditions
- `brakeIdleSpeed` behavior and units

**RPT tools (`tools/`):**
- All pattern strings centralized in `tools/rpt-patterns.ps1`
- `rpt-parser.ps1` and `watch-rpt.ps1` import from `rpt-patterns.ps1` — no inline patterns
- All console output prefixed with `FIXICS`
- Reports written only when explicitly requested
- Generated reports remain untracked in `.gitignore`
- All wrappers use repository-root resolution, prefer local `hemtt.exe`, propagate exit codes, use ASCII output only

---

## Project Memory Rules

Tracked in Git:
- Active guidance, orchestration, prompts, references, fix records, and tools

Never tracked:
- Generated output, reports, downloaded tools, packed binaries, logs, private keys

Backfill rules for `docs/fixes/fix-log.md`:
- Use only committed specs, validation logs, commits, and SQA-verified observations as evidence
- Missing measurements or dates: record as `not recorded` — do not estimate or invent
- Do not create placeholder open issues — `open-issues.md` stays empty unless a real unresolved issue exists

---

## Validation Acceptance Criteria

This cleanup is complete when all of the following pass:

| Check | Command |
|---|---|
| Governance static test | `tests\integration\fixics-governance-static.ps1` |
| Vehicle physics static test | `tests\integration\fixics-vehicle-physics-static.ps1` |
| HEMTT check | `tools\check.ps1` |
| Whitespace clean | `git diff --check` |

All assertions in `fixics-governance-static.ps1` must pass, including:

- Canonical files present: `AGENTS.md`, `CODEX.md`, `CONTEXT-LOAD.md`, `orchestration/state.md`
- `FIXICS_` naming in all registered SQF functions
- `x\fixics\addons\main` PBO prefix in `config.cpp`
- No `BASEARMA` identifiers or `x\base_arma` paths in active guidance or tools
- Phase 1 marked In Progress in `CODEX.md` and `agents/specialist/phase-control.md`
- No unsupported engine claims without hypothesis label in `docs/reference/`
- Tool console output uses `FIXICS` prefix
- YAML and PowerShell files parse without errors
- Generated-output and private-key ignore rules present in `.gitignore`
- All referenced files in agent and governance docs exist on disk

---

## Out of Scope

- Phase 2–7 work — BLOCKED, do not plan or mention
- Gameplay behavior changes
- New SQF functions or physics logic
- Native extension changes
- Any change not listed in the implementation plan tasks