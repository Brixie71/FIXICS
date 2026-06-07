# Phase Control Policy

## Purpose

This file defines the exact conditions under which each FIXICS development phase is considered complete and the next phase may begin. CODEX must not begin work on Phase N+1 until Phase N satisfies every criterion in its completion gate.

This policy exists because the project rule is absolute:

> **Phases will not start unless the previous phase has been done.**

"Done" is not an opinion. It is a checklist.

---

## Phase Status Overview

| Phase | Title | Status | Gate passed |
|---|---|---|---|
| 1 | Ground Vehicle Physics | 🔄 In Progress | ❌ Not yet |
| 2 | Human Limb Physics | ⏸ Blocked | ❌ Requires Phase 1 |
| 3 | Body Kit Attachments | ⏸ Blocked | ❌ Requires Phase 2 |
| 4 | Aircraft Physics | ⏸ Blocked | ❌ Requires Phase 3 |
| 5 | Ship and Boat Physics | ⏸ Blocked | ❌ Requires Phase 4 |
| 6 | Performance Improvements | ⏸ Blocked | ❌ Requires Phase 5 |
| 7 | Memory Improvements | ⏸ Blocked | ❌ Requires Phase 6 |

Update this table when SQA signs off on a phase gate.

---

## Phase 1 Completion Gate — Ground Vehicle Physics

Phase 1 is complete when **all** of the following are true:

### Functional Requirements

- [ ] All SQA-reported ground vehicle physics bugs are resolved or have an approved workaround with a documented gap.
- [ ] No open issues in `docs/fixes/open-issues.md` have priority `HIGH` or `CRITICAL` and category `ground-vehicle`.
- [ ] Every active workaround for ground vehicle physics is recorded in `docs/fixes/workaround-registry.md` with a removal condition.

### Code Quality Requirements

- [ ] All functions introduced in Phase 1 pass `hemtt check` with exit code `0`.
- [ ] All Phase 1 functions have complete block comments including the physics correction record (symptom, root cause, before, after, math, SQA approval, VR verified).
- [ ] All Phase 1 functions are registered in `CfgFunctions`.
- [ ] No debug `hint` calls remain ungated in Phase 1 functions.

### Verification Requirements

- [ ] Every Phase 1 function has a VR test result recorded in `docs/fixes/fix-log.md`.
- [ ] No VR test result is `fail` without an associated resolution entry.
- [ ] SQA has explicitly signed off on Phase 1 completion in writing (note the date below).

### SQA Sign-Off

```
Phase 1 sign-off date : ___________
Signed by             : SQA
Notes                 : ___________
```

---

## Phase 2 Completion Gate — Human Limb Physics

*(Defined here in advance. Do not begin implementation until Phase 1 gate is passed.)*

Phase 2 is complete when **all** of the following are true:

- [ ] All SQA-reported human limb physics bugs are resolved or have an approved workaround.
- [ ] No open `HIGH` or `CRITICAL` issues in `docs/fixes/open-issues.md` with category `human-limb`.
- [ ] `hemtt check` passes for all Phase 2 functions.
- [ ] All Phase 2 functions have complete block comments.
- [ ] Every Phase 2 function has a VR test result in `docs/fixes/fix-log.md`.
- [ ] SQA Phase 2 sign-off recorded below.

```
Phase 2 sign-off date : ___________
Signed by             : SQA
Notes                 : ___________
```

---

## Phase Gates for Phases 3–7

Phases 3 through 7 follow the same gate structure as Phase 2. When the time comes, define their specific functional requirements by creating a section for each phase above, following the Phase 2 template.

The minimum gate criteria that apply to **every** phase regardless:

1. All SQA-reported bugs for that phase are resolved or have approved workarounds with documented gaps.
2. No open `HIGH` or `CRITICAL` issues for that phase in `docs/fixes/open-issues.md`.
3. `hemtt check` passes.
4. All functions have complete block comments and VR test records.
5. SQA sign-off is recorded in this file with a date.

---

## CODEX Rules

- CODEX must check this file at the start of any session where new phase work is being considered.
- CODEX must not create functions, plan implementations, or write designs for a blocked phase.
- If SQA asks CODEX to begin a blocked phase, CODEX must state which gate criteria are unmet before proceeding with any planning.
- When SQA signs off on a phase, CODEX updates the status table at the top of this file and records the date.