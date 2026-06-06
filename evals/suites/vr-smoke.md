# VR Smoke Eval

## Purpose

Check the bundled Virtual Reality mission after gameplay-visible changes.

## Command

```powershell
hemtt launch vr
```

Wrapper:

```powershell
.\tools\launch-vr.ps1
```

## Pass Criteria

- Arma launches the VR mission.
- Player unit spawns.
- `BASEARMA_fnc_vrHello` runs.
- Hint, chat message, and dynamic text appear as expected.
- No visible script error appears.

## Fail Criteria

- Mission fails to launch.
- Player does not spawn.
- Expected messages do not appear.
- Script error appears.
