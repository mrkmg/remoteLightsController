RemoteLC_LightShow = RemoteLC_LightShow or {}
RemoteLC_LightShow.Modes = RemoteLC_LightShow.Modes or {}
RemoteLC_LightShow.Modes.ColorCycleRGB = {
    type = "RGB",
    name = getText("UI_RemoteLC_ColorCycle"),
    speeds = {Slow = 50, Normal = 50, Quick = 50}, -- always 20 fps
}

function RemoteLC_LightShow.Modes.ColorCycleRGB.init(lightShowArgs)
    local delta = 0.001
    if lightShowArgs.speed == "Slow" then
        delta = 0.001
    elseif lightShowArgs.speed == "Normal" then
        delta = 0.005
    elseif lightShowArgs.speed == "Quick" then
        delta = 0.01
    end
    return RemoteLC_Utilities.CreateColorWithShiftData(delta)
end

function RemoteLC_LightShow.Modes.ColorCycleRGB.run(lightShow, data)
    if not lightShow.data.lightDatas or #lightShow.data.lightDatas == 0 or not data.color then
        lightShow:destroy()
        return
    end

    RemoteLC_Utilities.ShiftColorHue(data)
    RemoteLC_Utilities.SetLightsColorFromData(getCell(), lightShow.data.lightDatas, data.color, true)
end