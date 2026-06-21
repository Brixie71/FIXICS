# Validation Log

Record validation runs that matter for implementation, review, or release decisions.

## Entries

### 2026-06-21 - Future feature requirements workflow

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1`
- Result: passed, exit code 0
- Automated coverage: confirmed governance guidance still passes after adding the Requirements Packet workflow.
- Manual coverage: not run.
- Notes: documentation-only process update. No addon source changed.

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1`
- Result: passed, exit code 0
- Automated coverage: confirmed vehicle physics static and mutation checks still pass after workflow documentation changes.
- Manual coverage: not run.
- Notes: no gameplay behavior changed.

- Command: `powershell -ExecutionPolicy Bypass -File tools\check.ps1`
- Result: passed, exit code 0
- Automated coverage: HEMTT/tool wrapper checks passed after workflow documentation changes.
- Manual coverage: not run.
- Notes: no build artifact was produced for this documentation-only task.

### 2026-06-20 - Vehicle Behavior Evidence Registry

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1`
- Result: passed, exit code 0
- Automated coverage: verified Evidence Registry files, telemetry schema fields, support status values, behavior classifications, recommended next actions, and registry boundary wording.
- Manual coverage: not run.
- Notes: documentation-only registry implementation. No SQF gameplay source changed.

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1`
- Result: passed, exit code 0
- Automated coverage: confirmed existing vehicle physics static and mutation checks still pass after registry documentation changes.
- Manual coverage: not run.
- Notes: registry does not claim gameplay behavior improvements.

- Command: `powershell -ExecutionPolicy Bypass -File tools\check.ps1`
- Result: passed, exit code 0
- Automated coverage: HEMTT/tool wrapper checks passed after registry documentation changes.
- Manual coverage: not run.
- Notes: no build artifact was produced for this documentation-only task.

### 2026-06-20 - Documentation cleanup and alignment

- Command: documentation review
- Result: completed
- Automated coverage: aligned README, fix log, workaround registry, open issues, and project state with the current ABS, driver controller, native advisory, telemetry, vehicle stability, and roll stability state.
- Manual coverage: not run.
- Notes: documentation-only pass. No addon source, native source, config, or generated build output changed.

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1`
- Result: passed, exit code 0
- Automated coverage: confirmed governance static contracts still pass after documentation alignment.
- Manual coverage: not run.
- Notes: documentation-only validation.

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1`
- Result: passed, exit code 0
- Automated coverage: confirmed vehicle physics static contracts and mutation checks still pass after documentation alignment.
- Manual coverage: not run.
- Notes: no addon source changed.

- Command: `powershell -ExecutionPolicy Bypass -File tools\check.ps1`
- Result: passed, exit code 0
- Automated coverage: HEMTT loaded FIXICS 1.0.0.1, rapified 2 addon configs, compiled 22 SQF files, checked 1 stringtable, and passed stability/roll recommendation tests.
- Manual coverage: not run.
- Notes: no build artifact was produced in this documentation-only pass.

### 2026-06-06 - Baseline before Codex operating layer

- Command: `hemtt check`
- Result: passed, exit code 0
- Automated coverage: HEMTT loaded FIXICS 0.1.0.0, rapified 2 addon configs, compiled 3 SQF files, checked 1 stringtable.
- Manual coverage: not run.
- Notes: run before adding the Codex operating scaffold.

### 2026-06-06 - Codex operating layer scaffold

- Command: `.\tools\check.ps1`
- Result: passed, exit code 0
- Automated coverage: HEMTT loaded FIXICS 0.1.0.0, rapified 2 addon configs, compiled 3 SQF files, checked 1 stringtable.
- Manual coverage: not run.
- Notes: run after adding `CODEX.md`, agent guidance, tool wrappers, orchestration, prompts, governance, evals, tests, and docs.

