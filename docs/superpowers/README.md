# Superpowers Workflow — README

This folder stores Superpowers design and planning artifacts for FIXICS.

---

## Layout

```
docs/superpowers/
├── README.md          This file — how to use Superpowers in this repo
├── specs/             Approved design specs (output of superpowers:brainstorming)
└── plans/             Implementation plans (output of superpowers:writing-plans)
```

---

## When to Use Each Superpowers Skill

| Skill | Trigger condition | Output location |
|---|---|---|
| `superpowers:brainstorming` | Before any broad design or behavior change — new phase work, architecture decisions, major rewrites | `docs/superpowers/specs/` |
| `superpowers:writing-plans` | After a design is approved and implementation needs to be decomposed into trackable steps | `docs/superpowers/plans/` |
| `superpowers:subagent-driven-development` | When executing a multi-step plan — preferred over `executing-plans` for parallel or complex tasks | Used during plan execution |
| `superpowers:executing-plans` | When executing a single-threaded step-by-step plan | Used during plan execution |
| `superpowers:verification-before-completion` | Before claiming any validation passed or any task is complete | Applied as a final check |

---

## File Naming Convention

All specs and plans use ISO date prefixes for chronological ordering:

```
YYYY-MM-DD-short-description.md
```

Examples:
```
docs/superpowers/specs/2026-06-06-vehicle-collision-detection.md
docs/superpowers/plans/2026-06-06-arma-scripting-docs.md
```

---

## Workflow

### Design Phase (Brainstorming → Spec)

1. Trigger `superpowers:brainstorming` for the topic.
2. Review and approve the output with SQA.
3. Save the approved design as `docs/superpowers/specs/YYYY-MM-DD-topic.md`.

### Planning Phase (Spec → Plan)

1. Trigger `superpowers:writing-plans` with the approved spec as input.
2. Review the generated plan — confirm task order, expected outputs, and validation steps.
3. Save as `docs/superpowers/plans/YYYY-MM-DD-topic.md`.

### Execution Phase (Plan → Implementation)

1. Use `superpowers:subagent-driven-development` or `superpowers:executing-plans` to execute the plan task-by-task.
2. Check off `- [ ]` steps as they are completed.
3. Do not mark a step complete unless its expected output was verified.
4. Run `.\tools\check.ps1` after every source change.
5. Apply `superpowers:verification-before-completion` before closing the plan.

---

## Validation

The primary automated validation command for this project is:

```powershell
.\tools\check.ps1
```

Equivalent direct command:

```powershell
hemtt check
```

Manual Arma gameplay checks require a separate launch:

```powershell
.\tools\launch-vr.ps1
```

> **Always report manual and automated validation separately.** Do not claim manual coverage unless `.\tools\launch-vr.ps1` was actually run and behavior was verified.

---

## Git Worktree Note

Git worktree workflows (parallel branches, isolated working trees) may be limited when this folder is not part of a git repository. If worktree commands fail, fall back to sequential branch work and document the limitation in the relevant plan file.