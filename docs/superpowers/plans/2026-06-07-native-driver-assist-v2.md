# Native Driver Assist v2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add optional native-assisted ABS and Drive/Reverse controller math with debug telemetry while preserving the existing SQF fallback behavior.

**Architecture:** `FIXICSPhysics` gains a `driverAssist` advisory command. SQF gathers local vehicle/controller context, calls the native advisor only when enabled, validates the response, and remains the only layer that mutates Arma vehicles. The existing `slopeControl` command and all SQF fallbacks remain intact.

**Tech Stack:** Arma 3 SQF, CBA settings, ACE interaction state, HEMTT, PowerShell static tests, C++ Arma `callExtension`.

---

## File Structure

- `tests/integration/fixics-vehicle-physics-static.ps1`: expands the static contract before implementation.
- `native/fixics_physics/src/FIXICSPhysics.cpp`: adds the native `driverAssist` command and schema entry.
- `native/fixics_physics/tests/FIXICSPhysicsTests.cpp`: exercises the exported native command with deterministic inputs.
- `native/fixics_physics/CMakeLists.txt`: builds and registers the native test executable.
- `tools/build-native.ps1`: runs CTest after building the extension.
- `native/fixics_physics/README.md`: documents the new native command and advisory boundary.
- `addons/main/functions/fn_getNativeDriverAssist.sqf`: new SQF bridge from controller code to the native advisor.
- `addons/main/functions/fn_applyABSBraking.sqf`: uses native recommendation first, then existing SQF ABS fallback.
- `addons/main/functions/fn_updateDriverController.sqf`: uses native recommendation during service brake and direction transitions without skipping neutral behavior.
- `addons/main/functions/fn_registerSettings.sqf`: adds native driver assist and telemetry settings.
- `addons/main/config.cpp`: registers the new SQF bridge.
- `addons/main/stringtable.xml`: adds localized setting labels and tooltips.
- `docs/fixes/workaround-registry.md`: updates WA-002 to document native-advised controller math.
- `docs/fixes/fix-log.md`: intentionally unchanged until a separate SQA-verified completion update.

---

### Task 1: Static Contract For Native Driver Assist

**Files:**
- Modify: `tests/integration/fixics-vehicle-physics-static.ps1`

- [ ] **Step 1: Add failing static assertions for the feature contract**

In `tests/integration/fixics-vehicle-physics-static.ps1`, add `fn_getNativeDriverAssist.sqf` to the expected function file list near the existing native bridge:

```powershell
'addons\main\functions\fn_getNativeDriverAssist.sqf',
```

Add a CfgFunctions registration assertion near the existing `getNativeSlopeControl` assertion:

```powershell
Assert-Contains $Config 'class getNativeDriverAssist\s*\{\s*\};' 'getNativeDriverAssist must be registered in CfgFunctions.'
```

Add stringtable assertions near the existing native slope setting assertions:

```powershell
Assert-Contains $Stringtable 'STR_FIXICS_SETTING_NATIVE_DRIVER_ASSIST' 'Stringtable must define the native driver assist setting title.'
Assert-Contains $Stringtable 'STR_FIXICS_SETTING_NATIVE_DRIVER_ASSIST_TOOLTIP' 'Stringtable must define the native driver assist setting tooltip.'
Assert-Contains $Stringtable 'STR_FIXICS_SETTING_DRIVER_ASSIST_DEBUG_LOGGING' 'Stringtable must define the driver assist debug logging setting title.'
Assert-Contains $Stringtable 'STR_FIXICS_SETTING_DRIVER_ASSIST_DEBUG_LOGGING_TOOLTIP' 'Stringtable must define the driver assist debug logging setting tooltip.'
```

Inside the `$SettingsFile` block, add:

```powershell
Assert-Contains $Settings '"FIXICS_nativeDriverAssistEnabled"' 'Settings registration must define FIXICS_nativeDriverAssistEnabled.'
Assert-Contains $Settings '"FIXICS_driverAssistDebugLogging"' 'Settings registration must define FIXICS_driverAssistDebugLogging.'
```

Add a new `$NativeDriverAssistFile` block after the `$NativeBridgeFile` block:

```powershell
$NativeDriverAssistFile = Join-Path $RepoRoot 'addons\main\functions\fn_getNativeDriverAssist.sqf'
if (Test-Path -LiteralPath $NativeDriverAssistFile) {
    $NativeDriverAssist = Get-Content -Raw -LiteralPath $NativeDriverAssistFile
    Assert-Contains $NativeDriverAssist '"FIXICS_nativeDriverAssistEnabled", false' 'Native driver assist bridge must default disabled.'
    Assert-Contains $NativeDriverAssist '"FIXICSPhysics"\s+callExtension\s+\[[\s\S]*?"driverAssist"' 'Native driver assist bridge must call the FIXICSPhysics driverAssist function.'
    Assert-Contains $NativeDriverAssist 'parseSimpleArray' 'Native driver assist bridge must parse the extension response.'
    Assert-Contains $NativeDriverAssist 'errorCode' 'Native driver assist bridge must check callExtension errorCode.'
    Assert-Contains $NativeDriverAssist 'isEqualType' 'Native driver assist bridge must validate response element types.'
    Assert-Contains $NativeDriverAssist 'finite' 'Native driver assist bridge must reject non-finite numeric recommendations.'
}
```

Add the native test file to the expected file list:

```powershell
'native\fixics_physics\tests\FIXICSPhysicsTests.cpp',
```

Inside the `$AbsFile` block, add:

```powershell
Assert-Contains $Abs 'FIXICS_fnc_getNativeDriverAssist' 'ABS helper must consult the optional native driver assist bridge.'
Assert-Contains $Abs 'source=%' 'ABS helper telemetry must include its recommendation source.'
Assert-Contains $Abs '"native"' 'ABS helper telemetry must identify native-sourced recommendations.'
Assert-Contains $Abs '"sqf"' 'ABS helper telemetry must identify SQF fallback recommendations.'
Assert-Contains $Abs 'FIXICS_driverAssistDebugLogging' 'ABS helper must honor driver assist debug logging.'
Assert-Contains $Abs 'private _applySqfAbsFallback' 'ABS helper must keep an explicit SQF fallback path.'
```

