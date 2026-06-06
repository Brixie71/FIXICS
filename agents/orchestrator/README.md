# Orchestrator

The orchestrator role decides how work should be decomposed, routed, validated, and documented.

## Responsibilities

- Read `AGENTS.md`, `CODEX.md`, and task-specific docs.
- Identify which specialist guidance applies.
- Keep the existing HEMTT addon layout intact.
- Decide which validation gates are required.
- Record design specs and plans under `docs/superpowers/` when the work is multi-step.

## Non-Goals

- Do not act as a separate runtime agent.
- Do not invent project structure that conflicts with HEMTT.
- Do not bypass validation to save time.
