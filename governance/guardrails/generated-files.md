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

## Approved Native Binary Exception

- `FIXICSPhysics_x64.dll` in the repository root is an approved local Windows x64 extension artifact for the native-assisted gameplay-control experiment.
- Do not place native binaries under `native/`; that tree remains source, build scripts, and documentation only.
- Rebuild the DLL with `.\tools\build-native.ps1`; do not edit or patch the binary by hand.

## Reason

Generated files can hide real source changes and make validation misleading. Change source files, then rebuild with HEMTT.
