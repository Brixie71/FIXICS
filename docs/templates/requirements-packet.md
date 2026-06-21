# Requirements Packet Template

## Objective

[Name the feature, research task, bug fix, or architecture change.]

## Current System State

- Phase:
- Relevant implemented systems:
- Relevant open issues:
- Known constraints:

## Files To Load

Load only exact paths.

| Purpose | File |
|---|---|
| Session state | `orchestration/state.md` |
| Open issue context | `docs/fixes/open-issues.md` |
| Fix/workaround history | `docs/fixes/fix-log.md`, `docs/fixes/workaround-registry.md` |
| Technical reference | `[exact reference path]` |
| Approved spec or plan | `[exact spec/plan path]` |
| Affected source | `[exact source path]` |

## SQA Questions And Answers

Ask all clarifying questions up front before implementation.

| Question | SQA Answer | Decision Impact |
|---|---|---|
| [question] | [answer] | [what this controls] |

## Constraints

- Do not change unrelated behavior.
- Do not touch generated output.
- Do not claim manual Arma behavior unless SQA verifies it in-game.
- Preserve ACE3 and CBA dependency boundaries.
- Keep SQF, config, native, and multiplayer authority boundaries explicit.

## Approval Gates

Stop before implementation if the work touches:

- Gameplay behavior
- Architecture or public interface
- New dependency or external tool
- Native extension
- Broad `CfgVehicles` patch
- Multiplayer authority or synchronization
- Material regression risk
- Direct SQA stop, pause, hold, or abort command

## Recommended Approach

1. Documentation/research:
2. Implementation plan:
3. Validation:
4. SQA handoff:

## Expected Output

- Files created:
- Files modified:
- Tests run:
- Manual SQA focus:
- Logs or docs updated:

## Validation Commands

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
powershell -ExecutionPolicy Bypass -File tools\check.ps1
```

## SQA QA Handoff

After implementation, hand the feature to SQA with:

- What changed
- What did not change
- Expected in-game behavior
- Suggested manual test matrix
- Known limitations
- Follow-up comment path

## Repeat Cycle

When SQA reports comments:

1. Record the comment.
2. Classify it as bug, tuning, regression, missing requirement, or new feature.
3. Update the Requirements Packet or open issue.
4. Recommend the next fix plan.
5. Wait for SQA approval.
6. Implement and validate.
