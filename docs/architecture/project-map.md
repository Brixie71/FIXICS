# Project Map

This document maps the Enterprise GenAI-inspired operating folders onto FIXICS.

## Actual Addon Layer

```text
.hemtt/
addons/main/
  config.cpp
  functions/
  stringtable.xml
  missions/
mod.cpp
meta.cpp
```

This layer is what HEMTT builds. Do not move it for folder aesthetics.

## Codex Operating Layer

```text
AGENTS.md
CODEX.md
agents/
tools/
orchestration/
prompts/
governance/
evals/
tests/
docs/
```

This layer helps Codex understand the project, route work, reuse prompts, and validate changes.

## Mapping

- Image `agents/`: repo `agents/`, role guidance for Codex.
- Image `orchestrator/`: repo `agents/orchestrator/`.
- Image `specialists/`: repo `agents/specialist/`.
- Image `tools/`: repo `tools/`, PowerShell HEMTT and RPT wrappers.
- Image `orchestration/`: repo `orchestration/`, routing and state.
- Image `prompts/`: repo `prompts/`, reusable task prompts.
- Image `governance/`: repo `governance/`, policy and guardrails.
- Image `evals/`: repo `evals/`, pass/fail definitions.
- Image `tests/`: repo `tests/`, validation procedures.
- Image `docs/`: repo `docs/`, architecture, references, fixes, and Superpowers docs.

## Rule

The Codex layer supports the addon layer. It does not replace the addon layer.
