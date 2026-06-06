class CfgPatches
{
    class BASE_ARMA_main
    {
        name = "FIXICS - Main";
        author = "Brixie71";
        url = "";
        requiredVersion = 2.14;
        requiredAddons[] = {"A3_Functions_F", "ace_interact_menu"};
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
            file = "x\base_arma\addons\main\functions";

            class init
            {
                postInit = 1;
            };

            class hello {};
            class vrHello {};
            class registerAceInteractions {};
            class setVehicleHandbrake {};
            class shouldVehicleRoll {};
            class monitorVehicleAutobrake {};
        };
    };
};
