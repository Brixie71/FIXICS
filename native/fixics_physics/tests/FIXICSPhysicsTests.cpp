#include <cstdlib>
#include <iostream>
#include <locale>
#include <string>
#include <vector>

#ifdef _WIN32
#define FIXICS_CALL __stdcall
#else
#define FIXICS_CALL
#endif

extern "C" int FIXICS_CALL RVExtensionArgs(
    char* output,
    unsigned int outputSize,
    const char* function,
    const char** args,
    unsigned int argsCount);

namespace {
class CommaDecimalPoint final : public std::numpunct<char> {
protected:
    char do_decimal_point() const override
    {
        return ',';
    }
};

std::string callDriverAssist(const std::vector<std::string>& values)
{
    std::vector<const char*> args;
    args.reserve(values.size());
    for (const auto& value : values) {
        args.push_back(value.c_str());
    }

    char output[1024] = {};
    RVExtensionArgs(
        output,
        static_cast<unsigned int>(sizeof(output)),
        "driverAssist",
        args.data(),
        static_cast<unsigned int>(args.size()));
    return output;
}

std::string callDriverAssist(const std::vector<const char*>& args, int& status)
{
    std::vector<const char*> mutableArgs = args;
    char output[1024] = {};
    status = RVExtensionArgs(
        output,
        static_cast<unsigned int>(sizeof(output)),
        "driverAssist",
        mutableArgs.data(),
        static_cast<unsigned int>(mutableArgs.size()));
    return output;
}

std::string callSlopeControl(const std::vector<std::string>& values, int& status)
{
    std::vector<const char*> args;
    args.reserve(values.size());
    for (const auto& value : values) {
        args.push_back(value.c_str());
    }

    char output[1024] = {};
    status = RVExtensionArgs(
        output,
        static_cast<unsigned int>(sizeof(output)),
        "slopeControl",
        args.data(),
        static_cast<unsigned int>(args.size()));
    return output;
}

std::string callTerrainTireV2(const std::vector<std::string>& values, int& status)
{
    std::vector<const char*> args;
    args.reserve(values.size());
    for (const auto& value : values) {
        args.push_back(value.c_str());
    }

    char output[2048] = {};
    status = RVExtensionArgs(
        output,
        static_cast<unsigned int>(sizeof(output)),
        "terrainTireV2",
        args.data(),
        static_cast<unsigned int>(args.size()));
    return output;
}

void expectEqual(const std::string& label, const std::string& actual, const std::string& expected)
{
    if (actual == expected) {
        return;
    }

    std::cerr << label << "\nExpected: " << expected << "\nActual:   " << actual << '\n';
    std::exit(EXIT_FAILURE);
}
}