### 2026-06-07 - Local vehicle slope rolling and ACE handbrake

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1`
- Result: passed, exit code 0
- Automated coverage: verified `FIXICS_fnc_*` source migration, ACE interaction dependency, handbrake stringtable keys, and local vehicle physics function registration.
- Manual coverage: not run.
- Notes: static regression was first run before implementation and failed for the expected missing feature checks.

- Command: `powershell -ExecutionPolicy Bypass -File tools\check.ps1`
- Result: passed, exit code 0
- Automated coverage: HEMTT loaded FIXICS 0.1.0.0, rapified 2 addon configs, compiled 7 SQF files, checked 1 stringtable.
- Manual coverage: not run.
- Notes: manual Eden/VR slope behavior with ACE loaded is still required for empty, driver-occupied, and passenger-only vehicles.

### 2026-06-07 - Idle autobrake setting

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1`
- Result: passed, exit code 0
- Automated coverage: verified CBA settings dependency, `FIXICS_disableIdleAutobrake` registration, setting stringtable keys, and brake-input priority before the idle-autobrake setting.
- Manual coverage: not run.
- Notes: added after SQA observed automatic stationary handbrake behavior conflicting with forward driving tests.

- Command: `powershell -ExecutionPolicy Bypass -File tools\check.ps1`
- Result: passed, exit code 0
- Automated coverage: HEMTT loaded FIXICS 0.1.0.0, rapified 2 addon configs, compiled 8 SQF files, checked 1 stringtable.
- Manual coverage: not run.
- Notes: manual Eden/VR retest should confirm the new addon setting prevents automatic stationary handbrake behavior while preserving active brake-key behavior.

### 2026-06-07 - Near-stationary brake/reverse bypass

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1`
- Result: passed, exit code 0
- Automated coverage: verified `CarBack` only blocks rolling while above the near-stationary threshold and that idle autobrake disabling is re-applied near zero speed unless the FIXICS ACE handbrake is set.
- Manual coverage: not run.
- Notes: added after SQA observed Arma's automatic handbrake behavior while transitioning from forward to reverse.

- Command: `powershell -ExecutionPolicy Bypass -File tools\check.ps1`
- Result: passed, exit code 0
- Automated coverage: HEMTT loaded FIXICS 0.1.0.0, rapified 2 addon configs, compiled 8 SQF files, checked 1 stringtable.
- Manual coverage: not run.
- Notes: manual Eden/VR retest should confirm normal braking still works while reverse can engage from near stationary without persistent autobrake.

### 2026-06-07 - Local slope rollback assist

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1`
- Result: passed, exit code 0
- Automated coverage: verified `FIXICS_fnc_applySlopeRollback` registration and monitor integration, terrain `surfaceNormal` use, downhill `setVelocity` assist, and throttle/handbrake input guards.
- Manual coverage: not run.
- Notes: added after SQA observed uphill coasting continuing in the same direction instead of rolling downhill when throttle was released.

- Command: `powershell -ExecutionPolicy Bypass -File tools\check.ps1`
- Result: passed, exit code 0
- Automated coverage: HEMTT loaded FIXICS 0.1.0.0, rapified 2 addon configs, compiled 9 SQF files, checked 1 stringtable.
- Manual coverage: not run.
- Notes: manual Eden/VR retest should confirm uphill forward coasting rolls backward after W is released, and uphill reverse coasting rolls forward after S is released.

### 2026-06-07 - ACE handbrake hard lock

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1`
- Result: passed, exit code 0
- Automated coverage: verified `FIXICS_fnc_applyHandbrakeLock` registration, immediate lock application when setting the ACE handbrake, monitor enforcement, local-only mutation, autobrake enablement, and velocity zeroing.
- Manual coverage: not run.
- Notes: added after SQA observed W/S throttle still moving vehicles while the FIXICS ACE handbrake was set.

- Command: `powershell -ExecutionPolicy Bypass -File tools\check.ps1`
- Result: passed, exit code 0
- Automated coverage: HEMTT loaded FIXICS 0.1.0.0, rapified 2 addon configs, compiled 10 SQF files, checked 1 stringtable.
- Manual coverage: not run.
- Notes: manual Eden/VR retest should confirm Set Handbrake hard-locks the vehicle against W and S until Release Handbrake is used.

### 2026-06-07 - Gear-independent near-zero rollback

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1`
- Result: passed, exit code 0
- Automated coverage: verified rollback assist uses the near-stationary threshold, keeps built-in `CarHandBrake` as an immediate temporary hold, lets W/S input block rollback only above near-stationary speed, and uses the stronger `FIXICS_slopeRollbackAcceleration` default.
- Manual coverage: not run.
- Notes: static regression was first run before implementation and failed for the expected missing near-stationary rollback and acceleration-default checks.

