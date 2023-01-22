RemoteLC_Options = { light_sensitivity = false }

if ModOptions and ModOptions.getInstance then
    local settings = ModOptions:getInstance(RemoteLC_Options, "partyLightsController", "Remote Lights Controller")
    settings:getData("light_sensitivity").name = "UI_RemoteLC_LightSensitivity"
    settings:getData("light_sensitivity").tooltip = "UI_RemoteLC_LightSensitivity_Tooltip"
else
    RemoteLC_Options.light_sensitivity = false
end