Inside the `$DriverControllerFile` block, add:

```powershell
Assert-Contains $DriverController 'FIXICS_fnc_getNativeDriverAssist' 'Driver controller must consult the optional native driver assist bridge.'
Assert-Contains $DriverController 'FIXICS_driverAssistDebugLogging' 'Driver controller must honor driver assist debug logging.'
Assert-Contains $DriverController 'source=%' 'Driver controller telemetry must include its recommendation source.'
Assert-Contains $DriverController '"native"' 'Driver controller telemetry must identify native-sourced recommendations.'
Assert-Contains $DriverController '"sqf"' 'Driver controller telemetry must identify SQF fallback recommendations.'
Assert-Contains $DriverController 'FIXICS_directionTransitionNeutralUntil' 'Native assist must preserve the existing neutral pulse deadline.'
```

Inside the `$NativeSourceFile` block, add:

```powershell
Assert-Contains $NativeSource 'driverAssist' 'Native source must implement driverAssist dispatch.'
Assert-Contains $NativeSource 'std::isfinite' 'Native source must reject non-finite driver assist inputs.'
Assert-Contains $NativeSource 'DriverAssistInput' 'Native source must use a named input structure for driver assist.'
Assert-Contains $NativeSource 'DriverAssistResult' 'Native source must use a named result structure for driver assist.'
Assert-Contains $NativeSource 'targetLongitudinalSpeed' 'Native source must return a bounded target longitudinal speed.'
Assert-Contains $NativeSource 'brakeDelta' 'Native source must return a bounded brake delta.'
```

Inside the `$NativeReadmeFile` block, add:

```powershell
Assert-Contains $NativeReadme 'driverAssist' 'Native README must document driverAssist.'
Assert-Contains $NativeReadme 'native advisor' 'Native README must preserve the SQF-owned mutation boundary.'
```

Inside the `$NativeCmakeFile` block, add:

```powershell
Assert-Contains $NativeCmake 'add_executable\(FIXICSPhysicsTests' 'Native CMake must build FIXICSPhysicsTests.'
Assert-Contains $NativeCmake 'add_test\(NAME FIXICSPhysicsTests' 'Native CMake must register FIXICSPhysicsTests with CTest.'
```

Inside the `$NativeBuildScriptFile` block, add:

```powershell
Assert-Contains $NativeBuildScript 'ctest' 'Native build script must run native command tests.'
```

- [ ] **Step 2: Run the static test and confirm RED**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: `FIXICS vehicle physics static test failed:` with failures for missing `fn_getNativeDriverAssist.sqf`, missing `getNativeDriverAssist` registration, missing settings/stringtable keys, missing native `driverAssist`, and missing telemetry hooks.

- [ ] **Step 3: Commit the failing static contract**

Run:

```powershell
git add tests\integration\fixics-vehicle-physics-static.ps1
git commit -m "Test native driver assist contract"
```

---

### Task 2: Native `driverAssist` Command

**Files:**
- Modify: `native/fixics_physics/src/FIXICSPhysics.cpp`
- Create: `native/fixics_physics/tests/FIXICSPhysicsTests.cpp`
- Modify: `native/fixics_physics/CMakeLists.txt`
- Modify: `tools/build-native.ps1`
- Modify: `native/fixics_physics/README.md`

- [ ] **Step 1: Add the failing native command tests**

Create `native/fixics_physics/tests/FIXICSPhysicsTests.cpp`:

```cpp
#include <cstdlib>
#include <iostream>
#include <string>
#include <vector>

#ifdef _WIN32
#define FIXICS_IMPORT __declspec(dllimport)
#define FIXICS_CALL __stdcall
#else
#define FIXICS_IMPORT
#define FIXICS_CALL
#endif

extern "C" FIXICS_IMPORT int FIXICS_CALL RVExtensionArgs(
    char* output,
    unsigned int outputSize,
    const char* function,
    const char** args,
    unsigned int argsCount);

namespace {
std::string callDriverAssist(const std::vector<const char*>& args)
{
    char output[1024] = {};
    const int returnCode = RVExtensionArgs(
        output,
        static_cast<unsigned int>(sizeof(output)),
        "driverAssist",
        args.data(),
        static_cast<unsigned int>(args.size()));

    if (returnCode != 0) {
        std::cerr << "driverAssist returned code " << returnCode << '\n';
        std::exit(EXIT_FAILURE);
    }

    return output;
}

void expectEqual(const std::string& name, const std::string& actual, const std::string& expected)
{
    if (actual == expected) {
        return;
    }

    std::cerr
        << name << " failed\n"
        << "Expected: " << expected << '\n'
        << "Actual:   " << actual << '\n';
    std::exit(EXIT_FAILURE);
}
}

int main()
{
    expectEqual(
        "forward braking",
        callDriverAssist({
            "SERVICE_BRAKE", "-1", "5", "0", "0", "0.25",
            "0.45", "0.35", "0.25", "0.5555556", "0.35", "0.08",
            "0.8333333", "1"
        }),
        "[true,\"SERVICE_BRAKE\",4.7075,0.2925,0,\"brake\"]");

    expectEqual(
        "reverse braking",
        callDriverAssist({
            "SERVICE_BRAKE", "1", "-5", "0", "0", "0.25",
            "0.45", "0.35", "0.25", "0.5555556", "0.35", "0.08",
            "0.8333333", "1"
        }),
        "[true,\"SERVICE_BRAKE\",-4.7075,0.2925,0,\"brake\"]");

    expectEqual(
        "low speed cutoff",
        callDriverAssist({
            "SERVICE_BRAKE", "-1", "0.5", "0", "0", "0.25",
            "0.45", "0.35", "0.25", "0.5555556", "0.35", "0.08",
            "0.8333333", "0"
        }),
        "[false,\"NONE\",0.5,0,0,\"below-cutoff\"]");

    expectEqual(
        "neutral launch",
        callDriverAssist({
            "NEUTRAL", "1", "0", "0", "0", "0.03",
            "0.45", "0.35", "0.25", "0.5555556", "0.35", "0.08",
            "0.8333333", "1"
        }),
        "[true,\"LAUNCH\",0.35,0,1,\"launch\"]");

    expectEqual(
        "non-finite input",
        callDriverAssist({
            "SERVICE_BRAKE", "-1", "nan", "0", "0", "0.25",
            "0.45", "0.35", "0.25", "0.5555556", "0.35", "0.08",
            "0.8333333", "1"
        }),
        "[false,\"NONE\",0,0,0,\"invalid\"]");

    std::cout << "FIXICSPhysicsTests passed.\n";
    return EXIT_SUCCESS;
}
```

