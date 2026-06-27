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

struct TerrainTireInput {
    int terrainClass;
    double speedKmh;
    double throttleDemand;
    double brakeDemand;
    double steeringDemand;
    double slopeSeverity;
    double massKg;
    double deltaTime;
    double tireAirState;
    double tireDamage;
    bool grounded;
    double lastGroundedAge;
    double vectorUpZ;
    double airborneGraceWindow;
    bool driverlessDecayEnabled;
    double driverlessDecayCap;
    double destroyedTireThreshold;
    int destroyedTireCount;
};

struct TerrainTireResult {
    bool applied;
    double tractionMultiplier;
    double accelerationTractionMultiplier;
    double brakingTractionMultiplier;
    double turningTractionMultiplier;
    double slopeTractionMultiplier;
    double wheelspinEstimate;
    double tireAirState;
    double tireDragPenalty;
    double tireSteeringPenalty;
    double massModifier;
    std::string wheelSupportState;
    bool rolloverSuppressed;
    double driverlessDecay;
    int destroyedTireCount;
    double destroyedTireRatio;
    double destroyedTirePenalty;
    double mobilityLimiter;
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

std::string formatTerrainTire(const TerrainTireResult& result)
{
    std::ostringstream payload;
    payload.imbue(std::locale::classic());
    payload
        << '[' << (result.applied ? "true" : "false")
        << ',' << formatNumber(result.tractionMultiplier)
        << ',' << formatNumber(result.accelerationTractionMultiplier)
        << ',' << formatNumber(result.brakingTractionMultiplier)
        << ',' << formatNumber(result.turningTractionMultiplier)
        << ',' << formatNumber(result.slopeTractionMultiplier)
        << ',' << formatNumber(result.wheelspinEstimate)
        << ',' << formatNumber(result.tireAirState)
        << ',' << formatNumber(result.tireDragPenalty)
        << ',' << formatNumber(result.tireSteeringPenalty)
        << ',' << formatNumber(result.massModifier)
        << ",\"" << result.wheelSupportState << "\""
        << ',' << (result.rolloverSuppressed ? "true" : "false")
        << ',' << formatNumber(result.driverlessDecay)
        << ',' << result.destroyedTireCount
        << ',' << formatNumber(result.destroyedTireRatio)
        << ',' << formatNumber(result.destroyedTirePenalty)
        << ',' << formatNumber(result.mobilityLimiter)
        << ",\"" << result.telemetry << "\"]";
    return payload.str();
}

bool parseTerrainTire(const char** args, unsigned int argsCount, TerrainTireInput& input)
{
    if (args == nullptr || argsCount < 18) {
        return false;
    }

    double values[18] = {};
    for (unsigned int index = 0; index < 18; ++index) {
        if (!parseStrictNumber(args[index], values[index])) {
            return false;
        }
    }

    input.terrainClass = static_cast<int>(std::round(values[0]));
    input.speedKmh = clampValue(values[1], 0.0, 400.0);
    input.throttleDemand = clampValue(values[2], 0.0, 1.0);
    input.brakeDemand = clampValue(values[3], 0.0, 1.0);
    input.steeringDemand = clampValue(values[4], 0.0, 1.0);
    input.slopeSeverity = clampValue(values[5], 0.0, 1.0);
    input.massKg = clampValue(values[6], 100.0, 100000.0);
    input.deltaTime = clampValue(values[7], 0.001, 1.0);
    input.tireAirState = clampValue(values[8], 0.0, 1.0);
    input.tireDamage = clampValue(values[9], 0.0, 1.0);
    input.grounded = values[10] != 0.0;
    input.lastGroundedAge = clampValue(values[11], 0.0, 999.0);
    input.vectorUpZ = clampValue(values[12], -1.0, 1.0);
    input.airborneGraceWindow = clampValue(values[13], 0.0, 1.0);
    input.driverlessDecayEnabled = values[14] != 0.0;
    input.driverlessDecayCap = clampValue(values[15], 0.0, 1.0);
    input.destroyedTireThreshold = clampValue(values[16], 0.5, 1.0);
    input.destroyedTireCount = static_cast<int>(clampValue(std::round(values[17]), 0.0, 16.0));
    return true;
}

TerrainTireResult invalidTerrainTire()
{
    return {
        false,
        1.0,
        1.0,
        1.0,
        1.0,
        1.0,
        0.0,
        1.0,
        0.0,
        0.0,
        1.0,
        "UNKNOWN",
        false,
        0.0,
        0,
        0.0,
        0.0,
        1.0,
        "invalid"
    };
}

std::string terrainTireV2(const char** args, unsigned int argsCount)
{
    TerrainTireInput input {};
    if (!parseTerrainTire(args, argsCount, input)) {
        return formatTerrainTire(invalidTerrainTire());
    }

    double terrainBase = 0.84;
    double wheelspinBase = 0.18;
    double roughness = 0.02;
    double looseAmplifier = 1.0;
    switch (input.terrainClass) {
        case 0:
            terrainBase = 1.0;
            wheelspinBase = 0.08;
            roughness = 0.02;
            looseAmplifier = 1.0;
            break;
        case 1:
            terrainBase = 0.78;
            wheelspinBase = 0.28;
            roughness = 0.08;
            looseAmplifier = 1.15;
            break;
        case 2:
            terrainBase = 0.66;
            wheelspinBase = 0.38;
            roughness = 0.10;
            looseAmplifier = 1.25;
            break;
        case 3:
            terrainBase = 0.52;
            wheelspinBase = 0.55;
            roughness = 0.12;
            looseAmplifier = 1.35;
            break;
        case 4:
            terrainBase = 0.70;
            wheelspinBase = 0.34;
            roughness = 0.22;
            looseAmplifier = 1.20;
            break;
        default:
            break;
    }

    std::string wheelSupportState = "SUPPORTED";
    if (!input.grounded) {
        wheelSupportState = input.lastGroundedAge <= input.airborneGraceWindow
            ? "AIRBORNE_GRACE"
            : "AIRBORNE";
    }
    if (input.grounded && input.vectorUpZ < -0.25) {
        wheelSupportState = "FLIPPED";
    }
    if (input.grounded && input.vectorUpZ >= -0.25 && input.vectorUpZ < 0.35) {
        wheelSupportState = "SIDE_UNSUPPORTED";
    }
    const bool rolloverSuppressed =
        wheelSupportState == "AIRBORNE" ||
        wheelSupportState == "FLIPPED" ||
        wheelSupportState == "SIDE_UNSUPPORTED";

    const double massModifier = clampValue(1.08 + ((input.massKg - 900.0) * ((0.72 - 1.08) / (4500.0 - 900.0))), 0.72, 1.08);
    const double speedDemand = clampValue((input.speedKmh - 10.0) / 90.0, 0.0, 1.0);
    const double accelDemand = clampValue(input.throttleDemand * (1.0 - terrainBase), 0.0, 1.0);
    const double turnDemand = clampValue(input.steeringDemand * speedDemand * (1.0 - (terrainBase * 0.65)), 0.0, 1.0);
    const double brakeLoss = clampValue(input.brakeDemand * speedDemand * (1.0 - (terrainBase * 0.75)), 0.0, 1.0);
    const double airLoss = 1.0 - input.tireAirState;
    const double cleanGripLoss = clampValue(airLoss * 0.35, 0.0, 0.35);
    double tireDragPenalty = clampValue(airLoss * 0.35, 0.0, 0.75);
    double tireSteeringPenalty = clampValue(airLoss * 0.30, 0.0, 0.65);

    double tractionMultiplier = clampValue(terrainBase - cleanGripLoss - (roughness * speedDemand * 0.25), 0.20, 1.10);
    double accelerationTractionMultiplier = clampValue(tractionMultiplier * (1.0 - (accelDemand * 0.35)) * massModifier, 0.15, 1.10);
    double brakingTractionMultiplier = clampValue(tractionMultiplier * (1.0 - (brakeLoss * 0.28)), 0.20, 1.05);
    double turningTractionMultiplier = clampValue(tractionMultiplier * (1.0 - (turnDemand * 0.34)) * (1.0 - tireSteeringPenalty), 0.15, 1.05);
    double slopeTractionMultiplier = clampValue(tractionMultiplier * (1.0 - (input.slopeSeverity * (1.0 - terrainBase) * 0.25)), 0.20, 1.05);
    double wheelspinEstimate = clampValue(wheelspinBase + accelDemand + (airLoss * 0.25) + (roughness * speedDemand), 0.0, 1.0);

    const double destroyedTireRatio = clampValue(static_cast<double>(input.destroyedTireCount) / 4.0, 0.0, 1.0);
    const double destroyedTirePenalty = clampValue(destroyedTireRatio * 0.85 * looseAmplifier, 0.0, 0.90);
    double mobilityLimiter = rolloverSuppressed ? 0.0 : clampValue(1.0 - destroyedTirePenalty, 0.08, 1.0);

    accelerationTractionMultiplier = clampValue(accelerationTractionMultiplier * mobilityLimiter, 0.05, 1.10);
    brakingTractionMultiplier = clampValue(brakingTractionMultiplier * (1.0 - (destroyedTirePenalty * 0.35)), 0.05, 1.05);
    turningTractionMultiplier = clampValue(turningTractionMultiplier * (1.0 - (destroyedTirePenalty * 0.75)), 0.03, 1.05);
    slopeTractionMultiplier = clampValue(slopeTractionMultiplier * mobilityLimiter, 0.05, 1.05);
    tireDragPenalty = clampValue(tireDragPenalty + (destroyedTirePenalty * 0.45), 0.0, 0.95);
    tireSteeringPenalty = clampValue(tireSteeringPenalty + (destroyedTirePenalty * 0.65), 0.0, 0.95);
    if (rolloverSuppressed) {
        accelerationTractionMultiplier = 0.0;
        slopeTractionMultiplier = 0.0;
        wheelspinEstimate = 0.0;
    }

    const double driverlessDecay = input.driverlessDecayEnabled ? input.driverlessDecayCap : 0.0;

    return formatTerrainTire({
        true,
        tractionMultiplier,
        accelerationTractionMultiplier,
        brakingTractionMultiplier,
        turningTractionMultiplier,
        slopeTractionMultiplier,
        wheelspinEstimate,
        input.tireAirState,
        tireDragPenalty,
        tireSteeringPenalty,
        massModifier,
        wheelSupportState,
        rolloverSuppressed,
        driverlessDecay,
        input.destroyedTireCount,
        destroyedTireRatio,
        destroyedTirePenalty,
        mobilityLimiter,
        "native-terrain-tire"
    });
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
        copyOutput(output, outputSize, "[\"slopeControl\",[\"downhillX\",\"downhillY\",\"velocityX\",\"velocityY\",\"slope\",\"maxRollbackSpeed\",\"rollbackAcceleration\",\"minimumDelta\"],\"driverAssist\",[\"state\",\"requestedDirection\",\"longitudinalSpeed\",\"slope\",\"downhillAlignment\",\"deltaTime\",\"absBrakeStrength\",\"absReleaseBias\",\"absSlopeCompensation\",\"directionThreshold\",\"directionLaunchVelocity\",\"neutralPulseSeconds\",\"lowSpeedCutoff\",\"ignoreLowSpeedCutoff\"],\"terrainTireV2\",[\"terrainClass\",\"speedKmh\",\"throttleDemand\",\"brakeDemand\",\"steeringDemand\",\"slopeSeverity\",\"massKg\",\"deltaTime\",\"tireAirState\",\"tireDamage\",\"grounded\",\"lastGroundedAge\",\"vectorUpZ\",\"airborneGraceWindow\",\"driverlessDecayEnabled\",\"driverlessDecayCap\",\"destroyedTireThreshold\",\"destroyedTireCount\"]]");
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

    if (command == "terrainTireV2") {
        copyOutput(output, outputSize, terrainTireV2(args, argsCount));
        return 0;
    }

    copyOutput(output, outputSize, "Unknown FIXICSPhysics command");
    return 1;
}
}
