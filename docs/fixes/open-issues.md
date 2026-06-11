# Open Issues

## Purpose

This file tracks SQA-reported bugs that are not yet resolved. Move fixed and verified items to `docs/fixes/fix-log.md`; do not keep resolved milestones here.

Phase 1 cannot close while any `HIGH` or `CRITICAL` `ground-vehicle` issue is open.

## Priority Levels

| Priority | Meaning |
|---|---|
| `CRITICAL` | Crashes the game, corrupts mission state, or makes the vehicle unusable |
| `HIGH` | Consistent physics behavior that materially affects gameplay |
| `MEDIUM` | Noticeable issue that does not block normal gameplay |
| `LOW` | Minor anomaly, edge case, or cosmetic issue |

## Status Values

| Status | Meaning |
|---|---|
| `OPEN` | Filed, not assigned |
| `RESEARCHING` | CODEX is analyzing root cause |
| `AWAITING APPROVAL` | Plan presented, waiting for SQA |
| `IN PROGRESS` | SQA approved implementation |
| `BLOCKED` | Cannot proceed; reason is documented |
| `RESOLVED` | Verified and ready to move to fix log |
| `WONT FIX` | SQA declined the issue |

## Open Issues

### ISSUE-001 - High-speed sharp-turn steering lock

- **Priority** : HIGH
- **Area**     : ground-vehicle steering
- **Status**   : OPEN
- **Reported** : SQA, 2026-06-12

At high speed, a sharp steering input can appear to lock the steering response while the vehicle continues forward and oversteers. SQA described moderate rally-style turns as acceptable, with the problem appearing on sharper left or right turns.

This issue is not currently attributed to ABS braking or Native Driver Assist v2. Root-cause research and a separate approved design are required before implementation.

Resolved Phase 1 milestones are recorded in `docs/fixes/fix-log.md`. Active approximations are recorded in `docs/fixes/workaround-registry.md`.