- [ ] **Step 2: Register the native test target and CTest**

In `native/fixics_physics/CMakeLists.txt`, add after the `FIXICSPhysics` target configuration:

```cmake
include(CTest)

if (BUILD_TESTING)
    add_executable(FIXICSPhysicsTests
        tests/FIXICSPhysicsTests.cpp
    )
    target_compile_features(FIXICSPhysicsTests PRIVATE cxx_std_17)
    target_link_libraries(FIXICSPhysicsTests PRIVATE FIXICSPhysics)

    if (MSVC)
        target_compile_options(FIXICSPhysicsTests PRIVATE /W4 /permissive-)
    else()
        target_compile_options(FIXICSPhysicsTests PRIVATE -Wall -Wextra -Wpedantic)
    endif()

    add_custom_command(TARGET FIXICSPhysicsTests POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            $<TARGET_FILE:FIXICSPhysics>
            $<TARGET_FILE_DIR:FIXICSPhysicsTests>
    )

    add_test(NAME FIXICSPhysicsTests COMMAND FIXICSPhysicsTests)
endif()
```

In `tools/build-native.ps1`, append `ctest` to `$BuildCommand`:

```powershell
$BuildCommand = @(
    "`"$VsDevCmd`" -arch=x64",
    "cmake -S `"$NativeSource`" -B `"$NativeBuild`" -A x64",
    "cmake --build `"$NativeBuild`" --config Release",
    "ctest --test-dir `"$NativeBuild`" -C Release --output-on-failure"
) -join ' && '
```

- [ ] **Step 3: Run native tests and confirm RED**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools\build-native.ps1
```

Expected: the extension and test executable compile, then CTest fails because `RVExtensionArgs` returns `Unknown FIXICSPhysics command` for `driverAssist`.

- [ ] **Step 4: Add native input/result structures and helpers**

In `native/fixics_physics/src/FIXICSPhysics.cpp`, add these structures inside the anonymous namespace after `parseNumber`:

```cpp
struct DriverAssistInput {
    std::string state;
    int requestedDirection = 0;
    double longitudinalSpeed = 0.0;
    double slope = 0.0;
    double downhillAlignment = 0.0;
    double deltaTime = 0.03;
    double absBrakeStrength = 0.45;
    double absReleaseBias = 0.35;
    double absSlopeCompensation = 0.25;
    double directionThreshold = 2.0 / 3.6;
    double directionLaunchVelocity = 0.35;
    double neutralPulseSeconds = 0.08;
    double lowSpeedCutoff = 3.0 / 3.6;
    bool ignoreLowSpeedCutoff = false;
};

struct DriverAssistResult {
    bool applied = false;
    std::string mode = "NONE";
    double targetLongitudinalSpeed = 0.0;
    double brakeDelta = 0.0;
    int launchDirection = 0;
    std::string telemetry = "none";
};

bool isFinite(double value)
{
    return std::isfinite(value);
}

double clampValue(double value, double minimum, double maximum)
{
    return std::min(std::max(value, minimum), maximum);
}
```

- [ ] **Step 5: Add driver assist parse and format functions**

Add this code after the structures:

```cpp
bool parseDriverAssist(const char** args, unsigned int argsCount, DriverAssistInput& input)
{
    if (argsCount < 14) {
        return false;
    }

    input.state = args[0] == nullptr ? "" : args[0];
    input.requestedDirection = static_cast<int>(parseNumber(args[1]));
    input.longitudinalSpeed = parseNumber(args[2]);
    input.slope = parseNumber(args[3]);
    input.downhillAlignment = parseNumber(args[4]);
    input.deltaTime = parseNumber(args[5], 0.03);
    input.absBrakeStrength = parseNumber(args[6], 0.45);
    input.absReleaseBias = parseNumber(args[7], 0.35);
    input.absSlopeCompensation = parseNumber(args[8], 0.25);
    input.directionThreshold = parseNumber(args[9], 2.0 / 3.6);
    input.directionLaunchVelocity = parseNumber(args[10], 0.35);
    input.neutralPulseSeconds = parseNumber(args[11], 0.08);
    input.lowSpeedCutoff = parseNumber(args[12], 3.0 / 3.6);
    input.ignoreLowSpeedCutoff = parseNumber(args[13]) > 0.5;

    input.requestedDirection = static_cast<int>(clampValue(input.requestedDirection, -1.0, 1.0));
    input.slope = clampValue(input.slope, 0.0, 1.0);
    input.downhillAlignment = clampValue(input.downhillAlignment, -1.0, 1.0);
    input.deltaTime = clampValue(input.deltaTime, 0.001, 0.25);
    input.absBrakeStrength = clampValue(input.absBrakeStrength, 0.0, 5.0);
    input.absReleaseBias = clampValue(input.absReleaseBias, 0.0, 1.0);
    input.absSlopeCompensation = clampValue(input.absSlopeCompensation, 0.0, 5.0);
    input.directionThreshold = std::max(0.0, input.directionThreshold);
    input.directionLaunchVelocity = clampValue(input.directionLaunchVelocity, 0.0, 5.0);
    input.neutralPulseSeconds = clampValue(input.neutralPulseSeconds, 0.0, 1.0);
    input.lowSpeedCutoff = std::max(0.0, input.lowSpeedCutoff);

    return isFinite(input.longitudinalSpeed)
        && isFinite(input.slope)
        && isFinite(input.downhillAlignment)
        && isFinite(input.deltaTime)
        && isFinite(input.absBrakeStrength)
        && isFinite(input.absReleaseBias)
        && isFinite(input.absSlopeCompensation)
        && isFinite(input.directionThreshold)
        && isFinite(input.directionLaunchVelocity)
        && isFinite(input.neutralPulseSeconds)
        && isFinite(input.lowSpeedCutoff);
}

std::string formatDriverAssist(const DriverAssistResult& result)
{
    std::ostringstream payload;
    payload << "["
        << (result.applied ? "true" : "false")
        << "," << '"' << result.mode << '"'
        << "," << result.targetLongitudinalSpeed
        << "," << result.brakeDelta
        << "," << result.launchDirection
        << "," << '"' << result.telemetry << '"'
        << "]";
    return payload.str();
}
```

