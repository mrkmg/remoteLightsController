RemoteLC_LightShow = RemoteLC_LightShow or {}
RemoteLC_LightShow.Modes = RemoteLC_LightShow.Modes or {}
RemoteLC_LightShow.Modes.ColorCycle = {
    type = "Standard",
    name = getText("UI_RemoteLC_ColorCycle"),
}

function RemoteLC_LightShow.Modes.ColorCycle.init(lightShowArgs)
    local colors = {}
    local tempLightDatas = {}
    for _, lightData in ipairs(lightShowArgs.lightDatas) do
        if not tempLightDatas[lightData.bulbColor] then
            tempLightDatas[lightData.bulbColor] = {}
            table.insert(colors, lightData.bulbColor)
        end
        table.insert(tempLightDatas[lightData.bulbColor], lightData)
    end
    local lightDatas = {}
    for i, d in ipairs(colors) do
        lightDatas[i] = tempLightDatas[d]
    end
    return {
        lightDatas = lightDatas,
        lastIndex = 1,
    }
end

function RemoteLC_LightShow.Modes.ColorCycle.run(lightShow, data)
    if not data.lightDatas or #data.lightDatas == 0 or not data.lastIndex then
        lightShow:destroy()
        return
    end

    local cell = getCell()
    RemoteLC_Utilities.SetLightsStateFromData(cell, data.lightDatas[data.lastIndex], false, true)
    data.lastIndex = data.lastIndex + 1
    if data.lastIndex > #data.lightDatas then
        data.lastIndex = 1
    end
    RemoteLC_Utilities.SetLightsStateFromData(cell, data.lightDatas[data.lastIndex], true, true)
end