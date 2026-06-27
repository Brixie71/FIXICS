# FIXICS - Arma 3 Vehicle Physics Improvements

> Targeted, SQA-validated physics improvements for Arma 3 ground vehicles. No engine replacement, only better behavior within what the engine supports.

[![Steam Workshop](https://images.steamusercontent.com/ugc/16688676930552024864/18020FAE216B0F8B3E0A83CC09F17F01A1A2BE6B/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false)](https://steamcommunity.com/sharedfiles/filedetails/?id=3742055954)

![Phase](https://img.shields.io/badge/Phase%201-In%20Progress-orange)
![Arma 3](https://img.shields.io/badge/Arma%203-Required-blue)
![ACE3](https://img.shields.io/badge/ACE3-Required-red)
![CBA](https://img.shields.io/badge/CBA__A3-Required-red)
![License](https://img.shields.io/badge/License-APL--SA-green)

> **Published on Steam Workshop:** [FIXICS](https://steamcommunity.com/sharedfiles/filedetails/?id=3742055954)

---

## Overview

FIXICS is an Arma 3 addon focused on Phase 1 ground-vehicle physics behavior. It improves slope rolling, braking, direction changes, stability, rollover resistance, controlled sliding, terrain/tire behavior, weather-aware grip, and vehicle-specific tuning through bounded SQF systems and optional native advisory math.

All public functions use the `FIXICS_fnc_*` prefix. Runtime namespace keys use the `FIXICS_*` prefix. The PBO prefix is `x\fixics\addons\main`.

FIXICS is developed through an SQA-first workflow: requirements are captured before behavior changes, implementation is validated with static checks, and gameplay acceptance is performed by SQA in Arma.

---

## Roadmap

| Phase | Title | Status |
|---|---|---|
| 1 | Ground Vehicle Physics | In Progress |
| 2 | Human Limb Physics | Blocked by Phase 1 |
| 3 | Body Kit Attachments | Blocked by Phase 2 |
| 4 | Aircraft Physics | Blocked by Phase 3 |
| 5 | Ship and Boat Physics | Blocked by Phase 4 |
| 6 | Performance Improvements | Blocked by Phase 5 |
| 7 | Memory Improvements | Blocked by Phase 6 |

Only Phase 1 is active.

---

## Phase 1 - Ground Vehicle Physics

### Completed And Implemented Milestones

| Fix | Title | Status |
|---|---|---|
| FIX-001 | ACE handbrake and local slope rolling | SQA verified |
| FIX-002 | Direction-change neutral pulse | SQA verified |
| FIX-003 | ABS braking and driver-state controller | SQA verified |
| FIX-004 | Reverse-to-Drive input and model-space braking correction | SQA verified |
| FIX-005 | Native Driver Assist v2 advisory math | SQA verified |
| FIX-006 | Vehicle Stability Assistance | Implemented, initial lateral damping scope |
| FIX-007 | Roll Stability Assist and presets | Implemented, SQA aggressive tuning verified |
| FIX-008 | Sway Bar Assist | Implemented, front/rear approximation settings |
| FIX-009 | Runtime Assist Coordinator | Implemented |
| FIX-010 | Controlled Slip Assist | Implemented, pending broader SQA terrain matrix |
| FIX-011 | Terrain Tire Behavior | Implemented |
| FIX-012 | Per-Vehicle Settings | Implemented |
| FIX-013 | Terrain Tire Phase 2 safety | Implemented |
| FIX-014 | Native Terrain Tire advisory | Implemented, disabled by default |
| FIX-015 | Weather-Aware Terrain Tire Effects | Implemented |
| FIX-016 | Runtime Assist priority stack and ABS terrain feedback | Implemented |
| FIX-017 | Multiplayer Phase 1 compatibility slice | Implemented, pending dedicated 2+ player SQA validation |

### What Phase 1 Changes

**ACE/FIXICS handbrake**
Ground vehicles get a persistent ACE interaction handbrake. The FIXICS handbrake is explicit and persistent; normal service braking remains separate.

**Slope rolling**
Empty and coasting vehicles can roll on slopes when the FIXICS handbrake is released, instead of being held by Arma's stationary autobrake until the driver presses W or S.

**ABS braking**
A local service-brake path approximates smooth ABS-like braking. Brake strength, release bias, low-speed cutoff, and slope compensation are tunable through CBA settings.

**Direction transitions**
Opposite direction input no longer waits for the vehicle to fully coast to zero. Drive input can interrupt Reverse, and Reverse input can interrupt Drive, through a short controlled neutral handoff.

**Driver-state controller**
A fast CBA per-frame controller tracks Drive, Service Brake, Reverse, Coast, Neutral, and Handbrake states explicitly instead of relying only on implicit Arma behavior.

**Vehicle Stability Assistance**
Registered vehicle classes can use bounded yaw/lateral stability assistance through the local driver controller. The current release avoids broad config steering/tire patches and avoids direct forced orientation.

**Roll Stability Assist**
Registered vehicles can use a separate roll-stability layer that applies bounded model-space vertical damping when bank angle and roll rate exceed configured limits. Presets include Realistic Stable, Offroad Assist, Aggressive SQA, and Custom.

**Sway Bar Assist**
Front and rear sway bar settings feed the stability and roll systems as an approximation. This is not true per-axle suspension simulation; it is a bounded anti-roll tuning layer.

**Runtime Assist Coordinator**
Runtime Assist coordinates ABS, slope rolling, driver intent, Vehicle Stability, Roll Stability, Sway Bar, Controlled Slip, Terrain Tire data, mass modifiers, and optional native advisory values through one shared decision layer. It now resolves conflicts through an explicit priority stack: handbrake, rollover suppression, ABS braking, slope correction, Terrain Tire modifier, then wind lateral influence.

**Controlled Slip Assist**
Controlled Slip Assist lets registered light vehicles release grip in a bounded way during high-speed steering demand. The goal is controlled lateral scrub before rollover energy becomes too high, not ice-like sliding or forced grip.

**Terrain Tire Behavior**
Terrain Tire Behavior adds SQF-first recommendations for terrain grip, wheelspin, tire pressure, slow deflation, run-flat-style degraded mobility, drag penalty, steering penalty, and mass influence. It also reports wheel support state, rollover suppression, destroyed tire penalties, driverless decay, and mobility limiting for flipped, airborne, or damaged-wheel cases.

**Weather-Aware Terrain Tire Effects**
Weather-aware terrain behavior adds gradual rain saturation, drying, wet-surface grip loss, paved hydroplaning risk, wet dirt/grass degradation, wet sand compaction, and minimal crosswind handling influence. These effects feed Terrain Tire telemetry and conservative runtime assist paths.

**Per-Vehicle Settings**
Vehicle profiles can be assigned by exact classname or parent class. Exact vehicle profiles take priority over parent profiles, and vehicles with no profile continue using global defaults. ACE interaction can show the active FIXICS vehicle profile.

**Native Terrain Tire advisory**
The optional native extension now supports `terrainTireV2` advisory math for Terrain Tire calculations. SQF remains authoritative; the DLL only recommends values and the SQF layer validates and applies them. Native Terrain Tire is disabled by default and includes short advisory caching to reduce repeated extension calls.

**Telemetry diagnostics**
Vehicle handling telemetry can record inputs, velocity, position, heading, yaw rate, pitch, bank, pitch/bank rates, terrain normal, ground contact, wheel hitpoint proxy data, Runtime Assist state, Controlled Slip state, Terrain Tire state, weather grip state, active vehicle profile, and relevant FIXICS settings. A terminal dashboard is available for live RPT telemetry watching.

---

## Dependencies

| Mod | Required | Notes |
|---|---|---|
| [ACE3](https://github.com/acemod/ACE3) | Yes | Handbrake interaction and `ace_interact_menu` component |
| [CBA_A3](https://github.com/CBATeam/CBA_A3) | Yes | Per-frame handlers and addon settings |
| [HEMTT](https://github.com/BrettMayson/HEMTT) | Build only | Required to build from source |

---

## Install From Steam Workshop

1. Open the [FIXICS Workshop page](https://steamcommunity.com/sharedfiles/filedetails/?id=3742055954).
2. Select **Subscribe**.
3. Enable FIXICS, ACE3, and CBA_A3 in the Arma 3 Launcher.

---

## Building From Source

For development or local builds, build directly from the repository.

```powershell
# 1. Validate static checks and governance tests
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1

# 2. Check HEMTT config, SQF compilation, stringtable, and unit tests
powershell -ExecutionPolicy Bypass -File tools\check.ps1

# 3. Build a packaged addon artifact
powershell -ExecutionPolicy Bypass -File tools\build.ps1
```

Built output is written to `.hemttout/`. Do not edit this directory directly.

### Manual Test Launches

```powershell
# Launch VR test mission
powershell -ExecutionPolicy Bypass -File tools\launch-vr.ps1

# Launch Eden Editor
powershell -ExecutionPolicy Bypass -File tools\launch-eden.ps1
```

---

## Native Extension

`native/fixics_physics/` contains optional Windows x64 native extension source for `FIXICSPhysics_x64.dll`.

The native extension is advisory only. SQF remains the final mutation authority. Native code can recommend slope, braking, direction-transition, and Terrain Tire values, but it cannot intercept Arma input processing, replace Arma's hidden gearbox, or directly own vehicle physics.

Implemented native commands:

| Command | Purpose | Default |
|---|---|---|
| `slopeControl` | Slope rollback advisory math | Disabled |
| `driverAssist` | ABS and Drive/Reverse advisory math | Disabled |
| `terrainTireV2` | Terrain Tire advisory math | Disabled |

Native Terrain Tire advisory results are cached for a short bounded interval and invalidated by surface, speed, support, and damage buckets.

New native binaries or native authority changes require explicit SQA approval before deployment.

---

## Configuration

All FIXICS settings are available in-game under **Options -> Addon Options -> FIXICS**.

### Slope Rolling

| Setting | Default | Range | Unit |
|---|---:|---|---|
| `FIXICS_slopeRollbackMinimumSlope` | `0.035` | `0 - 0.2` | ratio |
| `FIXICS_slopeRollbackMaxSpeed` | `2.2` | `0.2 - 10` | m/s |
| `FIXICS_slopeRollbackAcceleration` | `0.55` | `0 - 2` | scalar |
| `FIXICS_slopeCoastBreakawayVelocity` | `0.18` | `0 - 1` | m/s |
| `FIXICS_slopeDriveAcceleration` | `0.22` | `0 - 1` | scalar |
| `FIXICS_slopeDriveMaxSpeedKmh` | `120` | `10 - 240` | km/h |
| `FIXICS_stationaryBrakeBypassSpeedKmh` | `1` | `0 - 5` | km/h |

### ABS Braking

| Setting | Default | Range | Unit |
|---|---:|---|---|
| `FIXICS_absEnabled` | `true` | checkbox | boolean |
| `FIXICS_absBrakeStrength` | `0.45` | `0.05 - 2` | scalar |
| `FIXICS_absReleaseBias` | `0.35` | `0 - 1` | scalar |
| `FIXICS_absLowSpeedCutoffKmh` | `3` | `0 - 20` | km/h |
| `FIXICS_absSlopeCompensation` | `0.25` | `0 - 1` | scalar |
| `FIXICS_absDebugLogging` | `false` | checkbox | boolean |

ABS now reads Terrain Tire braking grip, weather grip, and hydroplaning risk when calculating effective brake force.

### Driver-State Controller

| Setting | Default | Range | Unit |
|---|---:|---|---|
| `FIXICS_driverControllerEnabled` | `true` | checkbox | boolean |
| `FIXICS_handbrakeInputMode` | `0` | `0` Hold / `1` Toggle | mode |
| `FIXICS_directionChangeThresholdKmh` | `2` | setting controlled | km/h |
| `FIXICS_directionLaunchVelocity` | `0.35` | setting controlled | m/s |
| `FIXICS_directionNeutralPulseSeconds` | `0.08` | setting controlled | seconds |
| `FIXICS_driverControllerInterval` | `0.03` | setting controlled | seconds |

### Vehicle Stability Assistance

| Setting | Default | Notes |
|---|---|---|
| Vehicle Stability Assistance | Enabled | Server-global option for registered classes |
| Stability mode | Yaw + lateral damping | Modes include Yaw Damping, Yaw + Lateral Damping, and Countersteering |
| Stability preset | Realistic Stable | Presets support tuning without editing SQF |

### Roll Stability Assist

| Setting | Default | Notes |
|---|---|---|
| Roll Stability Assist | Enabled | Server-global option for registered vehicle classes |
| Roll Stability preset | Realistic Stable | Realistic Stable, Offroad Assist, Aggressive SQA, Custom |
| Activation bank | Preset controlled | Aggressive SQA preserves SQA max-tested values |
| Roll activation rate | Preset controlled | Higher values delay correction until stronger roll-rate evidence |
| Roll stability strength | Preset controlled | Bounded correction strength |
| Maximum roll correction | Preset controlled | Per-update correction cap |
| Roll airborne grace | Preset controlled | Short contact-loss continuity |

### Sway Bar Assist

| Setting | Default | Notes |
|---|---|---|
| `FIXICS_swayBarEnabled` | `true` | Global/server approximation layer |
| Front sway bar enabled | `true` | Feeds roll/stability calculations |
| Rear sway bar enabled | `true` | Feeds roll/stability calculations |
| Front sway bar strength | `0.50` | Range `0 - 1` |
| Rear sway bar strength | `0.50` | Range `0 - 1` |

### Controlled Slip Assist

| Setting | Default | Notes |
|---|---|---|
| `FIXICS_controlledSlipEnabled` | `true` | Enables bounded controlled lateral scrub |
| `FIXICS_controlledSlipActivationSpeedKmh` | `55` | Activation speed threshold |
| `FIXICS_controlledSlipSteeringThreshold` | `0.65` | Steering demand threshold |
| `FIXICS_controlledSlipStrength` | `0.16` | Conservative default strength |
| `FIXICS_controlledSlipMaximumRelease` | `0.22` | Maximum release cap |
| `FIXICS_controlledSlipTerrainInfluence` | `true` | Terrain-aware slip recommendations |
| `FIXICS_controlledSlipDebugLogging` | `false` | RPT debug logging |

### Terrain Tire Behavior

| Setting | Default | Notes |
|---|---|---|
| `FIXICS_terrainTireEnabled` | `true` | Enables Terrain Tire recommendations |
| `FIXICS_nativeTerrainTireEnabled` | `false` | Enables optional native Terrain Tire advisory |
| `FIXICS_tirePressureEnabled` | `true` | Enables slow tire deflation model |
| `FIXICS_tireDeflationRate` | `0.025` | Simulated pressure loss rate |
| `FIXICS_tireMinimumMobility` | `0.35` | Run-flat-style minimum mobility floor |
| `FIXICS_tireDragStrength` | `0.35` | Drag penalty from low tire pressure |
| `FIXICS_tireSteeringPenalty` | `0.30` | Steering precision loss from low pressure |
| `FIXICS_tireDebugLogging` | `false` | RPT debug logging |
| `FIXICS_rolloverSafetyEnabled` | `true` | Suppresses drive/traction assist when flipped, airborne, or side unsupported |
| `FIXICS_airborneGraceWindow` | `0.50` | Short grace window after bumps/jumps |
| `FIXICS_driverlessDecayEnabled` | `true` | Gently decays abandoned vehicle residual motion |
| `FIXICS_driverlessDecayCap` | `0.15` | Gentle driverless deceleration cap |
| `FIXICS_destroyedTireThreshold` | `0.85` | Destroyed tire detection threshold |
| `FIXICS_destroyedTireDebugLogging` | `false` | Destroyed tire debug logging |

### Weather-Aware Terrain Tire Effects

| Setting | Default | Notes |
|---|---|---|
| `FIXICS_weatherTerrainEnabled` | `true` | Enables weather-aware terrain grip effects |
| `FIXICS_weatherSaturationTime` | `30` | Rain saturation time in seconds |
| `FIXICS_weatherDryingTime` | `180` | Drying time in seconds after rain stops |
| `FIXICS_hydroplaningEnabled` | `true` | Enables paved wet-road hydroplaning risk |
| `FIXICS_hydroplaningSpeedKmh` | `70` | Hydroplaning starts becoming relevant above this speed |
| `FIXICS_windHandlingEnabled` | `true` | Enables minimal crosswind lateral influence |
| `FIXICS_windHandlingStrength` | `0.05` | Conservative wind influence strength |
| `FIXICS_weatherDebugLogging` | `false` | Weather terrain RPT debug logging |

### Per-Vehicle Profiles

| Setting | Purpose |
|---|---|
| Exact vehicle profile text | Applies overrides to exact classnames first |
| Parent vehicle profile text | Applies overrides to parent classes when exact class is not set |
| Presets | `DEFAULT`, `LIGHT_OFFROAD`, `MRAP`, `TRUCK`, `TRACKED`, `CUSTOM` |

Profile diagnostics:

```sqf
[vehicle player, true] call FIXICS_fnc_dumpVehicleProfile;
[] call FIXICS_fnc_dumpVehicleClasses;
```

---

### Multiplayer

| Setting | Default | Notes |
|---|---|---|
| `FIXICS_multiplayerCompatibilityEnabled` | `true` | Enables the Phase 1 MP authority/sync slice |

Multiplayer rules:

- Existing physics mutations run only where the vehicle is local.
- ACE handbrake interaction is driver-only in multiplayer.
- Handbrake state is globally synchronized.
- Per-vehicle profile state can be shared for JIP/profile viewing.
- Native DLL advisory calls are disabled on dedicated server instances.
- This slice adds authority and sync safeguards only; it does not add new multiplayer physics behavior.

---

## Diagnostics And SQA Telemetry

Run a one-shot or continuous vehicle handling dump from the Arma debug console while in a vehicle:

```sqf
[vehicle player, 180, 0.1] call FIXICS_fnc_logVehicleHandlingConfig;
```

Enable Terrain Tire debug logging:

```sqf
missionNamespace setVariable ["FIXICS_tireDebugLogging", true, false];
systemChat str (missionNamespace getVariable ["FIXICS_tireDebugLogging", false]);
```

Terrain Tire telemetry includes:

- surface type
- terrain grip class
- traction multiplier
- acceleration, braking, turning, and slope traction multipliers
- wheelspin estimate
- tire-air state
- tire deflation state
- tire drag penalty
- tire steering penalty
- mass modifier
- per-wheel/fallback mode
- wheel support state
- rollover suppression state
- driverless decay
- destroyed tire count and penalty
- mobility limiter
- rain, overcast, wetness, saturation, weather grip, hydroplaning, and wind fields

Live terminal dashboard:

```powershell
python tools\live-vehicle-telemetry.py
```

---

## Known Limitations

Phase 1 multiplayer support is authority/sync focused. Existing gameplay corrections still run only where the vehicle is local; full server-authoritative physics remains deferred.

| Limit | Reference | Impact |
|---|---|---|
| No documented direct gearbox state setter | EL-001 | Direction transitions are SQF approximations |
| No documented runtime per-wheel friction setter | EL-002 | Terrain/tire behavior uses recommendations and bounded velocity-path effects, not real tire friction mutation |
| No documented vehicle collision restitution setter | EL-003 | Abnormal bounce fixes need event-driven velocity clamps |
| Suspension config is not a normal runtime SQF control surface | EL-004 | Suspension and anti-roll behavior remain approximations unless config research is approved |

Current Terrain Tire boundary:

- Active correction paths are conservative and bounded.
- ABS now consumes Terrain Tire braking/weather feedback.
- Broad tire/friction config patches remain deferred until SQA telemetry proves they are needed.
- Deep wet/mud/stuck behavior remains deferred until Arma surface data and SQA evidence justify it.

Full engine limit records: [`docs/reference/known-engine-limits.md`](docs/reference/known-engine-limits.md)
Active workarounds: [`docs/fixes/workaround-registry.md`](docs/fixes/workaround-registry.md)

---

## Functions

| Function | Purpose |
|---|---|
| `FIXICS_fnc_init` | Post-init entry point |
| `FIXICS_fnc_hello` | Basic diagnostic function |
| `FIXICS_fnc_vrHello` | VR/manual test diagnostic function |
| `FIXICS_fnc_registerSettings` | Registers CBA addon settings |
| `FIXICS_fnc_registerAceInteractions` | Registers ACE handbrake vehicle actions |
| `FIXICS_fnc_registerVehicleControls` | Installs CBA per-frame driver controller |
| `FIXICS_fnc_isVehicleLocal` | Pure helper for vehicle locality authority |
| `FIXICS_fnc_monitorVehicleAutobrake` | Local scheduled monitor for non-player vehicles |
| `FIXICS_fnc_updateDriverController` | Fast per-frame driver-state update |
| `FIXICS_fnc_setVehicleHandbrake` | Sets or clears `FIXICS_handbrakeEnabled` |
| `FIXICS_fnc_shouldVehicleRoll` | Pure decision helper for slope-roll state rules |
| `FIXICS_fnc_applySlopeRollback` | Applies capped downhill velocity correction |
| `FIXICS_fnc_applyHandbrakeLock` | Enforces persistent ACE/FIXICS handbrake lock |
| `FIXICS_fnc_applyABSBraking` | Applies ABS-like longitudinal braking correction |
| `FIXICS_fnc_getDriverInputIntent` | Reads and normalizes current driver input state |
| `FIXICS_fnc_getNativeSlopeControl` | Reads optional native slope-control advisory output |
| `FIXICS_fnc_getNativeDriverAssist` | Reads optional native driver-assist advisory output |
| `FIXICS_fnc_getNativeTerrainTire` | Reads optional native Terrain Tire advisory output |
| `FIXICS_fnc_getVehicleProfile` | Resolves exact/parent/global per-vehicle profile data |
| `FIXICS_fnc_dumpVehicleProfile` | Dumps active vehicle profile diagnostics |
| `FIXICS_fnc_dumpVehicleClasses` | Dumps available vehicle class information for profile authoring |
| `FIXICS_fnc_getVehicleStabilityProfile` | Resolves registered vehicle stability profile data |
| `FIXICS_fnc_getStabilityRecommendation` | Calculates stability recommendation data |
| `FIXICS_fnc_getRollStabilityRecommendation` | Calculates roll-stability recommendation data |
| `FIXICS_fnc_getRuntimeAssistRecommendation` | Calculates Runtime Assist coordination output |
| `FIXICS_fnc_coordinateVehicleAssists` | Coordinates assist recommendations and priorities |
| `FIXICS_fnc_getControlledSlipRecommendation` | Calculates Controlled Slip recommendation data |
| `FIXICS_fnc_getTerrainTireRecommendation` | Calculates Terrain Tire recommendation data |
| `FIXICS_fnc_applyVehicleStability` | Applies bounded local vehicle stability corrections |
| `FIXICS_fnc_startSteeringDiagnostics` | Starts bounded steering diagnostic sampling |
| `FIXICS_fnc_logVehicleHandlingConfig` | Records vehicle handling and telemetry diagnostics |

---

## Repository Structure

```text
addons/
  main/
    config.cpp              # patch dependencies and CfgFunctions
    functions/              # one fn_name.sqf per function
    missions/               # manual test missions
    stringtable.xml
agents/                     # task-specific Codex role overlays
docs/
  fixes/
    fix-log.md
    open-issues.md
    workaround-registry.md
  reference/
    known-engine-limits.md
    physx-command-ref.md
    vehicle-config-ref.md
  requirements/
  superpowers/
  vehicle-behavior/
governance/
  policies/
    coding-standards.md
    scope-control.md
    phase-control.md
  audit/
    validation-log.md
native/
  fixics_physics/           # optional Windows x64 extension source
orchestration/              # Codex routing and state
prompts/                    # Codex prompt templates
tests/
  integration/              # static governance and physics tests
  unit/                     # recommendation and mutation tests
tools/
  check.ps1
  build.ps1
  build-native.ps1
  launch-vr.ps1
  launch-eden.ps1
.hemtt/                     # HEMTT build config
.hemttout/                  # generated build output, do not edit
AGENTS.md                   # repository facts and mandatory commands
CODEX.md                    # workflow and approval gates
SQF-Syntax.md
```

---

## Validation

Current automated validation commands:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
powershell -ExecutionPolicy Bypass -File tools\check.ps1
git diff --check
```

Recent validation covered:

- governance static checks
- vehicle physics static checks
- HEMTT SQF compile checks
- stability recommendation tests
- roll stability recommendation tests
- runtime assist recommendation tests
- controlled slip recommendation tests
- Terrain Tire recommendation tests
- mutation checks for stability behavior

Manual Arma gameplay validation remains SQA-owned.

---

## Changelog

### 2026-06-27 - Expanded Vehicle Physics Systems

Added:

- Per-vehicle profile support by exact classname and parent class.
- ACE read-only profile viewing.
- Vehicle class/profile dump diagnostics.
- Terrain Tire Phase 2 safety fields for wheel support, rollover suppression, destroyed tires, driverless decay, and mobility limiting.
- Optional native `terrainTireV2` advisory command in `FIXICSPhysics_x64.dll`.
- Native Terrain Tire SQF bridge with validation and short advisory caching.
- Weather-aware terrain tire behavior with rain saturation, drying, wet grip, hydroplaning risk, wet sand compaction, and minimal wind handling influence.
- Live terminal telemetry dashboard at `tools/live-vehicle-telemetry.py`.
- Runtime Assist priority stack for deterministic assist conflict resolution.
- ABS feedback path from Terrain Tire braking/weather/hydroplaning values.
- SQA profile text artifacts for class-family tuning.
- Multiplayer Phase 1 authority helper and global compatibility setting.

Changed:

- Runtime Assist now resolves conflicts in this order: handbrake, rollover suppression, ABS braking, slope correction, Terrain Tire modifier, wind lateral.
- ABS braking is now terrain/weather-aware and records Terrain Tire ABS feedback telemetry.
- Terrain Tire telemetry now includes weather, wheel support, destroyed tire, and mobility limiter fields.
- Native extension documentation and tests now include Terrain Tire advisory behavior.
- Existing mutation paths now route locality authority through `FIXICS_fnc_isVehicleLocal`.
- Native advisory calls are suppressed on dedicated server instances.

Validation:

- Governance static checks passed.
- Vehicle physics static checks passed.
- HEMTT/check wrapper passed.
- Runtime Assist, Controlled Slip, Stability, Roll Stability, and Terrain Tire recommendation tests passed.
- Dedicated server 2+ player SQA validation remains required for MP acceptance.

### Steam Workshop Update Template

```text
[h1]FIXICS Vehicle Physics Update[/h1]

[b]This update expands Phase 1 ground vehicle physics with per-vehicle tuning, terrain tire behavior, weather-aware grip, native advisory support, and improved assist coordination.[/b]

[h1]Highlights[/h1]
[list]
[*] Added per-vehicle FIXICS profiles by exact classname and parent class.
[*] Added Terrain Tire Phase 2 safety for rollover, airborne, side-supported, destroyed tire, and driverless vehicle cases.
[*] Added weather-aware terrain tire effects: wet grip, rain saturation, drying, hydroplaning risk, wet sand compaction, and minimal wind influence.
[*] Added optional native Terrain Tire advisory support through FIXICSPhysics_x64.dll.
[*] Added deterministic Runtime Assist priority handling so ABS, slope rolling, rollover suppression, Terrain Tire, and wind no longer fight unpredictably.
[*] ABS now reads Terrain Tire braking grip, weather grip, and hydroplaning risk.
[*] Added live telemetry dashboard tooling for SQA testing.
[/list]

[h1]Gameplay Notes[/h1]
[list]
[*] Light vehicles should retain the accepted rally-like controlled handling feel.
[*] Heavy vehicles and MRAPs now have better profile separation and terrain-aware braking data.
[*] Flipped, airborne, side-supported, or heavily wheel-damaged vehicles receive reduced FIXICS drive/traction assistance.
[*] Wet paved roads can now produce hydroplaning risk at speed.
[*] Loose terrain, damaged tires, weather, and mass now provide richer telemetry for future tuning.
[/list]

[h1]Admin / SQA Notes[/h1]
[list]
[*] ACE3 and CBA_A3 remain required.
[*] Native Terrain Tire advisory is optional and disabled by default.
[*] Per-vehicle profiles fall back to global defaults when no exact or parent profile exists.
[*] Terrain Tire and weather behavior are still bounded SQF-first systems, not full engine replacement.
[/list]

[h1]Validation[/h1]
[list]
[*] Governance static checks passed.
[*] Vehicle physics static checks passed.
[*] HEMTT/check wrapper passed.
[*] Stability, Roll Stability, Runtime Assist, Controlled Slip, and Terrain Tire recommendation tests passed.
[/list]

[h1]Known Limits[/h1]
[list]
[*] Arma 3 still does not expose a direct hidden gearbox override.
[*] Per-wheel friction is not directly controlled at runtime.
[*] Full server-authoritative multiplayer physics remains deferred; this update adds locality-safe Phase 1 compatibility only.
[*] Broad tire/friction config patches remain deferred until SQA evidence proves they are needed.
[/list]

[h1]GitHub[/h1]
https://github.com/Brixie71/FIXICS
```

---

## Contributing

FIXICS follows a strict phase-gated development process. All behavior changes require SQA approval before implementation. Read these in order before contributing:

1. [`AGENTS.md`](AGENTS.md)
2. [`CODEX.md`](CODEX.md)
3. [`governance/policies/coding-standards.md`](governance/policies/coding-standards.md)
4. [`governance/policies/scope-control.md`](governance/policies/scope-control.md)

Editing rules:

- Keep `CfgFunctions` synchronized with `fn_*.sqf` files.
- Use four-space indentation.
- Do not edit `.hemttout/`, packed PBOs, reports, logs, or private keys.
- Do not introduce new native binaries, multiplayer authority, or broad `CfgVehicles` patches without explicit SQA approval.

SQA is the final authority for product behavior and acceptance.

---

## Reporting Issues

Please include:

- unexpected behavior
- steps to reproduce
- vehicle class
- terrain or surface type
- speed range
- CBA addon settings values
- whether ACE handbrake, ABS, Stability, Roll Stability, Controlled Slip, or Terrain Tire settings were enabled
- telemetry log path if available

---

## License

FIXICS is released under the [Arma Public License Share Alike (APL-SA)](https://www.bohemia.net/community/licenses/arma-public-license-share-alike).
