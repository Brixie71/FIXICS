# Superpowers Workflow — README

This folder stores Superpowers design and planning artifacts for FIXICS.

> **Codex:** These files are loaded on demand only — one plan + one spec per session.
> Do not load all files in this folder. Use `CONTEXT-LOAD.md` to match the active task to the correct pair.

---

## Layout

```
docs/superpowers/
├── README.md          This file — how to use Superpowers in this repo
├── specs/             Approved design specs
└── plans/             Implementation plans
```

---

## When to Use Each File

| File Type | When | Who Triggers |
|---|---|---|
| `specs/` | SQA approves a design — save the output here | SQA |
| `plans/` | Design is approved and implementation is ready to decompose | SQA |

Codex loads a spec or plan only when SQA assigns that specific task.
Codex does not scan this folder. Codex does not load all specs or all plans together.

---

## Superpowers Skills Reference

| Skill | When to Use | Output |
|---|---|---|
| `superpowers:brainstorming` | Before any broad design or behavior change | `docs/superpowers/specs/` |
| `superpowers:writing-plans` | After a design is approved — decompose into trackable steps | `docs/superpowers/plans/` |
| `superpowers:subagent-driven-development` | Executing a multi-step plan — preferred for complex tasks | Used during execution |
| `superpowers:executing-plans` | Executing a single-threaded step-by-step plan | Used during execution |
| `superpowers:verification-before-completion` | Before claiming any validation passed or task is complete | Applied as final check |

---

## File Naming Convention

All specs and plans use ISO date prefixes:

```
YYYY-MM-DD-short-description.md
```

Examples:
```
docs/superpowers/specs/2026-06-07-abs-braking-module-design.md
docs/superpowers/plans/2026-06-07-abs-braking-module.md
```

---

## Workflow

### Design Phase

1. SQA triggers `superpowers:brainstorming` for the topic.
2. SQA reviews and approves the output.
3. Save approved design as `docs/superpowers/specs/YYYY-MM-DD-topic.md`.

### Planning Phase

1. SQA triggers `superpowers:writing-plans` with the approved spec as input.
2. SQA reviews — confirm task order, expected outputs, and validation steps.
3. Save as `docs/superpowers/plans/YYYY-MM-DD-topic.md`.

### Execution Phase

1. SQA assigns the task. Codex loads the matching plan and spec via `CONTEXT-LOAD.md`.
2. Codex presents a suggestion card. Waits for SQA yes.
3. Codex executes task by task. Checks off `- [ ]` steps only when output is verified.
4. Codex runs `.\tools\check.ps1` after every source change.
5. Codex applies `superpowers:verification-before-completion` before closing the plan.
6. Codex presents a completion report to SQA.

---

## Validation

```powershell
# Required after every source change
.\tools\check.ps1

# Required after any gameplay or physics change — SQA runs this
.\tools\launch-vr.ps1
```

> Always report manual and automated validation separately.
> Do not claim manual coverage unless `.\tools\launch-vr.ps1` was actually run and behavior was verified by SQA.

---

## Active Plans and Specs

| Task | Plan | Spec |
|---|---|---|
| ABS Braking Module | `plans/2026-06-07-abs-braking-module.md` | `specs/2026-06-07-abs-braking-module-design.md` |
| Canonical Guidance Cleanup | `plans/2026-06-07-canonical-guidance-cleanup.md` | `specs/2026-06-07-canonical-guidance-cleanup-design.md` |
| Driver State Controller | `plans/2026-06-07-driver-state-controller.md` | `specs/2026-06-07-driver-state-controller-design.md` |
| Local Vehicle Slope Rolling | `plans/2026-06-07-local-vehicle-slope-rolling.md` | `specs/2026-06-07-local-vehicle-slope-rolling-design.md` |
| Neutral Direction Transition | `plans/2026-06-07-neutral-direction-transition.md` | *(no spec yet)* |
| Arma Scripting Docs | `plans/2026-06-06-arma-scripting-docs.md` | `specs/2026-06-06-arma-scripting-docs-design.md` |
| Codex Operating Layer | `plans/2026-06-06-codex-operating-layer.md` | `specs/2026-06-06-codex-operating-layer-design.md` |

Load only the row that matches the active task. All others stay unloaded.