- [ ] **Step 6: Add the advisory driverAssist algorithm**

Add this function before `slopeControl`:

```cpp
std::string driverAssist(const char** args, unsigned int argsCount)
{
    DriverAssistInput input;
    if (!parseDriverAssist(args, argsCount, input)) {
        return "[false,\"NONE\",0,0,0,\"invalid\"]";
    }

    DriverAssistResult result;
    result.targetLongitudinalSpeed = input.longitudinalSpeed;

    const bool forwardMotion = input.longitudinalSpeed > 0.0;
    const bool reverseMotion = input.longitudinalSpeed < 0.0;
    const bool forwardIntent = input.requestedDirection > 0;
    const bool reverseIntent = input.requestedDirection < 0;
    const bool brakingForward = (reverseIntent || input.requestedDirection == 0) && forwardMotion;
    const bool brakingReverse = (forwardIntent || input.requestedDirection == 0) && reverseMotion;
    const bool isBraking = brakingForward || brakingReverse;
    const double speed = std::abs(input.longitudinalSpeed);

    if (!input.ignoreLowSpeedCutoff && speed <= input.lowSpeedCutoff) {
        result.telemetry = "below-cutoff";
        return formatDriverAssist(result);
    }

    if (!isBraking) {
        if ((input.state == "NEUTRAL" || input.state == "SERVICE_BRAKE")
            && input.requestedDirection != 0
            && speed <= input.directionThreshold) {
            result.applied = true;
            result.mode = "LAUNCH";
            result.launchDirection = input.requestedDirection;
            result.targetLongitudinalSpeed = input.requestedDirection * input.directionLaunchVelocity;
            result.telemetry = "launch";
        } else {
            result.telemetry = "no-brake";
        }
        return formatDriverAssist(result);
    }

    const double downhillLoad = brakingForward
        ? std::max(input.downhillAlignment, 0.0)
        : std::max(-input.downhillAlignment, 0.0);
    const double timeScale = input.deltaTime / 0.25;
    const double effectiveBrake = input.absBrakeStrength
        * (1.0 - input.absReleaseBias)
        * (1.0 + (downhillLoad * input.absSlopeCompensation))
        * timeScale;
    const double delta = std::min(std::max(effectiveBrake, 0.0), speed);

    if (delta <= 0.0) {
        result.telemetry = "zero-delta";
        return formatDriverAssist(result);
    }

    result.applied = true;
    result.mode = input.state == "SERVICE_BRAKE" ? "SERVICE_BRAKE" : "ABS";
    result.brakeDelta = delta;
    result.targetLongitudinalSpeed = brakingForward
        ? std::max(input.longitudinalSpeed - delta, 0.0)
        : std::min(input.longitudinalSpeed + delta, 0.0);
    result.launchDirection = 0;
    result.telemetry = "brake";
    return formatDriverAssist(result);
}
```

- [ ] **Step 7: Dispatch driverAssist and update schema**

In the `RVExtensionArgs` schema branch, replace the schema payload with:

```cpp
copyOutput(output, outputSize, "[\"slopeControl\",[\"downhillX\",\"downhillY\",\"velocityX\",\"velocityY\",\"slope\",\"maxRollbackSpeed\",\"rollbackAcceleration\",\"minimumDelta\"],\"driverAssist\",[\"state\",\"requestedDirection\",\"longitudinalSpeed\",\"slope\",\"downhillAlignment\",\"deltaTime\",\"absBrakeStrength\",\"absReleaseBias\",\"absSlopeCompensation\",\"directionThreshold\",\"directionLaunchVelocity\",\"neutralPulseSeconds\",\"lowSpeedCutoff\",\"ignoreLowSpeedCutoff\"]]");
return 0;
```

Add this dispatch before the unknown-command fallback:

```cpp
if (command == "driverAssist") {
    copyOutput(output, outputSize, driverAssist(args, argsCount));
    return 0;
}
```

- [ ] **Step 8: Bump the native interface version**

In `native/fixics_physics/src/FIXICSPhysics.cpp`, change:

```cpp
constexpr const char* FIXICS_VERSION = "FIXICSPhysics 0.2.0";
```

In `native/fixics_physics/CMakeLists.txt`, change:

```cmake
project(FIXICSPhysics VERSION 0.2.0 LANGUAGES CXX)
```

- [ ] **Step 9: Document driverAssist in the native README**

In `native/fixics_physics/README.md`, add this supported call below `slopeControl`:

```sqf
"FIXICSPhysics" callExtension ["driverAssist", [_state, _requestedDirection, _longitudinalSpeed, _slope, _downhillAlignment, _deltaTime, _absBrakeStrength, _absReleaseBias, _absSlopeCompensation, _directionThreshold, _directionLaunchVelocity, _neutralPulseSeconds, _lowSpeedCutoff, _ignoreLowSpeedCutoff]];
```

Add this paragraph after the `slopeControl` return documentation:

````markdown
`driverAssist` returns:

```sqf
[applied, mode, targetLongitudinalSpeed, brakeDelta, launchDirection, telemetry]
```

This is a native advisor only. SQF validates the result and remains responsible for all vehicle mutation.
````

