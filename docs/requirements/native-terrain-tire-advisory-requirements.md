# Native Terrain Tire Advisory - Requirements Packet

## Objective

Add optional binary-level advisory support for Terrain Tire Phase 2 calculations
inside the existing `FIXICSPhysics_x64.dll`.

The native code should improve calculation performance and consistency for
bounded math only. SQF remains the gameplay authority.

## Current System State

- Phase: Phase 1 - Ground Vehicle Physics.
- Existing native binary: `FIXICSPhysics_x64.dll`.
- Existing native source: `native/fixics_physics/`.
- Existing CMake project builds one shared library and one native test
  executable.
- Existing native commands:
  - `slopeControl`
  - `driverAssist`
- Existing native boundary:
  - advisory math only;
  - no Arma object ownership;
  - no direct PhysX mutation;
  - SQF validates output and applies all gameplay changes.

## Files To Load

Load only exact paths.

| Purpose | File |
|---|---|
| Native README | `native/fixics_physics/README.md` |
| Native CMake | `native/fixics_physics/CMakeLists.txt` |
| Native source | `native/fixics_physics/src/FIXICSPhysics.cpp` |
| Native tests | `native/fixics_physics/tests/FIXICSPhysicsTests.cpp` |
| Native SQF bridge pattern | `addons/main/functions/fn_getNativeDriverAssist.sqf` |
| Terrain Tire SQF | `addons/main/functions/fn_getTerrainTireRecommendation.sqf` |
| Static tests | `tests/integration/fixics-vehicle-physics-static.ps1` |

## SQA Questions And Answers

| Question | SQA Answer | Decision Impact |
|---|---|---|
| Should this be one DLL or a separate DLL? | Use the existing DLL unless there is a strong reason not to. | Add `terrainTireV2` to `FIXICSPhysics_x64.dll`. |
| Should native code mutate Arma physics directly? | No. | Native output remains advisory only. |
| Should SQF fallback remain available? | Yes. | If native is disabled, missing, invalid, or returns bad data, SQF Terrain Tire remains authoritative. |
| Should CMake be used? | Yes. | Extend the existing CMake project and native tests. |
| Should this target performance-sensitive math first? | Yes. | Start with Terrain Tire Phase 2 recommendation math, not broad engine control. |

## Constraints

- Keep one native binary: `FIXICSPhysics_x64.dll`.
- Do not create `FIXICSTerrain_x64.dll` or another extension in this pass.
- Do not store generated native binaries under `native/`.
- Do not make native output authoritative.
- Do not remove SQF fallback.
- Do not add new third-party dependencies.
- Do not change multiplayer authority.
- Do not call `callExtension` in a high-frequency path unless SQA approves the
  runtime cost after profiling.

## Recommended Approach

1. Documentation/research:
   - Extend the native README with `terrainTireV2`.
   - Define exact input/output schema.
2. Implementation plan:
   - Add failing C++ tests first.
   - Implement pure C++ `terrainTireV2` parser and formatter.
   - Add SQF bridge only after native tests pass.
   - Keep SQF fallback as default path.
3. Validation:
   - Run native build/tests.
   - Run required repository validation.
4. SQA handoff:
   - Compare native-enabled and SQF fallback telemetry for the same vehicle and
     terrain test.

## Expected Output

- Files created:
  - `addons/main/functions/fn_getNativeTerrainTire.sqf`
- Files modified:
  - `native/fixics_physics/src/FIXICSPhysics.cpp`
  - `native/fixics_physics/tests/FIXICSPhysicsTests.cpp`
  - `native/fixics_physics/README.md`
  - `addons/main/config.cpp`
  - `addons/main/functions/fn_getTerrainTireRecommendation.sqf`
  - `addons/main/functions/fn_registerSettings.sqf`
  - `addons/main/stringtable.xml`
  - `tests/integration/fixics-vehicle-physics-static.ps1`
- Tests run:
  - native CMake/CTest through `tools\build-native.ps1`
  - governance static
  - vehicle physics static
  - `tools\check.ps1`

## Validation Commands

```powershell
powershell -ExecutionPolicy Bypass -File tools\build-native.ps1
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
powershell -ExecutionPolicy Bypass -File tools\check.ps1
git diff --check
```