int main()
{
    expectEqual(
        "forward braking",
        callDriverAssist({"SERVICE_BRAKE", "0", "5", "0.5", "1", "0.125", "0.5", "0.1", "0.6", "0.5", "0.35", "0.15", "0.25", "0"}),
        "[true,\"SERVICE_BRAKE\",4.7075,0.2925,0,\"brake\"]");
    expectEqual(
        "reverse braking",
        callDriverAssist({"SERVICE_BRAKE", "0", "-5", "0.5", "1", "0.125", "0.5", "0.1", "0.6", "0.5", "0.35", "0.15", "0.25", "0"}),
        "[true,\"SERVICE_BRAKE\",-4.7075,0.2925,0,\"brake\"]");
    expectEqual(
        "low speed cutoff",
        callDriverAssist({"COAST", "0", "0.5", "0", "0", "0.25", "0.5", "0", "0", "0.25", "0.35", "0.15", "0.5", "0"}),
        "[false,\"NONE\",0.5,0,0,\"below-cutoff\"]");
    expectEqual(
        "neutral launch",
        callDriverAssist({"NEUTRAL", "1", "0", "0", "0", "0.25", "0.5", "0", "0", "0.25", "0.35", "0.15", "0.1", "1"}),
        "[true,\"LAUNCH\",0.35,0,1,\"launch\"]");
    expectEqual(
        "non-finite input",
        callDriverAssist({"SERVICE_BRAKE", "0", "nan", "0", "0", "0.25", "0.5", "0", "0", "0.25", "0.35", "0.15", "0.1", "0"}),
        "[false,\"NONE\",0,0,0,\"invalid\"]");
    expectEqual(
        "trailing junk input",
        callDriverAssist({"SERVICE_BRAKE", "0", "5junk", "0", "0", "0.25", "0.5", "0", "0", "0.25", "0.35", "0.15", "0.1", "0"}),
        "[false,\"NONE\",0,0,0,\"invalid\"]");

    int status = -1;
    const std::vector<const char*> nullSpeedArgs = {
        "SERVICE_BRAKE", "0", nullptr, "0", "0", "0.25", "0.5", "0", "0", "0.25", "0.35", "0.15", "0.1", "0"
    };
    expectEqual(
        "null numeric input",
        callDriverAssist(nullSpeedArgs, status),
        "[false,\"NONE\",0,0,0,\"invalid\"]");
    if (status != 0) {
        std::cerr << "driverAssist ABI status\nExpected: 0\nActual:   " << status << '\n';
        return EXIT_FAILURE;
    }

    expectEqual(
        "slopeControl regression",
        callSlopeControl({"1", "0", "0", "0", "0.5", "2", "1", "0"}, status),
        "[true,0.5,0,0]");
    if (status != 0) {
        std::cerr << "slopeControl ABI status\nExpected: 0\nActual:   " << status << '\n';
        return EXIT_FAILURE;
    }

    expectEqual(
        "terrainTireV2 paved supported",
        callTerrainTireV2({"0", "80", "0.4", "0", "0.2", "0.05", "1600", "0.05", "1", "0", "1", "0", "1", "0.50", "1", "0.15", "0.85", "0"}, status),
        "[true,0.996111111111,1.00607222222,0.996111111111,0.977671987654,0.996111111111,0.0955555555556,1,0,0,1.01,\"SUPPORTED\",false,0.15,0,0,0,1,\"native-terrain-tire\"]");
    if (status != 0) {
        std::cerr << "terrainTireV2 paved ABI status\nExpected: 0\nActual:   " << status << '\n';
        return EXIT_FAILURE;
    }

    expectEqual(
        "terrainTireV2 flipped suppresses mobility",
        callTerrainTireV2({"0", "20", "0.6", "0", "0.5", "0.1", "1600", "0.05", "1", "0", "1", "0", "-0.5", "0.50", "1", "0.15", "0.85", "0"}, status),
        "[true,0.999444444444,0,0.999444444444,0.992837006173,0,0,1,0,0,1.01,\"FLIPPED\",true,0.15,0,0,0,0,\"native-terrain-tire\"]");
    if (status != 0) {
        std::cerr << "terrainTireV2 flipped ABI status\nExpected: 0\nActual:   " << status << '\n';
        return EXIT_FAILURE;
    }

    expectEqual(
        "terrainTireV2 destroyed tire",
        callTerrainTireV2({"3", "40", "0.7", "0", "0.4", "0.1", "1800", "0.05", "0.8", "0.9", "1", "0", "1", "0.50", "1", "0.15", "0.85", "1"}, status),
        "[true,0.44,0.2741063094,0.39582125,0.314869571229,0.3100097,0.976,0.8,0.19909375,0.24646875,0.99,\"SUPPORTED\",false,0.15,1,0.25,0.286875,0.713125,\"native-terrain-tire\"]");
    if (status != 0) {
        std::cerr << "terrainTireV2 destroyed ABI status\nExpected: 0\nActual:   " << status << '\n';
        return EXIT_FAILURE;
    }

    expectEqual(
        "terrainTireV2 non-finite input",
        callTerrainTireV2({"0", "nan", "0", "0", "0", "0", "1500", "0.05", "1", "0", "1", "0", "1", "0.50", "1", "0.15", "0.85", "0"}, status),
        "[false,1,1,1,1,1,0,1,0,0,1,\"UNKNOWN\",false,0,0,0,0,1,\"invalid\"]");
    if (status != 0) {
        std::cerr << "terrainTireV2 invalid ABI status\nExpected: 0\nActual:   " << status << '\n';
        return EXIT_FAILURE;
    }

    const std::locale originalLocale = std::locale();
    std::locale::global(std::locale(originalLocale, new CommaDecimalPoint));
    const std::string localeOutput = callDriverAssist(
        {"SERVICE_BRAKE", "0", "5", "0.5", "1", "0.125", "0.5", "0.1", "0.6", "0.5", "0.35", "0.15", "0.25", "0"});
    std::locale::global(originalLocale);
    expectEqual(
        "locale-independent output",
        localeOutput,
        "[true,\"SERVICE_BRAKE\",4.7075,0.2925,0,\"brake\"]");

    return EXIT_SUCCESS;
}