- [ ] **Step 10: Run native tests and confirm GREEN**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools\build-native.ps1
```

Expected: build exits 0 and CTest reports `100% tests passed, 0 tests failed`.

- [ ] **Step 11: Run the static test and confirm native failures are reduced**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: failures remain for missing SQF bridge, settings, registration, and telemetry integration; failures about native source/README missing `driverAssist` should be gone.

- [ ] **Step 12: Commit native driver assist command**

Run:

```powershell
git add native\fixics_physics\src\FIXICSPhysics.cpp native\fixics_physics\tests\FIXICSPhysicsTests.cpp native\fixics_physics\CMakeLists.txt native\fixics_physics\README.md tools\build-native.ps1 FIXICSPhysics_x64.dll
git commit -m "Add native driver assist advisor"
```

---

### Task 3: SQF Bridge, Settings, Registration, And Strings

**Files:**
- Create: `addons/main/functions/fn_getNativeDriverAssist.sqf`
- Modify: `addons/main/config.cpp`
- Modify: `addons/main/functions/fn_registerSettings.sqf`
- Modify: `addons/main/stringtable.xml`

- [ ] **Step 1: Create the native driver assist SQF bridge**

Create `addons/main/functions/fn_getNativeDriverAssist.sqf`:

```sqf
/*
 * FIXICS_fnc_getNativeDriverAssist
 *
 * Requests a native driver-control recommendation for ABS and direction transitions.
 *
 * Arguments:
 *   0: Driver state <STRING>
 *   1: Requested direction: -1 reverse, 0 neutral/brake/coast, 1 drive <NUMBER>
 *   2: Longitudinal model-space speed in m/s <NUMBER>
 *   3: Slope magnitude <NUMBER>
 *   4: Downhill alignment relative to vehicle forward axis <NUMBER>
 *   5: Elapsed time since previous update <NUMBER>
 *   6: Ignore low-speed cutoff <BOOL>
 *
 * Return: <ARRAY> [mode, targetSpeed, brakeDelta, launchDirection, telemetry] or []
 * Locality: local machine
 *
 * Example:
 *   ["SERVICE_BRAKE", 1, -4, 0.1, -0.4, 0.03, true] call FIXICS_fnc_getNativeDriverAssist;
 */

params [
    ["_state", "COAST", [""]],
    ["_requestedDirection", 0, [0]],
    ["_longitudinalSpeed", 0, [0]],
    ["_slope", 0, [0]],
    ["_downhillAlignment", 0, [0]],
    ["_deltaTime", 0.03, [0]],
    ["_ignoreLowSpeedCutoff", false, [true]]
];

if !(missionNamespace getVariable ["FIXICS_nativeDriverAssistEnabled", false]) exitWith {
    []
};

private _absBrakeStrength = missionNamespace getVariable ["FIXICS_absBrakeStrength", 0.45];
private _absReleaseBias = missionNamespace getVariable ["FIXICS_absReleaseBias", 0.35];
private _absSlopeCompensation = missionNamespace getVariable ["FIXICS_absSlopeCompensation", 0.25];
private _directionThreshold = (missionNamespace getVariable ["FIXICS_directionChangeThresholdKmh", 2]) / 3.6;
private _directionLaunchVelocity = missionNamespace getVariable ["FIXICS_directionLaunchVelocity", 0.35];
private _neutralPulseSeconds = missionNamespace getVariable ["FIXICS_directionNeutralPulseSeconds", 0.08];
private _lowSpeedCutoff = (missionNamespace getVariable ["FIXICS_absLowSpeedCutoffKmh", 3]) / 3.6;

private _result = "FIXICSPhysics" callExtension [
    "driverAssist",
    [
        _state,
        str ((_requestedDirection max -1) min 1),
        str _longitudinalSpeed,
        str (_slope max 0),
        str ((_downhillAlignment max -1) min 1),
        str ((_deltaTime max 0.001) min 0.25),
        str _absBrakeStrength,
        str _absReleaseBias,
        str _absSlopeCompensation,
        str _directionThreshold,
        str _directionLaunchVelocity,
        str _neutralPulseSeconds,
        str _lowSpeedCutoff,
        str ([0, 1] select _ignoreLowSpeedCutoff)
    ]
];

_result params [
    ["_payload", "", [""]],
    ["_returnCode", 0, [0]],
    ["_errorCode", 0, [0]]
];

if (_errorCode != 0) exitWith {
    if (missionNamespace getVariable ["FIXICS_driverAssistDebugLogging", false]) then {
        diag_log format ["[FIXICS_fnc_getNativeDriverAssist] Extension errorCode %1.", _errorCode];
    };
    []
};

if (_returnCode != 0) exitWith {
    if (missionNamespace getVariable ["FIXICS_driverAssistDebugLogging", false]) then {
        diag_log format ["[FIXICS_fnc_getNativeDriverAssist] Extension returnCode %1 payload %2.", _returnCode, _payload];
    };
    []
};

private _parsed = [];
try {
    _parsed = parseSimpleArray _payload;
} catch {
    if (missionNamespace getVariable ["FIXICS_driverAssistDebugLogging", false]) then {
        diag_log format ["[FIXICS_fnc_getNativeDriverAssist] Invalid extension payload: %1", _payload];
    };
};

if ((count _parsed) < 6) exitWith {
    []
};

_parsed params [
    ["_applied", false, [false]],
    ["_mode", "NONE", [""]],
    ["_targetLongitudinalSpeed", 0, [0]],
    ["_brakeDelta", 0, [0]],
    ["_launchDirection", 0, [0]],
    ["_telemetry", "", [""]]
];

if (
    !(_applied isEqualType false)
    || {!(_mode isEqualType "")}
    || {!(_targetLongitudinalSpeed isEqualType 0)}
    || {!(_brakeDelta isEqualType 0)}
    || {!(_launchDirection isEqualType 0)}
    || {!(_telemetry isEqualType "")}
) exitWith {
    []
};

if (!_applied) exitWith {
    []
};

