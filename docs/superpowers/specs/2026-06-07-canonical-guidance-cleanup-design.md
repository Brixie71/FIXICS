# Canonical Guidance Cleanup - Design Spec

## Purpose

Make the FIXICS operating layer consistent, tracked, source-verified, and efficient for future Codex sessions.

## Authority

Repository guidance uses this precedence:

1. `AGENTS.md` - repository facts and mandatory commands.
2. `CODEX.md` - task lifecycle and approval workflow.
3. `governance/policies/` - enforceable coding, scope, phase, and workaround rules.
4. `agents/` - short role-specific overlays.
5. `docs/reference/` - technical research aids.

The only valid public namespace is `FIXICS_`. The addon path is `x\fixics\addons\main`.

## Workflow

Formal design approval is risk-based. It is required for behavior changes, architecture, dependencies, public interfaces, broad config patches, native work, multiplayer authority, and other high-impact changes. File count alone does not trigger a design.

Phase 1 remains in progress until its gate is satisfied and SQA explicitly signs off. Existing ABS, handbrake, slope, and direction-transition work are completed milestones, not phase completion.

Detailed root-cause evidence, math, before/after observations, approval, and VR results live in `docs/fixes/`. Function headers stay concise and may reference the relevant fix or workaround record.

## References And Tools

Technical reference claims must cite Bohemia primary documentation or be labeled as an unverified project hypothesis. Unsupported commands and guessed units are not presented as facts.

RPT tools filter the `FIXICS` namespace, share one project pattern source, write reports only when requested, and keep generated reports untracked. PowerShell wrappers use repository-root resolution, prefer local `hemtt.exe`, propagate exit codes, and use ASCII output.

## Project Memory

Active guidance, orchestration, prompts, references, fix records, and tools are tracked in Git. Generated output, reports, downloaded tools, packed binaries, logs, and private keys remain ignored.

Historical Phase 1 records are backfilled only from committed specs, validation logs, commits, and SQA observations. Missing measurements or dates are recorded as `not recorded`.

## Validation

- Static governance consistency test.
- No stale `BASEARMA` identifiers or `x\base_arma` paths in active guidance and tools.
- Referenced files exist.
- YAML and PowerShell syntax parse successfully.
- Existing FIXICS vehicle-physics static test passes.
- HEMTT check passes.
- Generated and private paths remain ignored.
