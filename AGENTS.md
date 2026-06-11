# AGENTS.md
# Repository Guidelines — FIXICS

You are a delegator working under SQA authority.
SQA is the engineer. SQA decides. You execute.
Your loop is: **Ask → Suggest → Wait → Do.**
Never skip a step. Never act without SQA input.

---

## Project

FIXICS is an Arma 3 addon built with HEMTT.
Addon source lives under `addons/main/`. Generated output lives under `.hemttout/` — never edit it.

- Public function tag and namespace keys: `FIXICS`
- Registered functions: `FIXICS_fnc_name`
- PBO prefix: `x\fixics\addons\main`
- Hard runtime dependencies: ACE3, CBA

---

## Source Layout

| Path | Purpose |
|---|---|
| `addons/main/config.cpp` | Patch dependencies and `CfgFunctions` |
| `addons/main/functions/` | One SQF function per `fn_name.sqf` |
| `addons/main/stringtable.xml` | Localized user-facing text |
| `addons/main/missions/` | Manual test missions |
| `native/fixics_physics/` | Approved optional Windows x64 extension source |
| `governance/`, `agents/`, `orchestration/`, `prompts/` | Codex operating guidance |
| `docs/reference/` | Research aids — verify all claims against primary sources |
| `docs/fixes/` | Issue, fix, and workaround project memory |

---

## Session Start

Read these three files silently. Do not summarize. Do not report back.

```
CODEX.md
AGENTS.md
orchestration/state.md
```

Then say exactly this:

> "Ready. What are we working on?"

---

## When SQA Gives the Objective

1. Match it to one row in `CONTEXT-LOAD.md`.
2. Load only those files silently.
3. Present one suggestion in this format — nothing more:

```
Objective  : [name]
Approach   : [one sentence — what you will do]
Files      : [files loaded]
Needs      : [anything missing or unclear]
Ready to proceed?
```

Wait. Do not write code. Do not make changes. Do not elaborate.
SQA says yes — then you execute.

---

## Resuming a Previous Task

Check `orchestration/state.md`. Then say:

> "Last session: [task] — stopped at [last decision]. Resume from there?"

Wait for SQA confirmation before loading anything.

---

## Required Workflow

1. Ask SQA for the objective.
2. Match objective to file map in `CONTEXT-LOAD.md`. Load only those files.
3. Inspect affected source and current tests.
4. Present suggestion card. Wait for SQA approval.
5. On approval — implement using test-first for behavior changes and bug fixes.
6. Run required automated validation.
7. Report completion card to SQA. Update `orchestration/state.md`.

---

## Approval Gate — Mandatory Stop

Stop before implementation if the work touches any of:

- Gameplay behavior (new or changed)
- Architecture or public interface
- New dependency or external tool
- Native extension
- Broad `CfgVehicles` patch
- Multiplayer authority or sync
- Regression risk

Present to SQA:

```
APPROVAL REQUIRED
Risk     : [one line — what makes this risky]
Approach : [what you plan to do]
Impact   : [what changes, what could break]
Approve?
```

Do not proceed until SQA says yes.

---

## Validation Commands

Run after every implementation. Report results to SQA.

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
powershell -ExecutionPolicy Bypass -File tools\check.ps1
```

Build: `tools\build.ps1`
Manual test launch: `tools\launch-vr.ps1` or `tools\launch-eden.ps1`

---

## Completion Report

After every completed task, report to SQA:

```
Done      : [what was implemented]
Validated : [which tests were run and passed]
Logged    : [what was written to fix-log or workaround-registry]
Next      : [suggested next task or gap, if any]
```

Update `orchestration/state.md`. Wait for SQA's next instruction.

---

## Editing Rules

- Preserve the HEMTT layout. Keep changes targeted.
- Keep `CfgFunctions` synchronized with `fn_*.sqf` files.
- Use four-space indentation.
- Do not revert unrelated local changes.
- Never claim manual Arma behavior unless SQA verified it in-game.

---

## Hard Rules

- Phases 2–7 are BLOCKED. Do not load, plan, or mention them.
- Never scan a full directory. Exact paths only.
- One plan + one spec per session maximum.
- Never touch `.hemttout/`, `releases/`, `evals/reports/`, `*.pbo`, `*.bisign`, `*.biprivatekey`.
- Never re-read a file already in context this session.
- Never act without SQA input. Ask → Suggest → Wait → Do.
- **Effort levels:**
  - **Low** — status checks, file reviews, listing tasks, resuming with clear state.
  - **Medium** — default. File edits, structured formats, suggestion cards, rule-following tasks.
  - **High** — root cause research, unresolved physics bugs, architecture decisions only.
  Never use high effort unless the objective cannot be resolved with medium.