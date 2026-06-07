# Code Review Prompt

Use when reviewing FIXICS changes.

## Priority

Lead with findings:

1. Runtime errors or missing function registrations.
2. HEMTT config or SQF compile failures.
3. Locality, scheduling, or network mistakes.
4. Physics regressions or unsupported engine assumptions.
5. Missing tests or validation evidence.

## Files To Check

- `addons/main/config.cpp`
- `addons/main/functions/`
- `addons/main/stringtable.xml`
- `.hemtt/project.toml`
- relevant `docs/fixes/` and `governance/audit/validation-log.md`

## Validation

Request or run the relevant static test and `tools\check.ps1`. Do not claim manual Arma coverage unless SQA verified it.
