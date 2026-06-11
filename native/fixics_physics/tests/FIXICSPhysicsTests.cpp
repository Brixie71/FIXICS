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
