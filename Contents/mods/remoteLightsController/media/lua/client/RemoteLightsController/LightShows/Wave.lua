RemoteLC_LightShow = RemoteLC_LightShow or {}
RemoteLC_LightShow.Modes = RemoteLC_LightShow.Modes or {}
RemoteLC_LightShow.Modes.Wave = {
    type = "Standard",
    name = getText("UI_RemoteLC_Wave"),
}

function RemoteLC_LightShow.Modes.Wave.init(lightShowArgs)
    local distances = {}
    local tempLightDatas = {}
    local player = getPlayer()
    local playerSquare = player:getSquare()
    for _, lightData in ipairs(lightShowArgs.lightDatas) do
        local d = math.floor(RemoteLC_Utilities.DistanceBetweenSquareAndLightData(playerSquare, lightData))
        if not tempLightDatas[d] then
            tempLightDatas[d] = {}
        end
        table.insert(tempLightDatas[d], lightData)
        table.insert(distances, d)
    end
    table.sort(distances)

    local lightDatas = {}
    for _, d in ipairs(distances) do
        for _, light in ipairs(tempLightDatas[d]) do
            table.insert(lightDatas, light)
        end
    end
    return {
        lightDatas = lightDatas,
        lastIndex = 1,
    }
end

function RemoteLC_LightShow.Modes.Wave.run(lightShow, data)
    if not data.lightDatas or #data.lightDatas == 0 or not data.lastIndex then
        lightShow:destroy()
        return
    end

    local cell = getCell()
    RemoteLC_Utilities.SetLightStateFromData(cell, data.lightDatas[data.lastIndex], false, true)
    data.lastIndex = data.lastIndex + 1
    if data.lastIndex > #data.lightDatas then
        data.lastIndex = 1
    end
    RemoteLC_Utilities.SetLightStateFromData(cell, data.lightDatas[data.lastIndex], true, true)
end