#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdlib>
#include <cstring>
#include <locale>
#include <sstream>
#include <string>

#ifdef _WIN32
#define FIXICS_EXPORT __declspec(dllexport)
#define FIXICS_CALL __stdcall
#else
#define FIXICS_EXPORT __attribute__((visibility("default")))
#define FIXICS_CALL
#endif

namespace {
constexpr const char* FIXICS_VERSION = "FIXICSPhysics 0.2.0";

struct DriverAssistInput {
    std::string state;
    int requestedDirection;
    double longitudinalSpeed;
    double slope;
    double downhillAlignment;
    double deltaTime;
    double absBrakeStrength;
    double absReleaseBias;
    double absSlopeCompensation;
    double directionThreshold;
    double directionLaunchVelocity;
    double neutralPulseSeconds;
    double lowSpeedCutoff;
    bool ignoreLowSpeedCutoff;
};

struct DriverAssistResult {
    bool applied;
    std::string mode;
    double targetLongitudinalSpeed;
    double brakeDelta;
    int launchDirection;
    std::string telemetry;
};

void copyOutput(char* output, unsigned int outputSize, const std::string& value)
{
    if (output == nullptr || outputSize == 0) {
        return;
    }

    const auto copyLength = std::min<std::size_t>(value.size(), outputSize - 1);
    std::memcpy(output, value.c_str(), copyLength);
    output[copyLength] = '\0';
}

double parseNumber(const char* value, double fallback = 0.0)
{
    if (value == nullptr) {
        return fallback;
    }

    char* end = nullptr;
    const double parsed = std::strtod(value, &end);
    if (end == value) {
        return fallback;
    }

    return parsed;
}

bool isFinite(double value)
{
    return std::isfinite(value);
}

bool parseStrictNumber(const char* value, double& parsed)
{
    if (value == nullptr || value[0] == '\0') {
        return false;
    }

    std::istringstream input(value);
    input.imbue(std::locale::classic());
    input >> parsed;
    if (input.fail() || !isFinite(parsed)) {
        return false;
    }

    input >> std::ws;
    return input.eof();
}

double clampValue(double value, double minimum, double maximum)
{
    return std::max(minimum, std::min(value, maximum));
}

bool parseDriverAssist(const char** args, unsigned int argsCount, DriverAssistInput& input)
{
    if (args == nullptr || argsCount < 14 || args[0] == nullptr) {
        return false;
    }

    double values[13] = {};
    for (unsigned int index = 0; index < 13; ++index) {
        if (!parseStrictNumber(args[index + 1], values[index])) {
            return false;
        }
    }

    input.state = args[0];
    input.requestedDirection = values[0] > 0.0 ? 1 : (values[0] < 0.0 ? -1 : 0);
    input.longitudinalSpeed = values[1];
    input.slope = clampValue(values[2], 0.0, 1.0);
    input.downhillAlignment = clampValue(values[3], -1.0, 1.0);
    input.deltaTime = clampValue(values[4], 0.0, 1.0);
    input.absBrakeStrength = clampValue(values[5], 0.0, 100.0);
    input.absReleaseBias = clampValue(values[6], 0.0, 1.0);
    input.absSlopeCompensation = clampValue(values[7], 0.0, 10.0);
    input.directionThreshold = clampValue(values[8], 0.0, 100.0);
    input.directionLaunchVelocity = clampValue(values[9], 0.0, 100.0);
    input.neutralPulseSeconds = clampValue(values[10], 0.0, 10.0);
    input.lowSpeedCutoff = clampValue(values[11], 0.0, 100.0);
    input.ignoreLowSpeedCutoff = values[12] != 0.0;
    return true;
}

std::string formatNumber(double value)
{
    if (std::abs(value) < 1e-12) {
        value = 0.0;
    }

    std::ostringstream output;
    output.imbue(std::locale::classic());
    output.precision(12);
    output << value;
    return output.str();
}

std::string formatDriverAssist(const DriverAssistResult& result)
{
    std::ostringstream payload;
    payload.imbue(std::locale::classic());
    payload
        << '[' << (result.applied ? "true" : "false")
        << ",\"" << result.mode << "\""
        << ',' << formatNumber(result.targetLongitudinalSpeed)
        << ',' << formatNumber(result.brakeDelta)
        << ',' << result.launchDirection
        << ",\"" << result.telemetry << "\"]";
    return payload.str();
}

std::string driverAssist(const char** args, unsigned int argsCount)
{
    DriverAssistInput input {};
    if (!parseDriverAssist(args, argsCount, input)) {
        return formatDriverAssist({false, "NONE", 0.0, 0.0, 0, "invalid"});
    }

    const double speedMagnitude = std::abs(input.longitudinalSpeed);
    if (!input.ignoreLowSpeedCutoff && speedMagnitude <= input.lowSpeedCutoff) {
        return formatDriverAssist({false, "NONE", input.longitudinalSpeed, 0.0, 0, "below-cutoff"});
    }

    const bool launchState = input.state == "NEUTRAL" || input.state == "SERVICE_BRAKE";
    if (launchState && input.requestedDirection != 0 && speedMagnitude <= input.directionThreshold) {
        const double target = input.requestedDirection * input.directionLaunchVelocity;
        return formatDriverAssist({true, "LAUNCH", target, 0.0, input.requestedDirection, "launch"});
    }

    if (input.state == "SERVICE_BRAKE" || input.state == "ABS") {
        const double downhillLoad = clampValue(
            input.slope * std::max(0.0, input.downhillAlignment),
            0.0,
            1.0);
        const double effectiveBrake =
            input.absBrakeStrength *
            (1.0 - input.absReleaseBias) *
            (1.0 + (downhillLoad * input.absSlopeCompensation)) *
            (input.deltaTime / 0.25);
        const double brakeDelta = std::min(speedMagnitude, std::max(0.0, effectiveBrake));
        const double target = input.longitudinalSpeed >= 0.0
            ? input.longitudinalSpeed - brakeDelta
            : input.longitudinalSpeed + brakeDelta;
        const std::string mode = input.state == "ABS" ? "ABS" : "SERVICE_BRAKE";
        return formatDriverAssist({brakeDelta > 0.0, mode, target, brakeDelta, 0, "brake"});
    }

    return formatDriverAssist({false, "NONE", input.longitudinalSpeed, 0.0, 0, "none"});
}

std::string slopeControl(const char** args, unsigned int argsCount)
{
    if (argsCount < 7) {
        return "[false,0,0,0]";
    }

    const double downhillX = parseNumber(args[0]);
    const double downhillY = parseNumber(args[1]);
    const double velocityX = parseNumber(args[2]);
    const double velocityY = parseNumber(args[3]);
    const double slope = parseNumber(args[4]);
    const double maxRollbackSpeed = parseNumber(args[5]);
    const double rollbackAcceleration = parseNumber(args[6]);
    const double minimumDelta = argsCount >= 8 ? std::max(0.0, parseNumber(args[7])) : 0.0;

    const double downhillLength = std::sqrt((downhillX * downhillX) + (downhillY * downhillY));
    if (downhillLength <= 0.0 || slope <= 0.0 || maxRollbackSpeed <= 0.0 || rollbackAcceleration <= 0.0) {
        return "[false,0,0,0]";
    }

    const double normalizedX = downhillX / downhillLength;
    const double normalizedY = downhillY / downhillLength;
    const double downhillSpeed = (velocityX * normalizedX) + (velocityY * normalizedY);

    if (downhillSpeed >= maxRollbackSpeed) {
        return "[false,0,0,0]";
    }

    const double remainingSpeed = maxRollbackSpeed - downhillSpeed;
    double delta = std::min(rollbackAcceleration * std::max(slope, 0.15), remainingSpeed);
    if (minimumDelta > 0.0 && std::abs(downhillSpeed) <= minimumDelta) {
        delta = std::min(std::max(delta, minimumDelta), remainingSpeed);
    }

    if (delta <= 0.0) {
        return "[false,0,0,0]";
    }

    std::ostringstream payload;
    payload << "[true," << (normalizedX * delta) << "," << (normalizedY * delta) << ",0]";
    return payload.str();
}
}

