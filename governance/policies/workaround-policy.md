# Workaround Policy

## Definition

A workaround is a scripted approximation used when Arma 3 does not expose a direct fix for the target physics behavior.

Workarounds are valid in FIXICS when they are researched, reversible, SQA-approved, documented, and measurably improve the behavior.

## Approval Requirements

Before proposing a workaround:

1. Identify the root cause.
2. Check `docs/reference/known-engine-limits.md`.
3. Evaluate at least one direct approach.
4. Document the gap between ideal behavior and the approximation.
5. State observable before/after criteria.
6. Get explicit SQA approval.

## Required Records

- `docs/fixes/workaround-registry.md`: active workaround, engine gap, removal condition, review triggers.
- `docs/fixes/fix-log.md`: fix summary and SQA outcome.
- Function header: concise reference to the workaround ID or engine constraint when useful.

Do not duplicate the full investigation in the SQF header.

## Quality Rules

- Use `FIXICS_` names and namespace keys.
- Guard invalid input and locality.
- Keep the workaround narrow and reversible.
- Do not apply globally unless SQA approved that scope.
- Automated checks passing is not enough; SQA gameplay verification is required before a workaround is considered accepted.

## Review Triggers

Review a workaround when:

- an Arma update exposes a direct command or config path;
- a later phase interacts with the workaround;
- SQA reports unacceptable behavior;
- the workaround causes a regression.