- Command: `powershell -ExecutionPolicy Bypass -File tools\check.ps1`
- Result: passed, exit code 0
- Automated coverage: HEMTT loaded FIXICS 0.1.0.0, rapified 2 addon configs, compiled 10 SQF files, checked 1 stringtable.
- Manual coverage: not run.
- Notes: manual Eden/VR retest should confirm vehicles roll downhill from near-zero speed without requiring double-tap W/S while the FIXICS ACE handbrake remains the only persistent handbrake.

### 2026-06-07 - Beyond SQF vehicle physics evaluation

- Command: documentation review
- Result: completed
- Automated coverage: documented `FIXICS-EXC-2026-06-07-VEHICLE-PHYSICS-BEYOND-SQF` in scope control and added the config-class/native-extension evaluation spec.
- Manual coverage: not run.
- Notes: this is evaluation approval only. Implementation beyond SQF still requires SQA evidence, a separate user-approved plan, and fresh validation.

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1`
- Result: passed, exit code 0
- Automated coverage: confirmed the vehicle physics static regression still passes after documentation changes.
- Manual coverage: not run.
- Notes: no addon source changed in this documentation pass.

- Command: `powershell -ExecutionPolicy Bypass -File tools\check.ps1`
- Result: passed, exit code 0
- Automated coverage: HEMTT loaded FIXICS 0.1.0.0, rapified 2 addon configs, compiled 10 SQF files, checked 1 stringtable.
- Manual coverage: not run.
- Notes: no manual Arma launch was performed for the documentation-only exception evaluation.

### 2026-06-07 - Config-class vehicle handling escalation

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1`
- Result: failed, exit code 1
- Automated coverage: regression failed for the expected missing `A3_Soft_F` / `A3_Armor_F` dependencies, `CfgVehicles` handling patch, and vehicle handling diagnostic function.
- Manual coverage: not run.
- Notes: red phase before implementing the config-class escalation.

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1`
- Result: passed, exit code 0
- Automated coverage: verified `Car_F` and `Tank_F` handling patches, lowered `brakeIdleSpeed`, lowered zero-throttle damping, and registered `FIXICS_fnc_logVehicleHandlingConfig`.
- Manual coverage: not run.
- Notes: added after SQA confirmed the SQF rollback/autobrake mitigation still required W/S input to start rolling downhill.

- Command: `powershell -ExecutionPolicy Bypass -File tools\check.ps1`
- Result: passed, exit code 0
- Automated coverage: HEMTT loaded FIXICS 0.1.0.0, rapified 2 addon configs, compiled 11 SQF files, checked 1 stringtable.
- Manual coverage: not run.
- Notes: manual Eden/VR retest should confirm whether the config-class patch removes the remaining need to press W/S. Native-extension research remains out of scope unless this patch fails SQA testing and receives separate approval.

### 2026-06-07 - Native extension pre-research

- Command: documentation review
- Result: completed
- Automated coverage: documented native-extension feasibility, hard gates, deployment/security constraints, and the recommendation to keep any first spike diagnostic-only.
- Manual coverage: not run.
- Notes: no native source, binary, build tooling, dependencies, or extension wrapper was added.

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1`
- Result: passed, exit code 0
- Automated coverage: confirmed the existing vehicle physics static regression still passes after the research documentation.
- Manual coverage: not run.
- Notes: no addon source changed in this research pass.

