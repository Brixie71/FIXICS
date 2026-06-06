# Tools

Project-local helper scripts for FIXICS.

These wrappers keep common HEMTT commands consistent across Codex sessions. Each script runs from the repository root, prefers a local `.\hemtt.exe` when present, and falls back to `hemtt` on PATH.

## Commands

```powershell
.\tools\check.ps1
.\tools\build.ps1
.\tools\launch-vr.ps1
```

Use `check.ps1` as the default automated validation gate after source or documentation changes.
