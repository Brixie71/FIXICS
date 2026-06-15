class CfgPatches
{
    class FIXICS_main
    {
        name = "FIXICS - Main";
        author = "Brixie71";
        url = "";
        requiredVersion = 2.14;
        requiredAddons[] = {"A3_Functions_F", "ace_interact_menu", "cba_common", "cba_settings"};
        units[] = {};
        weapons[] = {};
    };
};

class CfgFunctions
{
    class FIXICS
    {
        tag = "FIXICS";

        class Main
        {
            file = "x\fixics\addons\main\functions";

            class init
            {
                postInit = 1;
            };

            class hello {};
            class vrHello {};
            class registerSettings {};
            class registerAceInteractions {};
            class setVehicleHandbrake {};
            class shouldVehicleRoll {};
            class monitorVehicleAutobrake {};
            class applySlopeRollback {};
            class applyHandbrakeLock {};
            class applyABSBraking {};
            class getDriverInputIntent {};
            class registerVehicleControls {};
            class updateDriverController {};
            class logVehicleHandlingConfig {};
            class getNativeSlopeControl {};
            class getNativeDriverAssist {};
            class getVehicleStabilityProfile {};
            class getVehicleStabilityRecommendation {};
        };
    };
};
