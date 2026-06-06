# HEMTT Check Eval

## Purpose

Validate addon config, SQF compilation, and stringtables.

## Command

```powershell
hemtt check
```

Wrapper:

```powershell
.\tools\check.ps1
```

## Pass Criteria

- Command exits with code 0.
- HEMTT loads project config.
- Addon configs rapify successfully.
- SQF files compile.
- Stringtables check successfully.

## Fail Criteria

- Non-zero exit code.
- Config parse or rapify error.
- SQF compile error.
- Stringtable error.
