# Workaround Policy

## Purpose

FIXICS operates under an engine constraint: the Arma 3 Real Virtuality 4 physics engine cannot be replaced. When a physics problem cannot be corrected directly through config or an exposed SQF command, a **scripted workaround** is a valid and expected output — not a failure.

This policy defines when a workaround is acceptable, what documentation is required before shipping one, and when it must be revisited or removed.

---

## Definition

A **workaround** is a scripted approximation that moves behavior closer to physically correct without having direct access to the underlying value or system that causes the problem.

A workaround is **not**:
- A quick fix that masks symptoms without understanding the root cause
- An excuse to skip the Pre-Implementation Review
- A permanent solution that never gets reconsidered

---

## When a Workaround Is Acceptable

A workaround may be proposed and approved when **all** of the following are true:

1. The root cause has been identified and documented.
2. `docs/reference/known-engine-limits.md` confirms (or CODEX has researched and documented) that the engine does not expose a direct fix for this problem.
3. At least one direct-fix approach was evaluated and found to be impossible or insufficient.
4. The workaround measurably improves the behavior compared to the current state.
5. The gap between the workaround's output and ideal physical behavior is documented.
6. SQA has approved the workaround approach explicitly.

If any of these conditions is not met, CODEX must continue researching before proposing a workaround.

---

## What "Measurably Improves" Means

CODEX must state the improvement in concrete terms — not just "it feels better":

```
Before workaround : vehicle launches ~8m into the air on 0.4m obstacle impact
After workaround  : vehicle launches ~0.6m — within acceptable range for this mass
Ideal behavior    : no abnormal launch; ~0.1m max — engine cannot achieve without
                    direct restitution control (see known-engine-limits.md #EL-003)
```

If CODEX cannot state the improvement with numbers or observable criteria, the workaround is not ready to propose.

---

## Required Documentation Before Shipping

Before a workaround is implemented, the following must exist:

### 1. In the function block comment

The `Physics correction` block must include:

```sqf
 * Method        : Workaround
 * Gap           : [what ideal behavior this cannot achieve]
 * Removal cond. : [what engine change would make this function unnecessary]
```

### 2. In `docs/fixes/workaround-registry.md`

An entry must be appended before or immediately after the fix is merged. See the registry template for the required fields.

### 3. In `docs/fixes/fix-log.md`

The fix log entry must note that the resolution is a workaround, not a direct fix, and link to the registry entry.

---

## Workaround Quality Standards

A workaround must meet the same code quality standards as any other function:

- Complete `params` declaration with type checking
- Guard clause for null/invalid input
- Full physics correction block comment
- `BASEARMA_` prefix on all globals and namespace keys
- `hemtt check` passes
- Manual VR test completed and result recorded

A workaround that passes code review but fails VR testing is not shippable.

---

## Workaround Review Triggers

An existing workaround must be reviewed and potentially removed when any of the following occur:

| Trigger | Action |
|---|---|
| A HEMTT or Arma 3 update exposes a direct fix for the gap | Evaluate replacement; file an issue in `open-issues.md` if replacement is worthwhile |
| A new Phase introduces logic that interacts with the workaround | Re-test in VR; update the registry entry |
| The workaround causes a regression in another system | Escalate to SQA immediately; do not silently patch |
| SQA reports the workaround behavior is no longer acceptable | Treat as a new bug; open an issue and re-run the full intake protocol |

---

## CODEX Rules

- CODEX must never propose a workaround before checking `docs/reference/known-engine-limits.md`.
- CODEX must never ship a workaround without SQA approval of the specific approach.
- CODEX must update `docs/fixes/workaround-registry.md` for every active workaround.
- CODEX must not remove a workaround without SQA approval, even if a direct fix becomes available.
- CODEX treats a workaround as successful only when the VR test result is `pass` or `partial` with an accepted gap — never on automated validation alone.