private _finite = {
    params ["_value"];
    !(_value isEqualTo 1e39) && {!(_value isEqualTo -1e39)} && {_value == _value}
};

if (!([_targetLongitudinalSpeed] call _finite) || {!([_brakeDelta] call _finite)}) exitWith {
    []
};

private _maxTargetSpeed = (abs _longitudinalSpeed)
    max ((missionNamespace getVariable ["FIXICS_directionLaunchVelocity", 0.35]) + 0.01);
if ((abs _targetLongitudinalSpeed) > _maxTargetSpeed) exitWith {
    []
};

if (_brakeDelta < 0 || {_brakeDelta > ((abs _longitudinalSpeed) + 0.01)}) exitWith {
    []
};

if (!(_mode in ["ABS", "SERVICE_BRAKE", "NEUTRAL", "LAUNCH"])) exitWith {
    []
};

_launchDirection = round ((_launchDirection max -1) min 1);

[_mode, _targetLongitudinalSpeed, _brakeDelta, _launchDirection, _telemetry]
```

- [ ] **Step 2: Register the new bridge in CfgFunctions**

In `addons/main/config.cpp`, add this line in `class Main` after `class getNativeSlopeControl {};`:

```cpp
class getNativeDriverAssist {};
```

- [ ] **Step 3: Add CBA default values and settings**

In `addons/main/functions/fn_registerSettings.sqf`, add defaults after `FIXICS_nativeSlopeControlEnabled`:

```sqf
missionNamespace setVariable ["FIXICS_nativeDriverAssistEnabled", false, false];
missionNamespace setVariable ["FIXICS_driverAssistDebugLogging", false, false];
```

Add these CBA settings after the native slope control checkbox:

```sqf
[
    "FIXICS_nativeDriverAssistEnabled",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_NATIVE_DRIVER_ASSIST",
        localize "STR_FIXICS_SETTING_NATIVE_DRIVER_ASSIST_TOOLTIP"
    ],
    "FIXICS",
    false,
    1
] call CBA_fnc_addSetting;

[
    "FIXICS_driverAssistDebugLogging",
    "CHECKBOX",
    [
        localize "STR_FIXICS_SETTING_DRIVER_ASSIST_DEBUG_LOGGING",
        localize "STR_FIXICS_SETTING_DRIVER_ASSIST_DEBUG_LOGGING_TOOLTIP"
    ],
    ["FIXICS", "Driver Controller"],
    false,
    1
] call CBA_fnc_addSetting;
```

- [ ] **Step 4: Add stringtable keys**

In `addons/main/stringtable.xml`, add these keys after `STR_FIXICS_SETTING_NATIVE_SLOPE_CONTROL_TOOLTIP`:

```xml
<Key ID="STR_FIXICS_SETTING_NATIVE_DRIVER_ASSIST">
    <Original>Enable native driver assist</Original>
</Key>
<Key ID="STR_FIXICS_SETTING_NATIVE_DRIVER_ASSIST_TOOLTIP">
    <Original>Uses the optional FIXICSPhysics native extension for ABS and Drive/Reverse controller recommendations. SQF fallback remains active when disabled or unavailable.</Original>
</Key>
<Key ID="STR_FIXICS_SETTING_DRIVER_ASSIST_DEBUG_LOGGING">
    <Original>Driver assist debug logging</Original>
</Key>
<Key ID="STR_FIXICS_SETTING_DRIVER_ASSIST_DEBUG_LOGGING_TOOLTIP">
    <Original>Writes compact native driver assist and SQF fallback decisions to the RPT log for SQA tuning.</Original>
</Key>
```

- [ ] **Step 5: Run the static test and confirm remaining RED is integration-only**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: failures remain for `FIXICS_fnc_getNativeDriverAssist` not being used in `fn_applyABSBraking.sqf` and `fn_updateDriverController.sqf`; bridge/settings/registration failures should be gone.

- [ ] **Step 6: Commit bridge and settings**

Run:

```powershell
git add addons\main\functions\fn_getNativeDriverAssist.sqf addons\main\config.cpp addons\main\functions\fn_registerSettings.sqf addons\main\stringtable.xml
git commit -m "Add native driver assist bridge"
```

---

### Task 4: ABS Native Assist Integration And Telemetry

**Files:**
- Modify: `addons/main/functions/fn_applyABSBraking.sqf`

- [ ] **Step 1: Extract SQF fallback into a local closure**

Inside `fn_applyABSBraking.sqf`, after `_deltaTime` and all slope/downhill context is calculated, wrap the existing brake-strength calculation and `setVelocityModelSpace` mutation in a closure named `_applySqfAbsFallback`.

Use this closure:

```sqf
private _logDriverAssist = {
    params ["_source", "_mode", "_targetSpeed", "_delta", "_detail"];

    if (missionNamespace getVariable ["FIXICS_driverAssistDebugLogging", false]) then {
        diag_log format [
            "FIXICS driverAssist: state=SERVICE_BRAKE mode=%1 source=%2 speed=%3 target=%4 delta=%5 slope=%6 requestedDirection=%7 detail=%8",
            _mode,
            _source,
            _longitudinalSpeed,
            _targetSpeed,
            _delta,
            _slope,
            _requestedDirection,
            _detail
        ];
    };
};

