# Project State

## Stable Facts

- Project name: FIXICS.
- Type: Arma 3 addon.
- Build tool: HEMTT.
- Addon source: `addons/main/`.
- Function tag: `FIXICS`.
- PBO prefix: `x\fixics\addons\main`.
- Required runtime dependencies: ACE3 interaction menu and CBA.
- Native extension boundary: optional Windows x64 `FIXICSPhysics_x64.dll`, approved only under `FIXICS-EXC-2026-06-07-VEHICLE-PHYSICS-BEYOND-SQF`.

## Current Phase

Phase 1, Ground Vehicle Physics, is In Progress.

Current Phase 1 systems:

- ACE/FIXICS persistent handbrake.
- Local idle autobrake bypass and slope rolling.
- Local player driver controller.
- ABS-like service braking.
- Reverse/Drive neutral handoff.
- Optional native slope-control bridge, disabled by default.
- Optional Native Driver Assist v2 advisory math for ABS and direction transitions, disabled by default.
- Vehicle Stability Assistance for the approved `EMP_Polaris_DAGOR`, `B_LSV_01_unarmed_F`, `LOP_IA_Offroad`, and `B_G_Offroad_01_F` classes, applying bounded lateral damping only through the local driver controller.
- Roll Stability Assist, server-global and enabled by default, applying bounded model-space vertical damping for registered vehicles and awaiting SQA manual validation on registered LSV/Offroad classes.
- Sway Bar Assist, server-global and enabled by default, exposes front and rear enabled/strength settings that scale Roll Stability Assist and yaw/lateral stability assistance as an approximation, not true per-axle suspension simulation.
- Roll Stability presets are available as Realistic Stable, Offroad Assist, Aggressive SQA, and Custom; Aggressive SQA preserves SQA's max-tested rollover-assist values.
- Runtime Assist Coordinator, local-player only, coordinating ABS, slope rollback, driver intent, Vehicle Stability Assistance, Roll Stability Assist, terrain, mass, per-system presets, and native advisory telemetry.
- Terrain Tire Behavior, server-global enabled and local-player applied, adding SQF-first terrain, traction, wheelspin, tire-pressure, deflation, drag, steering-penalty, and mass recommendations for registered FIXICS vehicles through Runtime Assist and telemetry.
- Per-Vehicle Settings, server-global CBA text configured and local-player applied, resolving optional exact-class and parent-class profiles for currently registered FIXICS vehicles while preserving global defaults when no profile matches.

## Last Decision

