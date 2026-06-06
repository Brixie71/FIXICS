# Tools

Project-local helper scripts for FIXICS.

These wrappers keep common HEMTT commands consistent across Codex sessions. Each script runs from the repository root, prefers a local `.\hemtt.exe` when present, and falls back to `hemtt` on PATH.

## Commands

```powershell
.\tools\check.ps1
.\tools\build.ps1
.\tools\launch-vr.ps1
.\tools\build-native.ps1
```

Use `check.ps1` as the default automated validation gate after source or documentation changes.

Use `build-native.ps1` to build the approved local Windows x64 `FIXICSPhysics_x64.dll` extension artifact from `native/fixics_physics`.
