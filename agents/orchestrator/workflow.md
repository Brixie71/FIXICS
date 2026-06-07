# Orchestrator Workflow

## Intake

1. Read `AGENTS.md`, `CODEX.md`, and `orchestration/router.yaml`.
2. Read relevant governance policy.
3. Classify the task: logic, physics, config, regression, tooling, documentation, or engine limitation.
4. Inspect affected files before asking discoverable questions.

## Research

- Logic: trace the execution path and conditions.
- Physics: identify velocity, force, mass, friction, slope, gearbox, collision, or locality quantities.
- Config: verify class names, PBO prefix, dependencies, and function registration.
- Tooling/docs: verify path references, syntax, and generated-output boundaries.

Use Bohemia primary documentation for engine/API claims. If a claim is not source-verified, label it as a project hypothesis.

## Approval

Follow the risk-based gate in `CODEX.md`.

When approval is required, present:

- problem summary;
- root cause or current unknowns;
- files to modify;
- dependencies and references;
- 2-3 approaches with tradeoffs;
- recommended approach;
- expected outcome;
- risks and validation.

## Implementation Handoff

After approval, the implementer follows the relevant specialist overlay, TDD where applicable, and the validation commands in `AGENTS.md`.
