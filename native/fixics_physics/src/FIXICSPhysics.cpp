#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdlib>
#include <cstring>
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
constexpr const char* FIXICS_VERSION = "FIXICSPhysics 0.1.0";

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
        copyOutput(output, outputSize, "[\"slopeControl\",[\"downhillX\",\"downhillY\",\"velocityX\",\"velocityY\",\"slope\",\"maxRollbackSpeed\",\"rollbackAcceleration\",\"minimumDelta\"]]");
        return 0;
    }

    if (command == "slopeControl") {
        copyOutput(output, outputSize, slopeControl(args, argsCount));
        return 0;
    }

    copyOutput(output, outputSize, "Unknown FIXICSPhysics command");
    return 1;
}
}
