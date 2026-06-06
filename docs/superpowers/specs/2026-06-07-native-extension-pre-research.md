# Native Extension Pre-Research

## Purpose

Research the native-extension path before FIXICS decides whether Phase 1 Ground Vehicle Physics should cross from SQF/config-class work into native code.

This document originally defined the feasibility boundary, evidence gate, likely architecture, and rejection criteria. After SQA reported that the config-class experiment made handling worse, the project approved a source-only native-assisted gameplay-control scaffold.

## Sources

- Bohemia Extensions overview: https://community.bohemia.net/wiki/Extensions
- Bohemia `callExtension`: https://community.bohemia.net/wiki/callExtension
- Bohemia `allExtensions`: https://community.bohemia.net/wiki/allExtensions
- Bohemia startup parameter `-debugCallExtension`: https://community.bohemia.net/wiki/Arma_3:_Startup_Parameters#debugCallExtension
- Bohemia vehicle handling config: https://community.bohemia.net/wiki/Arma_3:_Vehicle_Handling_Configuration
- Bohemia `disableBrakes`: https://community.bohemia.net/wiki/disableBrakes

## Research Conclusion

A native extension should not be treated as a direct replacement for Arma vehicle physics control.

The documented extension interface is a call boundary between SQF and an external DLL/SO. SQF calls the extension by name, passes a string or argument array, and receives a return value. The public docs do not describe an extension API that gives native code direct ownership of an Arma vehicle, its PhysX body, its gearbox state, or its wheels.

Inference: for FIXICS, a native extension can compute, log, validate, serialize, or integrate with external tools, but actual vehicle mutation would still need to return to SQF commands or addon config. That means a native extension is unlikely to solve the remaining Drive/Reverse or idle-brake behavior by itself unless a separate, documented engine hook is identified.

## What Extensions Can Do

Reasonable extension use cases for FIXICS:

- return version/build information for native diagnostics;
- ingest SQA telemetry and write structured external logs;
- perform heavier math or data processing outside SQF;
- normalize vehicle-class evidence across many tested vehicles;
- support tooling that is not needed during normal gameplay.

Poor extension use cases for FIXICS:

- directly editing Arma's hidden PhysX vehicle state;
- bypassing the internal Drive/Reverse gearbox transition;
- replacing `disableBrakes`, `setVelocity`, `addForce`, or config-class tuning;
- running every frame as part of the vehicle control loop;
- becoming a required client binary before SQF/config options are exhausted.

## Hard Requirements If Extension Work Is Approved Later

Interface:

- Export `RVExtension` or `RVExtensionArgs`.
- Export `RVExtensionVersion` so the version appears in the RPT on load.
- Prefer `RVExtensionArgs` for structured function names plus argument arrays.
- Keep return values small and deterministic.

Deployment:

- Place extension binaries in a loaded mod root, not loose in the Arma install folder.
- Provide both 32-bit and 64-bit outputs if release support requires it.
- Use the documented `_x64.dll` / `_x64.so` suffix for 64-bit binaries.
- Assume every client needs the extension if client-side gameplay code calls it.

Security:

- Treat the extension as executable code.
- Keep source available for review.
- Do not accept opaque third-party binaries for FIXICS physics control.
- Document runtime dependencies and install steps.
- Plan for BattlEye blocking on protected clients unless the extension is whitelisted.

Runtime:

- `callExtension` is blocking. Do not put extension calls in a per-frame or high-frequency physics loop.
- Use `-debugCallExtension` only for diagnostic runs because it increases logging.
- Use `allExtensions` to verify whether the extension is loaded and which interfaces it exposes.
- Provide SQF fallback behavior when the extension is missing or blocked.

## Evidence Gate Before Implementation

Do not start native-extension scaffolding until all items are true:

- SQA confirms the config-class experiment still fails.
- The tested vehicle class and inherited config values are captured with `FIXICS_fnc_logVehicleHandlingConfig`.
- The failed scenario is reproduced in a small Eden/VR setup.
- Per-vehicle or narrower config patches have been considered first.
- The proposed extension task is limited to diagnostics/tooling or has a documented engine API that can actually influence the missing behavior.
- The user approves a separate native-extension plan.

## Recommended Decision Tree

1. Finish SQA testing of the current `Car_F` / `Tank_F` config-class patch.
2. If tested vehicles do not inherit the patch, narrow or add class-specific config patches.
3. If tested vehicles inherit the patch but still do not roll, evaluate additional config candidates:
   - `brakeIdleSpeed`
   - `dampingRateZeroThrottleClutchEngaged`
   - `dampingRateZeroThrottleClutchDisengaged`
   - `class complexGearbox`
   - wheel brake and handbrake torque values
4. If config changes cannot solve the issue, decide whether the native extension would be:
   - diagnostic-only: acceptable as an optional research tool;
   - gameplay-control: reject unless an engine-accessible native control surface is documented.

## Minimal Extension Spike Shape

Only if explicitly approved later, the first spike should be deliberately non-gameplay:

- C++ native library source only.
- Exports:
  - `RVExtensionVersion`
  - `RVExtensionArgs`
- Supported calls:
  - `version`
  - `ping`
  - `schema`
- No vehicle control.
- No per-frame calls.
- No binary committed until the user approves build and distribution rules.
- SQF wrapper must be optional and disabled by default.

The spike is useful only to prove build, load, BattlEye, deployment, RPT logging, and `allExtensions` detection. It should not be sold as a physics fix.

## Current Recommendation

Native work has moved from research status to source scaffold status.

Current implemented state:

- Native source exists under `native/fixics_physics/`.
- No native binaries are committed.
- No native build tooling is integrated.
- `FIXICS_fnc_getNativeSlopeControl` provides an optional SQF bridge.
- `FIXICS_nativeSlopeControlEnabled` defaults to `false`.

Next decision:

- If the user approves binary work, write a separate build/deployment plan before compiling.
- If gameplay control remains the goal, keep Arma object mutation in SQF and let native code return control recommendations only.
