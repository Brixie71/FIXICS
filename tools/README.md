# Tools

Project-local PowerShell helpers for FIXICS.

## Commands

```powershell
powershell -ExecutionPolicy Bypass -File tools\check.ps1
powershell -ExecutionPolicy Bypass -File tools\build.ps1
powershell -ExecutionPolicy Bypass -File tools\launch-vr.ps1
powershell -ExecutionPolicy Bypass -File tools\launch-eden.ps1
powershell -ExecutionPolicy Bypass -File tools\rpt-parser.ps1
powershell -ExecutionPolicy Bypass -File tools\watch-rpt.ps1
powershell -ExecutionPolicy Bypass -File tools\build-native.ps1
```

Use `check.ps1` as the default automated validation gate.

Use `rpt-parser.ps1` after a manual Arma run to summarize script errors and FIXICS physics output.

Use `watch-rpt.ps1` during manual SQA sessions to stream new relevant RPT lines.

Use `build-native.ps1` only for the approved Windows x64 `FIXICSPhysics_x64.dll` extension boundary.