- Native Driver Assist v2 was accepted by SQA on 2026-06-12 after high-speed braking and moderate-turn testing.
- ISSUE-001 steering research is complete and a bounded continuous diagnostic sampler is implemented.
- SQA must run `FIXICS_fnc_startSteeringDiagnostics` for keyboard and analog high-speed sharp turns before steering coefficients are changed.
- Vehicle Stability Assistance implementation was approved by SQA for `EMP_Polaris_DAGOR`.
- The first release boundary is bounded lateral damping only; direct yaw/countersteering mutation and passive config changes remain pending SQA evidence.
- ISSUE-001 remains open until SQA completes the manual `EMP_Polaris_DAGOR` matrix across 30, 60, 90, and 120 km/h on paved, dirt, and grass surfaces.
- Roll Stability Assist was implemented as a separate vertical model-space damping layer after SQA telemetry showed mode 2 reduced yaw/pitch but did not prevent rollovers.
- Vehicle handling telemetry was expanded on 2026-06-20 through `FIXICS_fnc_logVehicleHandlingConfig` to capture drive/reverse/brake inputs, world/model velocity, world/ASL position, heading/yaw rate, pitch/bank/rates, vectors, terrain normal, ground contact, wheel hitpoint damage proxy data, and relevant FIXICS state values.
- Stability compatibility was expanded on 2026-06-20 to include `B_LSV_01_unarmed_F` after SQA telemetry showed the controller was exiting unsupported for that vanilla LSV.
- Stability compatibility was expanded on 2026-06-20 to include exact Offroad classes `LOP_IA_Offroad` and `B_G_Offroad_01_F` after SQA telemetry showed those classes were used for rollover validation.
- Roll Stability preset selection was added on 2026-06-20 after SQA confirmed maxed settings improved rollover assist on the LSV/buggy test case.
- Vehicle Behavior Evidence Registry architecture was approved on 2026-06-20. The first implementation is read-only documentation and static validation; Runtime Assist coordination and Config Research remain future designs.
- Documentation cleanup/alignment was approved on 2026-06-20 to bring README, fix memory, workaround records, open issues, validation notes, and project state into sync with the implemented Phase 1 vehicle systems.
- Future feature workflow was updated on 2026-06-21: all future features use a Requirements Packet, SQA questions are gathered up front, implementation proceeds autonomously after SQA approval, and completed gameplay work is handed back to SQA for QA comments and repeat-cycle fixes.
- Runtime Assist Coordination requirements were captured on 2026-06-21. SQA approved a new local-player coordination layer where ABS, slope rollback, driver intent, Vehicle Stability Assistance, Roll Stability Assist, terrain effects, per-system presets, and native advisory math communicate through one layer before implementation. Next gate is SQA review of `docs/requirements/runtime-assist-coordination-requirements.md`, then a design spec and implementation plan before any gameplay source changes.
- Runtime Assist Coordination design was drafted on 2026-06-21 in `docs/superpowers/specs/2026-06-21-runtime-assist-coordination-design.md`. The spec keeps the feature local-player only, preserves accepted ABS/handbrake/Drive-Reverse behavior, prioritizes roll and stability before braking/slope composition, keeps native advisory non-authoritative, and requires SQA review before implementation planning.
- Runtime Assist Coordination implementation plan was drafted on 2026-06-21 in `docs/superpowers/plans/2026-06-21-runtime-assist-coordination.md`. The next gate is SQA execution choice: subagent-driven implementation or inline execution.
- Runtime Assist Coordinator implementation was added on 2026-06-21 after SQA approved the requirements packet and design spec. It preserves accepted ABS, ACE handbrake, Drive/Reverse, slope rollback, Vehicle Stability, and Roll Stability behavior while adding explicit telemetry and conservative coordination modifiers.
- Runtime Assist compact telemetry was added on 2026-06-21 after SQA DAGOR/tarmac logs showed long handling sample lines could truncate before final Runtime Assist fields.
- Roll Stability recommendation now reports an explicit telemetry reason and uses a bounded `severity-anchor` correction when roll severity exists but vertical-speed damping would otherwise produce a zero correction. SQA manual gameplay validation is still required.
- Roll Stability eligibility telemetry version 2 was added on 2026-06-21. SQA telemetry then proved roll was enabled, eligible, and evaluated under `AGGRESSIVE_SQA`, but correction telemetry remained stale because `_rollRecommendation params [` did not update the outer variables used by the stability log. The controller now extracts recommendation fields explicitly.
- SQA telemetry on 2026-06-21 proved Roll Stability Assist correction is active under `AGGRESSIVE_SQA`. SQA then approved adding a Sway Bar Assist enable/disable setting as a separate anti-roll gate for Roll Stability Assist only.
- SQA approved front and rear Sway Bar settings on 2026-06-21. The accepted boundary is a global/server setting approximation that feeds Roll Stability Assist and yaw/lateral stability damping through a combined multiplier, with telemetry version 3 exposing front/rear values.
- Controlled Slip Assist requirements were captured on 2026-06-22 in `docs/requirements/controlled-slip-assist-requirements.md`. SQA approved the car-first direction: use real tire behavior and GTA IV / Driver 3 / WRC as feel references, implement first through SQF against Arma exposed behavior, and defer tire/friction config patches until evidence supports a separate config plan.
- Controlled Slip Assist design was drafted on 2026-06-22 in `docs/superpowers/specs/2026-06-22-controlled-slip-assist-design.md`. The spec keeps the feature car/light-vehicle first, SQF-first, local-player only, telemetry-heavy, and explicitly avoids broad tire/friction config patches or forced upright behavior.
- Controlled Slip Assist implementation was added on 2026-06-22 after SQA approved the requirements, design, and implementation plan. It adds a pure recommendation function, conservative CBA settings, local stability-path integration, Runtime Assist propagation, and telemetry fields for SQA evidence.
- Terrain Tire Behavior requirements and design were approved by SQA on 2026-06-26. Implementation was added on 2026-06-27 after SQA chose subagent-driven execution. The feature adds `FIXICS_fnc_getTerrainTireRecommendation`, CBA settings for Terrain Tire and tire pressure behavior, Runtime Assist propagation, bounded non-amplifying stability-path multipliers, local tire-air state persistence, debug logging, compact Terrain Tire telemetry, and SQA evidence matrix rows for paved/asphalt, dirt, grass, sand, rock/rough, and tire damage. Longitudinal tire drag, acceleration traction, and braking traction remain recommendation/telemetry data only until a safe existing-path integration is separately approved. Manual SQA gameplay validation is pending.
- Per-Vehicle Settings requirements and design were approved by SQA on 2026-06-27. Implementation adds `FIXICS_fnc_getVehicleProfile`, `FIXICS_fnc_dumpVehicleProfile`, CBA exact/parent class profile text settings, ACE read-only profile viewing, and telemetry fields for active profile id/source/overrides. DEFAULT preserves global settings; exact class entries override parent class entries. SQA must verify DEFAULT produces identical behavior before tuning class-specific presets.
- SQA confirmed on 2026-06-27 that parent profile QA was completed, exact profile behavior still needs one controlled verification pass, generated profile text files remain local SQA artifacts, tracked vehicles are ignored for now, and heavy HMMWV/MRAP braking still feels like hard snap while light vehicles and pickups feel acceptable. The next implementation adds mass-aware ABS damping for heavier vehicles and better vehicle-family dump filters.
- Live Vehicle Telemetry terminal dashboard was approved by SQA on 2026-06-27 as an external read-only diagnostic tool. Implementation added `tools/live-vehicle-telemetry.py`, which tails the newest Arma 3 RPT by default and displays latest FIXICS Stability, Runtime Assist, Terrain Tire, and handling sample telemetry during gameplay. It has no gameplay mutation path and is intended for SQA live observation.
- Terrain Tire Behavior Phase 2 was approved and implemented on 2026-06-27. It adds wheeled-vehicle rollover/wheel-contact safety, airborne grace, gentle driverless decay, destroyed-tire mobility loss, per-wheel hitpoint fallback handling for `getHitPointDamage` returning `-1`, new CBA settings, Runtime Assist propagation, and compact telemetry fields for `wheelSupportState`, `rolloverSuppressed`, `driverlessDecay`, `destroyedTireCount`, `destroyedTireRatio`, `destroyedTirePenalty`, and `mobilityLimiter`. SQA must verify default supported driving remains acceptable, WA-001 slope rolling is not fighting gentle driverless decay, flipped vehicles stop receiving FIXICS drive/traction help, and destroyed tires degrade mobility without hard locking vehicles.
- Native Terrain Tire Advisory was approved and implemented on 2026-06-27 inside the existing `FIXICSPhysics_x64.dll`. It adds the optional `terrainTireV2` native command, CMake/CTest coverage, `FIXICS_fnc_getNativeTerrainTire`, and the disabled-by-default `FIXICS_nativeTerrainTireEnabled` CBA setting. SQF remains authoritative and falls back to SQF Terrain Tire math when native output is disabled, missing, or invalid. SQA should compare telemetry with `FIXICS_nativeTerrainTireEnabled=false` and `true` on the same vehicle/surface matrix before enabling it by default.
- Weather-Aware Terrain Tire Effects were approved and implemented on 2026-06-27 as a Terrain Tire extension. It adds conservative default weather terrain settings, rain saturation over 30 seconds, drying over 180 seconds only when `rain == 0`, wet terrain grip multipliers, paved hydroplaning risk starting at 70 km/h, wet dirt/grass degradation, wet sand compaction, and minimal crosswind lateral influence through the existing stability path. Telemetry now records weather enablement, rain, overcast, surface wetness, terrain saturation, weather grip, hydroplaning risk, wind strength, wind cross component, wind handling multiplier, and weather reason. SQA must verify saturation feel, hydroplaning detectability, drying pause during active rain, and crosswind/slope interaction.
- Runtime Assist arbitration was tightened on 2026-06-27 after SQA identified same-frame assist conflicts. The pure Runtime Assist recommendation now exposes an explicit priority stack: ACE/FIXICS handbrake, rollover suppression, ABS braking, slope correction, Terrain Tire modifier, then wind lateral. ABS now reads current Terrain Tire braking/weather/hydroplaning values and records Terrain Tire ABS feedback telemetry. Native Terrain Tire advisory calls are cached for a bounded 0.10-0.25 second TTL and invalidated by surface, speed, support, and damage buckets to reduce repeated `callExtension` pressure.
- Multiplayer Phase 1 compatibility slice was approved and implemented on 2026-06-27 as an authority/sync-only change with zero new velocity mutations. Existing mutation-capable systems now route vehicle authority through `FIXICS_fnc_isVehicleLocal`; the global `FIXICS_multiplayerCompatibilityEnabled` setting defaults true; ACE handbrake is driver-only in MP and publishes state globally; per-vehicle profile cache can publish in MP; native DLL advisory calls are suppressed on dedicated server instances. SQA acceptance requires a dedicated server with 2+ players for locality transfer, JIP, server override, and native suppression checks.

## Constraints

- Manual gameplay validation is performed by SQA.
- Multiplayer vehicle authority is deferred.
- Broad config patches and additional native binaries require explicit SQA approval.
- Generated output and reports are ignored and not edited by hand.
- Do not mark ISSUE-001 resolved until SQA verifies rollover behavior and controlled sliding in-game.

## Required Checks

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
powershell -ExecutionPolicy Bypass -File tools\check.ps1
```
