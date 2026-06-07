# Phase Control

## Status

| Phase | Title | Status | Gate |
|---|---|---|---|
| 1 | Ground Vehicle Physics | In Progress | Not passed |
| 2 | Human Limb Physics | Blocked | Requires Phase 1 |
| 3 | Body Kit Attachments | Blocked | Requires Phase 2 |
| 4 | Aircraft Physics | Blocked | Requires Phase 3 |
| 5 | Ship and Boat Physics | Blocked | Requires Phase 4 |
| 6 | Performance Improvements | Blocked | Requires Phase 5 |
| 7 | Memory Improvements | Blocked | Requires Phase 6 |

## Phase 1 Gate

Phase 1 is complete only when all are true:

- No open `HIGH` or `CRITICAL` `ground-vehicle` issues in `docs/fixes/open-issues.md`.
- Active workarounds are recorded in `docs/fixes/workaround-registry.md`.
- Fixes have records in `docs/fixes/fix-log.md`.
- Required automated checks pass.
- SQA has manually verified required gameplay behavior or accepted explicit gaps.
- SQA signs off on Phase 1 completion in writing.

## Rules

- Do not start Phase 2 implementation while Phase 1 is in progress.
- A completed milestone does not close a phase.
- If SQA asks for blocked-phase work, report unmet gate criteria before planning.