- Command: `powershell -ExecutionPolicy Bypass -File tools\check.ps1`
- Result: passed, exit code 0
- Automated coverage: HEMTT loaded FIXICS 0.1.0.0, rapified 2 addon configs, compiled 11 SQF files, checked 1 stringtable.
- Manual coverage: not run.
- Notes: baseline remains clean while SQA tests the config-class experiment.

### 2026-06-07 - Native-assisted gameplay-control scaffold

- Command: SQA report
- Result: config-class experiment failed
- Automated coverage: not applicable.
- Manual coverage: SQA reported the config-class patch made vehicle behavior more buggy than before.
- Notes: broad `Car_F` / `Tank_F` handling patch was treated as failed and removed before native escalation.

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1`
- Result: failed, exit code 1
- Automated coverage: regression failed for the expected remaining config-class patch plus missing native bridge/source scaffold.
- Manual coverage: not run.
- Notes: red phase before native-assisted gameplay-control scaffold.

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1`
- Result: passed, exit code 0
- Automated coverage: verified config-class patch removal, optional native bridge registration, native source scaffold, no committed native binaries, and slope rollback bridge integration.
- Manual coverage: not run.
- Notes: native control remains disabled by default through `FIXICS_nativeSlopeControlEnabled`.

- Command: `powershell -ExecutionPolicy Bypass -File tools\check.ps1`
- Result: passed, exit code 0
- Automated coverage: HEMTT loaded FIXICS 0.1.0.0, rapified 2 addon configs, compiled 12 SQF files, checked 1 stringtable.
- Manual coverage: not run.
- Notes: HEMTT does not compile native C++ source. A separate native build plan is required before binary work.

