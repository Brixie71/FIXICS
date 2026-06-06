# HEMTT Check Procedure

## Command

```powershell
hemtt check
```

or:

```powershell
.\tools\check.ps1
```

## Procedure

1. Run the command from the repository root.
2. Confirm it exits with code 0.
3. Confirm HEMTT reports config rapification, SQF compilation, and stringtable checking.
4. Record failures with the first relevant error line.

## When Required

- SQF changes.
- Config changes.
- Stringtable changes.
- Mission changes.
- Tooling or documentation changes that should not alter addon behavior.