extern "C" {
FIXICS_EXPORT void FIXICS_CALL RVExtensionVersion(char* output, unsigned int outputSize)
{
    copyOutput(output, outputSize, FIXICS_VERSION);
}

FIXICS_EXPORT void FIXICS_CALL RVExtension(char* output, unsigned int outputSize, const char* function)
{
    const std::string input = function == nullptr ? "" : function;
    if (input == "version") {
        copyOutput(output, outputSize, FIXICS_VERSION);
        return;
    }

    if (input == "ping") {
        copyOutput(output, outputSize, "pong");
        return;
    }

    copyOutput(output, outputSize, "FIXICSPhysics");
}

FIXICS_EXPORT int FIXICS_CALL RVExtensionArgs(
    char* output,
    unsigned int outputSize,
    const char* function,
    const char** args,
    unsigned int argsCount)
{
    const std::string command = function == nullptr ? "" : function;

    if (command == "version") {
        copyOutput(output, outputSize, FIXICS_VERSION);
        return 0;
    }

    if (command == "ping") {
        copyOutput(output, outputSize, "pong");
        return 0;
    }

    if (command == "schema") {
        copyOutput(output, outputSize, "[\"slopeControl\",[\"downhillX\",\"downhillY\",\"velocityX\",\"velocityY\",\"slope\",\"maxRollbackSpeed\",\"rollbackAcceleration\",\"minimumDelta\"],\"driverAssist\",[\"state\",\"requestedDirection\",\"longitudinalSpeed\",\"slope\",\"downhillAlignment\",\"deltaTime\",\"absBrakeStrength\",\"absReleaseBias\",\"absSlopeCompensation\",\"directionThreshold\",\"directionLaunchVelocity\",\"neutralPulseSeconds\",\"lowSpeedCutoff\",\"ignoreLowSpeedCutoff\"]]");
        return 0;
    }

    if (command == "slopeControl") {
        copyOutput(output, outputSize, slopeControl(args, argsCount));
        return 0;
    }

    if (command == "driverAssist") {
        copyOutput(output, outputSize, driverAssist(args, argsCount));
        return 0;
    }

    copyOutput(output, outputSize, "Unknown FIXICSPhysics command");
    return 1;
}
}