### 2026-06-07 - Local Windows x64 native binary

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1`
- Result: failed, exit code 1
- Automated coverage: regression failed for the expected missing `native/fixics_physics/CMakeLists.txt`, `tools/build-native.ps1`, root `FIXICSPhysics_x64.dll`, and binary documentation.
- Manual coverage: not run.
- Notes: red phase before adding native build files and binary output.

- Command: `powershell -ExecutionPolicy Bypass -File tools\build-native.ps1`
- Result: passed, exit code 0
- Automated coverage: Visual Studio Build Tools 2022 loaded through `VsDevCmd.bat`, CMake configured the x64 project, MSBuild compiled `FIXICSPhysics.cpp`, and `FIXICSPhysics_x64.dll` was written to the repository root.
- Manual coverage: not run.
- Notes: first build emitted an MSVC `strncpy` warning; source was updated to use bounded `memcpy`, then rebuilt cleanly.

- Command: `dumpbin /exports FIXICSPhysics_x64.dll | findstr RVExtension`
- Result: passed, exit code 0
- Automated coverage: verified exports `RVExtension`, `RVExtensionArgs`, and `RVExtensionVersion`.
- Manual coverage: not run.
- Notes: run from the Visual Studio developer environment.

### 2026-06-07 - Slope-gated brake disable regression fix

- Command: SQA report
- Result: regression reproduced manually by SQA
- Automated coverage: not applicable.
- Manual coverage: SQA reported W/S release continued moving vehicles on flat ground, and opposite input did not reliably engage Drive/Reverse.
- Notes: root cause was `disableBrakes true` being applied without first checking terrain slope.

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1`
- Result: failed, exit code 1
- Automated coverage: regression failed for the expected missing slope gate in `FIXICS_fnc_shouldVehicleRoll` and W/S rollback suppression in `FIXICS_fnc_applySlopeRollback`.
- Manual coverage: not run.
- Notes: red phase before implementation.

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1`
- Result: passed, exit code 0
- Automated coverage: verified slope-gated brake disabling, no unconditional `FIXICS_disableIdleAutobrake` true return, and rollback suppression while W/S input is active.
- Manual coverage: not run.
- Notes: manual Arma retest must verify flat-ground stopping and Drive/Reverse switching.

- Command: `powershell -ExecutionPolicy Bypass -File tools\check.ps1`
- Result: passed, exit code 0
- Automated coverage: HEMTT loaded FIXICS 0.1.0.0, rapified 2 addon configs, compiled 12 SQF files, checked 1 stringtable.
- Manual coverage: not run.
- Notes: no native C++ source changed for this fix.

### 2026-06-07 - Slope-relative drive and coasting acceleration

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1`
- Result: failed, exit code 1
- Automated coverage: regression failed for the expected missing monitor sequencing, W/S drive-vs-brake classification, vehicle-orientation slope acceleration, coasting breakaway defaults, and native breakaway support.
- Manual coverage: not run.
- Notes: red phase after SQA reported reversing uphill and releasing `S` still left the vehicle stationary.

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1`
- Result: passed, exit code 0
- Automated coverage: verified separate slope-helper monitor call, active braking guard, vehicle `vectorDir` orientation handling, slope angle calculation, coasting breakaway, drive acceleration defaults, and native minimum-delta support.
- Manual coverage: not run.
- Notes: manual Eden/VR retest must confirm reverse-release downhill coasting and compare downhill versus uphill acceleration feel.

- Command: `powershell -ExecutionPolicy Bypass -File tools\check.ps1`
- Result: passed, exit code 0
- Automated coverage: HEMTT loaded FIXICS 0.1.0.0, rapified 2 addon configs, compiled 12 SQF files, checked 1 stringtable.
- Manual coverage: not run.
- Notes: SQF syntax and config compilation passed after the slope helper update.

- Command: `powershell -ExecutionPolicy Bypass -File tools\build-native.ps1`
- Result: passed, exit code 0
- Automated coverage: Visual Studio Build Tools 2022 loaded through `VsDevCmd.bat`, CMake configured the x64 project, MSBuild compiled `FIXICSPhysics.cpp`, and `FIXICSPhysics_x64.dll` was written to the repository root.
- Manual coverage: not run.
- Notes: rebuilt the approved local Windows x64 DLL after adding native `minimumDelta` support.

### 2026-06-07 - Local player driver state controller

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1`
- Result: failed, exit code 1
- Automated coverage: regression failed for the expected missing CBA PFH dependency, controller functions, settings, localization, monitor ownership, low-speed ABS override, and downhill-only powered slope behavior.
- Manual coverage: not run.
- Notes: red phase before implementing the approved Drive, Service Brake, Reverse, Coast, and Handbrake controller.

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1`
- Result: passed, exit code 0
- Automated coverage: verified controller registration, Hold/Toggle handbrake settings, model-space direction transitions, ABS ownership, elapsed-time normalization, grounded operation, ownership cleanup, slow-monitor exclusion, brake restoration, SQF input guard scope, and downhill-only powered slope assist.
- Manual coverage: not run.
- Notes: static checks cannot prove how each Arma vehicle PhysX class competes with native W/S drivetrain processing. Multiplayer locality-transfer cleanup remains deferred to the multiplayer phase.

- Command: `powershell -ExecutionPolicy Bypass -File tools\check.ps1`
- Result: passed, exit code 0
- Automated coverage: HEMTT loaded FIXICS 0.1.0.0, rapified 2 addon configs, compiled 15 SQF files, and checked 1 stringtable.
- Manual coverage: not run.
- Notes: no native C++ source changed; rebuilding `FIXICSPhysics_x64.dll` was not required.

- Command: focused subagent code review
- Result: completed; no remaining high-severity findings
- Automated coverage: reviewed W/S reversal, brake ownership, elapsed-time scaling, grounded handbrake behavior, ABS fallback, ACE/X handbrake state, and monitor/controller handoff.
- Manual coverage: not run.
- Notes: the remaining locality-transfer cleanup finding is explicitly deferred to the multiplayer phase.

### 2026-06-07 - Neutral pulse for Reverse-to-Drive and Drive-to-Reverse

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1`
- Result: failed, exit code 1
- Automated coverage: regression failed for the expected missing neutral-pulse setting and localization, `NEUTRAL` state, direction latch/deadline, input cancellation, exact-zero clamp, delayed launch, and removal of the same-update threshold launch.
- Manual coverage: SQA reproduced Reverse-to-Drive failure before implementation.
- Notes: root cause was immediate forward launch at the speed threshold before Arma's reverse gearbox observed a neutral stop.

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1`
- Result: passed, exit code 0
- Automated coverage: verified sign-based opposite-motion detection, latched transition target, configurable neutral deadline, exact-zero longitudinal hold, delayed launch, symmetric direction handling, and transition cancellation.
- Manual coverage: not run after implementation.
- Notes: normal ABS braking remains unchanged; the neutral pulse only runs during an opposite-direction handoff.

- Command: `powershell -ExecutionPolicy Bypass -File tools\check.ps1`
- Result: passed, exit code 0
- Automated coverage: HEMTT loaded FIXICS 0.1.0.0, rapified 2 addon configs, compiled 15 SQF files, and checked 1 stringtable.
- Manual coverage: not run.
- Notes: no native extension change or rebuild is required for this SQF/CBA gearbox workaround.

- Command: `powershell -ExecutionPolicy Bypass -File tools\build.ps1`
- Result: passed, exit code 0
- Automated coverage: HEMTT built 1 PBO after compiling 15 SQF files and checking 1 stringtable.
- Manual coverage: not run.
- Notes: updated local artifact is `.hemttout/build/addons/fixics_main.pbo`.

- Manual SQA matrix:
  1. Reverse at moderate speed, hold W through braking, neutral pulse, and forward launch.
  2. Release W during ABS braking; vehicle must not launch forward.
  3. Release W during the neutral pulse; vehicle must not launch forward.
  4. Drive at moderate speed, hold S through braking, neutral pulse, and reverse launch.
  5. Repeat both transitions uphill and downhill.
  6. Confirm ordinary S braking while driving remains smooth and does not enter a direction transition when S is released before the threshold.
  7. Compare neutral pulse values `0.03`, `0.08`, and `0.15` seconds across several vehicle classes.

### 2026-06-07 - Reverse-to-Drive forward-input and ABS correction

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1`
- Result: failed, exit code 1
- Automated coverage: regression failed for the missing shared input decoder, `CarFastForward`/`CarSlowForward`, controller-decoded ABS intent, model-space ABS writes, normal braking in `SERVICE_BRAKE`/`NEUTRAL`, and launch-velocity isolation.
- Manual coverage: SQA reproduced Reverse-to-Drive ignoring W while reverse motion remained.
- Notes: root cause was the controller reading only `CarForward`; Arma can bind W to another forward action while S remains `CarBack`.

