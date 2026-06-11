# FIXICS — Arma 3 Vehicle Physics Improvements

> Targeted, SQA-validated physics improvements for Arma 3 ground vehicles. No engine replacement — just better behavior within what the engine supports.

[![Steam Workshop](https://images.steamusercontent.com/ugc/16688676930552024864/18020FAE216B0F8B3E0A83CC09F17F01A1A2BE6B/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false)](https://steamcommunity.com/sharedfiles/filedetails/?id=3742055954)

![Phase](https://img.shields.io/badge/Phase%201-In%20Progress-orange)
![Arma 3](https://img.shields.io/badge/Arma%203-Required-blue)
![ACE3](https://img.shields.io/badge/ACE3-Required-red)
![CBA](https://img.shields.io/badge/CBA__A3-Required-red)
![License](https://img.shields.io/badge/License-APL--SA-green)

> **Published on Steam Workshop:** [FIXICS](https://steamcommunity.com/sharedfiles/filedetails/?id=3742055954)

---

## Overview

FIXICS collaborates with SQA to research, design, implement, and validate Arma 3 physics improvements phase by phase. Every behavior change is approved before implementation, regression risk is tracked, and each phase is gated by SQA sign-off before the next begins.

All public functions use the `FIXICS_fnc_*` prefix. All runtime namespace keys use the `FIXICS_*` prefix. The PBO prefix is `x\fixics\addons\main`.

---

## Roadmap

| Phase | Title | Status |
|---|---|---|
| 1 | Ground Vehicle Physics | 🟡 In Progress |
| 2 | Human Limb Physics | 🔒 Blocked by Phase 1 |
| 3 | Body Kit Attachments | 🔒 Blocked by Phase 2 |
| 4 | Aircraft Physics | 🔒 Blocked by Phase 3 |
| 5 | Ship and Boat Physics | 🔒 Blocked by Phase 4 |
| 6 | Performance Improvements | 🔒 Blocked by Phase 5 |
| 7 | Memory Improvements | 🔒 Blocked by Phase 6 |

---

## Phase 1 — Ground Vehicle Physics

### Completed milestones

| Fix | Title | Status |
|---|---|---|
| FIX-001 | ACE handbrake and local slope rolling | ✅ SQA verified |
| FIX-002 | Direction-change neutral pulse | ✅ SQA verified |
| FIX-003 | ABS braking and driver-state controller | ✅ SQA verified |
| FIX-004 | Reverse-to-Drive input and model-space braking correction | ✅ SQA verified |
| FIX-005 | Native Driver Assist v2 | ✅ SQA verified |

### What Phase 1 changes

**Slope rolling**
Empty and coasting vehicles now roll on slopes when the ACE handbrake is released, instead of being held by Arma's engine brake until the driver presses W or S.

**ABS braking**
A local service-brake path approximates ABS behavior. Brake strength, release bias, low-speed cutoff, and slope compensation are all tunable through CBA addon settings.

**Direction transitions**
Opposite direction input no longer waits for the vehicle to fully coast to zero. Drive input interrupts a Reverse run with a short controlled delay, matching the feel of a real vehicle gearbox handoff.

**Driver-state controller**
A fast per-frame CBA controller replaces slow implicit player-driving behavior with explicit Drive, Service Brake, Reverse, Coast, and Handbrake states.

---

## Dependencies

| Mod | Required | Notes |
|---|---|---|
| [ACE3](https://github.com/acemod/ACE3) | ✅ Yes | Handbrake interaction, `ace_interact_menu` component |
| [CBA_A3](https://github.com/CBATeam/CBA_A3) | ✅ Yes | Per-frame handler, addon settings |
| [HEMTT](https://github.com/BrettMayson/HEMTT) | 🔧 Build only | Required to build from source |

---

## Install From Steam Workshop

1. Open the [FIXICS Workshop page](https://steamcommunity.com/sharedfiles/filedetails/?id=3742055954).
2. Select **Subscribe**.
3. Enable FIXICS, ACE3, and CBA_A3 in the Arma 3 Launcher.

---

## Building from Source

For development or local builds, build directly from the repository.

```powershell
# 1. Validate static checks and governance tests
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1

# 2. Check HEMTT config, SQF compilation, and stringtable
powershell -ExecutionPolicy Bypass -File tools\check.ps1

# 3. Build a packaged addon artifact
powershell -ExecutionPolicy Bypass -File tools\build.ps1
```

Built output is written to `.hemttout/`. Do not edit this directory directly.

### Manual test launches

```powershell
# Launch VR test mission
powershell -ExecutionPolicy Bypass -File tools\launch-vr.ps1

# Launch Eden Editor
powershell -ExecutionPolicy Bypass -File tools\launch-eden.ps1
```

---

## Native Extension

`native/fixics_physics/` contains the source for the optional Windows x64 `FIXICSPhysics 0.2.0` extension (`FIXICSPhysics_x64.dll`). The extension is built and tested with `tools/build-native.ps1`.

> **Status:** The native extension is present in the repository root but release packaging is not yet approved. It provides advisory calculations for slope control, ABS service-brake targets, and post-neutral Drive/Reverse launch transitions. SQF validates every recommendation and remains the final vehicle-mutation authority. The extension cannot intercept Arma input processing or directly replace its gearbox.

New native binaries require explicit SQA approval before deployment.

---

## Configuration

All FIXICS settings are available in-game under **Options → Addon Options → FIXICS** with no mission restart required.

### Slope rolling

| Setting | Default | Range | Unit |
|---|---|---|---|
| `FIXICS_slopeRollbackMinimumSlope` | `0.035` | `0 – 0.2` | — |
| `FIXICS_slopeRollbackMaxSpeed` | `2.2` | `0.2 – 10` | m/s |
| `FIXICS_slopeRollbackAcceleration` | `0.55` | `0 – 2` | — |
| `FIXICS_slopeCoastBreakawayVelocity` | `0.18` | `0 – 1` | m/s |
| `FIXICS_slopeDriveAcceleration` | `0.22` | `0 – 1` | — |
| `FIXICS_slopeDriveMaxSpeedKmh` | `120` | `10 – 240` | km/h |
| `FIXICS_stationaryBrakeBypassSpeedKmh` | `1` | `0 – 5` | km/h |

### ABS braking

| Setting | Default | Range | Unit |
|---|---|---|---|
| `FIXICS_absEnabled` | `true` | — | checkbox |
| `FIXICS_absBrakeStrength` | `0.45` | `0.05 – 2` | — |
| `FIXICS_absReleaseBias` | `0.35` | `0 – 1` | — |
| `FIXICS_absLowSpeedCutoffKmh` | `3` | `0 – 20` | km/h |
| `FIXICS_absSlopeCompensation` | `0.25` | `0 – 1` | — |
| `FIXICS_absDebugLogging` | `false` | — | checkbox |

### Driver-state controller

| Setting | Default | Range | Unit |
|---|---|---|---|
| `FIXICS_driverControllerEnabled` | `true` | — | checkbox |
| `FIXICS_handbrakeInputMode` | `0` (Hold) | `0` Hold / `1` Toggle | — |
| `FIXICS_directionChangeThresholdKmh` | `2` | — | km/h |
| `FIXICS_directionLaunchVelocity` | `0.35` | — | m/s |
| `FIXICS_directionNeutralPulseSeconds` | `0.08` | — | seconds |
| `FIXICS_driverControllerInterval` | `0.03` | — | seconds |

---

## Known Limitations

All Phase 1 corrections are **local-only**. Multiplayer authority and server deployment are deferred.

| Limit | Reference | Impact |
|---|---|---|
| No documented direct gearbox state setter | EL-001 | Direction transitions are SQF approximations |
| No documented runtime per-wheel friction setter | EL-002 | Slope and ABS behavior uses velocity correction, not tire physics |
| No documented vehicle collision restitution setter | EL-003 | Abnormal bounce fixes need event-driven velocity clamps |
| Suspension config is not a runtime SQF control surface | EL-004 | Bounce/bottoming corrections start as config-class research |

Full engine limit records: [`docs/reference/known-engine-limits.md`](docs/reference/known-engine-limits.md)
Active workarounds: [`docs/fixes/workaround-registry.md`](docs/fixes/workaround-registry.md)

---

## Functions

| Function | Purpose |
|---|---|
| `FIXICS_fnc_init` | Post-init entry point |
| `FIXICS_fnc_registerSettings` | Registers all CBA addon settings |
| `FIXICS_fnc_registerAceInteractions` | Registers ACE handbrake vehicle actions |
| `FIXICS_fnc_registerVehicleControls` | Installs CBA per-frame driver controller |
| `FIXICS_fnc_monitorVehicleAutobrake` | Local scheduled monitor for non-player vehicles |
| `FIXICS_fnc_updateDriverController` | Fast per-frame driver-state update |
| `FIXICS_fnc_setVehicleHandbrake` | Sets or clears `FIXICS_handbrakeEnabled` |
| `FIXICS_fnc_shouldVehicleRoll` | Pure decision helper for slope-roll state rules |
| `FIXICS_fnc_applySlopeRollback` | Applies capped downhill velocity correction |
| `FIXICS_fnc_applyHandbrakeLock` | Enforces persistent ACE handbrake lock |
| `FIXICS_fnc_applyABSBraking` | Applies ABS-like longitudinal braking correction |
| `FIXICS_fnc_getDriverInputIntent` | Reads and normalises current driver input state |

---

## Repository Structure

```
addons/
  main/
    config.cpp              ← patch dependencies and CfgFunctions
    functions/              ← one fn_name.sqf per function
    missions/               ← manual test missions
    stringtable.xml
agents/                     ← task-specific Codex role overlays
docs/
  fixes/
    fix-log.md
    open-issues.md
    workaround-registry.md
  reference/
    known-engine-limits.md
    physx-command-ref.md
    vehicle-config-ref.md
evals/                      ← automated evaluation scripts
governance/
  policies/
    coding-standards.md
    scope-control.md
    phase-control.md
  audit/
    validation-log.md
native/
  fixics_physics/           ← optional Windows x64 extension source
orchestration/              ← Codex routing data
prompts/                    ← Codex prompt templates
tests/
  integration/              ← static governance and physics tests
tools/
  check.ps1
  build.ps1
  build-native.ps1
  launch-vr.ps1
  launch-eden.ps1
.hemtt/                     ← HEMTT build config
.hemttout/                  ← generated build output (do not edit)
AGENTS.md                   ← repository facts and mandatory commands
CODEX.md                    ← workflow and approval gates
FIXICSPhysics_x64.dll       ← built native extension (not yet release-packaged)
build.ps1                   ← root build entry point
meta.cpp
mod.cpp
SQF-Syntax.md
```

---

## Contributing

FIXICS follows a strict phase-gated development process. All behavior changes require SQA approval before implementation. Read these in order before contributing:

1. [`AGENTS.md`](AGENTS.md) — repository facts and mandatory commands
2. [`CODEX.md`](CODEX.md) — workflow and approval gates
3. [`governance/policies/coding-standards.md`](governance/policies/coding-standards.md)
4. [`governance/policies/scope-control.md`](governance/policies/scope-control.md)

**Editing rules:**
- Keep `CfgFunctions` synchronized with `fn_*.sqf` files
- Use four-space indentation
- Do not edit `.hemttout/`, packed PBOs, reports, logs, or private keys
- Do not introduce new native binaries, multiplayer authority, or broad `CfgVehicles` patches without explicit SQA approval

**SQA is the final authority for product behavior and acceptance.**

---

## Reporting Issues

Please include:

- A description of the unexpected behavior
- Steps to reproduce (vehicle type, terrain, conditions)
- Whether the issue occurs in singleplayer, multiplayer, or both
- Your CBA addon settings values if ABS or slope rolling is involved

---

## License

FIXICS is released under the [Arma Public License Share Alike (APL-SA)](https://www.bohemia.net/community/licenses/arma-public-license-share-alike).
EOF
echo "done"
Done
