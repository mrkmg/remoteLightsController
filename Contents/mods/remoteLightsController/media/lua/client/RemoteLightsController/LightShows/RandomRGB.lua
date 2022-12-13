RemoteLC_LightShow = RemoteLC_LightShow or {}
RemoteLC_LightShow.Modes = RemoteLC_LightShow.Modes or {}
RemoteLC_LightShow.Modes.RandomRGB = {
    type = "RGB",
    name = getText("UI_RemoteLC_Random"),
}

function RemoteLC_LightShow.Modes.RandomRGB.init(lightShowArgs)
    return nil
end

function RemoteLC_LightShow.Modes.RandomRGB.run(lightShow, data)
    if not lightShow.data.lightDatas then
        lightShow:destroy()
        return
    end

    local cell = getCell()
    for _, lightData in ipairs(lightShow.data.lightDatas) do
        local color = Color.HSBtoRGB(ZombRand(0, 255)/255, 1.0, 1.0)
        local c = {r = color:getRedFloat(), g = color:getGreenFloat(), b = color:getBlueFloat(), a = 1.0}
        RemoteLC_Utilities.SetLightColorFromData(cell, lightData, c, true)
    end
end