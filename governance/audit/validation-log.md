# Validation Log

Record validation runs that matter for implementation, review, or release decisions.

## Entries

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
