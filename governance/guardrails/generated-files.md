# Generated Files Guardrail

Do not manually edit generated or local-only output.

## Avoid Editing

- `.hemttout/`
- `releases/`
- `@FIXICS/`
- `*.pbo`
- `*.bisign`
- `*.rpt`
- `*.log`
- `*.tmp`
- private key files such as `*.biprivatekey` and `.hemttprivatekey`

## Reason

Generated files can hide real source changes and make validation misleading. Change source files, then rebuild with HEMTT.