- Command: `powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1`
- Result: passed, exit code 0
- Automated coverage: verified shared W/S decoding, all three forward action variants, direction intent passed into ABS, model-space longitudinal braking, outer-scope slope input assignment, engine braking during service/neutral states, and no ordinary-drive launch injection.
- Manual coverage: not run after implementation.
- Notes: manual Arma testing is still required for Reverse-to-Drive across vehicle classes and slopes.

- Command: `powershell -ExecutionPolicy Bypass -File tools\check.ps1`
- Result: passed, exit code 0
- Automated coverage: HEMTT loaded FIXICS 0.1.0.0, rapified 2 addon configs, compiled 16 SQF files, and checked 1 stringtable with no warnings.
- Manual coverage: not run.
- Notes: no native extension source changed.

- Command: `powershell -ExecutionPolicy Bypass -File tools\build.ps1`
- Result: blocked, exit code 1
- Automated coverage: build could not replace `.hemttout\build` because the running Arma 3 process held the directory open.
- Manual coverage: not run.
- Notes: do not terminate the active SQA session automatically; rebuild the normal test profile after Arma exits.

- Command: `.\hemtt.exe release --no-archive`
- Result: passed, exit code 0
- Automated coverage: HEMTT rapified 2 addon configs, compiled 16 SQF files, checked 1 stringtable, and built 1 PBO.
- Manual coverage: not run.
- Notes: packaged fallback artifact is `.hemttout/release/addons/fixics_main.pbo`; HEMTT warned that Arma 3 Tools was not installed, but no supported source required binarization.