private _applySqfAbsFallback = {
    private _slopeCompensation = missionNamespace getVariable ["FIXICS_absSlopeCompensation", 0.25];
    private _downhillBrakeLoad = if (_isForwardBraking) then {
        _downhillAlignment max 0
    } else {
        (-_downhillAlignment) max 0
    };

    private _brakeStrength = missionNamespace getVariable ["FIXICS_absBrakeStrength", 0.45];
    private _releaseBias = missionNamespace getVariable ["FIXICS_absReleaseBias", 0.35];
    private _timeScale = ((_deltaTime max 0.001) min 0.25) / 0.25;
    private _effectiveBrake = _brakeStrength
        * (1 - _releaseBias)
        * (1 + (_downhillBrakeLoad * _slopeCompensation))
        * _timeScale;
    private _delta = _effectiveBrake min (abs _longitudinalSpeed);
    if (_delta <= 0) exitWith {
        false
    };

    private _newLongitudinalSpeed = if (_isForwardBraking) then {
        (_longitudinalSpeed - _delta) max 0
    } else {
        (_longitudinalSpeed + _delta) min 0
    };
    _modelVelocity set [1, _newLongitudinalSpeed];
    _vehicle setVelocityModelSpace _modelVelocity;

    if (missionNamespace getVariable ["FIXICS_absDebugLogging", false]) then {
        diag_log format [
            "FIXICS ABS: type=%1 requestedDirection=%2 speedKmh=%3 longitudinalMps=%4 delta=%5 slope=%6 downhillLoad=%7",
            typeOf _vehicle,
            _requestedDirection,
            _speedKmh,
            _longitudinalSpeed,
            _delta,
            _slope,
            _downhillBrakeLoad
        ];
    };

    ["sqf", "ABS", _newLongitudinalSpeed, _delta, "fallback"] call _logDriverAssist;
    true
};
```

Replace the old inline SQF brake calculation with:

```sqf
call _applySqfAbsFallback
```

- [ ] **Step 2: Add native assist before SQF fallback**

Before `call _applySqfAbsFallback`, add:

```sqf
private _nativeAssist = [
    "SERVICE_BRAKE",
    _requestedDirection,
    _longitudinalSpeed,
    _slope,
    _downhillAlignment,
    _deltaTime,
    _ignoreLowSpeedCutoff
] call FIXICS_fnc_getNativeDriverAssist;

if ((count _nativeAssist) > 0) exitWith {
    _nativeAssist params [
        ["_nativeMode", "NONE", [""]],
        ["_nativeTargetSpeed", _longitudinalSpeed, [0]],
        ["_nativeBrakeDelta", 0, [0]],
        ["_nativeLaunchDirection", 0, [0]],
        ["_nativeTelemetry", "", [""]]
    ];

    if (!(_nativeMode in ["ABS", "SERVICE_BRAKE"])) exitWith {
        call _applySqfAbsFallback
    };

    if (_isForwardBraking && {_nativeTargetSpeed > _longitudinalSpeed}) exitWith {
        call _applySqfAbsFallback
    };

    if (_isReverseBraking && {_nativeTargetSpeed < _longitudinalSpeed}) exitWith {
        call _applySqfAbsFallback
    };

    _modelVelocity set [1, _nativeTargetSpeed];
    _vehicle setVelocityModelSpace _modelVelocity;
    ["native", _nativeMode, _nativeTargetSpeed, _nativeBrakeDelta, _nativeTelemetry] call _logDriverAssist;
    true
};

call _applySqfAbsFallback
```

- [ ] **Step 3: Remove the superseded trailing ABS debug block**

Delete the original trailing `FIXICS_absDebugLogging` block after moving the same logging into `_applySqfAbsFallback`. This preserves existing SQF fallback diagnostics without referencing closure-local variables outside their scope.

- [ ] **Step 4: Run static test**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: ABS helper failures should be gone; driver-controller integration failures may remain.

- [ ] **Step 5: Run HEMTT check**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools\check.ps1
```

Expected: HEMTT exits 0 and compiles all SQF files.

- [ ] **Step 6: Commit ABS integration**

Run:

```powershell
git add addons\main\functions\fn_applyABSBraking.sqf
git commit -m "Use native assist for ABS braking"
```

---

### Task 5: Driver Controller Native Assist Integration

**Files:**
- Modify: `addons/main/functions/fn_updateDriverController.sqf`

- [ ] **Step 1: Add shared driver-assist telemetry closure**

In `fn_updateDriverController.sqf`, after `_setState`, add:

```sqf
private _logDriverAssist = {
    params ["_state", "_source", "_mode", "_speed", "_targetSpeed", "_delta", "_slope", "_direction", "_detail"];

    if (missionNamespace getVariable ["FIXICS_driverAssistDebugLogging", false]) then {
        diag_log format [
            "FIXICS driverAssist: state=%1 mode=%2 source=%3 speed=%4 target=%5 delta=%6 slope=%7 requestedDirection=%8 detail=%9",
            _state,
            _mode,
            _source,
            _speed,
            _targetSpeed,
            _delta,
            _slope,
            _direction,
            _detail
        ];
    };
};
```

- [ ] **Step 2: Compute slope context once for the controller**

After `_longitudinalSpeed` is first assigned from `velocityModelSpace`, add:

```sqf
private _normal = surfaceNormal (getPosASL _vehicle);
private _normalZ = ((_normal # 2) max -1) min 1;
private _slopeAngleDegrees = acos _normalZ;
private _slope = sin _slopeAngleDegrees;
private _vehicleForward = vectorDir _vehicle;
private _forward = [_vehicleForward # 0, _vehicleForward # 1, 0];
private _forwardLength = sqrt (((_forward # 0) * (_forward # 0)) + ((_forward # 1) * (_forward # 1)));
private _downhillAlignment = 0;
if (_forwardLength > 0) then {
    _forward = _forward vectorMultiply (1 / _forwardLength);
    private _downhill = [_normal # 0, _normal # 1, 0];
    private _downhillLength = sqrt (((_downhill # 0) * (_downhill # 0)) + ((_downhill # 1) * (_downhill # 1)));
    if (_downhillLength > 0) then {
        _downhill = _downhill vectorMultiply (1 / _downhillLength);
        _downhillAlignment = ((_downhill # 0) * (_forward # 0)) + ((_downhill # 1) * (_forward # 1));
    };
};
```

- [ ] **Step 3: Add native assist helper closure**

After the slope context, add:

```sqf
private _getDriverAssist = {
    params ["_state", "_direction", "_speed", "_ignoreLowSpeedCutoff"];

    [
        _state,
        _direction,
        _speed,
        _slope,
        _downhillAlignment,
        _deltaTime,
        _ignoreLowSpeedCutoff
    ] call FIXICS_fnc_getNativeDriverAssist
};
```

- [ ] **Step 4: Keep direction-transition braking on the ABS helper path**

Do not add a second direct native call in the controller's service-brake branch. Keep this existing call as the single braking path because `FIXICS_fnc_applyABSBraking` now performs native-first braking and SQF fallback:

```sqf
private _absApplied = [
    _vehicle,
    _transitionTarget,
    true,
    _deltaTime
] call FIXICS_fnc_applyABSBraking;
```

- [ ] **Step 5: Preserve neutral pulse and native launch recommendation**

In the `_neutralUntil > 0` branch, keep `_modelVelocity set [1, 0]` and the `_now >= _neutralUntil` gate unchanged. Inside the `_now >= _neutralUntil` block, before setting launch velocity, add:

```sqf
private _launchSpeed = _transitionTarget * _launchVelocity;
private _nativeAssist = ["NEUTRAL", _transitionTarget, 0, true] call _getDriverAssist;
if ((count _nativeAssist) > 0) then {
    _nativeAssist params [
        ["_nativeMode", "NONE", [""]],
        ["_nativeTargetSpeed", _launchSpeed, [0]],
        ["_nativeBrakeDelta", 0, [0]],
        ["_nativeLaunchDirection", 0, [0]],
        ["_nativeTelemetry", "", [""]]
    ];

    if (_nativeMode == "LAUNCH" && {_nativeLaunchDirection == _transitionTarget}) then {
        _launchSpeed = _nativeTargetSpeed;
        ["NEUTRAL", "native", _nativeMode, 0, _nativeTargetSpeed, _nativeBrakeDelta, _slope, _transitionTarget, _nativeTelemetry] call _logDriverAssist;
    };
};
```

Then replace:

```sqf
_modelVelocity set [1, _transitionTarget * _launchVelocity];
```

with:

```sqf
_modelVelocity set [1, _launchSpeed];
```

- [ ] **Step 6: Add telemetry for SQF fallback service braking**

In both fallback braking blocks that calculate `_fallbackBrake`, after `_vehicle setVelocityModelSpace _modelVelocity;`, add:

```sqf
["SERVICE_BRAKE", "sqf", "SERVICE_BRAKE", _longitudinalSpeed, _modelVelocity # 1, _fallbackBrake, _slope, _transitionTarget, "fallback"] call _logDriverAssist;
```

For the combined W+S branch, use direction `0`:

```sqf
["SERVICE_BRAKE", "sqf", "SERVICE_BRAKE", _longitudinalSpeed, _modelVelocity # 1, _fallbackBrake, _slope, 0, "fallback"] call _logDriverAssist;
```

- [ ] **Step 7: Run static test**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
```

Expected: vehicle physics static test passes.

- [ ] **Step 8: Run HEMTT check**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools\check.ps1
```

Expected: HEMTT exits 0 and compiles all SQF files.

- [ ] **Step 9: Commit driver-controller integration**

Run:

```powershell
git add addons\main\functions\fn_updateDriverController.sqf
git commit -m "Use native assist for direction transitions"
```

---

### Task 6: Documentation, Workaround Record, And Final Verification

**Files:**
- Modify: `docs/fixes/workaround-registry.md`
- No implementation edit: `docs/fixes/fix-log.md`

- [ ] **Step 1: Update WA-002**

In `docs/fixes/workaround-registry.md`, update WA-002 `What it does` to mention native advice:

```markdown
When `FIXICS_nativeDriverAssistEnabled` is enabled and the optional DLL is installed, the controller can request native ABS and direction-transition recommendations. SQF still validates every recommendation and remains responsible for vehicle mutation. When native assist is disabled or unavailable, the current SQF fallback path remains active.
```

Add this review trigger:

```markdown
Review when changing the `driverAssist` native payload schema, enabling multiplayer authority, or replacing the SQF fallback.
```

- [ ] **Step 2: Defer fix-log entry until manual SQA**

Do not add a final `docs/fixes/fix-log.md` entry until SQA has manually tested native assist enabled and disabled. Leave a note in the PR body that fix-log completion is pending SQA verification.

- [ ] **Step 3: Run full automated verification**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-governance-static.ps1
powershell -ExecutionPolicy Bypass -File tests\integration\fixics-vehicle-physics-static.ps1
powershell -ExecutionPolicy Bypass -File tools\check.ps1
powershell -ExecutionPolicy Bypass -File tools\build-native.ps1
git diff --check
```

Expected:

- governance static test passed;
- vehicle physics static test passed;
- HEMTT compiles SQF and checks stringtable;
- native DLL builds;
- diff check exits 0, with only CRLF warnings acceptable.

- [ ] **Step 4: Record native runtime smoke-test status**

The repository has no standalone non-Arma extension runner. Record this in the handoff:

```text
Native runtime smoke was not run outside Arma because the repository does not include a standalone callExtension harness. Native runtime behavior requires Arma manual validation with FIXICSPhysics_x64.dll installed.
```

- [ ] **Step 5: Commit documentation update**

Run:

```powershell
git add docs\fixes\workaround-registry.md
git commit -m "Document native driver assist workaround"
```

- [ ] **Step 6: Prepare SQA manual test notes**

Report this exact manual matrix to SQA:

```text
Native assist disabled:
- ABS braking still feels like current accepted behavior.
- Reverse-to-Drive still responds with the current accepted delay.
- Drive-to-Reverse remains controlled.
- ACE handbrake hard-locks and overrides W/S.

Native assist enabled with FIXICSPhysics_x64.dll installed:
- ABS remains smooth.
- Reverse-to-Drive delay is same or better.
- Drive-to-Reverse does not skip neutral behavior.
- ACE handbrake hard-locks and overrides W/S.
- RPT telemetry is silent by default.
- RPT telemetry appears when FIXICS_driverAssistDebugLogging is enabled.
```

- [ ] **Step 7: Completion handoff**

Before claiming completion, use `superpowers:verification-before-completion` and report:

- branch name;
- commit list;
- automated verification commands and results;
- whether native runtime smoke was possible;
- SQA manual test matrix;
- any remaining gaps.
